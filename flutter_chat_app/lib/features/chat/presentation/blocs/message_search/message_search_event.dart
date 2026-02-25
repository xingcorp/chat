part of 'message_search_bloc.dart';

/// Events for message search
@freezed
class MessageSearchEvent with _$MessageSearchEvent {
  /// Search messages by keyword
  const factory MessageSearchEvent.search({
    required String keyword,
    required String conversationId,
    @Default(0) int page,
    @Default(50) int size,
  }) = _Search;

  /// Load more results (pagination)
  const factory MessageSearchEvent.loadMore() = _LoadMore;

  /// Clear search results
  const factory MessageSearchEvent.clear() = _Clear;
}
