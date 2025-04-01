import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:flutter_chat_app/domain/entities/chat.dart';
import 'package:flutter_chat_app/domain/entities/chat_message.dart';

/// Interface định nghĩa các phương thức cho repository xử lý chat
abstract class IChatRepository {
  /// Lấy client GraphQL để thực hiện các truy vấn
  GraphQLClient get client;
  
  /// Lấy danh sách chat của người dùng
  Future<List<Chat>> getChats();
  
  /// Lấy thông tin chi tiết của một chat
  Future<Chat?> getChatById(String chatId);
  
  /// Lấy danh sách chat từ local storage
  Future<List<Chat>> getChatsFromLocalStorage();
  
  /// Lưu chat vào local storage
  Future<void> saveChatLocally(Chat chat);
  
  /// Tạo chat mới
  Future<Chat> createChat({
    required String name,
    required List<String> participantIds,
    bool isGroup = false,
  });
  
  /// Cập nhật thông tin chat
  Future<Chat> updateChat({
    required String chatId,
    String? name,
    String? avatarUrl,
  });
  
  /// Thêm người dùng vào chat
  Future<bool> addParticipants({
    required String chatId,
    required List<String> userIds,
  });
  
  /// Xóa người dùng khỏi chat
  Future<bool> removeParticipants({
    required String chatId,
    required List<String> userIds,
  });
  
  /// Rời khỏi chat
  Future<bool> leaveChat(String chatId);
  
  /// Xóa chat
  Future<bool> deleteChat(String chatId);
  
  /// Đánh dấu chat là đã đọc
  Future<bool> markChatAsRead(String chatId);
  
  /// Đồng bộ chat giữa local và server
  Future<void> syncChat(String chatId);
} 