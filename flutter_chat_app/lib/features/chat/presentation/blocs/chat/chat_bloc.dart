import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_chat_app/domain/models/queued_message.dart';
import 'package:flutter_chat_app/domain/entities/conversation_type_filter.dart';
import 'package:flutter_chat_app/features/chat/domain/usecases/chat/delete_conversation_usecase.dart';
import 'package:flutter_chat_app/shared/domain/entities/message_queue_status.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';

import 'package:flutter_chat_app/core/cache/cache_sync_strategy.dart';
import 'package:flutter_chat_app/core/cache/media_cache_manager.dart';
import 'package:flutter_chat_app/core/services/connectivity_service.dart';
import 'package:flutter_chat_app/core/services/current_user_provider.dart';
import 'package:flutter_chat_app/core/services/realtime_service.dart';
import 'package:flutter_chat_app/shared/domain/entities/chat.dart';
import 'package:flutter_chat_app/shared/domain/entities/chat_message.dart';
import 'package:flutter_chat_app/core/pagination/page_request.dart';
import 'package:flutter_chat_app/domain/usecases/message/mark_as_read_usecase.dart';
import 'package:flutter_chat_app/features/chat/domain/usecases/chat/get_conversations_usecase.dart';
import 'package:flutter_chat_app/features/chat/domain/usecases/chat/get_conversation_detail_usecase.dart';
import 'package:flutter_chat_app/features/chat/domain/usecases/chat/create_group_usecase.dart';
import 'package:flutter_chat_app/features/chat/domain/usecases/chat/update_group_usecase.dart';
import 'package:flutter_chat_app/features/chat/domain/usecases/chat/leave_conversation_usecase.dart';
import 'package:flutter_chat_app/features/chat/domain/usecases/chat/search_conversations_usecase.dart';
import 'package:flutter_chat_app/presentation/blocs/base/bloc_error_mixin.dart';

part 'chat_event.dart';
part 'chat_state.dart';
part 'chat_bloc.freezed.dart';

/// **ENTERPRISE CHAT BLOC - CLEAN ARCHITECTURE**
///
/// Updated to use UseCases and BaseBloc core components.
/// Follows Clean Architecture with proper separation of concerns.
///
/// **Performance**: <2s for chat operations
/// **Architecture**: Clean Architecture + BLoC pattern + Result<T> handling
@injectable
class ChatBloc extends Bloc<ChatEvent, ChatState> with BlocErrorMixin {
  // UseCases (Domain Layer)
  final GetConversationsUseCase _getConversations;
  final GetConversationDetailUseCase _getConversationDetail;
  final CreateGroupUseCase _createGroup;
  final UpdateGroupUseCase _updateGroup;
  final LeaveConversationUseCase _leaveConversation;
  final DeleteConversationUseCase _deleteConversation;
  final SearchConversationsUseCase _searchConversations;
  
  // Services
  final ConnectivityService _connectivityService;
  final CacheSyncStrategy _cacheSyncStrategy;
  final MediaCacheManager _mediaCacheManager;
  final RealtimeService _realtimeService;
  final MarkAsReadUseCase _markAsRead;
  final CurrentUserProvider _currentUserProvider;

  // Subscriptions for real-time updates
  StreamSubscription<ChatMessage>? _messageSubscription;
  StreamSubscription<TypingIndicator>? _typingSubscription;
  StreamSubscription<MessageReadReceipt>? _readReceiptSubscription;
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;
  StreamSubscription<Chat>? _chatUpdatesSubscription;

  // Typing indicator timeout management
  // Key: "chatId:userId", Value: Timer that will clear typing status
  final Map<String, Timer> _typingTimers = {};
  static const _typingTimeout = Duration(seconds: 5);
  
