import 'package:flutter_chat_app/domain/entities/chat_message.dart';

/// Interface cho repository xử lý tin nhắn
abstract class IMessageRepository {
  /// Lấy tin nhắn theo ID
  Future<ChatMessage?> getMessageById(String messageId);
  
  /// Lấy danh sách tin nhắn gần đây của một chat
  Future<List<ChatMessage>> getRecentMessages(String chatId, int limit);
  
  /// Lấy danh sách tin nhắn của một chat với phân trang
  Future<List<ChatMessage>> getMessages(String chatId, {int limit = 20, String? cursor});
  
  /// Đánh dấu tin nhắn đã đọc
  Future<void> markAsRead(String messageId);
  
  /// Đánh dấu tất cả tin nhắn trong chat đã đọc
  Future<void> markChatAsRead(String chatId);
  
  /// Xóa tin nhắn
  Future<bool> deleteMessage(String messageId);
  
  /// Cập nhật nội dung tin nhắn
  Future<bool> updateMessage(String messageId, String newContent);
  
  /// Gửi tin nhắn mới
  Future<ChatMessage> sendMessage({
    required String chatId,
    required String content,
    required String senderId,
    required String contentType,
    List<String> attachmentIds = const [],
  });
  
  /// Kiểm tra xem tin nhắn có xung đột với dữ liệu từ server không
  Future<bool> checkMessageConflict(String localId, String serverId);
  
  /// Đồng bộ tin nhắn giữa local và server 
  Future<void> syncMessages(String chatId, {int limit = 50});
} 