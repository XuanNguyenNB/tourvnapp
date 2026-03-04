import 'dart:math';

import '../../domain/utils/geo_utils.dart';
import '../../domain/models/itinerary_constraints.dart';
import '../../../destination/domain/entities/location.dart';
import '../../../trip/domain/entities/activity.dart';
import '../../../trip/domain/entities/trip_day.dart';

/// Result of itinerary generation for a single day.
class GeneratedDay {
  final int dayIndex;
  final List<GeneratedSlot> slots;

  const GeneratedDay({required this.dayIndex, required this.slots});

  /// Convert to TripDay for the Trip entity.
  TripDay toTripDay() {
    return TripDay(
      dayNumber: dayIndex + 1, // TripDay uses 1-based dayNumber
      activities: slots.asMap().entries.map((e) {
        final slot = e.value;
        return Activity(
          id: '${dayIndex}_${e.key}_${slot.location.id}',
          locationId: slot.location.id,
          locationName: slot.location.name,
          emoji: slot.location.categoryEmoji,
          imageUrl: slot.location.image,
          timeSlot: slot.timeSlotName,
          sortOrder: e.key,
          estimatedDurationMin: slot.location.estimatedDurationMin,
          destinationId: slot.location.destinationId,
          destinationName: slot.location.resolvedDestinationName,
        );
      }).toList(),
    );
  }
}

/// A single slot assignment in the generated itinerary.
class GeneratedSlot {
  final Location location;
  final String timeSlotName; // 'morning', 'afternoon', 'evening'
  final int startMinute; // Minutes from midnight
  final int durationMin;

  const GeneratedSlot({
    required this.location,
    required this.timeSlotName,
    required this.startMinute,
    required this.durationMin,
  });
}

/// Service implementing the Smart Itinerary generation algorithm.
///
/// Pipeline:
/// 1. Filter locations with valid coordinates
/// 2. K-Means clustering → assign locations to days
/// 3. Nearest-Neighbor + 2-opt → optimize route per day
/// 4. Heuristic → assign time slots based on category preferences
class ItineraryService {
  const ItineraryService();

  /// Generate a full itinerary from a list of candidate locations.
  ///
  /// Returns a list of [GeneratedDay] that can be converted to [TripDay].
  List<GeneratedDay> generate({
    required List<Location> candidates,
    required ItineraryConstraints constraints,
  }) {
    // Step 0: Filter to locations with coordinates
    final locationsWithCoords = candidates
        .where((l) => l.hasCoordinates)
        .toList();
    if (locationsWithCoords.isEmpty) return [];

    // Cap total locations based on pace × days
    final maxTotal = constraints.maxLocationsPerDay * constraints.numberOfDays;
    final selected = locationsWithCoords.length > maxTotal
        ? _selectTopLocations(locationsWithCoords, maxTotal)
        : locationsWithCoords;

    // Step 1: Cluster locations into days
    final clusters = _kMeansCluster(selected, constraints.numberOfDays);

    // Step 2 & 3: For each cluster, optimize route then assign time slots
    final days = <GeneratedDay>[];
    for (int d = 0; d < clusters.length; d++) {
      if (clusters[d].isEmpty) continue;

      // Optimize route within cluster
      final ordered = _optimizeRoute(clusters[d]);

      // Assign time slots
      final slots = _assignTimeSlots(ordered, constraints);

      days.add(GeneratedDay(dayIndex: d, slots: slots));
    }

    return days;
  }

  // ──── Step 0: Select top locations by quality ────

  List<Location> _selectTopLocations(List<Location> locs, int n) {
    final sorted = List.of(locs)
      ..sort((a, b) {
        final scoreA = (a.rating ?? 0) * 2 + a.saveCount + a.viewCount * 0.1;
        final scoreB = (b.rating ?? 0) * 2 + b.saveCount + b.viewCount * 0.1;
        return scoreB.compareTo(scoreA);
      });
    return sorted.take(n).toList();
  }

  // ──── Step 1: K-Means Clustering ────