  /// Constructor with UseCases injection
  ChatBloc(
    this._getConversations,
    this._getConversationDetail,
    this._createGroup,
    this._updateGroup,
    this._leaveConversation,
    this._deleteConversation,
    this._searchConversations,
    this._connectivityService,
    this._cacheSyncStrategy,
    this._mediaCacheManager,
    this._realtimeService,
    this._markAsRead,
    this._currentUserProvider,
  ) : super(const ChatState.initial()) {
    on<_LoadChats>(_onLoadChats);
    on<_LoadMoreChats>(_onLoadMoreChats);
    on<_LoadChatDetails>(_onLoadChatDetails);
    on<_CreateChat>(_onCreateChat);
    on<_UpdateChat>(_onUpdateChat);
    on<_LeaveChat>(_onLeaveChat);
    on<_MarkMessagesAsRead>(_onMarkMessagesAsRead);
    on<_NewMessageReceived>(_onNewMessageReceived);
    on<_ConnectivityChanged>(_onConnectivityChanged);
    on<_ChatUpdated>(_onChatUpdated);
    on<_SearchChats>(_onSearchChats);
    on<_ClearSearch>(_onClearSearch);
    on<_ChangeConversationTypeFilter>(_onChangeConversationTypeFilter);
  }

  /// **Load chats using GetConversationsUseCase - CLEAN ARCHITECTURE**
  Future<void> _onLoadChats(
    _LoadChats event,
    Emitter<ChatState> emit,
  ) async {
    final current = state.whenOrNull(
      loaded: (chats, hasMore, isLoadingMore, page, pageSize, total,
          activeFilter, cachedLists, filterPages, filterHasMore) => (
        pageSize: pageSize,
        activeFilter: activeFilter,
        cachedLists: cachedLists,
        filterPages: filterPages,
        filterHasMore: filterHasMore,
      ),
    );

    final pageSize = current?.pageSize ?? 25;
    final activeFilter = current?.activeFilter ?? ConversationTypeFilter.all;

    // On refresh, clear the cache for the current tab so it re-fetches
    final cachedLists = Map<ConversationTypeFilter, List<Chat>>.from(
      current?.cachedLists ?? {},
    );
    final filterPages = Map<ConversationTypeFilter, int>.from(
      current?.filterPages ?? {},
    );
    final filterHasMore = Map<ConversationTypeFilter, bool>.from(
      current?.filterHasMore ?? {},
    );

    if (event.forceRefresh) {
      cachedLists.remove(activeFilter);
      filterPages.remove(activeFilter);
      filterHasMore.remove(activeFilter);
    }

    emit(const ChatState.loading());

    logger.i('Loading conversations using UseCase (filter: $activeFilter)');

    final shouldRefresh = event.forceRefresh || _cacheSyncStrategy.shouldRefreshChatList();

    final request = PageRequest.first(size: pageSize);
    final result = await _getConversations(
      request,
      typeFilter: activeFilter.apiValue,
    );

    result.fold(
      (failure) {
        logger.e('Failed to load conversations: ${failure.message}');
        emit(ChatState.error(message: getUserErrorMessage(failure)));
      },
      (paged) {
        final chats = paged.items;
        final effectiveHasMore = chats.length == request.size;

        if (shouldRefresh) {
          _cacheSyncStrategy.resetChatListDirtyFlag();
        }

        _prefetchAvatars(chats);
        _subscribeToRealTimeUpdates();

        cachedLists[activeFilter] = chats;
        filterPages[activeFilter] = 0;
        filterHasMore[activeFilter] = effectiveHasMore;

        emit(ChatState.loaded(
          chats: chats,
          hasMore: effectiveHasMore,
          isLoadingMore: false,
          page: 0,
          pageSize: pageSize,
          total: chats.length,
          activeFilter: activeFilter,
          cachedLists: cachedLists,
          filterPages: filterPages,
          filterHasMore: filterHasMore,
        ));
      },
    );
  }

