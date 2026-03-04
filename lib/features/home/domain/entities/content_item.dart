import 'destination_preview.dart';
import 'review_preview.dart';

/// Sealed class representing content items in the home Bento Grid.
///
/// Using sealed class pattern for type-safe content handling.
/// Each content type has its own card representation.
sealed class ContentItem {
  const ContentItem();
}

/// A destination content item for the Bento Grid
class DestinationContent extends ContentItem {
  final DestinationPreview destination;

  const DestinationContent(this.destination);
}

/// A review content item for the Bento Grid
class ReviewContent extends ContentItem {
  final ReviewPreview review;

  const ReviewContent(this.review);
}
