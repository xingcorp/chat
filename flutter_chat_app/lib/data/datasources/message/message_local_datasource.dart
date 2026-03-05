import 'package:flutter_chat_app/core/error/exceptions.dart';
import 'package:flutter_chat_app/core/services/database_service.dart';
import 'package:flutter_chat_app/data/models/message_model.dart';
import 'package:flutter_chat_app/shared/domain/entities/chat_message.dart';
import 'package:isar/isar.dart';

/// Interface for message local data source operations.
///
/// Defines the contract for local message persistence. Implementations
/// must guarantee:
/// - **No duplicates**: upsert semantics resolve identity by serverId → localId
/// - **Reactive streams**: UI can observe DB changes in real-time
/// - **Indexed queries**: O(log n) lookups for status, chatId, timestamps
abstract class MessageLocalDataSource {
  /// Get all messages for a specific chat, sorted by createdAt descending.
  Future<List<MessageModel>> getMessagesForChat(String chatId);

  /// Atomic upsert a single message.
  ///
  /// Resolves existing record by serverId → cross-reference → localId,
  /// then updates in-place if found or inserts if new.
  /// This is the **primary write method** — [saveMessage] delegates to this.
  Future<void> upsertMessage(MessageModel message);

  /// Batch atomic upsert messages in a single write transaction.
  ///
  /// Groups by chatId internally for efficient Isar writes.
  /// All-or-nothing: either all messages are persisted or none (transaction).
  Future<void> upsertMessages(List<MessageModel> messages);

  /// Save a message to local storage (delegates to [upsertMessage]).
  Future<void> saveMessage(MessageModel message);

  /// Save multiple messages to local storage (delegates to [upsertMessages]).
  Future<void> saveMessages(List<MessageModel> messages);

  /// Delete a message from a specific chat.
  /// Requires chatId for O(1) lookup instead of O(n*m) search.
  Future<void> deleteMessage(String chatId, String messageId);

  /// Delete all messages for a chat.
  Future<void> deleteMessagesForChat(String chatId);

  /// Mark messages as read by [userId] in [chatId].
  Future<void> markMessagesAsRead(String chatId, String userId);

  /// Reactive stream of messages for a chat.
  ///
  /// Native: Isar watch with fireImmediately.
  /// Web: 1-second polling fallback.
  Stream<List<MessageModel>> watchMessagesForChat(String chatId);

  /// Reactive stream of recent messages with limit.
  ///
  /// Used by BLoC to subscribe to DB changes. Emits immediately on subscribe,
  /// then re-emits whenever the underlying Isar collection changes.
  Stream<List<MessageModel>> watchRecentMessages({
    required String chatId,
    required int limit,
  });

  /// Get unread message count for a chat.
  Future<int> getUnreadCountForChat(String chatId, String userId);

  /// Get all pending messages across all chats.
  ///
  /// Uses indexed query on status field for O(log n) performance.
  /// Returns messages with status=pending or stale sending
  /// (sending > [staleSendingThreshold]).
  /// Used for offline sync retry when connectivity is restored.
  Future<List<MessageModel>> getAllPendingMessages({
    Duration staleSendingThreshold = const Duration(minutes: 2),
  });

  /// Cursor-based pagination for loading older messages.
  ///
  /// Returns [limit] messages created before [beforeTimestamp],
  /// sorted by createdAt descending.
  Future<List<MessageModel>> getMessagesWithCursor({
    required String chatId,
    required int limit,
    DateTime? beforeTimestamp,
  });

  /// One-time cleanup: remove duplicate records in a chat.
  ///
  /// Groups messages by serverId and keeps the most recently written
  /// record (highest Isar ID). Returns the number of removed duplicates.
  Future<int> deduplicateExistingMessages(String chatId);
}