  /// Simple K-Means clustering to partition locations into [k] groups
  /// based on geographic proximity.
  List<List<Location>> _kMeansCluster(List<Location> locations, int k) {
    if (locations.length <= k) {
      // One location per day max
      return List.generate(
        k,
        (i) => i < locations.length ? [locations[i]] : [],
      );
    }

    final rng = Random(42); // Fixed seed for deterministic results
    final n = locations.length;

    // Initialize centroids using K-Means++ strategy
    final centroids = _initCentroids(locations, k, rng);

    // Iterate until convergence (max 20 iterations)
    var assignments = List.filled(n, 0);
    for (int iter = 0; iter < 20; iter++) {
      // Assign each location to nearest centroid
      final newAssignments = List.filled(n, 0);
      for (int i = 0; i < n; i++) {
        double minDist = double.infinity;
        for (int c = 0; c < k; c++) {
          final d = GeoUtils.haversineKm(
            locations[i].latitude!,
            locations[i].longitude!,
            centroids[c].$1,
            centroids[c].$2,
          );
          if (d < minDist) {
            minDist = d;
            newAssignments[i] = c;
          }
        }
      }

      // Check convergence
      bool converged = true;
      for (int i = 0; i < n; i++) {
        if (newAssignments[i] != assignments[i]) {
          converged = true;
          break;
        }
      }
      assignments = newAssignments;

      // Update centroids
      for (int c = 0; c < k; c++) {
        double sumLat = 0, sumLon = 0;
        int count = 0;
        for (int i = 0; i < n; i++) {
          if (assignments[i] == c) {
            sumLat += locations[i].latitude!;
            sumLon += locations[i].longitude!;
            count++;
          }
        }
        if (count > 0) {
          centroids[c] = (sumLat / count, sumLon / count);
        }
      }

      if (converged && iter > 0) break;
    }

    // Group locations by assignment
    final clusters = List.generate(k, (_) => <Location>[]);
    for (int i = 0; i < n; i++) {
      clusters[assignments[i]].add(locations[i]);
    }

    // Balance: cap each cluster to maxLocationsPerDay
    // Reassign overflow to nearest non-full cluster
    return _balanceClusters(clusters, locations.length ~/ k + 1);
  }

  /// K-Means++ centroid initialization.
  List<(double, double)> _initCentroids(
    List<Location> locations,
    int k,
    Random rng,
  ) {
    final centroids = <(double, double)>[];
    // Pick first centroid randomly
    final first = locations[rng.nextInt(locations.length)];
    centroids.add((first.latitude!, first.longitude!));

    // Pick remaining centroids proportional to distance²
    for (int c = 1; c < k; c++) {
      final distances = <double>[];
      for (final loc in locations) {
        double minDist = double.infinity;
        for (final cent in centroids) {
          final d = GeoUtils.haversineKm(
            loc.latitude!,
            loc.longitude!,
            cent.$1,
            cent.$2,
          );
          minDist = min(minDist, d);
        }
        distances.add(minDist * minDist); // Distance squared
      }
      final total = distances.reduce((a, b) => a + b);
      if (total == 0) break;

      double target = rng.nextDouble() * total;
      for (int i = 0; i < locations.length; i++) {
        target -= distances[i];
        if (target <= 0) {
          centroids.add((locations[i].latitude!, locations[i].longitude!));
          break;
        }
      }
    }

    // Fill remaining if needed
    while (centroids.length < k) {
      final loc = locations[rng.nextInt(locations.length)];
      centroids.add((loc.latitude!, loc.longitude!));
    }

    return centroids;
  }