  Future<void> _onLoadMoreChats(
    _LoadMoreChats event,
    Emitter<ChatState> emit,
  ) async {
    final current = state.whenOrNull(
      loaded: (chats, hasMore, isLoadingMore, page, pageSize, total,
          activeFilter, cachedLists, filterPages, filterHasMore) => (
        chats: chats,
        hasMore: hasMore,
        isLoadingMore: isLoadingMore,
        page: page,
        pageSize: pageSize,
        total: total,
        activeFilter: activeFilter,
        cachedLists: cachedLists,
        filterPages: filterPages,
        filterHasMore: filterHasMore,
      ),
    );

    if (current == null) return;
    if (!current.hasMore) return;
    if (current.isLoadingMore) return;

    final cachedLists = Map<ConversationTypeFilter, List<Chat>>.from(current.cachedLists);
    final filterPages = Map<ConversationTypeFilter, int>.from(current.filterPages);
    final filterHasMore = Map<ConversationTypeFilter, bool>.from(current.filterHasMore);

    emit(ChatState.loaded(
      chats: current.chats,
      hasMore: current.hasMore,
      isLoadingMore: true,
      page: current.page,
      pageSize: current.pageSize,
      total: current.total,
      activeFilter: current.activeFilter,
      cachedLists: cachedLists,
      filterPages: filterPages,
      filterHasMore: filterHasMore,
    ));

    final nextPage = current.page + 1;
    final nextRequest = PageRequest(page: nextPage, size: current.pageSize);

    final result = await _getConversations(
      nextRequest,
      typeFilter: current.activeFilter.apiValue,
    );

    result.fold(
      (failure) {
        logger.e('Failed to load more conversations: ${failure.message}');
        emit(ChatState.loaded(
          chats: current.chats,
          hasMore: current.hasMore,
          isLoadingMore: false,
          page: current.page,
          pageSize: current.pageSize,
          total: current.total,
          activeFilter: current.activeFilter,
          cachedLists: cachedLists,
          filterPages: filterPages,
          filterHasMore: filterHasMore,
        ));
      },
      (paged) {
        if (paged.items.isEmpty) {
          filterHasMore[current.activeFilter] = false;
          emit(ChatState.loaded(
            chats: current.chats,
            hasMore: false,
            isLoadingMore: false,
            page: current.page,
            pageSize: current.pageSize,
            total: current.chats.length,
            activeFilter: current.activeFilter,
            cachedLists: cachedLists,
            filterPages: filterPages,
            filterHasMore: filterHasMore,
          ));
          return;
        }

        final merged = List<Chat>.from(current.chats);
        var addedNew = 0;
        for (final c in paged.items) {
          final idx = merged.indexWhere((x) => x.id == c.id);
          if (idx == -1) {
            merged.add(c);
            addedNew++;
          } else {
            merged[idx] = c;
          }
        }

        final effectiveHasMore = addedNew > 0 && paged.items.length == nextRequest.size;

        cachedLists[current.activeFilter] = merged;
        filterPages[current.activeFilter] = nextPage;
        filterHasMore[current.activeFilter] = effectiveHasMore;

        emit(ChatState.loaded(
          chats: merged,
          hasMore: effectiveHasMore,
          isLoadingMore: false,
          page: nextPage,
          pageSize: current.pageSize,
          total: merged.length,
          activeFilter: current.activeFilter,
          cachedLists: cachedLists,
          filterPages: filterPages,
          filterHasMore: filterHasMore,
        ));
      },
    );
  }

  /// **Load chat details using GetConversationDetailUseCase - CLEAN ARCHITECTURE**
  Future<void> _onLoadChatDetails(
    _LoadChatDetails event,
    Emitter<ChatState> emit,
  ) async {
    logger.i('Loading conversation detail: ${event.chatId}');

    // Create params for UseCase
    final conversationId = event.chatId;

    // Execute UseCase
    final result = await _getConversationDetail(conversationId);

    result.fold(
      (failure) {
        logger.e('Failed to load conversation detail: ${failure.message}');
        emit(ChatState.error(message: getUserErrorMessage(failure)));
      },
      (chat) {
        if (chat != null) {
          logger.i('Loaded conversation detail successfully');
          emit(ChatState.chatDetailsLoaded(chat: chat));
        } else {
          emit(const ChatState.error(message: 'Không tìm thấy cuộc trò chuyện'));
        }
      },
    );
  }

