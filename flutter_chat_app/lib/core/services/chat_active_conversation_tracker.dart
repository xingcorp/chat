/// Tracks the conversation currently visible to the user so notifications can
/// avoid firing for the chat already on screen.
class ChatActiveConversationTracker {
  String? _activeConversationId;
  bool _isAppInForeground = true;

  String? get activeConversationId => _activeConversationId;

  bool get isAppInForeground => _isAppInForeground;

  void setActiveConversation(String conversationId) {
    if (conversationId.trim().isEmpty) {
      return;
    }
    _activeConversationId = conversationId;
  }

  void clearActiveConversation([String? conversationId]) {
    if (conversationId != null && _activeConversationId != conversationId) {
      return;
    }
    _activeConversationId = null;
  }

  void markAppForeground() {
    _isAppInForeground = true;
  }

  void markAppBackground() {
    _isAppInForeground = false;
  }

  bool shouldSuppressConversationNotification(String conversationId) {
    return _isAppInForeground && _activeConversationId == conversationId;
  }
}
