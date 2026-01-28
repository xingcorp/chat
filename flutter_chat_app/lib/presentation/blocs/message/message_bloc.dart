import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';

import 'package:flutter_chat_app/core/cache/cache_sync_strategy.dart';
import 'package:flutter_chat_app/core/cache/media_cache_manager.dart';
import 'package:flutter_chat_app/core/services/realtime_service.dart';
import 'package:flutter_chat_app/domain/entities/chat_message.dart';
import 'package:flutter_chat_app/domain/usecases/message/delete_message_usecase.dart';
import 'package:flutter_chat_app/domain/usecases/message/edit_message_usecase.dart';
import 'package:flutter_chat_app/domain/usecases/message/get_messages_usecase.dart';
import 'package:flutter_chat_app/domain/usecases/message/mark_as_read_usecase.dart';
import 'package:flutter_chat_app/domain/usecases/message/send_message_usecase.dart';
import 'package:flutter_chat_app/presentation/blocs/base/base_bloc.dart';
import 'package:flutter_chat_app/presentation/blocs/base/bloc_error_mixin.dart';

part 'message_event.dart';
part 'message_state.dart';

/// **ENTERPRISE MESSAGE BLOC - CLEAN ARCHITECTURE**
///
/// Updated to use UseCases and BaseBloc core components.
/// Follows Clean Architecture with proper separation of concerns.
///
/// **Performance Targets:**
/// - State updates: <50ms
/// - Error handling: Comprehensive with user-friendly messages
/// - Real-time updates: <100ms delivery
@injectable
class MessageBloc extends BaseBloc<MessageEvent, MessageState> with BlocErrorMixin {
  // UseCases (Domain Layer)
  final GetMessagesUseCase _getMessages;
  final SendMessageUseCase _sendMessage;
  final EditMessageUseCase _editMessage;
  final DeleteMessageUseCase _deleteMessage;
  final MarkAsReadUseCase _markAsRead;
  
  // Services
  final CacheSyncStrategy _cacheSyncStrategy;
  final MediaCacheManager _mediaCacheManager;
  final RealtimeService _realtimeService;

  // Map chat ID -> StreamSubscription
  final Map<String, StreamSubscription?> _messageSubscriptions = {};

  /// Constructor with UseCases injection
  MessageBloc(
    this._getMessages,
    this._sendMessage,
    this._editMessage,
    this._deleteMessage,
    this._markAsRead,
    this._cacheSyncStrategy,
    this._mediaCacheManager,
    this._realtimeService,
  ) : super(const MessageInitial()) {
    on<LoadMessages>(_onLoadMessages);
    on<LoadMoreMessages>(_onLoadMoreMessages);
    on<SendMessage>(_onSendMessage);
    on<EditMessage>(_onEditMessage);
    on<DeleteMessage>(_onDeleteMessage);
    on<MarkChatAsRead>(_onMarkChatAsRead);
    on<ReceiveRealTimeMessage>(_onReceiveRealTimeMessage);
    on<RefreshMessages>(_onRefreshMessages);
    on<ClearMessages>(_onClearMessages);
  }
  
  /// **Load messages using GetMessagesUseCase - CLEAN ARCHITECTURE**
  Future<void> _onLoadMessages(LoadMessages event, Emitter<MessageState> emit) async {
    logger.i('Loading messages for chat: ${event.chatId}');

    if (state is MessagesLoaded && (state as MessagesLoaded).chatId == event.chatId) {
      // Already loaded messages for this chat, only emit again if force refresh
      if (!event.forceRefresh) {
        return;
      }
    }

    emit(MessagesLoading(chatId: event.chatId));

    // Create params for UseCase
    final params = GetMessagesParams(
      conversationId: event.chatId,
      limit: event.limit,
    );

    // Execute UseCase
    final result = await _getMessages(params);

    result.fold(
      (failure) {
        logger.e('Failed to load messages: ${failure.message}');
        emit(MessagesError(
          chatId: event.chatId,
          error: getUserErrorMessage(failure),
        ));
      },
      (messages) {
        logger.i('Loaded ${messages.length} messages for chat ${event.chatId}');

        // Reset dirty flag after successful load
        _cacheSyncStrategy.resetChatMessagesDirtyFlag(event.chatId);

        // Cancel old subscription if exists
        _cancelMessageSubscription(event.chatId);

        // Subscribe to real-time updates
        if (event.subscribeToUpdates) {
          _subscribeToMessages(event.chatId);
        }

        emit(MessagesLoaded(
          chatId: event.chatId,
          messages: messages,
          hasReachedMax: messages.length < event.limit,
        ));
      },
    );
  }
  
