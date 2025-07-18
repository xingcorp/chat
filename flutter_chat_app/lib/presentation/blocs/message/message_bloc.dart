import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_chat_app/core/cache/cache_sync_strategy.dart';
import 'package:flutter_chat_app/core/cache/media_cache_manager.dart';
import 'package:flutter_chat_app/core/error/failures.dart';
import 'package:flutter_chat_app/core/services/realtime_service.dart';
import 'package:flutter_chat_app/domain/entities/chat_message.dart';
import 'package:flutter_chat_app/domain/repositories/i_message_repository.dart';
import 'package:logger/logger.dart';

part 'message_event.dart';
part 'message_state.dart';

/// **ENTERPRISE MESSAGE BLOC**
///
/// Unified BLoC managing message state with Either<Failure, T> error handling
/// and enterprise-grade performance optimization.
///
/// **Performance Targets:**
/// - State updates: <50ms
/// - Error handling: Comprehensive with user-friendly messages
/// - Real-time updates: <100ms delivery
class MessageBloc extends Bloc<MessageEvent, MessageState> {
  final IMessageRepository _repository;
  final CacheSyncStrategy _cacheSyncStrategy;
  final MediaCacheManager _mediaCacheManager;
  final RealtimeService _realtimeService;
  final Logger _logger = Logger();

  // Map chat ID -> StreamSubscription
  final Map<String, StreamSubscription?> _messageSubscriptions = {};

  MessageBloc({
    required IMessageRepository repository,
    required CacheSyncStrategy cacheSyncStrategy,
    required MediaCacheManager mediaCacheManager,
    required RealtimeService realtimeService,
  }) : _repository = repository,
       _cacheSyncStrategy = cacheSyncStrategy,
       _mediaCacheManager = mediaCacheManager,
       _realtimeService = realtimeService,
       super(const MessageInitial()) {
    on<LoadMessages>(_onLoadMessages);
    on<LoadMoreMessages>(_onLoadMoreMessages);
    on<SendMessage>(_onSendMessage);
    on<DeleteMessage>(_onDeleteMessage);
    on<MarkChatAsRead>(_onMarkChatAsRead);
    on<ReceiveRealTimeMessage>(_onReceiveRealTimeMessage);
    on<RefreshMessages>(_onRefreshMessages);
    on<ClearMessages>(_onClearMessages);
  }
  
