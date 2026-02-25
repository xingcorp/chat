part of 'message_search_bloc.dart';

/// States for message search
@freezed
class MessageSearchState with _$MessageSearchState {
  /// Initial state — no search performed yet
  const factory MessageSearchState.initial() = _Initial;

  /// Loading state — search in progress
  const factory MessageSearchState.loading({
    /// Previous results to keep showing while loading more
    @Default([]) List<MessageSearchResult> previousResults,
    @Default(false) bool isLoadingMore,
  }) = _Loading;

  /// Loaded state — search results available
  const factory MessageSearchState.loaded({
    required List<MessageSearchResult> results,
    required String keyword,
    required int page,
    @Default(true) bool hasMore,
  }) = _Loaded;

  /// Empty state — search completed but no results
  const factory MessageSearchState.empty({
    required String keyword,
  }) = _Empty;

  /// Error state — search failed
  const factory MessageSearchState.error({
    required String message,
    required Failure failure,
    String? keyword,
  }) = _Error;
}