  /// **Load more messages using GetMessagesUseCase (pagination) - CLEAN ARCHITECTURE**
  Future<void> _onLoadMoreMessages(LoadMoreMessages event, Emitter<MessageState> emit) async {
    if (state is! MessagesLoaded) return;

    final currentState = state as MessagesLoaded;

    // If already reached max, do nothing
    if (currentState.hasReachedMax) return;

    logger.i('Loading more messages for chat: ${currentState.chatId}');

    // Calculate cursor based on last message
    final lastMessageId = currentState.messages.isNotEmpty
        ? currentState.messages.last.id
        : null;

    // Create params for UseCase
    final params = GetMessagesParams(
      conversationId: currentState.chatId,
      limit: event.limit,
      cursor: lastMessageId,
    );

    // Execute UseCase
    final result = await _getMessages(params);

    result.fold(
      (failure) {
        logger.e('Failed to load more messages: ${failure.message}');

        // Emit error state but preserve current messages
        emit(MessagesError(
          chatId: currentState.chatId,
          error: 'Không thể tải thêm tin nhắn: ${getUserErrorMessage(failure)}',
          previousMessages: currentState.messages,
        ));
      },
      (nextMessages) {
        logger.i('Loaded ${nextMessages.length} more messages');

        if (nextMessages.isEmpty) {
          // No more messages
          emit(currentState.copyWith(hasReachedMax: true));
        } else {
          // Add new messages to current list
          emit(currentState.copyWith(
            messages: [...currentState.messages, ...nextMessages],
            hasReachedMax: nextMessages.length < event.limit,
          ));
        }
      },
    );
  }
  
  /// **Send message using SendMessageUseCase - CLEAN ARCHITECTURE**
  Future<void> _onSendMessage(SendMessage event, Emitter<MessageState> emit) async {
    if (state is! MessagesLoaded) return;

    final currentState = state as MessagesLoaded;

    logger.i('Sending message in chat: ${currentState.chatId}');

    // Create params for UseCase
    final params = SendMessageParams(
      conversationId: currentState.chatId,
      content: event.content,
      contentType: event.contentType,
      attachmentIds: event.attachmentIds,
    );

    // Execute UseCase
    final result = await _sendMessage(params);

    result.fold(
      (failure) {
        logger.e('Failed to send message: ${failure.message}');

        // Emit error state with current messages preserved
        emit(MessagesError(
          chatId: currentState.chatId,
          error: 'Không thể gửi tin nhắn: ${getUserErrorMessage(failure)}',
          previousMessages: currentState.messages,
        ));
      },
      (newMessage) {
        logger.i('Message sent successfully: ${newMessage.id}');
        
        // Add new message to the beginning of the list (optimistic update)
        emit(currentState.copyWith(
          messages: [newMessage, ...currentState.messages],
        ));

        // Mark message list as dirty
        _cacheSyncStrategy.markChatMessagesDirty(currentState.chatId);
        _cacheSyncStrategy.markChatListDirty();
      },
    );
  }

  /// **Edit message using EditMessageUseCase - CLEAN ARCHITECTURE**
  Future<void> _onEditMessage(EditMessage event, Emitter<MessageState> emit) async {
    if (state is! MessagesLoaded) return;

    final currentState = state as MessagesLoaded;

    logger.i('Editing message: ${event.messageId}');

    // Create params for UseCase
    final params = EditMessageParams(
      messageId: event.messageId,
      content: event.content,
    );

    // Execute UseCase
    final result = await _editMessage(params);

    result.fold(
      (failure) {
        logger.e('Failed to edit message: ${failure.message}');

        // Emit error state but preserve current messages
        emit(MessagesError(
          chatId: currentState.chatId,
          error: 'Không thể chỉnh sửa tin nhắn: ${getUserErrorMessage(failure)}',
          previousMessages: currentState.messages,
        ));
      },
      (editedMessage) {
        logger.i('Message edited successfully');
        
        // Update message in list
        final updatedMessages = currentState.messages.map((msg) {
          return msg.id == event.messageId ? editedMessage : msg;
        }).toList();

        emit(currentState.copyWith(messages: updatedMessages));

        // Mark message list as dirty
        _cacheSyncStrategy.markChatMessagesDirty(currentState.chatId);
      },
    );
  }
  
  /// **Delete message using DeleteMessageUseCase - CLEAN ARCHITECTURE**
  Future<void> _onDeleteMessage(DeleteMessage event, Emitter<MessageState> emit) async {
    if (state is! MessagesLoaded) return;

    final currentState = state as MessagesLoaded;

    logger.i('Deleting message: ${event.messageId}');

    // Create params for UseCase
    final params = DeleteMessageParams(messageId: event.messageId);

    // Execute UseCase
    final result = await _deleteMessage(params);

    result.fold(
      (failure) {
        logger.e('Failed to delete message: ${failure.message}');

        // Emit error state but preserve current messages
        emit(MessagesError(
          chatId: currentState.chatId,
          error: 'Không thể xóa tin nhắn: ${getUserErrorMessage(failure)}',
          previousMessages: currentState.messages,
        ));
      },
      (success) {
        if (success) {
          logger.i('Message deleted successfully');
          
          // Remove message from list
          final updatedMessages = currentState.messages
              .where((msg) => msg.id != event.messageId)
              .toList();

          emit(currentState.copyWith(messages: updatedMessages));

          // Mark message list as dirty
          _cacheSyncStrategy.markChatMessagesDirty(currentState.chatId);
          _cacheSyncStrategy.markChatListDirty();
        }
      },
    );
  }

