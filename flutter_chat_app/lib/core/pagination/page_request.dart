class PageRequest {
  final int page;
  final int size;

  const PageRequest({
    required this.page,
    required this.size,
  });

  const PageRequest.first({this.size = 25}) : page = 0;

  PageRequest next() => PageRequest(page: page + 1, size: size);
}
