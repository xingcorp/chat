import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';

import 'package:flutter_chat_app/core/cache/cache_sync_strategy.dart';
import 'package:flutter_chat_app/core/services/realtime_service.dart' hide MessageReaction;
import 'package:flutter_chat_app/shared/domain/entities/chat_message.dart';
import 'package:flutter_chat_app/features/chat/presentation/models/message_ui_state.dart';
import 'package:flutter_chat_app/features/chat/presentation/models/message_list_transformer.dart';
import 'package:flutter_chat_app/domain/usecases/message/delete_message_usecase.dart';
import 'package:flutter_chat_app/domain/usecases/message/edit_message_usecase.dart';
import 'package:flutter_chat_app/domain/usecases/message/get_messages_usecase.dart';
import 'package:flutter_chat_app/domain/usecases/message/mark_as_read_usecase.dart';
import 'package:flutter_chat_app/domain/usecases/message/send_message_usecase.dart';
import 'package:flutter_chat_app/domain/usecases/message/add_reaction_usecase.dart';
import 'package:flutter_chat_app/domain/usecases/message/remove_reaction_usecase.dart';
import 'package:flutter_chat_app/presentation/blocs/base/bloc_error_mixin.dart';
import 'package:flutter_chat_app/domain/repositories/i_attachment_repository.dart';
import 'package:flutter_chat_app/core/services/location_service.dart';
import 'dart:io';

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
  final AddReactionUseCase _addReaction;
  final RemoveReactionUseCase _removeReaction;

  // Repositories
  final IAttachmentRepository _attachmentRepository;

  // Services
  final CacheSyncStrategy _cacheSyncStrategy;
  final RealtimeService _realtimeService;
  final ILocationService _locationService;

  // Logger (injected via DI) - must be Logger for BlocErrorMixin
  @override
  final Logger logger;

  // Map chat ID -> StreamSubscription
  final Map<String, StreamSubscription?> _messageSubscriptions = {};

  // UI transform context
  String _currentUserId = '';
  bool _isGroupChat = false;
  String? _lastReadMessageId;
  String? _highlightedMessageId;

  /// Cập nhật context cho UI transform (gọi từ Page khi mở chat)
  void setTransformContext({
    required String currentUserId,
    bool isGroupChat = false,
    String? lastReadMessageId,
    String? highlightedMessageId,
  }) {
    _currentUserId = currentUserId;
    _isGroupChat = isGroupChat;
    _lastReadMessageId = lastReadMessageId;
    _highlightedMessageId = highlightedMessageId;
  }

  /// Transform messages thành UI state
  List<MessageUIState> _transformMessages(List<ChatMessage> messages) {
    return MessageListTransformer.transform(
      messages: messages,
      currentUserId: _currentUserId,
      lastReadMessageId: _lastReadMessageId,
      highlightedMessageId: _highlightedMessageId,
      isGroupChat: _isGroupChat,
    );
  }

  /// Constructor with UseCases injection
  MessageBloc({
    required GetMessagesUseCase getMessages,
    required SendMessageUseCase sendMessage,
    required EditMessageUseCase editMessage,
    required DeleteMessageUseCase deleteMessage,
    required MarkAsReadUseCase markAsRead,
    required AddReactionUseCase addReaction,
    required RemoveReactionUseCase removeReaction,
    required IAttachmentRepository attachmentRepository,
    required CacheSyncStrategy cacheSyncStrategy,
    required RealtimeService realtimeService,
    required ILocationService locationService,
    required this.logger,
  })  : _getMessages = getMessages,
        _sendMessage = sendMessage,
        _editMessage = editMessage,
        _deleteMessage = deleteMessage,
        _markAsRead = markAsRead,
        _addReaction = addReaction,
        _removeReaction = removeReaction,
        _attachmentRepository = attachmentRepository,
        _cacheSyncStrategy = cacheSyncStrategy,
        _realtimeService = realtimeService,
        _locationService = locationService,
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
    on<ToggleReaction>(_onToggleReaction);
    on<SendMessageWithAttachments>(_onSendMessageWithAttachments);
    on<SendLocationMessage>(_onSendLocationMessage);
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

        // Subscribe to real-time updates
        if (event.subscribeToUpdates) {
          unawaited(_subscribeToMessages(event.chatId));
        } else {
          // Ensure old subscription is cancelled if caller disables updates
          unawaited(_cancelMessageSubscription(event.chatId));
        }

        emit(MessagesLoaded(
          chatId: event.chatId,
          messages: messages,
          uiMessages: _transformMessages(messages),
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

    // Calculate cursor based on oldest message timestamp.
    // Backend supports timestamp-based pagination via filters.from.
    final lastMessageCursor = currentState.messages.isNotEmpty
        ? currentState.messages.last.createdAt.millisecondsSinceEpoch.toString()
        : null;

    // Execute UseCase
    final result = await _getMessages(
      conversationId: currentState.chatId,
      limit: event.limit,
      cursor: lastMessageCursor,
    );

    result.fold(
      (failure) {
        logger.e('Failed to load more messages', error: failure);
        // Don't emit error for pagination — just log and re-emit with a
        // pagination error flag so the page can reset its loading indicator.
        emit(currentState.copyWith(paginationError: failure.message));
      },
      (nextMessages) {
        logger.i('Loaded ${nextMessages.length} more messages');

        if (nextMessages.isEmpty) {
          // No more messages
          emit(currentState.copyWith(hasReachedMax: true));
        } else {
          // Add new messages to current list
          final byId = <String, ChatMessage>{
            for (final m in currentState.messages) m.id: m,
          };
          for (final m in nextMessages) {
            byId[m.id] = m;
          }

          final allMessages = byId.values.toList()
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
          emit(currentState.copyWith(
            messages: allMessages,
            uiMessages: _transformMessages(allMessages),
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
      replyMessageId: event.replyMessageId,
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
        final allMessages = [newMessage, ...currentState.messages];
        emit(currentState.copyWith(
          messages: allMessages,
          uiMessages: _transformMessages(allMessages),
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

        emit(currentState.copyWith(
          messages: updatedMessages,
          uiMessages: _transformMessages(updatedMessages),
        ));

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

        emit(currentState.copyWith(
          messages: updatedMessages,
          uiMessages: _transformMessages(updatedMessages),
        ));

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
      final allMessages = [event.message, ...currentState.messages];
      emit(currentState.copyWith(
        messages: allMessages,
        uiMessages: _transformMessages(allMessages),
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
    final result = await _realtimeService.leaveChatRoom(chatId);
    result.fold(
      (failure) {
        logger.w('Failed to leave chat room $chatId: ${failure.toString()}');
      },
      (_) {
        logger.d('Successfully left chat room: $chatId');
      },
    );
  }
  
  /// **Subscribe to real-time messages - ENTERPRISE REAL-TIME**
  ///
  /// **Performance**: <100ms message delivery
  /// **Strategy**: WebSocket subscription with automatic room management
  Future<void> _subscribeToMessages(String chatId) async {
    logger.i('Subscribing to real-time messages for chat: $chatId');

    // Cancel existing subscription if any
    await _cancelMessageSubscription(chatId);

    // Ensure real-time connection is established
    if (!_realtimeService.isConnected) {
      final connectResult = await _realtimeService.connect();
      final connectOk = connectResult.fold((_) => false, (_) => true);
      if (!connectOk) {
        logger.e('Failed to connect to real-time server before joining chat room $chatId');
        return;
      }
    }

    // Join chat room for real-time updates
    final joinResult = await _realtimeService.joinChatRoom(chatId);
    final joined = joinResult.fold(
      (failure) {
        logger.e('Failed to join chat room $chatId', error: failure);
        return false;
      },
      (_) {
        logger.i('Successfully joined chat room: $chatId');
        return true;
      },
    );

    if (!joined) {
      return;
    }

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

  /// Handle toggle reaction on message (optimistic update + API call)
  Future<void> _onToggleReaction(
    ToggleReaction event,
    Emitter<MessageState> emit,
  ) async {
    if (state is! MessagesLoaded) return;

    final currentState = state as MessagesLoaded;

    logger.i('Toggling reaction ${event.emojiCode} on message ${event.messageId}');

    // Determine if we're adding or removing
    final targetMessage = currentState.messages.firstWhere(
      (msg) => msg.id == event.messageId,
      orElse: () => currentState.messages.first, // Fallback
    );

    final existingReaction = targetMessage.reactions.where(
      (r) => r.code == event.emojiCode && r.userId == _currentUserId,
    );

    final isRemoving = existingReaction.isNotEmpty;

    // Optimistic update: toggle reaction locally
    final updatedMessages = currentState.messages.map((msg) {
      if (msg.id != event.messageId) return msg;

      List<MessageReaction> updatedReactions;
      if (isRemoving) {
        // Remove reaction
        updatedReactions = msg.reactions
            .where((r) => !(r.code == event.emojiCode && r.userId == _currentUserId))
            .toList();
      } else {
        // Add reaction
        updatedReactions = [
          ...msg.reactions,
          MessageReaction(
            code: event.emojiCode,
            userId: _currentUserId,
            createdAt: DateTime.now(),
          ),
        ];
      }

      return ChatMessage(
        id: msg.id,
        chatId: msg.chatId,
        sender: msg.sender,
        content: msg.content,
        contentType: msg.contentType,
        createdAt: msg.createdAt,
        updatedAt: msg.updatedAt,
        editedAt: msg.editedAt,
        deletedAt: msg.deletedAt,
        urls: msg.urls,
        fileName: msg.fileName,
        forwardedFromMessageId: msg.forwardedFromMessageId,
        replyMessageId: msg.replyMessageId,
        replyMessage: msg.replyMessage,
        actionType: msg.actionType,
        actor: msg.actor,
        targetUsers: msg.targetUsers,
        newValue: msg.newValue,
        oldValue: msg.oldValue,
        mentionTo: msg.mentionTo,
        readBy: msg.readBy,
        deliveredTo: msg.deliveredTo,
        attachments: msg.attachments,
        reactions: updatedReactions,
      );
    }).toList();

    // Emit optimistic update immediately
    emit(currentState.copyWith(
      messages: updatedMessages,
      uiMessages: _transformMessages(updatedMessages),
    ));

    // Call API to persist reaction on server
    try {
      final result = isRemoving
          ? await _removeReaction(
              messageId: event.messageId,
              code: event.emojiCode,
            )
          : await _addReaction(
              messageId: event.messageId,
              code: event.emojiCode,
            );

      result.fold(
        (failure) {
          logger.e('Failed to toggle reaction', error: failure.message);

          // Rollback optimistic update on failure
          emit(currentState.copyWith(
            messages: currentState.messages,
            uiMessages: _transformMessages(currentState.messages),
          ));

          // Note: Error handling can be improved by adding error field to MessagesLoaded state
        },
        (_) {
          logger.i('Reaction updated successfully');
          // Success - optimistic update already shown
          // Real-time socket will sync the full reaction list with reactors
        },
      );
    } catch (e, stackTrace) {
      logger.e('Unexpected error toggling reaction', error: e, stackTrace: stackTrace);

      // Rollback on unexpected error
      emit(currentState.copyWith(
        messages: currentState.messages,
        uiMessages: _transformMessages(currentState.messages),
      ));
    }
  }

  /// **Send message with file attachments - CLEAN ARCHITECTURE**
  ///
  /// Handles complete flow:
  /// 1. Upload files to GCP Cloud Storage
  /// 2. Send message with uploaded file paths
  /// 3. Update UI state
  Future<void> _onSendMessageWithAttachments(
    SendMessageWithAttachments event,
    Emitter<MessageState> emit,
  ) async {
    if (state is! MessagesLoaded) {
      logger.w('Cannot send message with attachments - messages not loaded');
      return;
    }

    final currentState = state as MessagesLoaded;
    logger.i('Sending message with ${event.localFilePaths.length} attachments');

    try {
      // Step 1: Upload all files in parallel
      final uploadResults = await Future.wait(
        event.localFilePaths.map((filePath) async {
          final result = await _attachmentRepository.uploadAttachment(
            messageId: 'temp-${DateTime.now().millisecondsSinceEpoch}',
            chatId: currentState.chatId,
            file: File(filePath),
            onProgress: (progress) {
              // Progress logging can be added if needed
            },
          );

          return result.fold(
            (failure) {
              logger.e('Failed to upload file', error: failure);
              throw Exception(failure.message);
            },
            (uploadResult) => uploadResult.id, // Return storage path
          );
        }),
      );

      logger.i('All files uploaded successfully: ${uploadResults.length}');

      // Step 2: Determine message type based on first file extension
      final firstFilePath = event.localFilePaths.first;
      final extension = firstFilePath.split('.').last.toLowerCase();
      final messageType = _getMessageTypeFromExtension(extension);

      // Step 3: Send message with uploaded paths
      final result = await _sendMessage(
        conversationId: currentState.chatId,
        content: event.content,
        senderId: event.senderId,
        type: messageType,
        urls: uploadResults,
        replyMessageId: event.replyMessageId,
      );

      result.fold(
        (failure) {
          logger.e('Failed to send message with attachments', error: failure);
        },
        (message) {
          logger.i('Message with attachments sent successfully: ${message.id}');

          // Add new message to top of list
          final updatedMessages = [message, ...currentState.messages];
          emit(currentState.copyWith(
            messages: updatedMessages,
            uiMessages: _transformMessages(updatedMessages),
          ));
        },
      );
    } catch (e, stackTrace) {
      logger.e('Error sending message with attachments', error: e, stackTrace: stackTrace);
    }
  }

  /// **Send location message - CLEAN ARCHITECTURE**
  ///
  /// Handles location sharing:
  /// 1. Get address from coordinates (optional)
  /// 2. Create location data JSON
  /// 3. Send message with type LOCATION
  Future<void> _onSendLocationMessage(
    SendLocationMessage event,
    Emitter<MessageState> emit,
  ) async {
    if (state is! MessagesLoaded) {
      logger.w('Cannot send location - messages not loaded');
      return;
    }

    final currentState = state as MessagesLoaded;
    logger.i('Sending location message');

    try {
      // Get address from coordinates (optional, for better UX)
      String? locationName = event.locationName;

      if (locationName == null) {
        final addressResult = await _locationService.getAddressFromCoordinates(
          latitude: event.latitude,
          longitude: event.longitude,
        );

        locationName = addressResult.fold(
          (failure) {
            logger.w('Failed to get address');
            return null;
          },
          (address) => address,
        );
      }

      // Create location data JSON
      final locationData = LocationData(
        latitude: event.latitude,
        longitude: event.longitude,
        name: locationName,
        timestamp: DateTime.now(),
      );

      // Send message with type LOCATION
      final result = await _sendMessage(
        conversationId: currentState.chatId,
        content: locationData.toJson(),
        senderId: event.senderId,
        type: 'LOCATION',
      );

      result.fold(
        (failure) {
          logger.e('Failed to send location message', error: failure);
        },
        (message) {
          logger.i('Location message sent successfully: ${message.id}');

          // Add new message to top of list
          final updatedMessages = [message, ...currentState.messages];
          emit(currentState.copyWith(
            messages: updatedMessages,
            uiMessages: _transformMessages(updatedMessages),
          ));
        },
      );
    } catch (e, stackTrace) {
      logger.e('Error sending location message', error: e, stackTrace: stackTrace);
    }
  }

  /// Helper: Determine message type from file extension
  String _getMessageTypeFromExtension(String extension) {
    switch (extension) {
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
      case 'webp':
      case 'bmp':
        return 'IMAGE';

      case 'mp4':
      case 'mov':
      case 'avi':
      case 'mkv':
      case 'webm':
        return 'VIDEO';

      case 'mp3':
      case 'wav':
      case 'ogg':
      case 'm4a':
      case 'aac':
        return 'AUDIO';

      case 'pdf':
      case 'doc':
      case 'docx':
      case 'xls':
      case 'xlsx':
      case 'ppt':
      case 'pptx':
      case 'txt':
        return 'DOC';

      default:
        return 'DOC';
    }
  }

  @override
  Future<void> close() async {
    // Cancel all subscriptions when closing bloc
    for (final chatId in _messageSubscriptions.keys) {
      await _cancelMessageSubscription(chatId);
    }
    _messageSubscriptions.clear();
    return super.close();
  }
}