  /// **Mark chat as read using MarkAsReadUseCase - CLEAN ARCHITECTURE**
  Future<void> _onMarkChatAsRead(MarkChatAsRead event, Emitter<MessageState> emit) async {
    logger.i('Marking chat as read: ${event.chatId}');

    // Create params for UseCase
    final params = MarkAsReadParams(conversationId: event.chatId);

    // Execute UseCase
    final result = await _markAsRead(params);

    result.fold(
      (failure) {
        logger.e('Failed to mark chat as read: ${failure.message}');
        // Don't emit error for this operation, it's not critical
      },
      (success) {
        if (success) {
          logger.i('Chat marked as read successfully');
          
          // Mark chat list as dirty (unread count changed)
          _cacheSyncStrategy.markChatListDirty();
        }
      },
    );
  }
  
  /// Handle real-time message received
  void _onReceiveRealTimeMessage(ReceiveRealTimeMessage event, Emitter<MessageState> emit) {
    if (state is! MessagesLoaded) return;
    
    final currentState = state as MessagesLoaded;
    
    // Only process messages for current chat
    if (event.message.chatId != currentState.chatId) return;
    
    logger.i('Received real-time message via socket: ${event.message.id}');
    
    // Check if message already exists in list
    final messageExists = currentState.messages.any((msg) => msg.id == event.message.id);
    
    if (!messageExists) {
      // Add new message to beginning of list
      emit(currentState.copyWith(
        messages: [event.message, ...currentState.messages],
      ));
      
      // Mark message list as dirty
      _cacheSyncStrategy.markChatMessagesDirty(currentState.chatId);
      _cacheSyncStrategy.markChatListDirty();
    }
  }
  
  /// Handle refresh messages
  Future<void> _onRefreshMessages(RefreshMessages event, Emitter<MessageState> emit) async {
    if (state is! MessagesLoaded) return;
    
    add(LoadMessages(
      chatId: (state as MessagesLoaded).chatId,
      forceRefresh: true,
    ));
  }
  
  /// Handle clear messages
  void _onClearMessages(ClearMessages event, Emitter<MessageState> emit) {
    emit(const MessageInitial());
  }
  
  /// **Cancel real-time message subscription - ENTERPRISE CLEANUP**
  ///
  /// **Performance**: <100ms cleanup
  /// **Strategy**: Clean subscription cancellation with room exit
  Future<void> _cancelMessageSubscription(String chatId) async {
    logger.d('Cancelling real-time subscription for chat: $chatId');

    final subscription = _messageSubscriptions[chatId];
    if (subscription != null) {
      await subscription.cancel();
      _messageSubscriptions[chatId] = null;
      logger.d('Subscription cancelled for chat: $chatId');
    }

    // Leave chat room to stop receiving updates
    _realtimeService.leaveChatRoom(chatId).then((result) {
      result.fold(
        (failure) {
          logger.w('Failed to leave chat room $chatId: ${failure.message}');
        },
        (success) {
          logger.d('Successfully left chat room: $chatId');
        },
      );
    });
  }
  
  /// **Subscribe to real-time messages - ENTERPRISE REAL-TIME**
  ///
  /// **Performance**: <100ms message delivery
  /// **Strategy**: WebSocket subscription with automatic room management
  void _subscribeToMessages(String chatId) {
    logger.i('Subscribing to real-time messages for chat: $chatId');

    // Cancel existing subscription if any
    _cancelMessageSubscription(chatId);

    // Join chat room for real-time updates
    _realtimeService.joinChatRoom(chatId).then((result) {
      result.fold(
        (failure) {
          logger.e('Failed to join chat room $chatId: ${failure.message}');
        },
        (success) {
          logger.i('Successfully joined chat room: $chatId');
        },
      );
    });

    // Subscribe to real-time message stream
    _messageSubscriptions[chatId] = _realtimeService.messageStream
        .where((message) => message.chatId == chatId)
        .listen(
          (message) {
            logger.d('Received real-time message: ${message.id} in chat $chatId');
            add(ReceiveRealTimeMessage(message));
          },
          onError: (error) {
            logger.e('Error in real-time message stream: $error');
          },
        );

    logger.i('Real-time subscription established for chat: $chatId');
  }

  @override
  Future<void> close() async {
    // Cancel all subscriptions when closing bloc
    for (final chatId in _messageSubscriptions.keys) {
      _cancelMessageSubscription(chatId);
    }
    _messageSubscriptions.clear();
    return super.close();
  }
} 