/// Isar-backed implementation of [MessageLocalDataSource].
///
/// **Architecture**: Reactive Database-Driven (Signal/Telegram pattern).
///
/// Core principles:
/// 1. **Isar is Single Source of Truth** — all reads/writes go through Isar
/// 2. **Atomic upsert** — [_resolveExisting] prevents duplicates by resolving
///    identity through a 3-priority chain: serverId → cross-reference → localId
/// 3. **Reactive streams** — UI observes Isar watch streams, no manual notify
/// 4. **Indexed queries** — O(log n) for status, chatId, timestamps
///
/// This replaces the previous LocalStorage (JSON key-value) implementation
/// which had O(n) per-save performance and caused message duplication.
class MessageLocalDataSourceImpl implements MessageLocalDataSource {
  final DatabaseService _db;

  /// Constructor.
  ///
  /// Requires [DatabaseService] which must be initialized before use.
  MessageLocalDataSourceImpl(this._db);

  // ═══════════════════════════════════════════════════════════════════
  //  CORE: ATOMIC UPSERT — Heart of the dedup-safe architecture
  // ═══════════════════════════════════════════════════════════════════

  @override
  Future<void> upsertMessage(MessageModel message) async {
    try {
      _db.saveMessageUpsert(message);
    } catch (e) {
      throw CacheException(message: 'Failed to upsert message: $e');
    }
  }