  /// **Xử lý sự kiện tải tin nhắn với Either<Failure, T> error handling**
  Future<void> _onLoadMessages(LoadMessages event, Emitter<MessageState> emit) async {
    _logger.i('Loading messages for chat: ${event.chatId}');

    if (state is MessagesLoaded && (state as MessagesLoaded).chatId == event.chatId) {
      // Already loaded messages for this chat, only emit again if force refresh
      if (!event.forceRefresh) {
        return;
      }
    }

    emit(MessagesLoading(chatId: event.chatId));

    // Get messages using Either pattern
    final result = await _repository.getMessages(
      event.chatId,
      limit: event.limit,
    );

    result.fold(
      (failure) {
        _logger.e('Failed to load messages: ${failure.message}');
        emit(MessagesError(
          chatId: event.chatId,
          error: _getErrorMessage(failure),
        ));
      },
      (messages) {
        _logger.i('Loaded ${messages.length} messages for chat ${event.chatId}');

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
  
  /// **Xử lý sự kiện tải thêm tin nhắn (pagination) với Either pattern**
  Future<void> _onLoadMoreMessages(LoadMoreMessages event, Emitter<MessageState> emit) async {
    if (state is! MessagesLoaded) return;

    final currentState = state as MessagesLoaded;

    // If already reached max, do nothing
    if (currentState.hasReachedMax) return;

    _logger.i('Loading more messages for chat: ${currentState.chatId}');

    // Calculate cursor based on last message
    final lastMessageId = currentState.messages.isNotEmpty
        ? currentState.messages.last.id
        : null;

    final result = await _repository.getMessages(
      currentState.chatId,
      limit: event.limit,
      cursor: lastMessageId,
    );

    result.fold(
      (failure) {
        _logger.e('Failed to load more messages: ${failure.message}');

        // Emit error state but preserve current messages
        emit(MessagesError(
          chatId: currentState.chatId,
          error: 'Không thể tải thêm tin nhắn: ${_getErrorMessage(failure)}',
          previousMessages: currentState.messages,
        ));
      },
      (nextMessages) {
        _logger.i('Loaded ${nextMessages.length} more messages');

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
  
  /// **Xử lý sự kiện gửi tin nhắn với Either pattern**
  Future<void> _onSendMessage(SendMessage event, Emitter<MessageState> emit) async {
    if (state is! MessagesLoaded) return;

    final currentState = state as MessagesLoaded;

    _logger.i('Sending message in chat: ${currentState.chatId}');

    final result = await _repository.sendMessage(
      chatId: currentState.chatId,
      content: event.content,
      senderId: event.senderId,
      contentType: event.contentType,
      attachmentIds: event.attachmentIds,
    );

    result.fold(
      (failure) {
        _logger.e('Failed to send message: ${failure.message}');

        // Emit error state with current messages preserved
        emit(MessagesError(
          chatId: currentState.chatId,
          error: 'Không thể gửi tin nhắn: ${_getErrorMessage(failure)}',
          previousMessages: currentState.messages,
        ));
      },
      (newMessage) {
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
  
  /// **Xử lý sự kiện xóa tin nhắn với Either pattern**
  Future<void> _onDeleteMessage(DeleteMessage event, Emitter<MessageState> emit) async {
    if (state is! MessagesLoaded) return;

    final currentState = state as MessagesLoaded;

    _logger.i('Deleting message: ${event.messageId}');

    final result = await _repository.deleteMessage(event.messageId);

    result.fold(
      (failure) {
        _logger.e('Failed to delete message: ${failure.message}');

        // Emit error state but preserve current messages
        emit(MessagesError(
          chatId: currentState.chatId,
          error: 'Không thể xóa tin nhắn: ${_getErrorMessage(failure)}',
          previousMessages: currentState.messages,
        ));
      },
      (success) {
        if (success) {
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

  /// **Xử lý sự kiện đánh dấu chat đã đọc với Either pattern**
  Future<void> _onMarkChatAsRead(MarkChatAsRead event, Emitter<MessageState> emit) async {
    _logger.i('Marking chat as read: ${event.chatId}');

    final result = await _repository.markChatAsRead(event.chatId);

    result.fold(
      (failure) {
        _logger.e('Failed to mark chat as read: ${failure.message}');
      },
      (_) {
        // Mark chat list as dirty (unread count changed)
        _cacheSyncStrategy.markChatListDirty();
      },
    );
  }
  
  /// Xử lý sự kiện nhận tin nhắn thời gian thực
  void _onReceiveRealTimeMessage(ReceiveRealTimeMessage event, Emitter<MessageState> emit) {
    if (state is! MessagesLoaded) return;
    
    final currentState = state as MessagesLoaded;
    
    // Chỉ xử lý tin nhắn thuộc chat hiện tại
    if (event.message.chatId != currentState.chatId) return;
    
    _logger.i('Nhận tin nhắn mới qua socket: ${event.message.id}');
    
    // Kiểm tra xem tin nhắn đã có trong danh sách chưa
    final messageExists = currentState.messages.any((msg) => msg.id == event.message.id);
    
    if (!messageExists) {
      // Thêm tin nhắn mới vào đầu danh sách
      emit(currentState.copyWith(
        messages: [event.message, ...currentState.messages],
      ));
      
      // Đánh dấu danh sách tin nhắn đã thay đổi
      _cacheSyncStrategy.markChatMessagesDirty(currentState.chatId);
      _cacheSyncStrategy.markChatListDirty();
    }
  }
  
  /// Xử lý sự kiện làm mới tin nhắn
  Future<void> _onRefreshMessages(RefreshMessages event, Emitter<MessageState> emit) async {
    if (state is! MessagesLoaded) return;
    
    add(LoadMessages(
      chatId: (state as MessagesLoaded).chatId,
      forceRefresh: true,
    ));
  }
  
  /// Xử lý sự kiện xóa tin nhắn
  void _onClearMessages(ClearMessages event, Emitter<MessageState> emit) {
    emit(const MessageInitial());
  }
  
  /// **Hủy đăng ký nhận tin nhắn thời gian thực - ENTERPRISE CLEANUP**
  ///
  /// **Performance**: <100ms cleanup
  /// **Strategy**: Clean subscription cancellation with room exit
  Future<void> _cancelMessageSubscription(String chatId) async {
    _logger.d('Cancelling real-time subscription for chat: $chatId');

    final subscription = _messageSubscriptions[chatId];
    if (subscription != null) {
      await subscription.cancel();
      _messageSubscriptions[chatId] = null;
      _logger.d('Subscription cancelled for chat: $chatId');
    }

    // Leave chat room to stop receiving updates
    _realtimeService.leaveChatRoom(chatId).then((result) {
      result.fold(
        (failure) {
          _logger.w('Failed to leave chat room $chatId: ${failure.message}');
        },
        (success) {
          _logger.d('Successfully left chat room: $chatId');
        },
      );
    });
  }
  
  /// **Đăng ký nhận tin nhắn thời gian thực - ENTERPRISE REAL-TIME**
  ///
  /// **Performance**: <100ms message delivery
  /// **Strategy**: WebSocket subscription with automatic room management
  void _subscribeToMessages(String chatId) {
    _logger.i('Subscribing to real-time messages for chat: $chatId');

    // Cancel existing subscription if any
    _cancelMessageSubscription(chatId);

    // Join chat room for real-time updates
    _realtimeService.joinChatRoom(chatId).then((result) {
      result.fold(
        (failure) {
          _logger.e('Failed to join chat room $chatId: ${failure.message}');
        },
        (success) {
          _logger.i('Successfully joined chat room: $chatId');
        },
      );
    });

    // Subscribe to real-time message stream
    _messageSubscriptions[chatId] = _realtimeService.messageStream
        .where((message) => message.chatId == chatId)
        .listen(
          (message) {
            _logger.d('Received real-time message: ${message.id} in chat $chatId');
            add(ReceiveRealTimeMessage(message));
          },
          onError: (error) {
            _logger.e('Error in real-time message stream: $error');
          },
        );

    _logger.i('Real-time subscription established for chat: $chatId');
  }
  
  /// **Helper method to convert Failure to user-friendly error message**
  String _getErrorMessage(Failure failure) {
    if (failure is ConnectionFailure) {
      return 'Không có kết nối internet. Vui lòng kiểm tra lại.';
    } else if (failure is ServerFailure) {
      return 'Lỗi server. Vui lòng thử lại sau.';
    } else if (failure is CacheFailure) {
      return 'Lỗi cache. Dữ liệu có thể không được cập nhật.';
    } else {
      return failure.message.isNotEmpty
          ? failure.message
          : 'Đã xảy ra lỗi không xác định.';
    }
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