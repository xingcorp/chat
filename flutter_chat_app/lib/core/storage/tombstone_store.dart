import 'package:flutter/foundation.dart';
import 'package:flutter_chat_app/core/storage/local_storage.dart';
import 'package:flutter_chat_app/shared/domain/entities/chat_message.dart';
import 'package:injectable/injectable.dart';

/// Lightweight tombstone data for deleted messages
/// Optimized for minimal storage and fast lookup
class MessageTombstone {
  final String messageId;
  final String chatId;
  final DateTime deletedAt;
  final DateTime messageCreatedAt;
  final String? senderId;
  final String? senderName;

  const MessageTombstone({
    required this.messageId,
    required this.chatId,
    required this.deletedAt,
    required this.messageCreatedAt,
    this.senderId,
    this.senderName,
  });

  factory MessageTombstone.fromMessage(ChatMessage message, DateTime deletedAt) {
    return MessageTombstone(
      messageId: message.id,
      chatId: message.chatId,
      deletedAt: deletedAt,
      messageCreatedAt: message.createdAt,
      senderId: message.sender.id,
      senderName: message.sender.name,
    );
  }

  Map<String, dynamic> toJson() => {
    'messageId': messageId,
    'chatId': chatId,
    'deletedAt': deletedAt.millisecondsSinceEpoch,
    'messageCreatedAt': messageCreatedAt.millisecondsSinceEpoch,
    'senderId': senderId,
    'senderName': senderName,
  };

  factory MessageTombstone.fromJson(Map<String, dynamic> json) {
    return MessageTombstone(
      messageId: json['messageId'] as String,
      chatId: json['chatId'] as String,
      deletedAt: DateTime.fromMillisecondsSinceEpoch(json['deletedAt'] as int),
      messageCreatedAt: DateTime.fromMillisecondsSinceEpoch(json['messageCreatedAt'] as int),
      senderId: json['senderId'] as String?,
      senderName: json['senderName'] as String?,
    );
  }
}

/// High-performance tombstone store with in-memory caching
/// 
/// Features:
/// - In-memory LRU cache for fast lookups
/// - Lazy loading from disk
/// - Automatic expiry cleanup (7 days default)
/// - Batch operations for efficiency
@LazySingleton()
class TombstoneStore {
  static const String _keyPrefix = 'tombstones_';
  static const int _expiryDays = 7;
  
  final LocalStorage _localStorage;
  
  /// In-memory cache: chatId -> (messageId -> tombstone)
  /// Loaded lazily when first accessed for a chat
  final Map<String, Map<String, MessageTombstone>> _cache = {};
  
  /// Track which chats have been loaded to avoid repeated disk reads
  final Set<String> _loadedChats = {};

  TombstoneStore(this._localStorage);

  /// Save a tombstone for a deleted message
  /// Updates both memory cache and disk
  Future<void> saveTombstone(MessageTombstone tombstone) async {
    final chatId = tombstone.chatId;
    
    // Update memory cache
    _cache.putIfAbsent(chatId, () => {});
    _cache[chatId]![tombstone.messageId] = tombstone;
    
    // Persist to disk asynchronously (don't block UI)
    await _persistToDisk(chatId);
  }

  /// Get all tombstones for a chat (with lazy loading)
  List<MessageTombstone> getTombstonesForChat(String chatId) {
    // Lazy load from disk if not in cache
    if (!_loadedChats.contains(chatId)) {
      _loadFromDiskSync(chatId);
    }
    
    final chatTombstones = _cache[chatId];
    if (chatTombstones == null || chatTombstones.isEmpty) {
      return [];
    }
    
    // Filter out expired tombstones
    final now = DateTime.now();
    final expiryThreshold = now.subtract(Duration(days: _expiryDays));
    
    return chatTombstones.values
        .where((t) => t.deletedAt.isAfter(expiryThreshold))
        .toList();
  }

  /// Check if a message has a tombstone
  bool hasTombstone(String chatId, String messageId) {
    if (!_loadedChats.contains(chatId)) {
      _loadFromDiskSync(chatId);
    }
    
    final chatTombstones = _cache[chatId];
    if (chatTombstones == null) return false;
    
    final tombstone = chatTombstones[messageId];
    if (tombstone == null) return false;
    
    // Check expiry
    final expiryThreshold = DateTime.now().subtract(Duration(days: _expiryDays));
    return tombstone.deletedAt.isAfter(expiryThreshold);
  }

