import 'package:flutter_chat_app/shared/domain/entities/chat.dart';
import 'package:flutter_chat_app/shared/domain/entities/chat_message.dart';

/// Cached user information for quick name/avatar resolution.
class CachedUser {
  final String id;
  final String name;
  final String? avatar;

  const CachedUser({
    required this.id,
    required this.name,
    this.avatar,
  });

  @override
  String toString() => 'CachedUser($id, $name)';
}

/// **Global in-memory user cache for name resolution.**
///
/// Follows the WhatsApp/Telegram pattern: once we learn a user's name
/// from any source (member list, message sender, GraphQL response),
/// we cache it forever (until logout). This ensures subsequent renders
/// never show UUIDs even if the original data source is incomplete.
///
/// **Population sources:**
/// - [populateFromMembers] — When conversation members are loaded
/// - [populateFromMessages] — When messages arrive (from API or socket)
/// - [populateFromSender] — When a single sender is encountered
///
/// **Consumption:**
/// - [getUserName] / [getUser] — Used by transformers and model layers
///
/// **Lifecycle:**
/// - Created as a lazy singleton via DI
/// - Cleared on logout via [clear]
class UserCacheService {
  final Map<String, CachedUser> _cache = {};

  /// Populate cache from conversation members list.
  ///
  /// Called when a chat is loaded and members are available.
  /// Only caches users with valid (non-empty, non-UUID) names.
  void populateFromMembers(List<ConversationMember> members) {
    for (final m in members) {
      if (m.userId.isEmpty) continue;
      final name = m.fullName;
      if (name == null || name.trim().isEmpty || _looksLikeUUID(name)) continue;

      // Only update if we don't have a cached name, or the new name is better
      final existing = _cache[m.userId];
      if (existing == null || existing.name.isEmpty || _looksLikeUUID(existing.name)) {
        _cache[m.userId] = CachedUser(
          id: m.userId,
          name: name.trim(),
          avatar: m.avatarUrl,
        );
      }
    }
  }

  /// Populate cache from a list of chat messages.
  ///
  /// Extracts sender, actor, targetUsers, and mentionTo names.
  void populateFromMessages(List<ChatMessage> messages) {
    for (final msg in messages) {
      populateFromSender(msg.sender);
      if (msg.actor != null) populateFromSender(msg.actor!);
      for (final u in msg.targetUsers) {
        populateFromSender(u);
      }
      for (final m in msg.mentionTo) {
        populateFromSender(m);
      }
    }
  }

  /// Populate cache from a single MessageSender.
  ///
  /// Only caches if the name is valid (non-empty, non-UUID, non-'Unknown').
  void populateFromSender(MessageSender sender) {
    if (sender.id.isEmpty) return;
    if (sender.name.isEmpty ||
        sender.name == 'Unknown' ||
        _looksLikeUUID(sender.name)) {
      return;
    }

    final existing = _cache[sender.id];
    if (existing == null || existing.name.isEmpty || _looksLikeUUID(existing.name)) {
      _cache[sender.id] = CachedUser(
        id: sender.id,
        name: sender.name,
        avatar: sender.avatar ?? existing?.avatar,
      );
    }
  }

  /// Look up a user's display name by ID.
  ///
  /// Returns null if the user is not in cache.
  String? getUserName(String userId) => _cache[userId]?.name;

  /// Look up full cached user info by ID.
  CachedUser? getUser(String userId) => _cache[userId];

  /// Number of cached users (for debugging).
  int get size => _cache.length;

  /// Clear all cached data (called on logout).
  void clear() => _cache.clear();

  /// Check if a string looks like a UUID (8-4-4-4-12 hex pattern).
  static final _uuidRegex = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  );
  static bool _looksLikeUUID(String s) => _uuidRegex.hasMatch(s);
}
