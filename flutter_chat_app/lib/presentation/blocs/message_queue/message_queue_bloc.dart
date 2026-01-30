import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';
import 'package:flutter_chat_app/core/services/message_queue_service.dart' as service;
import 'package:flutter_chat_app/domain/entities/attachment.dart';
import 'package:flutter_chat_app/domain/entities/chat_message.dart';
import 'package:flutter_chat_app/domain/entities/message_queue_status.dart';
import 'package:flutter_chat_app/domain/models/queued_message.dart' as domain;

part 'message_queue_event.dart';
part 'message_queue_state.dart';
part 'message_queue_bloc.freezed.dart';

/// BLoC for managing message queue
@injectable
class MessageQueueBloc extends Bloc<MessageQueueEvent, MessageQueueState> {
  /// Service to manage message queue
  final service.MessageQueueService _queueService;
  
  /// Subscription to message status updates
  StreamSubscription? _statusSubscription;
  
  /// Creates a new message queue bloc
  MessageQueueBloc(this._queueService) : super(const MessageQueueState.initial()) {
    on<_EnqueueMessage>(_onEnqueueMessage);
    on<_CancelMessage>(_onCancelMessage);
    on<_MessageStatusUpdated>(_onMessageStatusUpdated);
    on<_LoadPendingMessages>(_onLoadPendingMessages);
    on<_ClearCompletedMessages>(_onClearCompletedMessages);
    
    // Subscribe to status updates from the queue service
    _statusSubscription = _queueService.messageStatusStream.listen(
      (message) => add(MessageQueueEvent.messageStatusUpdated(message.localId)),
    );
  }
  
  /// Handles enqueuing a message
  Future<void> _onEnqueueMessage(
    _EnqueueMessage event, 
    Emitter<MessageQueueState> emit,
  ) async {
    emit(const MessageQueueState.loading());
    
    try {
      // TODO: Get senderId and recipientId from auth/chat context
      final senderId = 'current_user_id'; // Placeholder
      final recipientId = 'recipient_id'; // Placeholder
      
      final message = await _queueService.enqueueMessage(
        chatId: event.chatId,
        senderId: senderId,
        recipientId: recipientId,
        content: event.content,
        contentType: event.contentType,
      );
      
      emit(MessageQueueState.messageEnqueued(message.localId));
    } catch (e) {
      emit(MessageQueueState.error(e.toString()));
    }
  }
  
  /// Handles cancelling a message
  Future<void> _onCancelMessage(
    _CancelMessage event, 
    Emitter<MessageQueueState> emit,
  ) async {
    emit(const MessageQueueState.loading());
    
    try {
      final success = await _queueService.cancelMessage(event.messageId);
      
      if (success) {
        emit(MessageQueueState.messageCancelled(event.messageId));
      } else {
        emit(const MessageQueueState.noChange());
      }
    } catch (e) {
      emit(MessageQueueState.error(e.toString()));
    }
  }
  
  /// Handles message status updates
  void _onMessageStatusUpdated(
    _MessageStatusUpdated event, 
    Emitter<MessageQueueState> emit,
  ) {
    emit(MessageQueueState.messageStatusUpdated(event.messageId));
  }
  
  /// Handles loading pending messages
  Future<void> _onLoadPendingMessages(
    _LoadPendingMessages event, 
    Emitter<MessageQueueState> emit,
  ) async {
    emit(const MessageQueueState.loading());
    
    try {
      // TODO: Implement getPendingMessages in MessageQueueService
      final messageIds = <String>[]; // Placeholder
      emit(MessageQueueState.pendingMessagesLoaded(messageIds));
    } catch (e) {
      emit(MessageQueueState.error(e.toString()));
    }
  }
  
  /// Handles clearing completed messages
  Future<void> _onClearCompletedMessages(
    _ClearCompletedMessages event, 
    Emitter<MessageQueueState> emit,
  ) async {
    emit(const MessageQueueState.loading());
    
    try {
      // TODO: Implement clearCompletedMessages in MessageQueueService
      // Placeholder - no action needed for now
      emit(const MessageQueueState.completedMessagesCleared());
    } catch (e) {
      emit(MessageQueueState.error(e.toString()));
    }
  }
  
  @override
  Future<void> close() {
    _statusSubscription?.cancel();
    return super.close();
  }
} 