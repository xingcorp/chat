import 'package:flutter/foundation.dart';

/// Groups all action callbacks for desktop message hover actions.
///
/// Passed from `ChatDetailsPage` → `DesktopMessageHoverWrapper` → `MessageHoverActionBar`.
/// Avoids passing 8+ individual function parameters through the widget tree.
///
/// **Usage**:
/// ```dart
/// MessageActionCallbacks(
///   onReaction: (emoji) => bloc.add(ToggleReaction(...)),
///   onReply: () => _startReply(message),
///   onForward: () => showForwardMessageSheet(...),
///   onCopy: () => Clipboard.setData(...),
///   onEdit: () => _startEditMode(message),
///   onDelete: () => _confirmDeleteMessage(message),
///   onSelect: () => _enterSelectionMode(messageId),
///   onOpenEmojiPicker: () => EmojiPickerBottomSheet.show(...),
/// )
/// ```
class MessageActionCallbacks {
  /// Toggle a quick reaction emoji on the message
  final void Function(String emoji) onReaction;

  /// Reply to the message (sets reply preview in input bar)
  final VoidCallback onReply;

  /// Forward the message to another chat
  final VoidCallback onForward;

  /// Copy message text content to clipboard
  final VoidCallback onCopy;

  /// Edit the message (own text messages only)
  final VoidCallback onEdit;

  /// Delete the message with confirmation (own messages only)
  final VoidCallback onDelete;

  /// Enter selection mode with this message selected
  final VoidCallback onSelect;

  /// Open full emoji picker for reactions
  final VoidCallback onOpenEmojiPicker;

  const MessageActionCallbacks({
    required this.onReaction,
    required this.onReply,
    required this.onForward,
    required this.onCopy,
    required this.onEdit,
    required this.onDelete,
    required this.onSelect,
    required this.onOpenEmojiPicker,
  });
}
