import 'dart:async';

import 'package:rxdart/rxdart.dart';

/// Shared selected-conversation state for desktop split-view flows.
///
/// This keeps "which conversation should be visible in the detail pane"
/// separate from actual page navigation so notifications, list clicks,
/// and deep links can all target the same state.
class ChatConversationSelectionService {
  final BehaviorSubject<String?> _selectedConversationController =
      BehaviorSubject<String?>.seeded(null);

  Stream<String?> get selectedConversationStream =>
      _selectedConversationController.stream;

  String? get selectedConversationId =>
      _selectedConversationController.valueOrNull;

  void selectConversation(String conversationId) {
    final trimmedConversationId = conversationId.trim();
    if (trimmedConversationId.isEmpty) {
      return;
    }

    if (_selectedConversationController.valueOrNull == trimmedConversationId) {
      return;
    }

    _selectedConversationController.add(trimmedConversationId);
  }

  void clearSelection([String? conversationId]) {
    if (conversationId != null &&
        _selectedConversationController.valueOrNull != conversationId) {
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
