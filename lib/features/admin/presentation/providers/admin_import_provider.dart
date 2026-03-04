import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../destination/data/repositories/destination_repository.dart';
import '../../../destination/domain/entities/destination.dart';
import '../../../destination/domain/entities/location.dart';
import '../../../destination/presentation/providers/destination_provider.dart';
import '../../../review/data/repositories/review_repository.dart';
import '../../../review/domain/entities/review.dart';

/// Parsed data from JSON file, ready for preview and import.
class ParsedImportData {
  final List<Destination> destinations;
  final List<Location> locations;
  final List<Review> reviews;

  const ParsedImportData({
    this.destinations = const [],
    this.locations = const [],
    this.reviews = const [],
  });

  int get totalCount => destinations.length + locations.length + reviews.length;
}

/// Progress tracking during import.
class ImportProgress {
  final int imported;
  final int skipped;
  final int failed;
  final int total;
  final String currentCollection;
  final List<String> errors;

  const ImportProgress({
    this.imported = 0,
    this.skipped = 0,
    this.failed = 0,
    this.total = 0,
    this.currentCollection = '',
    this.errors = const [],
  });

  double get progress => total == 0 ? 0 : (imported + skipped + failed) / total;
}

/// States for the import flow.
sealed class ImportState {
  const ImportState();
}

class ImportIdle extends ImportState {
  const ImportIdle();
}

class ImportParsing extends ImportState {
  const ImportParsing();
}

class ImportParsed extends ImportState {
  final ParsedImportData data;
  const ImportParsed(this.data);
}

class ImportInProgress extends ImportState {
  final ImportProgress progress;
  const ImportInProgress(this.progress);
}

class ImportSuccess extends ImportState {
  final ImportProgress result;
  const ImportSuccess(this.result);
}

class ImportError extends ImportState {
  final String message;
  const ImportError(this.message);
}

class AdminImportNotifier extends Notifier<ImportState> {
  late final DestinationRepository _destRepo;
  late final ReviewRepository _reviewRepo;

  @override
  ImportState build() {
    _destRepo = ref.watch(destinationRepositoryProvider);
    _reviewRepo = ref.watch(reviewRepositoryProvider);
    return const ImportIdle();
  }

