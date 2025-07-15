import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_chat_app/core/cache/cache_sync_strategy.dart';
import 'package:flutter_chat_app/core/cache/media_cache_manager.dart';
import 'package:flutter_chat_app/data/repositories/message_repository_with_cache.dart';
import 'package:flutter_chat_app/domain/entities/chat_message.dart';
import 'package:logger/logger.dart';

part 'message_event.dart';
part 'message_state.dart';

/// Bloc quản lý trạng thái tin nhắn với tích hợp cache thông minh
class MessageBloc extends Bloc<MessageEvent, MessageState> {
  final MessageRepositoryWithCache _repository;
  final CacheSyncStrategy _cacheSyncStrategy;
  final MediaCacheManager _mediaCacheManager;
  final Logger _logger = Logger();
  
  // Map chat ID -> StreamSubscription
  final Map<String, StreamSubscription?> _messageSubscriptions = {};
  
  MessageBloc({
    required MessageRepositoryWithCache repository,
    required CacheSyncStrategy cacheSyncStrategy,
    required MediaCacheManager mediaCacheManager,
  }) : _repository = repository,
       _cacheSyncStrategy = cacheSyncStrategy,
       _mediaCacheManager = mediaCacheManager,
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
  
  /// Xử lý sự kiện tải tin nhắn
  Future<void> _onLoadMessages(LoadMessages event, Emitter<MessageState> emit) async {
    _logger.i('Tải tin nhắn cho chat: ${event.chatId}');
    
    if (state is MessagesLoaded && (state as MessagesLoaded).chatId == event.chatId) {
      // Đã tải tin nhắn cho chat này rồi, chỉ emit lại nếu cần refresh
      if (!event.forceRefresh) {
        return;
      }
    }
    
    emit(MessagesLoading(chatId: event.chatId));
    
    try {
      // Kiểm tra xem có cần refresh cache không
      final bool shouldRefresh = event.forceRefresh || 
          _cacheSyncStrategy.shouldRefreshChatMessages(event.chatId);
      
      final messages = await _repository.getMessages(
        event.chatId,
        limit: event.limit,
        forceRefresh: shouldRefresh,
      );
      
      _logger.i('Đã tải ${messages.length} tin nhắn cho chat ${event.chatId}');
      
      // Reset dirty flag sau khi load thành công
      if (shouldRefresh) {
        _cacheSyncStrategy.resetChatMessagesDirtyFlag(event.chatId);
      }
      
      // Cancel subscription cũ nếu có
      await _cancelMessageSubscription(event.chatId);
      
      // Đăng ký nhận tin nhắn real-time mới
      if (event.subscribeToUpdates) {
        _subscribeToMessages(event.chatId);
      }
      
      emit(MessagesLoaded(
        chatId: event.chatId,
        messages: messages,
        hasReachedMax: messages.length < event.limit,
      ));
    } catch (e) {
      _logger.e('Lỗi khi tải tin nhắn: $e');
      emit(MessagesError(chatId: event.chatId, error: e.toString()));
    }
  }
  
  /// Xử lý sự kiện tải thêm tin nhắn (pagination)
  Future<void> _onLoadMoreMessages(LoadMoreMessages event, Emitter<MessageState> emit) async {
    if (state is! MessagesLoaded) return;
    
    final currentState = state as MessagesLoaded;
    
    // Nếu đã tải hết tin nhắn, không làm gì cả
    if (currentState.hasReachedMax) return;
    
    try {
      _logger.i('Tải thêm tin nhắn cho chat: ${currentState.chatId}');
      
      // Tính toán cursor dựa trên tin nhắn cuối cùng
      final lastMessageId = currentState.messages.isNotEmpty 
          ? currentState.messages.last.id 
          : null;
      
      final nextMessages = await _repository.getMessages(
        currentState.chatId,
        limit: event.limit,
        cursor: lastMessageId,
      );
      
      _logger.i('Đã tải thêm ${nextMessages.length} tin nhắn');
      
      if (nextMessages.isEmpty) {
        // Không có tin nhắn nào nữa
        emit(currentState.copyWith(hasReachedMax: true));
      } else {
        // Thêm tin nhắn mới vào danh sách hiện tại
        emit(currentState.copyWith(
          messages: [...currentState.messages, ...nextMessages],
          hasReachedMax: nextMessages.length < event.limit,
        ));
      }
    } catch (e) {
      _logger.e('Lỗi khi tải thêm tin nhắn: $e');
      // Không thay đổi state hiện tại, chỉ log lỗi
    }
  }
  
