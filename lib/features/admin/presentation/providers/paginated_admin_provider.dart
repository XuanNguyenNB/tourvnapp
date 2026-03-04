import 'package:cloud_firestore/cloud_firestore.dart';

/// Generic paginated state for admin list screens.
///
/// Holds the currently loaded items, cursor for next page,
/// and loading/error states.
class PaginatedState<T> {
  final List<T> items;
  final bool isLoadingMore;
  final bool hasMore;
  final DocumentSnapshot? lastDoc;
  final String? error;
  final bool isInitialLoading;

  const PaginatedState({
    this.items = const [],
    this.isLoadingMore = false,
    this.hasMore = true,
    this.lastDoc,
    this.error,
    this.isInitialLoading = true,
  });

  PaginatedState<T> copyWith({
    List<T>? items,
    bool? isLoadingMore,
    bool? hasMore,
    DocumentSnapshot? lastDoc,
    String? error,
    bool? isInitialLoading,
    bool clearLastDoc = false,
  }) {
    return PaginatedState<T>(
      items: items ?? this.items,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      lastDoc: clearLastDoc ? null : (lastDoc ?? this.lastDoc),
      error: error,
      isInitialLoading: isInitialLoading ?? this.isInitialLoading,
    );
  }
}
