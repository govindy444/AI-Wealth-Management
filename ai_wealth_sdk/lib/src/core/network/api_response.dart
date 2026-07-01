
class ApiResponse {
  const ApiResponse({
    required this.statusCode,
    required this.data,
    this.headers = const {},
  });

  final int statusCode;

  final dynamic data;
  final Map<String, List<String>> headers;

  bool get isSuccess => statusCode >= 200 && statusCode < 300;

  Map<String, dynamic> get asMap =>
      data is Map<String, dynamic> ? data as Map<String, dynamic> : <String, dynamic>{};

  List<dynamic> get asList => data is List ? data as List : const [];
}

class Paginated<T> {
  const Paginated({
    required this.items,
    required this.page,
    required this.pageSize,
    required this.total,
  });

  final List<T> items;
  final int page;
  final int pageSize;
  final int total;

  bool get hasMore => page * pageSize < total;

  factory Paginated.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromItem,
  ) {
    final rawItems = (json['items'] as List? ?? const [])
        .cast<Map<String, dynamic>>()
        .map(fromItem)
        .toList();
    return Paginated<T>(
      items: rawItems,
      page: (json['page'] as num?)?.toInt() ?? 1,
      pageSize: (json['page_size'] as num?)?.toInt() ?? rawItems.length,
      total: (json['total'] as num?)?.toInt() ?? rawItems.length,
    );
  }
}