  /// **Create chat using CreateGroupUseCase - CLEAN ARCHITECTURE**
  Future<void> _onCreateChat(
    _CreateChat event,
    Emitter<ChatState> emit,
  ) async {
    logger.i('Creating new chat: ${event.name}');

    emit(const ChatState.loading());

    final result = await _createGroup(
      name: event.name ?? 'New Group',
      memberIds: event.participantIds,
      description: event.description,
    );

    result.fold(
      (failure) {
        logger.e('Failed to create chat: ${failure.message}');
        emit(ChatState.error(message: getUserErrorMessage(failure)));
      },
      (chat) {
        logger.i('Chat created successfully: ${chat.id}');
        emit(ChatState.chatDetailsLoaded(chat: chat));
      },
    );
  }

  /// **Update chat using UpdateGroupUseCase - CLEAN ARCHITECTURE**
  Future<void> _onUpdateChat(
    _UpdateChat event,
    Emitter<ChatState> emit,
  ) async {
    logger.i('Updating chat: ${event.chatId}');

    emit(const ChatState.loading());

    // Create params for UseCase
    final params = UpdateGroupParams(
      conversationId: event.chatId,
      name: event.name,
      imageUrl: event.avatar,
      description: event.description,
    );

    // Execute UseCase
    final result = await _updateGroup(params);

    result.fold(
      (failure) {
        logger.e('Failed to update chat: ${failure.message}');
        emit(ChatState.error(message: getUserErrorMessage(failure)));
      },
      (chat) {
        logger.i('Chat updated successfully');

        // Update chat in current state
        add(ChatEvent.chatUpdated(chat: chat));

        // Reload chats to reflect changes
        add(const ChatEvent.loadChats(forceRefresh: true));
      },
    );
  }

  /// **Leave chat using LeaveConversationUseCase - CLEAN ARCHITECTURE**
  Future<void> _onLeaveChat(
    _LeaveChat event,
    Emitter<ChatState> emit,
  ) async {
    logger.i('Leaving chat: ${event.chatId}');

    emit(const ChatState.loading());

    // Create params for UseCase
    final conversationId = event.chatId;

    // Execute UseCase
    final result = await _leaveConversation(conversationId);

    result.fold(
      (failure) {
        logger.e('Failed to leave chat: ${failure.message}');
        emit(ChatState.error(message: getUserErrorMessage(failure)));
      },
      (success) {
        if (success) {
          logger.i('Left chat successfully');

          // Reload chats to remove the left chat
          add(const ChatEvent.loadChats(forceRefresh: true));
        }
      },
    );
  }

  /// Handle connectivity changes
  Future<void> _onConnectivityChanged(
    _ConnectivityChanged event,
    Emitter<ChatState> emit,
  ) async {
    logger.i('Connectivity changed: ${event.isConnected ? "online" : "offline"}');
    
    if (event.isConnected) {
      // Sync when connection is restored
      logger.i('Connection restored, reloading chats');
      add(const ChatEvent.loadChats(forceRefresh: true));
    } else {
      logger.w('Connection lost, switching to offline mode');
      emit(const ChatState.offline());
    }
  }

  /// Handle chat updates from real-time events
  Future<void> _onChatUpdated(
    _ChatUpdated event,
    Emitter<ChatState> emit,
  ) async {
    logger.d('Chat updated: ${event.chat.id}');

    if (state is _Loaded) {
      final currentState = state as _Loaded;
      final updatedChats = currentState.chats.map((chat) {
        return chat.id == event.chat.id ? event.chat : chat;
      }).toList();

      emit(_preserveLoaded(currentState, chats: updatedChats));
      logger.i('Chat list updated with new data');
    }
  }