  /// Parse JSON string into structured data for preview.
  void parseJson(String jsonString) {
    state = const ImportParsing();
    try {
      final Map<String, dynamic> json = jsonDecode(jsonString);

      // Parse destinations
      final destinations = <Destination>[];
      if (json.containsKey('destinations')) {
        for (final d in json['destinations'] as List) {
          final map = d as Map<String, dynamic>;
          destinations.add(
            Destination(
              id: map['id'] as String,
              name: map['name'] as String,
              heroImage: map['heroImage'] as String? ?? '',
              description: map['description'] as String? ?? '',
              countryCode: map['countryCode'] as String? ?? 'VN',
              status: map['status'] as String? ?? 'published',
              createdAt: map['createdAt'] != null
                  ? DateTime.tryParse(map['createdAt'] as String) ??
                        DateTime.now()
                  : DateTime.now(),
              engagementCount: map['engagementCount'] as int? ?? 0,
              postCount: map['postCount'] as int? ?? 0,
              locationCount: map['locationCount'] as int? ?? 0,
            ),
          );
        }
      }

      // Parse locations
      final locations = <Location>[];
      if (json.containsKey('locations')) {
        for (final l in json['locations'] as List) {
          final map = l as Map<String, dynamic>;
          locations.add(
            Location(
              id: map['id'] as String,
              destinationId: map['destinationId'] as String,
              destinationName: map['destinationName'] as String?,
              name: map['name'] as String,
              image: map['image'] as String? ?? '',
              category: map['category'] as String? ?? 'places',
              address: map['address'] as String?,
              description: map['description'] as String?,
              priceRange: map['priceRange'] as String?,
              rating: (map['rating'] as num?)?.toDouble(),
              latitude: (map['latitude'] as num?)?.toDouble(),
              longitude: (map['longitude'] as num?)?.toDouble(),
              tags:
                  (map['tags'] as List?)?.map((e) => e.toString()).toList() ??
                  [],
              searchKeywords:
                  (map['searchKeywords'] as List?)
                      ?.map((e) => e.toString())
                      .toList() ??
                  [],
              estimatedDurationMin: map['estimatedDurationMin'] as int?,
              status: map['status'] as String? ?? 'published',
              viewCount: map['viewCount'] as int? ?? 0,
              saveCount: map['saveCount'] as int? ?? 0,
            ),
          );
        }
      }

      // Parse reviews
      final reviews = <Review>[];
      if (json.containsKey('reviews')) {
        for (final r in json['reviews'] as List) {
          final map = r as Map<String, dynamic>;
          reviews.add(
            Review(
              id: map['id'] as String,
              heroImage: map['heroImage'] as String? ?? '',
              title: map['title'] as String? ?? '',
              authorId: map['authorId'] as String? ?? 'admin',
              authorName: map['authorName'] as String? ?? 'Admin',
              authorAvatar: map['authorAvatar'] as String? ?? '',
              fullText: map['fullText'] as String? ?? '',
              createdAt:
                  DateTime.tryParse(map['createdAt'] as String? ?? '') ??
                  DateTime.now(),
              likeCount: map['likeCount'] as int? ?? 0,
              commentCount: map['commentCount'] as int? ?? 0,
              saveCount: map['saveCount'] as int? ?? 0,
              destinationId: map['destinationId'] as String?,
              destinationName: map['destinationName'] as String?,
              category: map['category'] as String?,
              slug: map['slug'] as String?,
              status: map['status'] as String? ?? 'published',
              relatedLocationIds:
                  (map['relatedLocationIds'] as List?)
                      ?.map((e) => e.toString())
                      .toList() ??
                  [],
            ),
          );
        }
      }

      state = ImportParsed(
        ParsedImportData(
          destinations: destinations,
          locations: locations,
          reviews: reviews,
        ),
      );
    } catch (e) {
      state = ImportError('Lỗi parse JSON: $e');
    }
  }

  /// Import parsed data into Firestore with progress tracking.
  Future<void> importToFirestore(ParsedImportData data) async {
    final errors = <String>[];
    int imported = 0;
    int skipped = 0;
    int failed = 0;
    final total = data.totalCount;

    void updateProgress(String collection) {
      state = ImportInProgress(
        ImportProgress(
          imported: imported,
          skipped: skipped,
          failed: failed,
          total: total,
          currentCollection: collection,
          errors: errors,
        ),
      );
    }

    // --- Import destinations ---
    for (final dest in data.destinations) {
      updateProgress('destinations');
      try {
        // Check if exists
        try {
          await _destRepo.getDestinationById(dest.id);
          skipped++;
          continue; // Already exists
        } catch (_) {
          // Not found — proceed to create
        }
        await _destRepo.createDestination(dest);
        imported++;
      } catch (e) {
        failed++;
        errors.add('Destination "${dest.name}": $e');
      }
    }

    // --- Import locations ---
    for (final loc in data.locations) {
      updateProgress('locations');
      try {
        try {
          await _destRepo.getLocationById(loc.id);
          skipped++;
          continue;
        } catch (_) {}
        await _destRepo.createLocation(loc);
        imported++;
      } catch (e) {
        failed++;
        errors.add('Location "${loc.name}": $e');
      }
    }

    // --- Import reviews ---
    for (final review in data.reviews) {
      updateProgress('reviews');
      try {
        try {
          await _reviewRepo.getReviewById(review.id);
          skipped++;
          continue;
        } catch (_) {}
        await _reviewRepo.createReview(review);
        imported++;
      } catch (e) {
        failed++;
        errors.add('Review "${review.title}": $e');
      }
    }

    state = ImportSuccess(
      ImportProgress(
        imported: imported,
        skipped: skipped,
        failed: failed,
        total: total,
        errors: errors,
      ),
    );
  }

  /// Reset state to idle.
  void reset() {
    state = const ImportIdle();
  }
}

final adminImportProvider = NotifierProvider<AdminImportNotifier, ImportState>(
  AdminImportNotifier.new,
);
