import 'dart:async';

import 'package:rxdart/rxdart.dart';

/// Data class for selected conversation state in desktop split-view.
class SelectedConversation {
  const SelectedConversation({
    required this.conversationId,
    this.receiverId,
  });

  final String conversationId;

  /// For pending direct chats (no server conversation yet), this is the
  /// other user's ID. The backend will auto-create the conversation when
  /// the first message is sent with this receiverId.
  final String? receiverId;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SelectedConversation &&
          runtimeType == other.runtimeType &&
          conversationId == other.conversationId &&
          receiverId == other.receiverId;

  @override
  int get hashCode => Object.hash(conversationId, receiverId);
}

/// Shared selected-conversation state for desktop split-view flows.
///
/// This keeps "which conversation should be visible in the detail pane"
/// separate from actual page navigation so notifications, list clicks,
/// and deep links can all target the same state.
class ChatConversationSelectionService {
  final BehaviorSubject<SelectedConversation?> _selectedConversationController =
      BehaviorSubject<SelectedConversation?>.seeded(null);

  Stream<SelectedConversation?> get selectedConversationStream =>
      _selectedConversationController.stream;

  String? get selectedConversationId =>
      _selectedConversationController.valueOrNull?.conversationId;

  String? get selectedReceiverId =>
      _selectedConversationController.valueOrNull?.receiverId;

  SelectedConversation? get selectedConversation =>
      _selectedConversationController.valueOrNull;

  void selectConversation(String conversationId, {String? receiverId}) {
    final trimmedConversationId = conversationId.trim();
    if (trimmedConversationId.isEmpty) {
      return;
    }

    final newSelection = SelectedConversation(
      conversationId: trimmedConversationId,
      receiverId: receiverId,
    );

    if (_selectedConversationController.valueOrNull == newSelection) {
      return;
    }

    _selectedConversationController.add(newSelection);
  }

  void clearSelection([String? conversationId]) {
    if (conversationId != null &&
        _selectedConversationController.valueOrNull?.conversationId !=
            conversationId) {
      return;
    }

    if (_selectedConversationController.valueOrNull == null) {
      return;
    }

    _selectedConversationController.add(null);
  }

  Future<void> dispose() async {
    await _selectedConversationController.close();
  }
}
