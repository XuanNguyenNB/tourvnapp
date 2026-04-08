import 'package:cloud_firestore/cloud_firestore.dart';

/// Shared query object for admin list screens.
class AdminListQuery {
  final String search;
  final Map<String, String?> filters;
  final int pageSize;
  final DocumentSnapshot? cursor;
  final String sortKey;
  final bool descending;

  const AdminListQuery({
    this.search = '',
    this.filters = const {},
    this.pageSize = 20,
    this.cursor,
    this.sortKey = 'createdAt',
    this.descending = true,
  });

  bool get hasSearch => search.trim().isNotEmpty;

  bool get hasFilters => filters.values.any((value) {
    return value != null && value.trim().isNotEmpty;
  });

  bool get hasActiveCriteria => hasSearch || hasFilters;

  String? filterValue(String key) => filters[key];

  AdminListQuery copyWith({
    String? search,
    Map<String, String?>? filters,
    int? pageSize,
    DocumentSnapshot? cursor,
    String? sortKey,
    bool? descending,
    bool clearCursor = false,
  }) {
    return AdminListQuery(
      search: search ?? this.search,
      filters: filters ?? this.filters,
      pageSize: pageSize ?? this.pageSize,
      cursor: clearCursor ? null : (cursor ?? this.cursor),
      sortKey: sortKey ?? this.sortKey,
      descending: descending ?? this.descending,
    );
  }
}

/// Result for admin batch operations.
class AdminBulkActionResult {
  final int processed;
  final int succeeded;
  final int failed;
  final List<String> errors;

  const AdminBulkActionResult({
    required this.processed,
    required this.succeeded,
    required this.failed,
    this.errors = const [],
  });

  bool get hasErrors => failed > 0 || errors.isNotEmpty;

  factory AdminBulkActionResult.empty() {
    return const AdminBulkActionResult(processed: 0, succeeded: 0, failed: 0);
  }
}

/// Generic state used by admin list screens.
class AdminListState<T> {
  final List<T> items;
  final AdminListQuery query;
  final Set<String> selectedIds;
  final bool isInitialLoading;
  final bool isRefreshing;
  final bool isLoadingMore;
  final bool hasMore;
  final String? errorMessage;

  const AdminListState({
    this.items = const [],
    this.query = const AdminListQuery(),
    this.selectedIds = const {},
    this.isInitialLoading = true,
    this.isRefreshing = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.errorMessage,
  });

  bool get hasError => errorMessage != null && errorMessage!.trim().isNotEmpty;

  bool get hasSelection => selectedIds.isNotEmpty;

  String? get error => errorMessage;

  AdminListState<T> copyWith({
    List<T>? items,
    AdminListQuery? query,
    Set<String>? selectedIds,
    bool? isInitialLoading,
    bool? isRefreshing,
    bool? isLoadingMore,
    bool? hasMore,
    String? errorMessage,
    bool clearError = false,
  }) {
    return AdminListState<T>(
      items: items ?? this.items,
      query: query ?? this.query,
      selectedIds: selectedIds ?? this.selectedIds,
      isInitialLoading: isInitialLoading ?? this.isInitialLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}
