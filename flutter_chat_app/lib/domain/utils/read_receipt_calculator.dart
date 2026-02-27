import 'package:flutter_chat_app/domain/entities/reader_info.dart';
import 'package:flutter_chat_app/shared/domain/entities/chat.dart';
import 'package:flutter_chat_app/shared/domain/entities/chat_message.dart';

/// Tính toán vị trí hiển thị read receipt avatars
///
/// Pure function, không phụ thuộc Flutter — thuộc Domain layer.
/// Thuật toán O(n): duyệt messages từ mới nhất → cũ nhất,
/// gán mỗi reader vào message cuối cùng do currentUser gửi mà reader đã đọc.
class ReadReceiptCalculator {
  const ReadReceiptCalculator._();

  /// Tính Last Read Position cho mỗi reader
  ///
  /// Input:
  ///   - [messages]: danh sách tin nhắn đã sắp xếp theo createdAt DESC (mới nhất trước)
  ///   - [currentUserId]: ID người dùng hiện tại (loại trừ khỏi kết quả)
  ///   - [members]: danh sách thành viên (để map userId → avatar/name)
  ///
  /// Output: `Map<String, List<ReaderInfo>>` — messageId → readers tại vị trí đó.
  /// Chỉ chứa tin nhắn do currentUser gửi.
  ///
  /// Thuật toán O(n):
  ///   1. Build memberMap O(m) cho lookup nhanh
  ///   2. Collect tất cả unique reader IDs từ readBy (loại trừ currentUser)
  ///   3. Duyệt messages từ mới nhất → cũ nhất
  ///   4. Với mỗi message do currentUser gửi, kiểm tra readBy
  ///   5. Với mỗi readerId chưa được gán, gán vào message hiện tại
  ///   6. Dừng sớm khi tất cả reader đã được gán
  static Map<String, List<ReaderInfo>> computeLastReadPositions({
    required List<ChatMessage> messages,
    required String currentUserId,
    required List<ConversationMember> members,
  }) {
    if (messages.isEmpty) {
      return const {};
    }

    // Build member lookup map: userId → ConversationMember
    final memberMap = <String, ConversationMember>{};
    for (final member in members) {
      memberMap[member.userId] = member;
    }

    // Collect all unique reader IDs across all messages (excluding currentUser)
    final allReaderIds = <String>{};
    for (final message in messages) {
      for (final readerId in message.readBy) {
        if (readerId != currentUserId) {
          allReaderIds.add(readerId);
        }
      }
    }

    if (allReaderIds.isEmpty) {
      return const {};
    }

    // Track which readers have been assigned to a message
    final assignedReaders = <String>{};
    final result = <String, List<ReaderInfo>>{};
    final totalReaders = allReaderIds.length;

    // Iterate messages newest → oldest (already sorted DESC)
    for (final message in messages) {
      // Only consider messages sent by currentUser
      if (message.sender.id != currentUserId) {
        continue;
      }

      final readersForMessage = <ReaderInfo>[];

      for (final readerId in message.readBy) {
        // Skip currentUser and already-assigned readers
        if (readerId == currentUserId || assignedReaders.contains(readerId)) {
          continue;
        }

        // Assign this reader to the current message
        assignedReaders.add(readerId);
        final member = memberMap[readerId];
        readersForMessage.add(ReaderInfo(
          userId: readerId,
          fullName: member?.fullName,
          avatarUrl: member?.avatarUrl,
        ));
      }

      if (readersForMessage.isNotEmpty) {
        result[message.id] = readersForMessage;
      }

      // Early termination when all readers have been assigned
      if (assignedReaders.length >= totalReaders) {
        break;
      }
    }

    return result;
  }
}
