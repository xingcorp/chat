class PagedResult<T> {
  final List<T> items;
  final int total;

  const PagedResult({
    required this.items,
    required this.total,
  });

  bool get hasMore => items.length < total;
}
