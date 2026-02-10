import 'dart:async';

import 'package:flutter_chat_core/flutter_chat_core.dart' as flyer;
import 'package:flutter_chat_app/shared/domain/entities/chat_message.dart';

import 'flyer_message_mapper.dart';
import 'flyer_user_resolver.dart';

/// Bridges our BLoC-managed message list into Flyer Chat's [flyer.ChatController].
///
/// This adapter extends [flyer.InMemoryChatController] so that:
/// 1. The Chat widget can read `messages` and subscribe to `operationsStream`.
/// 2. Our BLoC remains the single source of truth for data.
/// 3. Message insert/update/remove animate correctly in the Flyer list.
///
/// Typical lifecycle:
/// ```dart
/// final adapter = ChatControllerAdapter(
///   mapper: FlyerMessageMapper(),
///   resolver: resolver,
///   currentUserId: userId,
/// );
///
/// // When BLoC emits a new message list:
/// adapter.syncMessages(domainMessages);
///
/// // When a single real-time message arrives:
/// adapter.addMessage(newDomainMessage);
///
/// // Pass to Flyer Chat widget:
/// Chat(chatController: adapter, ...)
/// ```
class ChatControllerAdapter extends flyer.InMemoryChatController {
  final FlyerMessageMapper _mapper;
  final FlyerUserResolver _resolver;
  final String currentUserId;

  /// Tracks domain message IDs currently in the controller,
  /// for efficient diffing when syncing.
  final Set<String> _knownIds = {};

  ChatControllerAdapter({
    required FlyerMessageMapper mapper,
    required FlyerUserResolver resolver,
    required this.currentUserId,
  })  : _mapper = mapper,
        _resolver = resolver,
        super();

  // ---------------------------------------------------------------------------
  // Public API for BLoC integration
  // ---------------------------------------------------------------------------

  /// Replace the full message list (e.g. initial load or refresh).
  ///
  /// Maps all domain messages → Flyer messages, then calls [setMessages].
  /// Also seeds the user resolver from message senders.
  Future<void> syncMessages(List<ChatMessage> domainMessages) async {
    // Seed user resolver
    _resolver.seedFromMessages(domainMessages);

    // Map and set
    final flyerMessages = _mapper.toFlyerList(domainMessages);

    _knownIds
      ..clear()
      ..addAll(domainMessages.map((m) => m.id));

    await setMessages(flyerMessages);
  }

  /// Add a single new message (e.g. from real-time socket event).
  ///
  /// Inserts at index 0 (newest first) with animation.
  Future<void> addMessage(ChatMessage domainMessage) async {
    if (_knownIds.contains(domainMessage.id)) {
      // Already exists → treat as update
      await updateDomainMessage(domainMessage);
      return;
    }

    _resolver.addSender(domainMessage.sender);

    final flyerMessage = _mapper.toFlyer(domainMessage);
    _knownIds.add(domainMessage.id);

    await insertMessage(flyerMessage, index: 0);
  }

  /// Update an existing message (e.g. edit, status change, reaction).
  Future<void> updateDomainMessage(ChatMessage domainMessage) async {
    _resolver.addSender(domainMessage.sender);

    final newFlyerMessage = _mapper.toFlyer(domainMessage);

    // Find the existing flyer message by ID
    final existingIndex = messages.indexWhere((m) => m.id == domainMessage.id);
    if (existingIndex == -1) {
      // Not found → insert as new
      _knownIds.add(domainMessage.id);
      await insertMessage(newFlyerMessage, index: 0);
      return;
    }

    final oldFlyerMessage = messages[existingIndex];
    await updateMessage(oldFlyerMessage, newFlyerMessage);
  }

  /// Remove a message (e.g. hard delete).
  Future<void> removeDomainMessage(String messageId) async {
    final existingIndex = messages.indexWhere((m) => m.id == messageId);
    if (existingIndex == -1) return;

    _knownIds.remove(messageId);
    await removeMessage(messages[existingIndex]);
  }

  /// Append older messages at the end (pagination - load more).
  Future<void> appendOlderMessages(List<ChatMessage> olderMessages) async {
    if (olderMessages.isEmpty) return;

    _resolver.seedFromMessages(olderMessages);

    final newMessages = olderMessages
        .where((m) => !_knownIds.contains(m.id))
        .toList();

    if (newMessages.isEmpty) return;

    final flyerMessages = _mapper.toFlyerList(newMessages);

    for (final id in newMessages.map((m) => m.id)) {
      _knownIds.add(id);
    }

    await insertAllMessages(flyerMessages, index: messages.length);
  }

  /// The user resolver to pass to the Flyer Chat widget.
  FlyerUserResolver get userResolver => _resolver;
}
