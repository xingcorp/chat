import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_chat_app/core/error/failures.dart';
import 'package:flutter_chat_app/domain/models/queued_message.dart';
import 'package:flutter_chat_app/domain/entities/conversation_type_filter.dart';
import 'package:flutter_chat_app/features/chat/domain/usecases/chat/delete_conversation_usecase.dart';
import 'package:flutter_chat_app/features/chat/domain/usecases/chat/persist_incoming_message_usecase.dart';
import 'package:flutter_chat_app/shared/domain/entities/message_queue_status.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';

import 'package:flutter_chat_app/core/cache/cache_sync_strategy.dart';
import 'package:flutter_chat_app/core/cache/media_cache_manager.dart';
import 'package:flutter_chat_app/core/extensions/extensions.dart';
import 'package:flutter_chat_app/core/services/chat_module_event_bus.dart';
import 'package:flutter_chat_app/core/services/connectivity_service.dart';
import 'package:flutter_chat_app/core/services/current_user_provider.dart';
import 'package:flutter_chat_app/core/services/realtime_service.dart';
import 'package:flutter_chat_app/core/network/models/socket_connection_state.dart';
import 'package:flutter_chat_app/shared/domain/entities/chat.dart';
import 'package:flutter_chat_app/shared/domain/entities/chat_message.dart';
import 'package:flutter_chat_app/core/pagination/page_request.dart';
import 'package:flutter_chat_app/domain/usecases/message/mark_as_read_usecase.dart';
import 'package:flutter_chat_app/domain/repositories/i_attachment_repository.dart';
import 'package:flutter_chat_app/core/utils/either.dart';
import 'package:flutter_chat_app/features/chat/domain/usecases/chat/get_conversations_usecase.dart';
import 'package:flutter_chat_app/features/chat/domain/usecases/chat/get_local_conversations_usecase.dart';
import 'package:flutter_chat_app/features/chat/domain/usecases/chat/get_conversation_detail_usecase.dart';
import 'package:flutter_chat_app/features/chat/domain/usecases/chat/create_group_usecase.dart';
import 'package:flutter_chat_app/features/chat/domain/usecases/chat/update_group_usecase.dart';
import 'package:flutter_chat_app/features/chat/domain/usecases/chat/leave_conversation_usecase.dart';
import 'package:flutter_chat_app/features/chat/domain/usecases/chat/search_conversations_usecase.dart';
import 'package:flutter_chat_app/presentation/blocs/base/bloc_error_mixin.dart';

part 'chat_event.dart';
part 'chat_state.dart';
part 'chat_bloc.freezed.dart';

