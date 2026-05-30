class PagedResult<T> {
  const PagedResult({
    required this.items,
    required this.totalCount,
    required this.page,
    required this.pageSize,
  });

  final List<T> items;
  final int totalCount;
  final int page;
  final int pageSize;

  bool get hasMore => page * pageSize < totalCount;

  /// Dohvati sve stranice dok API vraća `hasMore == true`.
  static Future<List<T>> collectAllPages<T>({
    required Future<PagedResult<T>> Function(int page, int pageSize) fetchPage,
    int pageSize = 100,
  }) async {
    final List<T> all = <T>[];
    var page = 1;
    while (true) {
      final PagedResult<T> result = await fetchPage(page, pageSize);
      all.addAll(result.items);
      if (!result.hasMore) break;
      page++;
    }
    return all;
  }

  factory PagedResult.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic> json) itemFromJson,
  ) {
    final dynamic rawItems = json['items'] ?? json['Items'];
    final List<dynamic> itemsList = rawItems is List<dynamic> ? rawItems : <dynamic>[];
    return PagedResult<T>(
      items: itemsList.map((dynamic e) => itemFromJson(e as Map<String, dynamic>)).toList(),
      totalCount: _readInt(json, 'totalCount', 'TotalCount'),
      page: _readInt(json, 'page', 'Page', fallback: 1),
      pageSize: _readInt(json, 'pageSize', 'PageSize', fallback: 20),
    );
  }

  static int _readInt(
    Map<String, dynamic> json,
    String camelKey,
    String pascalKey, {
    int fallback = 0,
  }) {
    final dynamic value = json[camelKey] ?? json[pascalKey];
    if (value is int) return value;
    if (value is num) return value.toInt();
    return fallback;
  }
}
