import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_chat_app/domain/models/queued_message.dart';
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
  }

  /// **Load chats using GetConversationsUseCase - CLEAN ARCHITECTURE**
  Future<void> _onLoadChats(
    _LoadChats event,
    Emitter<ChatState> emit,
  ) async {
    final pageSize = state.whenOrNull(
          loaded: (_, __, ___, ____, pageSize, _____) => pageSize,
        ) ??
        25;

    emit(const ChatState.loading());

    logger.i('Loading conversations using UseCase');

    // Check if cache refresh is needed
    final shouldRefresh = event.forceRefresh || _cacheSyncStrategy.shouldRefreshChatList();

    // Execute UseCase
    final request = PageRequest.first(size: pageSize);
    final result = await _getConversations(request);

    result.fold(
        (failure) {
          logger.e('Failed to load conversations: ${failure.message}');
          emit(ChatState.error(message: getUserErrorMessage(failure)));
        },
        (paged) {
          final chats = paged.items;
          // Backend `total` is not reliable (it can be equal to the current page length).
          // Use a simple heuristic consistent with the Angular frontend:
          // - If a page returns exactly `pageSize` items, assume there may be more.
          // - Stop when a page returns fewer than `pageSize` items (including empty).
          final effectiveHasMore = chats.length == request.size;

          // Reset dirty flag after successful load
          if (shouldRefresh) {
            _cacheSyncStrategy.resetChatListDirtyFlag();
          }

          // Pre-cache avatars for better UX
          _prefetchAvatars(chats);

          // Subscribe to real-time updates
          _subscribeToRealTimeUpdates();

          emit(
            ChatState.loaded(
              chats: chats,
              hasMore: effectiveHasMore,
              isLoadingMore: false,
              page: 0,
              pageSize: pageSize,
              total: chats.length,
            ),
          );
        },
      );
  }

  Future<void> _onLoadMoreChats(
    _LoadMoreChats event,
    Emitter<ChatState> emit,
  ) async {
    final current = state.whenOrNull(loaded: (chats, hasMore, isLoadingMore, page, pageSize, total) {
      return (
        chats: chats,
        hasMore: hasMore,
        isLoadingMore: isLoadingMore,
        page: page,
        pageSize: pageSize,
        total: total,
      );
    });

    if (current == null) return;
    if (!current.hasMore) return;
    if (current.isLoadingMore) return;

    emit(
      ChatState.loaded(
        chats: current.chats,
        hasMore: current.hasMore,
        isLoadingMore: true,
        page: current.page,
        pageSize: current.pageSize,
        total: current.total,
      ),
    );

    final nextRequest = PageRequest(
      page: current.page + 1,
      size: current.pageSize,
    );

    final result = await _getConversations(nextRequest);

    result.fold(
      (failure) {
        logger.e('Failed to load more conversations: ${failure.message}');
        emit(
          ChatState.loaded(
            chats: current.chats,
            hasMore: current.hasMore,
            isLoadingMore: false,
            page: current.page,
            pageSize: current.pageSize,
            total: current.total,
          ),
        );
      },
      (paged) {
        if (paged.items.isEmpty) {
          emit(
            ChatState.loaded(
              chats: current.chats,
              hasMore: false,
              isLoadingMore: false,
              page: current.page,
              pageSize: current.pageSize,
              total: current.chats.length,
            ),
          );
          return;
        }

        final merged = <Chat>[...current.chats];
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

        // Continue paging only when the returned page is full.
        // If backend returns fewer than `pageSize`, we reached the end.
        final effectiveHasMore = addedNew > 0 && paged.items.length == nextRequest.size;

        emit(
          ChatState.loaded(
            chats: merged,
            hasMore: effectiveHasMore,
            isLoadingMore: false,
            page: nextRequest.page,
            pageSize: current.pageSize,
            total: merged.length,
          ),
        );
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

        // Reload chats to include the new one
        add(const ChatEvent.loadChats(forceRefresh: true));
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
    
    // Update chat in current state if loaded
    if (state is _Loaded) {
      final currentState = state as _Loaded;
      final updatedChats = currentState.chats.map((chat) {
        return chat.id == event.chat.id ? event.chat : chat;
      }).toList();
      
      emit(ChatState.loaded(chats: updatedChats));
      logger.i('Chat list updated with new data');
    }
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

    emit(ChatState.loaded(chats: updatedChats));
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
      emit(ChatState.loaded(chats: updatedChats));
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

    if (indicator.isTyping) {
      if (!typing.contains(indicator.userId)) {
        typing.add(indicator.userId);
      }
    } else {
      typing.remove(indicator.userId);
    }

    final updatedChats = List<Chat>.from(currentState.chats);
    updatedChats[idx] = chat.copyWith(typingUserIds: typing);
    emit(ChatState.loaded(chats: updatedChats));
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
    emit(ChatState.loaded(chats: updatedChats));
  }

  @override
  Future<void> close() {
    _messageSubscription?.cancel();
    _typingSubscription?.cancel();
    _readReceiptSubscription?.cancel();
    _connectivitySubscription?.cancel();
    _chatUpdatesSubscription?.cancel();
    return super.close();
  }
}