  /// Balance clusters so no cluster exceeds [maxPerCluster].
  List<List<Location>> _balanceClusters(
    List<List<Location>> clusters,
    int maxPerCluster,
  ) {
    for (int c = 0; c < clusters.length; c++) {
      while (clusters[c].length > maxPerCluster) {
        final overflow = clusters[c].removeLast();
        // Find nearest non-full cluster
        int bestCluster = -1;
        double bestDist = double.infinity;
        for (int other = 0; other < clusters.length; other++) {
          if (other == c || clusters[other].length >= maxPerCluster) continue;
          if (clusters[other].isEmpty) {
            bestCluster = other;
            break;
          }
          final centLat =
              clusters[other].map((l) => l.latitude!).reduce((a, b) => a + b) /
              clusters[other].length;
          final centLon =
              clusters[other].map((l) => l.longitude!).reduce((a, b) => a + b) /
              clusters[other].length;
          final d = GeoUtils.haversineKm(
            overflow.latitude!,
            overflow.longitude!,
            centLat,
            centLon,
          );
          if (d < bestDist) {
            bestDist = d;
            bestCluster = other;
          }
        }
        if (bestCluster >= 0) {
          clusters[bestCluster].add(overflow);
        } else {
          clusters[c].add(overflow); // Can't rebalance, keep it
          break;
        }
      }
    }
    return clusters;
  }

  // ──── Step 2: Route Optimization (Nearest Neighbor + 2-opt) ────

  /// Order locations within a day to minimize total travel distance.
  List<Location> _optimizeRoute(List<Location> locations) {
    if (locations.length <= 2) return locations;

    // Build distance matrix
    final points = locations
        .map((l) => (lat: l.latitude!, lon: l.longitude!))
        .toList();
    final dMatrix = GeoUtils.distanceMatrix(points);

    // Nearest-Neighbor starting from each point, pick best
    var bestRoute = _nearestNeighbor(dMatrix, 0);
    var bestCost = _routeCost(dMatrix, bestRoute);

    for (int start = 1; start < locations.length; start++) {
      final route = _nearestNeighbor(dMatrix, start);
      final cost = _routeCost(dMatrix, route);
      if (cost < bestCost) {
        bestCost = cost;
        bestRoute = route;
      }
    }

    // Improve with 2-opt
    bestRoute = _twoOpt(dMatrix, bestRoute);

    return bestRoute.map((i) => locations[i]).toList();
  }

  /// Nearest-Neighbor heuristic from a starting point.
  List<int> _nearestNeighbor(List<List<double>> dist, int start) {
    final n = dist.length;
    final visited = List.filled(n, false);
    final route = <int>[start];
    visited[start] = true;

    for (int step = 1; step < n; step++) {
      int current = route.last;
      int nearest = -1;
      double minDist = double.infinity;
      for (int j = 0; j < n; j++) {
        if (!visited[j] && dist[current][j] < minDist) {
          minDist = dist[current][j];
          nearest = j;
        }
      }
      if (nearest >= 0) {
        route.add(nearest);
        visited[nearest] = true;
      }
    }
    return route;
  }

  /// 2-opt local search improvement.
  List<int> _twoOpt(List<List<double>> dist, List<int> route) {
    final n = route.length;
    if (n < 4) return route;

    var improved = true;
    var bestRoute = List.of(route);
    var bestCost = _routeCost(dist, bestRoute);

    while (improved) {
      improved = false;
      for (int i = 0; i < n - 1; i++) {
        for (int j = i + 2; j < n; j++) {
          final newRoute = List.of(bestRoute);
          // Reverse segment between i+1 and j
          final segment = newRoute.sublist(i + 1, j + 1).reversed.toList();
          newRoute.replaceRange(i + 1, j + 1, segment);
          final newCost = _routeCost(dist, newRoute);
          if (newCost < bestCost - 0.001) {
            bestRoute = newRoute;
            bestCost = newCost;
            improved = true;
          }
        }
      }
    }
    return bestRoute;
  }

  /// Total route distance (sum of consecutive pair distances).
  double _routeCost(List<List<double>> dist, List<int> route) {
    double cost = 0;
    for (int i = 0; i < route.length - 1; i++) {
      cost += dist[route[i]][route[i + 1]];
    }
    return cost;
  }

  // ──── Step 3: Time Slot Assignment ────

