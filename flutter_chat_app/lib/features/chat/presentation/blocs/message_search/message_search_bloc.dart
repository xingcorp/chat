import 'package:bloc/bloc.dart';
import 'package:flutter_chat_app/core/error/failures.dart';
import 'package:flutter_chat_app/core/utils/logger.dart';
import 'package:flutter_chat_app/features/chat/domain/repositories/i_chat_repository.dart';
import 'package:flutter_chat_app/features/chat/domain/usecases/chat/search_messages_usecase.dart';
import 'package:flutter_chat_app/presentation/blocs/base/bloc_error_mixin.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';

part 'message_search_event.dart';
part 'message_search_state.dart';
part 'message_search_bloc.freezed.dart';

/// **Message Search BLoC**
///
/// Handles message search with pagination, error handling,
/// and proper state management following Clean Architecture.
///
/// **Features:**
/// - Debounced search via UI layer
/// - Pagination support (load more)
/// - Proper error states (network, server, etc.)
/// - Offline-aware error messaging
@injectable
class MessageSearchBloc extends Bloc<MessageSearchEvent, MessageSearchState>
    with BlocErrorMixin {
  final SearchMessagesUseCase _searchMessages;
  final AppLogger _logger;

  /// Current search context for pagination
  String? _currentKeyword;
  String? _currentConversationId;
  int _currentPage = 0;
  static const int _pageSize = 50;

  MessageSearchBloc({
    required SearchMessagesUseCase searchMessages,
    required AppLogger logger,
  })  : _searchMessages = searchMessages,
        _logger = logger,
        super(const MessageSearchState.initial()) {
    on<_Search>(_onSearch);
    on<_LoadMore>(_onLoadMore);
    on<_Clear>(_onClear);
  }

  Future<void> _onSearch(
    _Search event,
    Emitter<MessageSearchState> emit,
  ) async {
    final keyword = event.keyword.trim();
    if (keyword.isEmpty) {
      emit(const MessageSearchState.initial());
      return;
    }

    _currentKeyword = keyword;
    _currentConversationId = event.conversationId;
    _currentPage = 0;

    _logger.info('MessageSearchBloc: Searching', {
      'keyword': keyword,
      'conversationId': event.conversationId,
    });

    emit(const MessageSearchState.loading());

    final result = await _searchMessages(
      keyword: keyword,
      conversationId: event.conversationId,
      limit: _pageSize,
    );

    result.fold(
      (failure) {
        _logger.error('MessageSearchBloc: Search failed', failure);
        emit(MessageSearchState.error(
          message: getUserErrorMessage(failure),
          failure: failure,
          keyword: keyword,
        ));
      },
      (results) {
        if (results.isEmpty) {
          emit(MessageSearchState.empty(keyword: keyword));
        } else {
          emit(MessageSearchState.loaded(
            results: results,
            keyword: keyword,
            page: 0,
            hasMore: results.length >= _pageSize,
          ));
        }
        _logger.info('MessageSearchBloc: Search completed', {
          'count': results.length,
        });
      },
    );
  }

  Future<void> _onLoadMore(
    _LoadMore event,
    Emitter<MessageSearchState> emit,
  ) async {
    final currentState = state;
    if (currentState is! _Loaded) return;
    if (!currentState.hasMore) return;
    if (_currentKeyword == null || _currentConversationId == null) return;

    _currentPage++;

    _logger.info('MessageSearchBloc: Loading more', {
      'page': _currentPage,
    });

    emit(MessageSearchState.loading(
      previousResults: currentState.results,
      isLoadingMore: true,
    ));

    final result = await _searchMessages(
      keyword: _currentKeyword!,
      conversationId: _currentConversationId,
      limit: _pageSize,
    );

    result.fold(
      (failure) {
        _logger.error('MessageSearchBloc: Load more failed', failure);
        // Restore previous state on load more failure
        emit(MessageSearchState.loaded(
          results: currentState.results,
          keyword: currentState.keyword,
          page: _currentPage - 1,
          hasMore: currentState.hasMore,
        ));
      },
      (newResults) {
        final allResults = [...currentState.results, ...newResults];
        emit(MessageSearchState.loaded(
          results: allResults,
          keyword: currentState.keyword,
          page: _currentPage,
          hasMore: newResults.length >= _pageSize,
        ));
      },
    );
  }

  void _onClear(
    _Clear event,
    Emitter<MessageSearchState> emit,
  ) {
    _currentKeyword = null;
    _currentConversationId = null;
    _currentPage = 0;
    emit(const MessageSearchState.initial());
  }
}
