import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/location.dart';
import '../../domain/entities/category.dart';
import '../../data/repositories/destination_repository.dart';
import '../../data/repositories/category_repository.dart';
import '../../../recommendation/presentation/providers/recommendation_provider.dart';

/// Repository provider for destination data.
final destinationRepositoryProvider = Provider<DestinationRepository>((ref) {
  return DestinationRepository();
});

/// Repository provider for category data.
final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  return CategoryRepository();
});

/// Provider for fetching active categories dynamically from Firestore.
///
/// Returns a list with an "All" tab prepended, followed by active categories.
/// This replaces the old hardcoded `categoryTabs` list.
final categoryTabsProvider = FutureProvider<List<Category>>((ref) async {
  final repo = ref.read(categoryRepositoryProvider);
  final active = await repo.getActiveCategories();
  // Prepend the "All" virtual category
  return [
    const Category(id: 'all', name: 'Tất cả', emoji: '✨', sortOrder: -1),
    ...active,
  ];
});

/// Provider for fetching all locations for a specific destination.
///
/// Usage:
/// ```dart
/// final locationsAsync = ref.watch(locationsForDestinationProvider(destinationId));
/// ```
final locationsForDestinationProvider =
    FutureProvider.family<List<Location>, String>((ref, destinationId) async {
      final repository = ref.read(destinationRepositoryProvider);
      return repository.getLocationsByDestination(destinationId);
    });

/// Notifier for managing selected category state.
///
/// Riverpod 3.x pattern using Notifier instead of StateProvider.
class SelectedCategoryNotifier extends Notifier<String> {
  @override
  String build() => 'all';

  void select(String category) {
    state = category;
  }
}

/// Provider for the currently selected category tab.
final selectedCategoryProvider =
    NotifierProvider<SelectedCategoryNotifier, String>(
      SelectedCategoryNotifier.new,
    );

/// Provider for filtered locations based on selected category.
///
/// Watches both the locations list and selected category,
/// returns filtered results **sorted by recommendation score** (hottest first).
final filteredLocationsProvider =
    Provider.family<AsyncValue<List<Location>>, String>((ref, destinationId) {
      final locationsAsync = ref.watch(
        locationsForDestinationProvider(destinationId),
      );
      final category = ref.watch(selectedCategoryProvider);

      // Watch recommendation data for sorting
      final recAsync = ref.watch(recommendedLocationsProvider(destinationId));

      return locationsAsync.whenData((locations) {
        // Filter by category
        List<Location> filtered;
        if (category == 'all') {
          filtered = List.of(locations);
        } else {
          filtered = locations
              .where((l) => l.category.toLowerCase() == category.toLowerCase())
              .toList();
        }

        // Sort by recommendation score (hottest first)
        final recData = recAsync.whenOrNull(data: (recs) => recs);
        if (recData != null && recData.isNotEmpty) {
          // Build score map: locationId -> score
          final scoreMap = {for (final r in recData) r.locationId: r.score};
          filtered.sort((a, b) {
            final scoreA = scoreMap[a.id] ?? 0.0;
            final scoreB = scoreMap[b.id] ?? 0.0;
            return scoreB.compareTo(scoreA); // Descending: highest first
          });
        } else {
          // Fallback: sort by popularity (viewCount + saveCount)
          filtered.sort((a, b) {
            final popA = a.viewCount + a.saveCount;
            final popB = b.viewCount + b.saveCount;
            return popB.compareTo(popA);
          });
        }

        return filtered;
      });
    });

/// Provider for getting a single location by ID.
final locationByIdProvider = FutureProvider.family<Location, String>((
  ref,
  locationId,
) async {
  final repository = ref.read(destinationRepositoryProvider);
  return repository.getLocationById(locationId);
});
