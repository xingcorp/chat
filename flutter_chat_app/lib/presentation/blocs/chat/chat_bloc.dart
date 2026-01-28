import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';

import 'package:flutter_chat_app/core/cache/cache_sync_strategy.dart';
import 'package:flutter_chat_app/core/cache/media_cache_manager.dart';
import 'package:flutter_chat_app/core/services/connectivity_service.dart';
import 'package:flutter_chat_app/domain/entities/chat.dart';
import 'package:flutter_chat_app/domain/entities/chat_message.dart';
import 'package:flutter_chat_app/domain/entities/message_queue_status.dart';
import 'package:flutter_chat_app/domain/models/queued_message.dart';
import 'package:flutter_chat_app/domain/usecases/chat/create_group_usecase.dart';
import 'package:flutter_chat_app/domain/usecases/chat/delete_conversation_usecase.dart';
import 'package:flutter_chat_app/domain/usecases/chat/get_conversation_detail_usecase.dart';
import 'package:flutter_chat_app/domain/usecases/chat/get_conversations_usecase.dart';
import 'package:flutter_chat_app/domain/usecases/chat/leave_conversation_usecase.dart';
import 'package:flutter_chat_app/domain/usecases/chat/search_conversations_usecase.dart';
import 'package:flutter_chat_app/domain/usecases/chat/update_group_usecase.dart';
import 'package:flutter_chat_app/presentation/blocs/base/base_bloc.dart';
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
class ChatBloc extends BaseBloc<ChatEvent, ChatState> with BlocErrorMixin {
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

  // Subscriptions for real-time updates
  StreamSubscription<ChatMessage>? _messageSubscription;
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
  ) : super(const ChatState.initial()) {
    on<_LoadChats>(_onLoadChats);
    on<_LoadChatDetails>(_onLoadChatDetails);
    on<_CreateChat>(_onCreateChat);
    on<_UpdateChat>(_onUpdateChat);
    on<_LeaveChat>(_onLeaveChat);
    on<_ConnectivityChanged>(_onConnectivityChanged);
    on<_ChatUpdated>(_onChatUpdated);
  }

  /// **Load chats using GetConversationsUseCase - CLEAN ARCHITECTURE**
  Future<void> _onLoadChats(
    _LoadChats event,
    Emitter<ChatState> emit,
  ) async {
    // Skip if already loading
    if (state is _Loading) {
      return;
    }

    emitLoading(message: 'Đang tải danh sách chat...');
    emit(const ChatState.loading());

    logger.i('Loading conversations using UseCase');

    // Check if cache refresh is needed
    final shouldRefresh = event.forceRefresh || _cacheSyncStrategy.shouldRefreshChatList();

    // Execute with retry for resilience
    final result = await executeWithRetry(
      () => _getConversations(),
      maxRetries: 3,
      emitLoadingState: false, // Already emitted above
      loadingMessage: 'Đang tải danh sách chat...',
    );

    if (result != null) {
      result.fold(
        (failure) {
          logger.e('Failed to load conversations: ${failure.message}');
          emit(ChatState.error(message: getUserErrorMessage(failure)));
        },
        (chats) {
          logger.i('Loaded ${chats.length} conversations successfully');

          // Reset dirty flag after successful load
          if (shouldRefresh) {
            _cacheSyncStrategy.resetChatListDirtyFlag();
          }

          // Pre-cache avatars for better UX
          _prefetchAvatars(chats);

          // Subscribe to real-time updates
          _subscribeToRealTimeUpdates();

          emit(ChatState.loaded(chats: chats));
        },
      );
    }
  }

  /// **Load chat details using GetConversationDetailUseCase - CLEAN ARCHITECTURE**
  Future<void> _onLoadChatDetails(
    _LoadChatDetails event,
    Emitter<ChatState> emit,
  ) async {
    logger.i('Loading conversation detail: ${event.chatId}');

    // Create params for UseCase
    final params = GetConversationDetailParams(conversationId: event.chatId);

    // Execute UseCase
    final result = await _getConversationDetail(params);

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

    emitLoading(message: 'Đang tạo cuộc trò chuyện...');

    // Create params for UseCase
    final params = CreateGroupParams(
      name: event.name ?? 'New Group',
      memberIds: event.participantIds,
      description: event.description,
    );

    // Execute UseCase
    final result = await _createGroup(params);

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

    emitLoading(message: 'Đang cập nhật...');

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

    emitLoading(message: 'Đang rời khỏi cuộc trò chuyện...');

    // Create params for UseCase
    final params = LeaveConversationParams(conversationId: event.chatId);

    // Execute UseCase
    final result = await _leaveConversation(params);

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
    // TODO: Implement when socket manager is available
    // Cancel existing subscription
    // _chatUpdatesSubscription?.cancel();
    // _chatUpdatesSubscription = _socketService.onChatUpdated().listen((chat) {
    //   add(ChatEvent.chatUpdated(chat: chat));
    // });
    logger.d('Real-time updates subscription setup (pending socket implementation)');
  }

  @override
  Future<void> close() {
    _messageSubscription?.cancel();
    _connectivitySubscription?.cancel();
    _chatUpdatesSubscription?.cancel();
    return super.close();
  }
}
