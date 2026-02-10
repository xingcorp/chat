import 'package:flutter_chat_core/flutter_chat_core.dart' as flyer;
import 'package:flutter_chat_app/shared/domain/entities/user.dart' as domain;
import 'package:flutter_chat_app/shared/domain/entities/chat.dart';
import 'package:flutter_chat_app/shared/domain/entities/chat_message.dart';

/// Resolves a [flyer.UserID] into a Flyer [flyer.User].
///
/// This provides the [flyer.ResolveUserCallback] required by the Flyer Chat
/// widget. It looks up users from an in-memory cache built from conversation
/// members and message senders.
///
/// Usage:
/// ```dart
/// final resolver = FlyerUserResolver();
/// resolver.seedFromChat(chat);       // pre-populate from conversation
/// resolver.seedFromMessages(msgs);   // pre-populate from messages
///
/// Chat(
///   resolveUser: resolver.resolve,   // pass as callback
///   ...
/// )
/// ```
class FlyerUserResolver {
  final Map<String, flyer.User> _cache = {};

  /// The callback to pass into Flyer Chat's `resolveUser` parameter.
  Future<flyer.User?> resolve(String userId) async {
    return _cache[userId];
  }

  /// Pre-populate cache from a [Chat]'s member list.
  void seedFromChat(Chat chat) {
    for (final member in chat.members) {
      _cache[member.userId] = flyer.User(
        id: member.userId,
        name: member.fullName,
        imageSource: member.avatarUrl,
      );
    }
  }

  /// Pre-populate cache from a list of [ChatMessage]s.
  void seedFromMessages(List<ChatMessage> messages) {
    for (final msg in messages) {
      _cache.putIfAbsent(
        msg.sender.id,
        () => flyer.User(
          id: msg.sender.id,
          name: msg.sender.name,
          imageSource: msg.sender.avatar,
        ),
      );
      // Also seed mentions
      for (final mention in msg.mentionTo) {
        _cache.putIfAbsent(
          mention.id,
          () => flyer.User(
            id: mention.id,
            name: mention.name,
            imageSource: mention.avatar,
          ),
        );
      }
    }
  }

  /// Add or update a single user.
  void addUser(domain.User user) {
    _cache[user.id] = flyer.User(
      id: user.id,
      name: user.fullName ?? user.username,
      imageSource: user.avatar,
    );
  }

  /// Add a user from a [MessageSender].
  void addSender(MessageSender sender) {
    _cache.putIfAbsent(
      sender.id,
      () => flyer.User(
        id: sender.id,
        name: sender.name,
        imageSource: sender.avatar,
      ),
    );
  }

  /// Add a user from a [ConversationMember].
  void addMember(ConversationMember member) {
    _cache[member.userId] = flyer.User(
      id: member.userId,
      name: member.fullName,
      imageSource: member.avatarUrl,
    );
  }

  /// Check if a user is cached.
  bool has(String userId) => _cache.containsKey(userId);

  /// Clear the cache.
  void clear() => _cache.clear();
}