  /// Assign time slots to ordered locations based on category preferences.
  ///
  /// Two‑phase approach:
  ///   Phase 1 – Pin essential categories to realistic time slots:
  ///     • Stay → first slot of the day (check‑in / drop luggage)
  ///     • Food → lunch (~11:30) and dinner (~18:30)
  ///   Phase 2 – Fill remaining capacity with other categories using
  ///             the existing preference × capacity scoring heuristic.
  List<GeneratedSlot> _assignTimeSlots(
    List<Location> orderedLocations,
    ItineraryConstraints constraints,
  ) {
    final slots = <GeneratedSlot>[];
    final slotNames = ['morning', 'afternoon', 'evening'];
    final slotBudgets = [
      constraints.morningBudget,
      constraints.afternoonBudget,
      constraints.eveningBudget,
    ];
    final slotStarts = [
      constraints.morningStart * 60,
      constraints.afternoonStart * 60,
      constraints.eveningStart * 60,
    ];
    final slotUsed = [0, 0, 0]; // Minutes used per slot

    // Separate essential vs other locations
    final stayLocations = <Location>[];
    final foodLocations = <Location>[];
    final otherLocations = <Location>[];

    for (final loc in orderedLocations) {
      final cat = loc.category.toLowerCase();
      if (cat == 'stay') {
        stayLocations.add(loc);
      } else if (cat == 'food') {
        foodLocations.add(loc);
      } else {
        otherLocations.add(loc);
      }
    }

    // ── Phase 1: Pin essential slots ──

    // Stay → morning (check-in at day start, ~8:00, 30 min)
    for (final stay in stayLocations) {
      final duration = stay.estimatedDurationMin ?? 30;
      slots.add(
        GeneratedSlot(
          location: stay,
          timeSlotName: 'morning',
          startMinute: slotStarts[0] + slotUsed[0],
          durationMin: duration,
        ),
      );
      slotUsed[0] += duration + 15;
    }

    // Food → distribute: odd-indexed to lunch (morning slot end ~11:30),
    //                     even-indexed to dinner (evening slot start ~18:30)
    bool nextIsLunch = true;
    for (final food in foodLocations) {
      final duration = food.estimatedDurationMin ?? 60;

      if (nextIsLunch) {
        // Lunch: place at end of morning slot (~11:30)
        final lunchStart = constraints.morningEnd * 60 - 60; // ~11:00
        final actualStart = max(slotStarts[0] + slotUsed[0], lunchStart);
        slots.add(
          GeneratedSlot(
            location: food,
            timeSlotName: 'morning',
            startMinute: actualStart,
            durationMin: duration,
          ),
        );
        slotUsed[0] += duration + 15;
      } else {
        // Dinner: place at start of evening slot (~18:00-18:30)
        slots.add(
          GeneratedSlot(
            location: food,
            timeSlotName: 'evening',
            startMinute: slotStarts[2] + slotUsed[2],
            durationMin: duration,
          ),
        );
        slotUsed[2] += duration + 15;
      }
      nextIsLunch = !nextIsLunch;
    }

    // ── Phase 2: Fill remaining with other categories ──
    for (final loc in otherLocations) {
      final duration =
          loc.estimatedDurationMin ?? constraints.defaultDurationMin;
      final cat = loc.category.toLowerCase();

      // Score each slot by: category preference × remaining capacity
      int bestSlot = 0;
      double bestScore = -1;
      for (int s = 0; s < 3; s++) {
        final remaining = slotBudgets[s] - slotUsed[s];
        if (remaining < duration) continue; // Not enough time

        final pref = categorySlotPreferences[cat]?[slotNames[s]] ?? 0.5;
        final capRatio = remaining / slotBudgets[s]; // Prefer emptier slots
        final score = pref * 0.7 + capRatio * 0.3;

        if (score > bestScore) {
          bestScore = score;
          bestSlot = s;
        }
      }

      // If all slots full, still assign to least-full slot
      if (bestScore < 0) {
        int minUsed = slotUsed[0];
        bestSlot = 0;
        for (int s = 1; s < 3; s++) {
          if (slotUsed[s] < minUsed) {
            minUsed = slotUsed[s];
            bestSlot = s;
          }
        }
      }

      slots.add(
        GeneratedSlot(
          location: loc,
          timeSlotName: slotNames[bestSlot],
          startMinute: slotStarts[bestSlot] + slotUsed[bestSlot],
          durationMin: duration,
        ),
      );
      slotUsed[bestSlot] += duration + 15; // +15 min buffer between activities
    }

    return slots;
  }
}
