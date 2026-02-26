import 'package:flutter_chat_app/core/utils/logger.dart';
import 'package:flutter_chat_app/data/models/sync_metadata_model.dart';
import 'package:flutter_chat_app/shared/domain/entities/chat_message.dart';
import 'package:injectable/injectable.dart';
import 'package:isar/isar.dart';

/// Quản lý metadata đồng bộ cho mỗi conversation.
/// Sử dụng Isar để scale tốt với hàng nghìn conversations.
@lazySingleton
class SyncMetadataManager {
  final Isar _isar;
  final AppLogger _logger;

  /// TTL cho sync metadata: 60 ngày
  static const int _ttlDays = 60;

  SyncMetadataManager({
    required Isar isar,
    required AppLogger logger,
  })  : _isar = isar,
        _logger = logger;

  /// Lấy lastKnownTimestamp cho conversation (millisecondsSinceEpoch)
  int? getLastKnownTimestamp(String conversationId) {
    try {
      final record = _isar.syncMetadataModels
          .where()
          .conversationIdEqualTo(conversationId)
          .findFirst();
      return record?.lastKnownTimestamp;
    } catch (e) {
      _logger.w('Failed to read sync metadata for $conversationId', error: e);
      return null;
    }
  }

  /// Cập nhật lastKnownTimestamp
  Future<void> setLastKnownTimestamp(String conversationId, int timestamp) async {
    try {
      final now = DateTime.now().millisecondsSinceEpoch;
      _isar.write((isar) {
        final existing = isar.syncMetadataModels
            .where()
            .conversationIdEqualTo(conversationId)
            .findFirst();

        final record = SyncMetadataModel(
          id: existing?.id ?? 0,
          conversationId: conversationId,
          lastKnownTimestamp: timestamp,
          lastSyncTime: existing?.lastSyncTime ?? now,
          updatedAt: now,
        );

        isar.syncMetadataModels.put(record);
      });
    } catch (e) {
      _logger.w('Failed to save sync metadata for $conversationId', error: e);
    }
  }

  /// Lấy thời gian sync cuối cùng
  int? getLastSyncTime(String conversationId) {
    try {
      final record = _isar.syncMetadataModels
          .where()
          .conversationIdEqualTo(conversationId)
          .findFirst();
      return record?.lastSyncTime;
    } catch (e) {
      _logger.w('Failed to read last sync time for $conversationId', error: e);
      return null;
    }
  }

  /// Cập nhật thời gian sync
  Future<void> setLastSyncTime(String conversationId) async {
    try {
      final now = DateTime.now().millisecondsSinceEpoch;
      _isar.write((isar) {
        final existing = isar.syncMetadataModels
            .where()
            .conversationIdEqualTo(conversationId)
            .findFirst();

        if (existing != null) {
          final updated = existing.copyWith(
            lastSyncTime: now,
            updatedAt: now,
          );
          isar.syncMetadataModels.put(updated);
        }
      });
    } catch (e) {
      _logger.w('Failed to update last sync time for $conversationId', error: e);
    }
  }

  /// Xóa metadata cho conversation
  Future<void> clearMetadata(String conversationId) async {
    try {
      _isar.write((isar) {
        final records = isar.syncMetadataModels
            .where()
            .conversationIdEqualTo(conversationId)
            .findAll();
        final ids = records.map((r) => r.id).toList();
        isar.syncMetadataModels.deleteAll(ids);
      });
    } catch (e) {
      _logger.w('Failed to clear sync metadata for $conversationId', error: e);
    }
  }

  /// Cập nhật timestamp từ danh sách tin nhắn (monotonic — never decrease)
  Future<void> updateFromMessages(
    String conversationId,
    List<ChatMessage> messages,
  ) async {
    if (messages.isEmpty) return;

    final maxTimestamp = messages
        .map((m) => m.createdAt.millisecondsSinceEpoch)
        .reduce((a, b) => a > b ? a : b);

    final current = getLastKnownTimestamp(conversationId) ?? 0;
    if (maxTimestamp > current) {
      await setLastKnownTimestamp(conversationId, maxTimestamp);
    }
  }

  /// Batch cleanup: xóa metadata cho conversations không truy cập > TTL
  Future<int> cleanupStaleMetadata() async {
    try {
      final cutoff = DateTime.now()
          .subtract(const Duration(days: _ttlDays))
          .millisecondsSinceEpoch;

      var count = 0;
      _isar.write((isar) {
        final staleRecords = isar.syncMetadataModels
            .where()
            .updatedAtLessThan(cutoff)
            .findAll();
        final ids = staleRecords.map((r) => r.id).toList();
        count = ids.length;
        isar.syncMetadataModels.deleteAll(ids);
      });
      if (count > 0) {
        _logger.i('Cleaned up $count stale sync metadata records');
      }
      return count;
    } catch (e) {
      _logger.w('Failed to cleanup stale sync metadata', error: e);
      return 0;
    }
  }

  /// Lấy tổng số conversations đang track
  int getTrackedConversationCount() {
    try {
      return _isar.syncMetadataModels.count();
    } catch (e) {
      _logger.w('Failed to count tracked conversations', error: e);
      return 0;
    }
  }
}
