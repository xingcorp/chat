import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';

import 'package:flutter_chat_app/core/cache/cache_sync_strategy.dart';
import 'package:flutter_chat_app/core/services/realtime_service.dart';
import 'package:flutter_chat_app/shared/domain/entities/chat_message.dart';
import 'package:flutter_chat_app/domain/usecases/message/delete_message_usecase.dart';
import 'package:flutter_chat_app/domain/usecases/message/edit_message_usecase.dart';
import 'package:flutter_chat_app/domain/usecases/message/get_messages_usecase.dart';
import 'package:flutter_chat_app/domain/usecases/message/mark_as_read_usecase.dart';
import 'package:flutter_chat_app/domain/usecases/message/send_message_usecase.dart';
import 'package:flutter_chat_app/presentation/blocs/base/bloc_error_mixin.dart';

part 'message_event.dart';
part 'message_state.dart';

/// **ENTERPRISE MESSAGE BLOC - CLEAN ARCHITECTURE**
///
/// Updated to use UseCases and proper dependency injection.
/// Follows Clean Architecture with proper separation of concerns.
///
/// **Performance Targets:**
/// - State updates: <50ms
/// - Error handling: Comprehensive with user-friendly messages
/// - Real-time updates: <100ms delivery
@injectable
class MessageBloc extends Bloc<MessageEvent, MessageState> with BlocErrorMixin {
  // UseCases (Domain Layer)
  final GetMessagesUseCase _getMessages;
  final SendMessageUseCase _sendMessage;
  final EditMessageUseCase _editMessage;
  final DeleteMessageUseCase _deleteMessage;
  final MarkAsReadUseCase _markAsRead;
  
  // Services
  final CacheSyncStrategy _cacheSyncStrategy;
  final RealtimeService _realtimeService;
  
  // Logger (injected via DI) - must be Logger for BlocErrorMixin
  @override
  final Logger logger;

  // Map chat ID -> StreamSubscription
  final Map<String, StreamSubscription?> _messageSubscriptions = {};

  /// Constructor with UseCases injection
  MessageBloc({
    required GetMessagesUseCase getMessages,
    required SendMessageUseCase sendMessage,
    required EditMessageUseCase editMessage,
    required DeleteMessageUseCase deleteMessage,
    required MarkAsReadUseCase markAsRead,
    required CacheSyncStrategy cacheSyncStrategy,
    required RealtimeService realtimeService,
    required this.logger,
  })  : _getMessages = getMessages,
        _sendMessage = sendMessage,
        _editMessage = editMessage,
        _deleteMessage = deleteMessage,
        _markAsRead = markAsRead,
        _cacheSyncStrategy = cacheSyncStrategy,
        _realtimeService = realtimeService,
        super(const MessageInitial()) {
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

    // Execute UseCase
    final result = await _getMessages(
      conversationId: event.chatId,
      limit: event.limit,
    );

    result.fold(
      (failure) {
        logger.e('Failed to load messages', error: failure);
        emit(MessagesError(
          chatId: event.chatId,
          error: failure.message,
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

    // Execute UseCase
    final result = await _getMessages(
      conversationId: currentState.chatId,
      limit: event.limit,
      cursor: lastMessageId,
    );

    result.fold(
      (failure) {
        logger.e('Failed to load more messages', error: failure);

        // Don't emit error for pagination - just log it
        // User can retry by scrolling again
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

    // Execute UseCase
    final result = await _sendMessage(
      conversationId: currentState.chatId,
      content: event.content,
      senderId: event.senderId,
      type: event.contentType,
      urls: event.attachmentIds,
    );

    result.fold(
      (failure) {
        logger.e('Failed to send message', error: failure);
        emit(MessagesError(
          chatId: currentState.chatId,
          error: failure.message,
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

    // Execute UseCase
    final result = await _editMessage(
      messageId: event.messageId,
      content: event.content,
    );

    result.fold(
      (failure) {
        logger.e('Failed to edit message', error: failure);
        emit(MessagesError(
          chatId: currentState.chatId,
          error: failure.message,
          previousMessages: currentState.messages,
        ));
      },
      (_) {
        logger.i('Message edited successfully');
        
        // Update message in list with new content
        final updatedMessages = currentState.messages.map((msg) {
          if (msg.id == event.messageId) {
            // Create updated message with new content
            return ChatMessage(
              id: msg.id,
              chatId: msg.chatId,
              sender: msg.sender,
              content: event.content, // Use new content
              contentType: msg.contentType,
              createdAt: msg.createdAt,
              updatedAt: DateTime.now(),
              editedAt: DateTime.now(),
              readBy: msg.readBy,
              deliveredTo: msg.deliveredTo,
              attachments: msg.attachments,
              reactions: msg.reactions,
            );
          }
          return msg;
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
        logger.e('Failed to delete message', error: failure);
        emit(MessagesError(
          chatId: currentState.chatId,
          error: failure.message,
          previousMessages: currentState.messages,
        ));
      },
      (_) {
        logger.i('Message deleted successfully');
        
        // Remove message from list
        final updatedMessages = currentState.messages
            .where((msg) => msg.id != event.messageId)
            .toList();

        emit(currentState.copyWith(messages: updatedMessages));

        // Mark message list as dirty
        _cacheSyncStrategy.markChatMessagesDirty(currentState.chatId);
        _cacheSyncStrategy.markChatListDirty();
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
        logger.w('Failed to mark chat as read: ${failure.toString()}');
        // Don't emit error for this operation, it's not critical
      },
      (_) {
        logger.i('Chat marked as read successfully');
        
        // Mark chat list as dirty (unread count changed)
        _cacheSyncStrategy.markChatListDirty();
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
          logger.w('Failed to leave chat room $chatId: ${failure.toString()}');
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
          logger.e('Failed to join chat room $chatId', error: failure);
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
