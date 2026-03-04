import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../destination/data/repositories/destination_repository.dart';
import '../../../destination/domain/entities/destination.dart';
import '../../../destination/domain/entities/location.dart';
import '../../../destination/presentation/providers/destination_provider.dart';
import '../../../review/data/repositories/review_repository.dart';
import '../../../review/domain/entities/review.dart';
import '../../domain/entities/destination_preview.dart';
import '../../domain/entities/review_preview.dart';
import '../../domain/entities/content_item.dart';

/// Provider for home content items
///
/// Fetches real data from Firestore via DestinationRepository and ReviewRepository.
/// Returns mixed content (destinations + reviews) for Bento Grid.
final homeContentProvider = FutureProvider<List<ContentItem>>((ref) async {
  final destRepo = ref.watch(destinationRepositoryProvider);
  final reviewRepo = ref.watch(reviewRepositoryProvider);

  // Fetch real data from Firestore
  final destinations = await destRepo.getAllDestinations();
  final reviews = await reviewRepo.getAllReviews();

  // Fetch all locations for GPS resolution
  final allLocations = await destRepo.getAllLocations();
  final locationMap = <String, Location>{};
  for (final loc in allLocations) {
    locationMap[loc.id] = loc;
  }

  // Map to preview entities
  final destPreviews = destinations.map(_mapDestination).toList();
  final reviewPreviews = reviews
      .map((r) => _mapReview(r, locationMap))
      .toList();

  // Build mixed content list for Bento Grid
  return _buildContentList(destPreviews, reviewPreviews);
});

/// Provider for trending categories/pills
final trendingCategoriesProvider = Provider<List<TrendingCategory>>((ref) {
  return [
    const TrendingCategory(
      id: 'hot',
      label: 'Điểm đến hot 🔥',
      isSelected: true,
    ),
    const TrendingCategory(id: 'weekend', label: 'Lịch trình cuối tuần'),
    const TrendingCategory(id: 'ai', label: 'AI gợi ý'),
    const TrendingCategory(id: 'reviews', label: 'Đánh giá hay'),
    const TrendingCategory(id: 'budget', label: 'Tiết kiệm'),
  ];
});

// ── Mapping Helpers ──────────────────────────────────────────

/// Map a Firestore [Destination] to a [DestinationPreview] for UI.
DestinationPreview _mapDestination(Destination d) {
  return DestinationPreview(
    id: d.id,
    name: d.name,
    heroImage: d.heroImage,
    engagementCount: d.engagementCount,
    sizeHint: 1, // default; the UI can override later
  );
}

/// Map a Firestore [Review] to a [ReviewPreview] for UI.
/// Resolves GPS from the first relatedLocationId.
ReviewPreview _mapReview(Review r, Map<String, Location> locationMap) {
  final catInfo = _categoryInfo(r.category);

  // Resolve GPS from first related location
  double? lat;
  double? lng;
  if (r.relatedLocationIds.isNotEmpty) {
    for (final locId in r.relatedLocationIds) {
      final loc = locationMap[locId];
      if (loc != null && loc.latitude != null && loc.longitude != null) {
        lat = loc.latitude;
        lng = loc.longitude;
        break;
      }
    }
  }

  return ReviewPreview(
    id: r.id,
    title: r.title,
    authorName: r.authorName,
    authorAvatar: r.authorAvatar,
    shortText: r.fullText.length > 80
        ? '${r.fullText.substring(0, 80)}…'
        : r.fullText,
    heroImage: r.heroImage,
    likeCount: r.likeCount,
    commentCount: r.commentCount,
    moods: null, // TODO: populate when Review has moods
    destinationId: r.destinationId,
    destinationName: r.destinationName,
    category: r.category,
    categoryName: catInfo.$1,
    categoryEmoji: catInfo.$2,
    rating: 0.0, // TODO: populate when Review has rating field
    createdAt: r.createdAt,
    latitude: lat,
    longitude: lng,
  );
}

/// Returns (categoryName, categoryEmoji) for a given category string.
(String?, String?) _categoryInfo(String? category) {
  if (category == null) return (null, null);
  switch (category.toLowerCase()) {
    case 'food':
      return ('Ẩm thực', '🍜');
    case 'places':
      return ('Điểm đến', '📸');
    case 'stay':
      return ('Lưu trú', '🏨');
    default:
      return (category, '📍');
  }
}

// ── Content List Builder ─────────────────────────────────────

/// Build a mixed content list: destinations first, then reviews.
/// Alternating pattern: destination .. destination, review, review ...
List<ContentItem> _buildContentList(
  List<DestinationPreview> destinations,
  List<ReviewPreview> reviews,
) {
  final items = <ContentItem>[];

  // First, add all destinations (limited to keep feed balanced)
  for (final d in destinations.take(4)) {
    items.add(DestinationContent(d));
  }

  // Then, add all reviews
  for (final r in reviews) {
    items.add(ReviewContent(r));
  }

  return items;
}

/// Model for trending category pills
class TrendingCategory {
  final String id;
  final String label;
  final bool isSelected;

  const TrendingCategory({
    required this.id,
    required this.label,
    this.isSelected = false,
  });
}