  /// Xử lý sự kiện gửi tin nhắn
  Future<void> _onSendMessage(SendMessage event, Emitter<MessageState> emit) async {
    if (state is! MessagesLoaded) return;
    
    final currentState = state as MessagesLoaded;
    
    try {
      _logger.i('Gửi tin nhắn trong chat: ${currentState.chatId}');
      
      // Tạo tin nhắn mới (optimistic update)
      final newMessage = await _repository.sendMessage(
        chatId: currentState.chatId,
        content: event.content,
        senderId: event.senderId,
        contentType: event.contentType,
        attachmentIds: event.attachmentIds,
      );
      
      // Thêm tin nhắn mới vào đầu danh sách
      emit(currentState.copyWith(
        messages: [newMessage, ...currentState.messages],
      ));
      
      // Đánh dấu danh sách tin nhắn đã thay đổi
      _cacheSyncStrategy.markChatMessagesDirty(currentState.chatId);
      _cacheSyncStrategy.markChatListDirty();
    } catch (e) {
      _logger.e('Lỗi khi gửi tin nhắn: $e');
      // Giữ nguyên state hiện tại, không hiển thị lỗi UI
      // TODO: Có thể thêm thông báo lỗi nếu cần
    }
  }
  
  /// Xử lý sự kiện xóa tin nhắn
  Future<void> _onDeleteMessage(DeleteMessage event, Emitter<MessageState> emit) async {
    if (state is! MessagesLoaded) return;
    
    final currentState = state as MessagesLoaded;
    
    try {
      _logger.i('Xóa tin nhắn: ${event.messageId}');
      
      final success = await _repository.deleteMessage(event.messageId);
      
      if (success) {
        // Xóa tin nhắn khỏi danh sách
        final updatedMessages = currentState.messages
            .where((msg) => msg.id != event.messageId)
            .toList();
        
        emit(currentState.copyWith(messages: updatedMessages));
        
        // Đánh dấu danh sách tin nhắn đã thay đổi
        _cacheSyncStrategy.markChatMessagesDirty(currentState.chatId);
        _cacheSyncStrategy.markChatListDirty();
      }
    } catch (e) {
      _logger.e('Lỗi khi xóa tin nhắn: $e');
      // Giữ nguyên state hiện tại, không hiển thị lỗi UI
    }
  }
  
  /// Xử lý sự kiện đánh dấu chat đã đọc
  Future<void> _onMarkChatAsRead(MarkChatAsRead event, Emitter<MessageState> emit) async {
    try {
      _logger.i('Đánh dấu chat đã đọc: ${event.chatId}');
      
      await _repository.markChatAsRead(event.chatId);
      
      // Đánh dấu danh sách chat đã thay đổi (vì unread count thay đổi)
      _cacheSyncStrategy.markChatListDirty();
    } catch (e) {
      _logger.e('Lỗi khi đánh dấu chat đã đọc: $e');
    }
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
  
  /// Hủy đăng ký nhận tin nhắn thời gian thực
  Future<void> _cancelMessageSubscription(String chatId) async {
    final subscription = _messageSubscriptions[chatId];
    if (subscription != null) {
      await subscription.cancel();
      _messageSubscriptions[chatId] = null;
    }
  }
  
  /// Đăng ký nhận tin nhắn thời gian thực
  void _subscribeToMessages(String chatId) {
    // TODO: Implement subscription logic when socket handler is available
    // _messageSubscriptions[chatId] = _socketService.onNewMessage(chatId).listen((message) {
    //   add(ReceiveRealTimeMessage(message));
    // });
  }
  
  @override
  Future<void> close() async {
    // Hủy tất cả subscription khi đóng bloc
    for (final chatId in _messageSubscriptions.keys) {
      await _cancelMessageSubscription(chatId);
    }
    _messageSubscriptions.clear();
    return super.close();
  }
} 