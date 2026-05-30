class PagedListState<T> {
  const PagedListState({
    required this.items,
    required this.totalCount,
    required this.page,
    required this.pageSize,
    this.isLoadingMore = false,
  });

  final List<T> items;
  final int totalCount;
  final int page;
  final int pageSize;
  final bool isLoadingMore;

  bool get hasMore => items.length < totalCount;

  PagedListState<T> copyWith({
    List<T>? items,
    int? totalCount,
    int? page,
    int? pageSize,
    bool? isLoadingMore,
  }) {
    return PagedListState<T>(
      items: items ?? this.items,
      totalCount: totalCount ?? this.totalCount,
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }
}