  /// **Search conversations using SearchConversationsUseCase**
  ///
  /// Calls remote API with keyword filter (same approach as Angular frontend).
  Future<void> _onSearchChats(
    _SearchChats event,
    Emitter<ChatState> emit,
  ) async {
    final keyword = event.keyword.trim();
    if (keyword.isEmpty) {
      add(const ChatEvent.clearSearch());
      return;
    }

    emit(const ChatState.loading());

    final result = await _searchConversations(
      query: keyword,
      limit: 100,
    );

    result.fold(
      (failure) {
        logger.e('Search conversations failed: ${failure.message}');
        emit(ChatState.error(message: getUserErrorMessage(failure)));
      },
      (chats) {
        // Search results don't filter by type — preserve activeFilter from current state
        final activeFilter = state.whenOrNull(
              loaded: (_, __, ___, ____, _____, ______, activeFilter, _______, ________, _________) =>
                  activeFilter,
            ) ??
            ConversationTypeFilter.all;
        emit(ChatState.loaded(
          chats: chats,
          hasMore: false,
          isLoadingMore: false,
          page: 0,
          pageSize: 100,
          total: chats.length,
          activeFilter: activeFilter,
        ));
      },
    );
  }

  /// **Clear search and reload normal chat list**
  Future<void> _onClearSearch(
    _ClearSearch event,
    Emitter<ChatState> emit,
  ) async {
    add(const ChatEvent.loadChats(forceRefresh: false));
  }

  /// **Change conversation type filter**
  ///
  /// Switches the active tab filter. Uses cached data when available,
  /// otherwise fetches from remote with the appropriate type filter.
  /// Requirements: 2.1, 2.2, 2.3, 2.4, 2.5
  Future<void> _onChangeConversationTypeFilter(
    _ChangeConversationTypeFilter event,
    Emitter<ChatState> emit,
  ) async {
    final filter = event.filter;

    // Extract current loaded state fields (if loaded)
    final current = state.whenOrNull(
      loaded: (chats, hasMore, isLoadingMore, page, pageSize, total,
          activeFilter, cachedLists, filterPages, filterHasMore) => (
        chats: chats,
        hasMore: hasMore,
        page: page,
        pageSize: pageSize,
        total: total,
        activeFilter: activeFilter,
        cachedLists: cachedLists,
        filterPages: filterPages,
        filterHasMore: filterHasMore,
      ),
    );

    final pageSize = current?.pageSize ?? 25;
    final cachedLists = Map<ConversationTypeFilter, List<Chat>>.from(
      current?.cachedLists ?? {},
    );
    final filterPages = Map<ConversationTypeFilter, int>.from(
      current?.filterPages ?? {},
    );
    final filterHasMore = Map<ConversationTypeFilter, bool>.from(
      current?.filterHasMore ?? {},
    );

    // Cache the current tab's list before switching
    if (current != null) {
      cachedLists[current.activeFilter] = current.chats;
    }

    // Check cache hit for the new filter
    final cached = cachedLists[filter];
    if (cached != null && cached.isNotEmpty) {
      logger.i('ChangeConversationTypeFilter: cache hit for $filter');
      emit(ChatState.loaded(
        chats: cached,
        hasMore: filterHasMore[filter] ?? false,
        isLoadingMore: false,
        page: filterPages[filter] ?? 0,
        pageSize: pageSize,
        total: cached.length,
        activeFilter: filter,
        cachedLists: cachedLists,
        filterPages: filterPages,
        filterHasMore: filterHasMore,
      ));
      return;
    }

    // No cache — emit loading then fetch
    emit(ChatState.loaded(
      chats: const [],
      hasMore: false,
      isLoadingMore: true,
      page: 0,
      pageSize: pageSize,
      total: 0,
      activeFilter: filter,
      cachedLists: cachedLists,
      filterPages: filterPages,
      filterHasMore: filterHasMore,
    ));

    logger.i('ChangeConversationTypeFilter: fetching for $filter');

    final request = PageRequest.first(size: pageSize);
    final result = await _getConversations(
      request,
      typeFilter: filter.apiValue,
    );

    result.fold(
      (failure) {
        logger.e('ChangeConversationTypeFilter: failed for $filter: ${failure.message}');
        emit(ChatState.error(message: getUserErrorMessage(failure)));
      },
      (paged) {
        final chats = paged.items;
        final effectiveHasMore = chats.length == request.size;

        cachedLists[filter] = chats;
        filterPages[filter] = 0;
        filterHasMore[filter] = effectiveHasMore;

        emit(ChatState.loaded(
          chats: chats,
          hasMore: effectiveHasMore,
          isLoadingMore: false,
          page: 0,
          pageSize: pageSize,
          total: chats.length,
          activeFilter: filter,
          cachedLists: cachedLists,
          filterPages: filterPages,
          filterHasMore: filterHasMore,
        ));
      },
    );
  }

