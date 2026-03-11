import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// Custom keyboard handler that intercepts Enter / Shift+Enter in the
/// Quill editor and routes them to the appropriate action.
///
/// **Desktop behaviour (default):**
/// - `Enter`         → send message
/// - `Shift + Enter` → insert newline
///
/// **Mobile behaviour:**
/// - `Enter`         → insert newline (on-screen keyboard sends Enter)
/// - Send button     → send message
///
/// Usage:
/// ```dart
/// QuillEditor(
///   ...
///   config: QuillEditorConfig(
///     customShortcuts: ComposerEnterKeyHandler.shortcuts(onSend: _handleSend),
///   ),
/// )
/// ```
class ComposerEnterKeyHandler {
  const ComposerEnterKeyHandler._();

  /// Whether the current platform uses desktop-style Enter-to-send.
  static bool get _isDesktop {
    return defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.linux;
  }

  /// Build a [Map] of keyboard shortcuts to be passed to
  /// [QuillEditorConfig.customShortcuts].
  ///
  /// [onSend] is called when the user presses Enter on desktop.
  /// Returns `null` on mobile (Enter handled natively as newline).
  static Map<ShortcutActivator, VoidCallback>? shortcuts({
    required VoidCallback onSend,
  }) {
    if (!_isDesktop) return null;

    return {
      // Enter alone → send message
      const SingleActivator(LogicalKeyboardKey.enter): onSend,
    };
  }

  /// Returns `true` if the given [event] is a Shift+Enter combination.
  ///
  /// The Quill editor handles Shift+Enter natively to insert a newline,
  /// so this helper is primarily used for logging / analytics.
  static bool isShiftEnter(KeyEvent event) {
    return event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.enter &&
        HardwareKeyboard.instance.isShiftPressed;
  }
}
