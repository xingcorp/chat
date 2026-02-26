import 'package:isar/isar.dart';

part 'sync_metadata_model.g.dart';

/// Isar collection lưu trữ sync metadata cho mỗi conversation.
/// Hỗ trợ query, batch cleanup, TTL eviction — scale tốt với hàng nghìn conversations.
@collection
class SyncMetadataModel {
  /// Auto-increment ID (0 = auto-assign in Isar v4)
  @Id()
  final int id;

  /// Conversation ID — unique index cho lookup nhanh
  @Index(unique: true)
  final String conversationId;

  /// Timestamp (millisecondsSinceEpoch) của tin nhắn mới nhất đã biết
  final int lastKnownTimestamp;

  /// Thời gian sync cuối cùng (millisecondsSinceEpoch)
  final int lastSyncTime;

  /// Thời gian record được cập nhật — dùng cho TTL cleanup
  @Index()
  final int updatedAt;

  const SyncMetadataModel({
    this.id = 0,
    required this.conversationId,
    required this.lastKnownTimestamp,
    required this.lastSyncTime,
    required this.updatedAt,
  });

  /// Create a copy with updated fields
  SyncMetadataModel copyWith({
    int? id,
    String? conversationId,
    int? lastKnownTimestamp,
    int? lastSyncTime,
    int? updatedAt,
  }) {
    return SyncMetadataModel(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      lastKnownTimestamp: lastKnownTimestamp ?? this.lastKnownTimestamp,
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