  /// Pre-fetch avatars for better UX
  void _prefetchAvatars(List<Chat> chats) {
    final avatarUrls = chats
        .where((chat) => chat.avatarUrl != null)
        .map((chat) => chat.avatarUrl!)
        .toList();
    
    if (avatarUrls.isNotEmpty) {
      logger.d('Pre-fetching ${avatarUrls.length} avatars');
      _mediaCacheManager.prefetchThumbnails(avatarUrls);
    }
  }

  /// Subscribe to real-time updates
  void _subscribeToRealTimeUpdates() {
    _messageSubscription?.cancel();
    _typingSubscription?.cancel();
    _readReceiptSubscription?.cancel();

    if (!_realtimeService.isConnected) {
      _realtimeService.connect();
    }

    _messageSubscription = _realtimeService.messageStream.listen(
      (message) {
        add(ChatEvent.newMessageReceived(message));
      },
      onError: (error) {
        logger.w('Error in realtime message stream: $error');
      },
    );

    _typingSubscription = _realtimeService.typingStream.listen(
      (indicator) {
        _applyTypingIndicator(indicator);
      },
      onError: (error) {
        logger.w('Error in realtime typing stream: $error');
      },
    );

    _readReceiptSubscription = _realtimeService.readReceiptStream.listen(
      (receipt) {
        _applyReadReceipt(receipt);
      },
      onError: (error) {
        logger.w('Error in realtime read receipt stream: $error');
      },
    );

    logger.d('Real-time updates subscription setup completed');
  }

  Future<void> _onNewMessageReceived(
    _NewMessageReceived event,
    Emitter<ChatState> emit,
  ) async {
    if (state is! _Loaded) return;

    final currentState = state as _Loaded;
    final message = event.message;

    final idx = currentState.chats.indexWhere((c) => c.id == message.chatId);
    if (idx < 0) {
      return;
    }

    final existingChat = currentState.chats[idx];
    final isIncoming = message.sender.id != _currentUserProvider.currentUserId;

    final updatedChat = existingChat.copyWith(
      lastMessageTime: message.createdAt,
      lastMessagePreview: message.content,
      unreadCount: isIncoming ? (existingChat.unreadCount + 1) : existingChat.unreadCount,
    );

    final updatedChats = List<Chat>.from(currentState.chats);
    updatedChats[idx] = updatedChat;

    updatedChats.sort((a, b) {
      final at = a.lastMessageTime;
      final bt = b.lastMessageTime;
      if (at == null && bt == null) return 0;
      if (at == null) return 1;
      if (bt == null) return -1;
      return bt.compareTo(at);
    });

    emit(_preserveLoaded(currentState, chats: updatedChats));
  }

