import 'dart:async';

import 'package:flutter_chat_app/shared/domain/entities/chat_message.dart';
import 'package:injectable/injectable.dart';
import 'package:rxdart/rxdart.dart';

/// Central event bus for cross-layer communication in the chat module.
///
/// Enables the host app to receive events (unread count, new messages)
/// without requiring ChatBloc to be active. Internal services write to
/// this bus; [ChatModule] reads from it and forwards to host app callbacks.
///
/// ## Streams
/// - [totalUnreadCountStream] — total unread badge count across all chats
/// - [newMessageStream] — broadcasts every incoming real-time message
/// - [fcmDataStream] — host app forwards raw FCM data payloads here
/// - [syncTriggerStream] — host app requests a foreground data sync
@lazySingleton
class ChatModuleEventBus {
  // ---------------------------------------------------------------------------
  // Unread count
  // ---------------------------------------------------------------------------

  final BehaviorSubject<int> _totalUnreadCount =
      BehaviorSubject<int>.seeded(0);

  /// Stream of total unread message count across all conversations.
  Stream<int> get totalUnreadCountStream => _totalUnreadCount.stream;

  /// Current total unread count (synchronous).
  int get currentTotalUnreadCount => _totalUnreadCount.value;

  /// Set total unread count (e.g. after loading chat list).
  void updateTotalUnreadCount(int count) {
    _totalUnreadCount.add(count);
  }

  /// Increment by 1 when a new incoming message arrives.
  void incrementUnreadCount() {
    _totalUnreadCount.add(_totalUnreadCount.value + 1);
  }

  /// Decrement when messages are marked as read.
  void decrementUnreadCount(int by) {
    final newValue = (_totalUnreadCount.value - by).clamp(0, 1 << 30);
    _totalUnreadCount.add(newValue);
  }

  // ---------------------------------------------------------------------------
  // New message
  // ---------------------------------------------------------------------------

  final StreamController<ChatMessage> _newMessageController =
      StreamController<ChatMessage>.broadcast();

  /// Stream of new messages from any conversation.
  Stream<ChatMessage> get newMessageStream => _newMessageController.stream;

  /// Emit a new incoming message.
  void emitNewMessage(ChatMessage message) {
    _newMessageController.add(message);
  }

  // ---------------------------------------------------------------------------
  // FCM data
  // ---------------------------------------------------------------------------

  final StreamController<Map<String, dynamic>> _fcmDataController =
      StreamController<Map<String, dynamic>>.broadcast();

  /// Stream of raw FCM data payloads forwarded by the host app.
  Stream<Map<String, dynamic>> get fcmDataStream => _fcmDataController.stream;

  /// Forward FCM data into the module for processing.
  void emitFCMData(Map<String, dynamic> data) {
    _fcmDataController.add(data);
  }

  // ---------------------------------------------------------------------------
  // Sync trigger
  // ---------------------------------------------------------------------------

  final StreamController<void> _syncTriggerController =
      StreamController<void>.broadcast();

  /// Stream that fires when the host app requests a foreground sync.
  Stream<void> get syncTriggerStream => _syncTriggerController.stream;

  /// Request a foreground sync of chat data.
  void triggerSync() {
    _syncTriggerController.add(null);
  }

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  /// Dispose all stream controllers. Called during [ChatModule.dispose].
  void dispose() {
    _totalUnreadCount.close();
    _newMessageController.close();
    _fcmDataController.close();
    _syncTriggerController.close();
  }
}