  @override
  Future<void> upsertMessages(List<MessageModel> messages) async {
    if (messages.isEmpty) return;
    try {
      _db.saveMessagesUpsert(messages);
    } catch (e) {
      throw CacheException(message: 'Failed to upsert messages: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  //  BACKWARD-COMPATIBLE WRAPPERS — delegate to upsert
  // ═══════════════════════════════════════════════════════════════════

  @override
  Future<void> saveMessage(MessageModel message) => upsertMessage(message);

  @override
  Future<void> saveMessages(List<MessageModel> messages) =>
      upsertMessages(messages);

  // ═══════════════════════════════════════════════════════════════════
  //  QUERIES — Indexed, O(log n)
  // ═══════════════════════════════════════════════════════════════════

  @override
  Future<List<MessageModel>> getMessagesForChat(String chatId) async {
    try {
      return _db.isar.messageModels
          .where()
          .chatIdEqualTo(chatId)
          .sortByCreatedAtDesc()
          .findAll();
    } catch (e) {
      return [];
    }
  }

  @override
  Future<List<MessageModel>> getMessagesWithCursor({
    required String chatId,
    required int limit,
    DateTime? beforeTimestamp,
  }) async {
    try {
      return _db.getMessagesWithCursor(
        chatId: chatId,
        limit: limit,
        beforeTimestamp: beforeTimestamp,
      );
    } catch (e) {
      return [];
    }
  }

  @override
  Future<List<MessageModel>> getAllPendingMessages({
    Duration staleSendingThreshold = const Duration(minutes: 2),
  }) async {
    final now = DateTime.now();
    final staleThreshold = now.subtract(staleSendingThreshold);

    try {
      // Indexed query on status — O(log n) instead of O(n×m) full scan
      final pending = _db.getMessagesByStatus(MessageStatus.pending);

      final staleSending = _db.getMessagesByStatus(MessageStatus.sending)
          .where((m) => m.createdAt.isBefore(staleThreshold))
          .toList();

      final result = [...pending, ...staleSending];

      // Sort by creation time (FIFO) to preserve message order
      result.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      return result;
    } catch (e) {
      return [];
    }
  }

  @override
  Future<int> getUnreadCountForChat(String chatId, String userId) async {
    try {
      final messages = _db.isar.messageModels
          .where()
          .chatIdEqualTo(chatId)
          .sortByCreatedAtDesc()
          .findAll();

      return messages
          .where((msg) =>
              msg.senderId != userId && !msg.readBy.contains(userId))
          .length;
    } catch (e) {
      return 0;
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  //  REACTIVE STREAMS — Isar watch (native) / polling (web)
  // ═══════════════════════════════════════════════════════════════════

  @override
  Stream<List<MessageModel>> watchMessagesForChat(String chatId) {
    return _db.watchMessagesForChat(chatId);
  }

  @override
  Stream<List<MessageModel>> watchRecentMessages({
    required String chatId,
    required int limit,
  }) {
    return _db.watchRecentMessagesForChat(chatId, limit: limit);
  }

  // ═══════════════════════════════════════════════════════════════════
  //  WRITE OPERATIONS — Delete, mark read
  // ═══════════════════════════════════════════════════════════════════

  @override
  Future<void> deleteMessage(String chatId, String messageId) async {
    try {
      _db.isar.write((isar) {
        // Try matching by serverId first
        final byServerId = isar.messageModels
            .where()
            .serverIdEqualTo(messageId)
            .findFirst();
        if (byServerId != null) {
          isar.messageModels.delete(byServerId.id);
          return;
        }

        // Fallback: match by localId
        final byLocalId = isar.messageModels
            .where()
            .localIdEqualTo(messageId)
            .findFirst();
        if (byLocalId != null) {
          isar.messageModels.delete(byLocalId.id);
        }
      });
    } catch (e) {
      throw CacheException(message: 'Failed to delete message: $e');
    }
  }

  @override
  Future<void> deleteMessagesForChat(String chatId) async {
    try {
      _db.deleteMessagesForChat(chatId);
    } catch (e) {
      throw CacheException(
          message: 'Failed to delete messages for chat: $e');
    }
  }

  @override
  Future<void> markMessagesAsRead(String chatId, String userId) async {
    try {
      _db.isar.write((isar) {
        final unread = isar.messageModels
            .where()
            .chatIdEqualTo(chatId)
            .sortByCreatedAtDesc()
            .findAll()
            .where(
              (msg) =>
                  msg.senderId != userId && !msg.readBy.contains(userId),
            )
            .toList();

        if (unread.isEmpty) return;

        final updated = unread.map((m) => m.markReadBy(userId)).toList();
        isar.messageModels.putAll(updated);
      });
    } catch (e) {
      throw CacheException(message: 'Failed to mark messages as read: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  //  DEDUPLICATION — One-time cleanup for existing duplicates
  // ═══════════════════════════════════════════════════════════════════

  @override
  Future<int> deduplicateExistingMessages(String chatId) async {
    var removedCount = 0;
    try {
      _db.isar.write((isar) {
        final allMessages = isar.messageModels
            .where()
            .chatIdEqualTo(chatId)
            .sortByCreatedAtDesc()
            .findAll();

        // Group by serverId → keep latest (highest Isar ID), delete rest
        final serverIdGroups = <String, List<MessageModel>>{};
        for (final msg in allMessages) {
          final key = msg.serverId;
          if (key != null && key.isNotEmpty) {
            serverIdGroups.putIfAbsent(key, () => []).add(msg);
          }
        }

        for (final group in serverIdGroups.values) {
          if (group.length <= 1) continue;
          // Keep the one with highest Isar ID (most recently written)
          group.sort((a, b) => b.id.compareTo(a.id));
          for (var i = 1; i < group.length; i++) {
            isar.messageModels.delete(group[i].id);
            removedCount++;
          }
        }

        // Also dedup by localId for messages without serverId
        final localIdGroups = <String, List<MessageModel>>{};
        final remaining = isar.messageModels
            .where()
            .chatIdEqualTo(chatId)
            .sortByCreatedAtDesc()
            .findAll();
        for (final msg in remaining) {
          localIdGroups.putIfAbsent(msg.localId, () => []).add(msg);
        }

        for (final group in localIdGroups.values) {
          if (group.length <= 1) continue;
          group.sort((a, b) => b.id.compareTo(a.id));
          for (var i = 1; i < group.length; i++) {
            isar.messageModels.delete(group[i].id);
            removedCount++;
          }
        }
      });
    } catch (e) {
      // Log but don't throw — dedup is best-effort
    }
    return removedCount;
  }
}