  Future<void> _onMarkMessagesAsRead(
    _MarkMessagesAsRead event,
    Emitter<ChatState> emit,
  ) async {
    if (state is _Loaded) {
      final currentState = state as _Loaded;
      final updatedChats = currentState.chats
          .map((c) => c.id == event.chatId ? c.copyWith(unreadCount: 0) : c)
          .toList();
      emit(_preserveLoaded(currentState, chats: updatedChats));
    }

    final result = await _markAsRead(MarkAsReadParams(conversationId: event.chatId));
    result.fold(
      (failure) {
        logger.w('Failed to mark messages as read: ${failure.message}');
      },
      (_) {},
    );
  }

  void _applyTypingIndicator(TypingIndicator indicator) {
    if (state is! _Loaded) return;

    final currentState = state as _Loaded;
    final idx = currentState.chats.indexWhere((c) => c.id == indicator.chatId);
    if (idx < 0) return;

    final chat = currentState.chats[idx];
    final typing = List<String>.from(chat.typingUserIds);
    final timerKey = '${indicator.chatId}:${indicator.userId}';

    // Cancel existing timer for this user
    _typingTimers[timerKey]?.cancel();

    if (indicator.isTyping) {
      if (!typing.contains(indicator.userId)) {
        typing.add(indicator.userId);
      }
      // Set timeout to auto-clear typing status
      _typingTimers[timerKey] = Timer(_typingTimeout, () {
        _clearTypingStatus(indicator.chatId, indicator.userId);
        _typingTimers.remove(timerKey);
      });
    } else {
      typing.remove(indicator.userId);
      _typingTimers.remove(timerKey);
    }

    final updatedChats = List<Chat>.from(currentState.chats);
    updatedChats[idx] = chat.copyWith(typingUserIds: typing);
    emit(_preserveLoaded(currentState, chats: updatedChats));
  }

  void _clearTypingStatus(String chatId, String userId) {
    if (state is! _Loaded) return;

    final currentState = state as _Loaded;
    final idx = currentState.chats.indexWhere((c) => c.id == chatId);
    if (idx < 0) return;

    final chat = currentState.chats[idx];
    final typing = List<String>.from(chat.typingUserIds);

    if (!typing.contains(userId)) return;

    typing.remove(userId);
    final updatedChats = List<Chat>.from(currentState.chats);
    updatedChats[idx] = chat.copyWith(typingUserIds: typing);
    emit(_preserveLoaded(currentState, chats: updatedChats));
  }

  void _applyReadReceipt(MessageReadReceipt receipt) {
    if (state is! _Loaded) return;

    if (receipt.readerId != _currentUserProvider.currentUserId) {
      return;
    }

    final currentState = state as _Loaded;
    final idx = currentState.chats.indexWhere((c) => c.id == receipt.chatId);
    if (idx < 0) return;

    final chat = currentState.chats[idx];
    if (chat.unreadCount == 0) return;

    final updatedChats = List<Chat>.from(currentState.chats);
    updatedChats[idx] = chat.copyWith(unreadCount: 0);
    emit(_preserveLoaded(currentState, chats: updatedChats));
  }

  /// Emit a new loaded state preserving all filter/cache/pagination fields
  /// from [current], only replacing [chats] (and optionally other fields).
  ChatState _preserveLoaded(_Loaded current, {required List<Chat> chats}) {
    return ChatState.loaded(
      chats: chats,
      hasMore: current.hasMore,
      isLoadingMore: current.isLoadingMore,
      page: current.page,
      pageSize: current.pageSize,
      total: current.total,
      activeFilter: current.activeFilter,
      cachedLists: current.cachedLists,
      filterPages: current.filterPages,
      filterHasMore: current.filterHasMore,
    );
  }

  @override
  Future<void> close() {
    _messageSubscription?.cancel();
    _typingSubscription?.cancel();
    _readReceiptSubscription?.cancel();
    _connectivitySubscription?.cancel();
    _chatUpdatesSubscription?.cancel();
    // Cancel all typing timers
    for (final timer in _typingTimers.values) {
      timer.cancel();
    }
    _typingTimers.clear();
    return super.close();
  }
}