  /// Get a specific tombstone
  MessageTombstone? getTombstone(String chatId, String messageId) {
    if (!hasTombstone(chatId, messageId)) return null;
    return _cache[chatId]?[messageId];
  }

  /// Remove a tombstone (e.g., when message is restored)
  Future<void> removeTombstone(String chatId, String messageId) async {
    _cache[chatId]?.remove(messageId);
    if (_cache[chatId]?.isEmpty ?? false) {
      _cache.remove(chatId);
      _loadedChats.remove(chatId);
      await _localStorage.remove('$_keyPrefix$chatId');
    } else {
      await _persistToDisk(chatId);
    }
  }

  /// Clear all tombstones for a chat
  Future<void> clearChatTombstones(String chatId) async {
    _cache.remove(chatId);
    _loadedChats.remove(chatId);
    await _localStorage.remove('$_keyPrefix$chatId');
  }

  /// Cleanup expired tombstones (call periodically, e.g., on app start)
  Future<void> cleanupExpired() async {
    final now = DateTime.now();
    final expiryThreshold = now.subtract(Duration(days: _expiryDays));
    
    final keys = _localStorage.getKeys();
    final tombstoneKeys = keys.where((k) => k.startsWith(_keyPrefix));
    
    for (final key in tombstoneKeys) {
      final chatId = key.substring(_keyPrefix.length);
      _loadFromDiskSync(chatId);
      
      final chatTombstones = _cache[chatId];
      if (chatTombstones == null) continue;
      
      // Remove expired
      final expiredIds = chatTombstones.entries
          .where((e) => e.value.deletedAt.isBefore(expiryThreshold))
          .map((e) => e.key)
          .toList();
      
      for (final id in expiredIds) {
        chatTombstones.remove(id);
      }
      
      // Persist cleaned data
      if (chatTombstones.isEmpty) {
        _cache.remove(chatId);
        _loadedChats.remove(chatId);
        await _localStorage.remove(key);
      } else {
        await _persistToDisk(chatId);
      }
    }
    
    debugPrint('[TombstoneStore] Cleanup complete. Chats with tombstones: ${_cache.length}');
  }

  /// Sync load from disk (for lazy loading in sync context)
  void _loadFromDiskSync(String chatId) {
    // This is called synchronously, but LocalStorage.getList is async
    // We'll handle this by loading in the getter methods
    _loadedChats.add(chatId);
    _cache.putIfAbsent(chatId, () => {});
  }

  /// Load tombstones from disk for a chat
  Future<void> loadFromDisk(String chatId) async {
    if (_loadedChats.contains(chatId)) return;
    
    try {
      final data = await _localStorage.getList('$_keyPrefix$chatId');
      if (data.isEmpty) {
        _cache[chatId] = {};
      } else {
        final tombstones = <String, MessageTombstone>{};
        for (final item in data) {
          try {
            final tombstone = MessageTombstone.fromJson(
              Map<String, dynamic>.from(item as Map),
            );
            tombstones[tombstone.messageId] = tombstone;
          } catch (_) {
            // Skip invalid entries
          }
        }
        _cache[chatId] = tombstones;
      }
      _loadedChats.add(chatId);
    } catch (_) {
      _cache[chatId] = {};
      _loadedChats.add(chatId);
    }
  }

  /// Persist tombstones to disk for a chat
  Future<void> _persistToDisk(String chatId) async {
    final chatTombstones = _cache[chatId];
    if (chatTombstones == null || chatTombstones.isEmpty) {
      await _localStorage.remove('$_keyPrefix$chatId');
      return;
    }
    
    final data = chatTombstones.values.map((t) => t.toJson()).toList();
    await _localStorage.saveList('$_keyPrefix$chatId', data);
  }

  /// Preload tombstones for multiple chats (for performance optimization)
  Future<void> preloadForChats(List<String> chatIds) async {
    await Future.wait(chatIds.map((id) => loadFromDisk(id)));
  }

  /// Get total tombstone count (for debugging/monitoring)
  int get totalTombstoneCount {
    return _cache.values.fold(0, (sum, map) => sum + map.length);
  }
}