enum ChatConversationAction {
  leave,
  delete,
}

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
  final GetLocalConversationsUseCase _getLocalConversations;
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
  final PersistIncomingMessageUseCase _persistIncomingMessage;
  final ChatModuleEventBus _eventBus;
  final IAttachmentRepository _attachmentRepository;

  // Subscriptions for real-time updates
  StreamSubscription<ChatMessage>? _messageSubscription;
  StreamSubscription<TypingIndicator>? _typingSubscription;
  StreamSubscription<MessageReadReceipt>? _readReceiptSubscription;
  StreamSubscription<bool>? _connectivitySubscription;
  StreamSubscription<Chat>? _chatUpdatesSubscription;
  StreamSubscription<SocketConnectionState>? _connectionStateSubscription;

  // Typing indicator timeout management
  // Key: "chatId:userId", Value: Timer that will clear typing status
  final Map<String, Timer> _typingTimers = {};
  static const _typingTimeout = Duration(seconds: 5);
  DateTime? _lastOnlineRefreshTriggerAt;
  static const _onlineRefreshTriggerCooldown = Duration(seconds: 2);

  /// Pending direct chats that exist only locally (not yet on server).
  /// Key: temp chat ID (timestamp), Value: the optimistic Chat object.
  /// These are preserved across `_onLoadChats` server refreshes until
  /// the first message resolves them to a real server conversation ID.
  final Map<String, Chat> _pendingDirectChats = {};

  /// Constructor with UseCases injection
  ChatBloc(
    this._getConversations,
    this._getLocalConversations,
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
    this._persistIncomingMessage,
    this._eventBus,
    this._attachmentRepository,
  ) : super(const ChatState.initial()) {
    on<_LoadChats>(_onLoadChats);
    on<_LoadMoreChats>(_onLoadMoreChats);
    on<_LoadChatDetails>(_onLoadChatDetails);
    on<_CreateChat>(_onCreateChat);
    on<_UpdateChat>(_onUpdateChat);
    on<_LeaveChat>(_onLeaveChat);
    on<_DeleteChat>(_onDeleteChat);
    on<_MarkMessagesAsRead>(_onMarkMessagesAsRead);
    on<_NewMessageReceived>(_onNewMessageReceived);
    on<_ConnectivityChanged>(_onConnectivityChanged);
    on<_ChatUpdated>(_onChatUpdated);
    on<_SearchChats>(_onSearchChats);
    on<_ClearSearch>(_onClearSearch);
    on<_ChangeConversationTypeFilter>(_onChangeConversationTypeFilter);
    on<_PendingDirectResolved>(_onPendingDirectResolved);

    // When network restores but socket is dead (Socket.IO exhausted its
    // auto-reconnect attempts), trigger reconnection + data reload.
    _connectivitySubscription =
        _connectivityService.onConnectivityChanged.listen((isConnected) {
      if (isConnected) {
        _triggerOnlineRefresh(source: 'connectivity_stream');
      }
    });

    // When socket transitions from any non-connected state to connected
    // (e.g. after Socket.IO auto-reconnect during short outages),
    // reload chats to pick up messages missed during the gap.
    SocketConnectionState? previousSocketState;
    _connectionStateSubscription = _realtimeService.connectionState.listen(
      (socketState) {
        final wasDisconnected = previousSocketState != null &&
            previousSocketState != SocketConnectionState.connected;
        previousSocketState = socketState;
        if (wasDisconnected && socketState == SocketConnectionState.connected) {
          _triggerOnlineRefresh(source: 'socket_connected_transition');
        }
      },
    );
  }

  void _triggerOnlineRefresh({required String source}) {
    final now = DateTime.now();
    final lastTrigger = _lastOnlineRefreshTriggerAt;
    if (lastTrigger != null &&
        now.difference(lastTrigger) < _onlineRefreshTriggerCooldown) {
      logger.d('Skip duplicate online refresh trigger from $source');
      return;
    }
    _lastOnlineRefreshTriggerAt = now;
    add(const ChatEvent.connectivityChanged(true));
  }

  /// **Load chats with cache-first pattern**
  ///
  /// Flow: Show cached data instantly → fetch network in background → update UI
  /// Like WhatsApp/Telegram: user never sees a spinner if cache exists.
  Future<void> _onLoadChats(
    _LoadChats event,
    Emitter<ChatState> emit,
  ) async {
    final current = state.whenOrNull(
      loaded: (chats,
              hasMore,
              isLoadingMore,
              page,
              pageSize,
              total,
              activeFilter,
              cachedLists,
              filterPages,
              filterHasMore,
              isSyncing) =>
          (
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

    logger.i(
        'Loading conversations (filter: $activeFilter, forceRefresh: ${event.forceRefresh})');

    // === CACHE-FIRST: Show local data instantly ===
    final localResult = await _getLocalConversations();
    final localChatsRaw = localResult.fold(
      (_) => <Chat>[],
      (chats) => chats,
    );
    // Defensive dedup: Isar may contain duplicates from race conditions
    // between saveChat/saveChats and socket-driven persist operations.
    final localChats = _deduplicateChats(localChatsRaw);

    if (localChats.isNotEmpty && !event.forceRefresh) {
      // Emit cached data immediately — user sees content in < 50ms
      _prefetchAvatars(localChats);
      _subscribeToRealTimeUpdates();

      cachedLists[activeFilter] = localChats;

      emit(ChatState.loaded(
        chats: localChats,
        hasMore: true,
        isLoadingMore: false,
        page: 0,
        pageSize: pageSize,
        total: localChats.length,
        activeFilter: activeFilter,
        cachedLists: cachedLists,
        filterPages: filterPages,
        filterHasMore: filterHasMore,
        isSyncing: true, // Indicate background refresh in progress
      ));
    } else {
      // No cache (first launch) — show loading shimmer
      emit(const ChatState.loading());
    }

    // === NETWORK REFRESH: Fetch fresh data in background ===
    final shouldRefresh =
        event.forceRefresh || _cacheSyncStrategy.shouldRefreshChatList();

    final request = PageRequest.first(size: pageSize);
    final result = await _getConversations(
      request,
      typeFilter: activeFilter.apiValue,
    );

    result.fold(
      (failure) {
        logger.e('Failed to load conversations: ${failure.message}');
        if (localChats.isNotEmpty) {
          // Network failed but we have cache — keep showing cached data, clear syncing
          emit(ChatState.loaded(
            chats: localChats,
            hasMore: true,
            isLoadingMore: false,
            page: 0,
            pageSize: pageSize,
            total: localChats.length,
            activeFilter: activeFilter,
            cachedLists: cachedLists,
            filterPages: filterPages,
            filterHasMore: filterHasMore,
            isSyncing: false,
          ));
        } else {
          // No cache and network failed — show error
          emit(ChatState.error(message: getUserErrorMessage(failure)));
        }
      },
      (paged) {
        // Defensive dedup: API pagination overlap may return duplicates
        final chats = _deduplicateChats(paged.items);
        final effectiveHasMore = chats.length == request.size;

        if (shouldRefresh) {
          _cacheSyncStrategy.resetChatListDirtyFlag();
        }

        _prefetchAvatars(chats);
        _subscribeToRealTimeUpdates();

        // Merge pending direct chats (local-only) back into the list.
        // Server doesn't know about these yet — they only exist locally
        // until the first message is sent (like Angular frontend pattern).
        final mergedChats = _mergePendingDirectChats(chats, activeFilter);

        cachedLists[activeFilter] = mergedChats;
        filterPages[activeFilter] = 0;
        filterHasMore[activeFilter] = effectiveHasMore;

        // Update total unread count on event bus for host app badge
        int totalUnread = 0;
        for (final c in mergedChats) {
          totalUnread += c.unreadCount;
        }
        _eventBus.updateTotalUnreadCount(totalUnread);

        emit(ChatState.loaded(
          chats: mergedChats,
          hasMore: effectiveHasMore,
          isLoadingMore: false,
          page: 0,
          pageSize: pageSize,
          total: mergedChats.length,
          activeFilter: activeFilter,
          cachedLists: cachedLists,
          filterPages: filterPages,
          filterHasMore: filterHasMore,
          isSyncing: false, // Background refresh complete
        ));
      },
    );
  }

  Future<void> _onLoadMoreChats(
    _LoadMoreChats event,
    Emitter<ChatState> emit,
  ) async {
    final current = state.whenOrNull(
      loaded: (chats,
              hasMore,
              isLoadingMore,
              page,
              pageSize,
              total,
              activeFilter,
              cachedLists,
              filterPages,
              filterHasMore,
              isSyncing) =>
          (
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

    final cachedLists =
        Map<ConversationTypeFilter, List<Chat>>.from(current.cachedLists);
    final filterPages =
        Map<ConversationTypeFilter, int>.from(current.filterPages);
    final filterHasMore =
        Map<ConversationTypeFilter, bool>.from(current.filterHasMore);

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

        final effectiveHasMore =
            addedNew > 0 && paged.items.length == nextRequest.size;

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
          emit(
              const ChatState.error(message: 'Không tìm thấy cuộc trò chuyện'));
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

    String? avatarUrl;
    final shouldUploadAvatar = event.type == ChatType.group &&
        (event.avatarBytes?.isNotEmpty ?? false);
    if (shouldUploadAvatar) {
      final avatarBytes = event.avatarBytes;
      if (avatarBytes == null) {
        const failure = ValidationFailure(
          message: 'Group avatar data is missing',
        );
        emit(ChatState.error(message: getUserErrorMessage(failure)));
        return;
      }

      final uploadResult = await _uploadGroupAvatar(
        avatarBytes: avatarBytes,
        avatarFileName: event.avatarFileName,
        avatarFilePath: event.avatarFilePath,
      );

      bool uploadFailed = false;
      uploadResult.fold(
        (failure) {
          uploadFailed = true;
          logger.e(
            'Create group avatar upload failed: ${failure.message}',
            error: failure,
          );
          emit(ChatState.error(message: getUserErrorMessage(failure)));
        },
        (uploadedAvatarUrl) {
          avatarUrl = uploadedAvatarUrl;
        },
      );

      if (uploadFailed) {
        return;
      }
    }

    final result = await _createGroup(
      name: event.name ?? 'New Group',
      memberIds: event.participantIds,
      avatar: avatarUrl,
      description: event.description,
      groupType: event.groupType,
    );

    Chat? createdChat;
    result.fold(
      (failure) {
        logger.e('Failed to create chat: ${failure.message}');
        emit(ChatState.error(message: getUserErrorMessage(failure)));
      },
      (chat) {
        createdChat = chat;
      },
    );

    final chat = createdChat;
    if (chat == null) {
      return;
    }

    logger.i('Chat created successfully: ${chat.id}');
    emit(ChatState.chatDetailsLoaded(chat: chat));

    // Mark chat list as dirty so the next _onLoadChats knows to refresh.
    // This ensures the newly created conversation appears when the user
    // navigates back to the conversation list.
    _cacheSyncStrategy.markChatListDirty();
  }

  Future<Either<Failure, String>> _uploadGroupAvatar({
    required Uint8List avatarBytes,
    String? avatarFileName,
    String? avatarFilePath,
  }) async {
    final trimmedFileName = avatarFileName?.trim();
    final resolvedFileName =
        trimmedFileName != null && trimmedFileName.isNotEmpty
            ? trimmedFileName
            : 'group_avatar_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final trimmedFilePath = avatarFilePath?.trim();
    final canUseFileUpload =
        !kIsWeb && trimmedFilePath != null && trimmedFilePath.isNotEmpty;
    final resolvedFilePath = trimmedFilePath ?? '';

    final uploadResult = await _attachmentRepository.uploadAttachment(
      messageId: 'group-avatar-${DateTime.now().millisecondsSinceEpoch}',
      chatId: 'pending-group-avatar',
      file: canUseFileUpload ? File(resolvedFilePath) : null,
      bytes: canUseFileUpload ? null : avatarBytes,
      fileName: resolvedFileName,
    );

    return uploadResult.fold(
      Left.new,
      (result) {
        final avatarUrl = result.url.trim();
        if (avatarUrl.isEmpty) {
          return const Left(
            UnexpectedFailure(
              message: 'Group avatar upload returned an empty URL',
            ),
          );
        }
        return Right(avatarUrl);
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
      groupType: event.groupType,
      memberIds: event.memberIds,
      adminIds: event.adminIds,
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
          _cacheSyncStrategy.markChatListDirty();
          emit(
            ChatState.conversationActionCompleted(
              chatId: event.chatId,
              action: ChatConversationAction.leave,
            ),
          );

          // Reload chats to remove the left chat
          add(const ChatEvent.loadChats(forceRefresh: true));
        }
      },
    );
  }

  /// **Delete chat using DeleteConversationUseCase - CLEAN ARCHITECTURE**
  Future<void> _onDeleteChat(
    _DeleteChat event,
    Emitter<ChatState> emit,
  ) async {
    logger.i('Deleting chat: ${event.chatId}');

    emit(const ChatState.loading());

    final result = await _deleteConversation(event.chatId);

    result.fold(
      (failure) {
        logger.e('Failed to delete chat: ${failure.message}');
        emit(ChatState.error(message: getUserErrorMessage(failure)));
      },
      (success) {
        if (success) {
          logger.i('Deleted chat successfully');
          _cacheSyncStrategy.markChatListDirty();
          emit(
            ChatState.conversationActionCompleted(
              chatId: event.chatId,
              action: ChatConversationAction.delete,
            ),
          );
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
    logger
        .i('Connectivity changed: ${event.isConnected ? "online" : "offline"}');

    if (event.isConnected) {
      // Connection restored — use soft reload (no forceRefresh) so the
      // cache-first pattern keeps showing existing data while syncing
      // in the background. Using forceRefresh would clear the cache and
      // cause a shimmer flash, which breaks the WhatsApp/Telegram UX.
      logger.i('Connection restored, soft-syncing chats');
      _cacheSyncStrategy.markChatListDirty();
      add(const ChatEvent.loadChats());
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

    // Track pending direct chats (local-only, temp timestamp ID, no members).
    // These survive server refreshes until resolved by first message send.
    final chat = event.chat;
    if (_isPendingDirectChat(chat)) {
      _pendingDirectChats[chat.id] = chat;
      logger.i(
          '[ChatBloc] Tracked pending direct chat: ${chat.id} '
          '(participantIds=${chat.participantIds})');
    }

    if (state is _Loaded) {
      final currentState = state as _Loaded;
      emit(_upsertChatIntoLoadedState(currentState, event.chat));
      logger.i('Chat list upserted with latest data');
    }
  }

  /// A pending direct chat resolved to a real server conversation.
  /// Remove the temp chat from tracking and refresh from server.
  Future<void> _onPendingDirectResolved(
    _PendingDirectResolved event,
    Emitter<ChatState> emit,
  ) async {
    logger.i(
        '[ChatBloc] Pending direct resolved: '
        'temp=${event.tempChatId} → server=${event.serverChatId}');

    // Remove temp chat from pending tracking
    _pendingDirectChats.remove(event.tempChatId);

    // Also remove the temp chat from the current loaded state immediately
    // so it doesn't show as a duplicate while server refresh is in progress.
    if (state is _Loaded) {
      final currentState = state as _Loaded;
      final filteredChats = currentState.chats
          .where((c) => c.id != event.tempChatId)
          .toList();
      if (filteredChats.length != currentState.chats.length) {
        emit(_preserveLoaded(currentState, chats: filteredChats));
      }
    }

    // Refresh from server — the real conversation now exists
    add(const ChatEvent.loadChats(forceRefresh: true));
  }

  /// Check if a chat is a pending direct chat (local-only, not yet on server).
  /// Pending direct chats have: direct type, empty members, numeric temp ID.
  bool _isPendingDirectChat(Chat chat) {
    return chat.type == ChatType.direct &&
        chat.members.isEmpty &&
        chat.participantIds.isNotEmpty &&
        RegExp(r'^\d{10,}$').hasMatch(chat.id);
  }

  /// Merge pending direct chats into the server-fetched chat list.
  /// This ensures local-only pending chats survive server refreshes
  /// (the Angular frontend does the same: temp conversations stay in
  /// the local array until resolved by first message).
  List<Chat> _mergePendingDirectChats(
    List<Chat> serverChats,
    ConversationTypeFilter activeFilter,
  ) {
    if (_pendingDirectChats.isEmpty) {
      return serverChats;
    }

    // Only merge chats that match the active filter
    final pendingToMerge = _pendingDirectChats.values.where((pending) {
      return _chatMatchesFilter(pending, activeFilter);
    }).toList();

    if (pendingToMerge.isEmpty) {
      return serverChats;
    }

    // Don't add pending chats that already exist in server list
    // (the server might have created the conversation by now)
    final serverIds = serverChats.map((c) => c.id).toSet();
    final toAdd = pendingToMerge
        .where((pending) => !serverIds.contains(pending.id))
        .toList();

    if (toAdd.isEmpty) {
      // All pending chats already resolved on server — clean up tracking
      for (final chat in pendingToMerge) {
        _pendingDirectChats.remove(chat.id);
      }
      return serverChats;
    }

    logger.d(
        '[ChatBloc] Merging ${toAdd.length} pending direct chats into list');
    final merged = [...serverChats, ...toAdd];
    _sortChatsByRecency(merged);
    return merged;
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
        final dedupedChats = _deduplicateChats(chats);
        // Search results don't filter by type — preserve activeFilter from current state
        final activeFilter = state.whenOrNull(
              loaded: (_, __, ___, ____, _____, ______, activeFilter, _______,
                      ________, _________, __________) =>
                  activeFilter,
            ) ??
            ConversationTypeFilter.all;
        emit(ChatState.loaded(
          chats: dedupedChats,
          hasMore: false,
          isLoadingMore: false,
          page: 0,
          pageSize: 100,
          total: dedupedChats.length,
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
      loaded: (chats,
              hasMore,
              isLoadingMore,
              page,
              pageSize,
              total,
              activeFilter,
              cachedLists,
              filterPages,
              filterHasMore,
              isSyncing) =>
          (
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
        logger.e(
            'ChangeConversationTypeFilter: failed for $filter: ${failure.message}');
        emit(ChatState.error(message: getUserErrorMessage(failure)));
      },
      (paged) {
        final chats = _deduplicateChats(paged.items);
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
      // Chat not in current list — this can happen when:
      // 1. A new conversation was created on the server (receiver's side)
      // 2. A pending direct chat was resolved to a real server ID
      // Fetch the conversation detail from server and add it to the list
      // (same pattern as Angular frontend: fetch chatConversationDetail).
      logger.i(
          '[ChatBloc] Received message for unknown chat ${message.chatId}, '
          'fetching conversation detail...');
      final result = await _getConversationDetail(message.chatId);
      result.fold(
        (failure) {
          logger.w(
              '[ChatBloc] Failed to fetch unknown chat ${message.chatId}: '
              '${failure.message}');
        },
        (chat) {
          if (chat != null) {
            add(ChatEvent.chatUpdated(chat: chat));
          }
        },
      );
      return;
    }

    final existingChat = currentState.chats[idx];
    final isIncoming = message.sender.id != _currentUserProvider.currentUserId;

    final preview = _formatMessagePreview(message, existingChat.members);

    final updatedChat = existingChat.copyWith(
      lastMessageTime: message.createdAt,
      lastMessagePreview: preview,
      unreadCount: isIncoming
          ? (existingChat.unreadCount + 1)
          : existingChat.unreadCount,
    );

    final updatedChats = List<Chat>.from(currentState.chats);
    updatedChats[idx] = updatedChat;

    _sortChatsByRecency(updatedChats);

    emit(_preserveLoaded(currentState, chats: updatedChats));

    // Fire-and-forget: persist to local cache (Isar)
    unawaited(
      _persistIncomingMessage(PersistIncomingMessageParams(
        message: message,
        updatedChat: updatedChat,
      )).then((_) {}, onError: (Object e) {
        logger.w('Failed to persist incoming message: $e');
      }),
    );

    // Notify event bus for host app
    if (isIncoming) {
      _eventBus.emitNewMessage(message);
      _eventBus.incrementUnreadCount();
    }
  }

  Future<void> _onMarkMessagesAsRead(
    _MarkMessagesAsRead event,
    Emitter<ChatState> emit,
  ) async {
    if (state is _Loaded) {
      final currentState = state as _Loaded;
      final chat = currentState.chats.firstWhere(
        (c) => c.id == event.chatId,
        orElse: () => currentState.chats.first,
      );
      final previousUnread = chat.id == event.chatId ? chat.unreadCount : 0;

      final updatedChats = currentState.chats
          .map((c) => c.id == event.chatId ? c.copyWith(unreadCount: 0) : c)
          .toList();
      emit(_preserveLoaded(currentState, chats: updatedChats));

      // Update event bus for host app badge
      if (previousUnread > 0) {
        _eventBus.decrementUnreadCount(previousUnread);
      }
    }

    // Skip remote call for pending direct chats — temp numeric IDs are not
    // valid UUIDs and will cause backend errors.
    if (!event.chatId.contains('-')) {
      logger.d('[ChatBloc] Skipping markAsRead for pending direct: ${event.chatId}');
      return;
    }

    final result =
        await _markAsRead(MarkAsReadParams(conversationId: event.chatId));
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

  /// Deduplicate chats by [Chat.id], keeping the LAST occurrence
  /// (which is typically the most recently updated version).
  ///
  /// This is a defensive safety net for the cache-first pattern:
  /// - Phase 1 (local cache) may contain stale duplicates from Isar
  /// - Phase 2 (remote) may return duplicates if API has pagination overlap
  /// - Socket events may add a chat that already exists in the list
  List<Chat> _deduplicateChats(List<Chat> chats) {
    final seen = <String>{};
    final result = <Chat>[];
    // Iterate in reverse so the LAST (most recent) occurrence wins,
    // then reverse back to preserve original order.
    for (var i = chats.length - 1; i >= 0; i--) {
      if (seen.add(chats[i].id)) {
        result.add(chats[i]);
      }
    }
    return result.reversed.toList();
  }

  ChatState _upsertChatIntoLoadedState(_Loaded current, Chat updatedChat) {
    final cachedLists =
        Map<ConversationTypeFilter, List<Chat>>.from(current.cachedLists);
    final filterPages =
        Map<ConversationTypeFilter, int>.from(current.filterPages);
    final filterHasMore =
        Map<ConversationTypeFilter, bool>.from(current.filterHasMore);

    List<Chat> visibleChats = current.chats;

    for (final filter in ConversationTypeFilter.values) {
      final hasExistingCache =
          filter == current.activeFilter || cachedLists.containsKey(filter);
      if (!hasExistingCache) {
        continue;
      }

      final baseList = filter == current.activeFilter
          ? current.chats
          : cachedLists[filter] ?? const <Chat>[];
      final matchesFilter = _chatMatchesFilter(updatedChat, filter);
      final nextList = matchesFilter
          ? _upsertAndSortChats(baseList, updatedChat)
          : baseList.where((chat) => chat.id != updatedChat.id).toList();

      cachedLists[filter] = nextList;
      filterPages[filter] = filterPages[filter] ?? current.page;
      filterHasMore[filter] = filterHasMore[filter] ?? current.hasMore;

      if (filter == current.activeFilter) {
        visibleChats = nextList;
      }
    }

    return ChatState.loaded(
      chats: visibleChats,
      hasMore: current.hasMore,
      isLoadingMore: current.isLoadingMore,
      page: current.page,
      pageSize: current.pageSize,
      total: visibleChats.length,
      activeFilter: current.activeFilter,
      cachedLists: cachedLists,
      filterPages: filterPages,
      filterHasMore: filterHasMore,
      isSyncing: current.isSyncing,
    );
  }

  List<Chat> _upsertAndSortChats(List<Chat> chats, Chat updatedChat) {
    final updatedChats =
        chats.where((chat) => chat.id != updatedChat.id).toList(growable: true);
    updatedChats.add(updatedChat);
    _sortChatsByRecency(updatedChats);
    return updatedChats;
  }

  void _sortChatsByRecency(List<Chat> chats) {
    chats.sort((a, b) => _compareChatsByRecency(a, b));
  }

  int _compareChatsByRecency(Chat a, Chat b) {
    final aRecency = _chatRecency(a);
    final bRecency = _chatRecency(b);
    final recencyCompare = bRecency.compareTo(aRecency);
    if (recencyCompare != 0) {
      return recencyCompare;
    }

    final aCreatedAt = a.createdAt;
    final bCreatedAt = b.createdAt;
    if (aCreatedAt != null && bCreatedAt != null) {
      final createdAtCompare = bCreatedAt.compareTo(aCreatedAt);
      if (createdAtCompare != 0) {
        return createdAtCompare;
      }
    } else if (aCreatedAt == null && bCreatedAt != null) {
      return 1;
    } else if (aCreatedAt != null && bCreatedAt == null) {
      return -1;
    }

    return a.id.compareTo(b.id);
  }

  DateTime _chatRecency(Chat chat) {
    return chat.lastMessageTime ??
        chat.createdAt ??
        DateTime.fromMillisecondsSinceEpoch(0);
  }

  bool _chatMatchesFilter(Chat chat, ConversationTypeFilter filter) {
    switch (filter) {
      case ConversationTypeFilter.all:
        return true;
      case ConversationTypeFilter.direct:
        return chat.type == ChatType.direct;
      case ConversationTypeFilter.group:
        return chat.type == ChatType.group;
    }
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
      isSyncing: current.isSyncing,
    );
  }

  /// Format message preview based on content type for chat list display.
  ///
  /// Handles all message types: text, media, system events, forwarded, etc.
  /// Resolves mentions using conversation members.
  String _formatMessagePreview(
    ChatMessage message,
    List<ConversationMember> members,
  ) {
    final mentionNameById = <String, String>{
      for (final m in members)
        if (m.userId.isNotEmpty && (m.fullName?.trim().isNotEmpty ?? false))
          m.userId: m.fullName!.trim(),
      for (final m in message.mentionTo)
        if (m.id.isNotEmpty && m.name.trim().isNotEmpty) m.id: m.name.trim(),
    };

    String formatContent(String? content) {
      if (content == null || content.trim().isEmpty) return '';
      return content.formatChatMessage(mentionNameById: mentionNameById).trim();
    }

    // System events
    if (message.contentType == ContentType.event) {
      return '⚙ Thông báo hệ thống';
    }

    // Forwarded messages
    if (message.forwardedFromMessageId != null) {
      final content = formatContent(message.content);
      if (content.isNotEmpty) return '↩ $content';
      return switch (message.contentType) {
        ContentType.image => '↩ 📷 Photo',
        ContentType.video => '↩ 📹 Video',
        ContentType.audio => '↩ 🎧 Audio',
        ContentType.file => '↩ 📄 ${message.fileName ?? "File"}',
        ContentType.sticker => '↩ 🎯 Sticker',
        _ => '↩ Tin nhắn chuyển tiếp',
      };
    }

    // Media types
    switch (message.contentType) {
      case ContentType.image:
        final text = formatContent(message.content);
        return text.isNotEmpty ? '📷 $text' : '📷 Photo';
      case ContentType.video:
        final text = formatContent(message.content);
        return text.isNotEmpty ? '📹 $text' : '📹 Video';
      case ContentType.audio:
        final text = formatContent(message.content);
        return text.isNotEmpty ? '🎧 $text' : '🎧 Audio';
      case ContentType.file:
        final name = message.fileName?.trim();
        return name != null && name.isNotEmpty ? '📄 $name' : '📄 File';
      case ContentType.location:
        return '📍 Vị trí';
      case ContentType.link:
        final text = formatContent(message.content);
        return text.isNotEmpty ? text : '🔗 Liên kết';
      case ContentType.sticker:
        return '🎯 Sticker';
      case ContentType.text:
      case ContentType.event:
        final text = formatContent(message.content);
        return text.isNotEmpty ? text : message.content;
    }
  }

  @override
  Future<void> close() {
    _messageSubscription?.cancel();
    _typingSubscription?.cancel();
    _readReceiptSubscription?.cancel();
    _connectivitySubscription?.cancel();
    _chatUpdatesSubscription?.cancel();
    _connectionStateSubscription?.cancel();
    // Cancel all typing timers
    for (final timer in _typingTimers.values) {
      timer.cancel();
    }
    _typingTimers.clear();
    return super.close();
  }
}
