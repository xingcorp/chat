import 'package:flutter_chat_app/core/constants/app_dimens.dart';

/// Constants for the rich text composer system.
///
/// Centralises magic numbers so that all composer widgets share the
/// same sizing, timing, and limits. Values are based on [AppDimens]
/// wherever an equivalent exists.
class ComposerConstants {
  const ComposerConstants._();

  // ───────────────────── Editor Surface ─────────────────────

  /// Minimum height of the editor when empty (single line).
  static const double editorMinHeight = 40.0;

  /// Maximum height before the editor switches to internal scroll.
  static const double editorMaxHeight = 200.0;

  /// Horizontal padding inside the editor surface.
  static const double editorHorizontalPadding = AppDimens.paddingSmall;

  /// Vertical padding inside the editor surface.
  static const double editorVerticalPadding = AppDimens.paddingSmall;

  /// Border radius of the editor container.
  static const double editorBorderRadius = AppDimens.radiusLarge;

  // ───────────────────── Toolbar ─────────────────────

  /// Height of the quick-action row (Layer A).
  static const double actionRowHeight = 44.0;

  /// Height of the formatting panel (Layer B).
  static const double formattingPanelHeight = 44.0;

  /// Size of each format icon button.
  static const double formatButtonSize = 36.0;

  /// Icon size inside format buttons.
  static const double formatIconSize = AppDimens.iconSmall;

  /// Spacing between format buttons.
  static const double formatButtonSpacing = AppDimens.spaceXSmall;

  /// Border radius of format buttons.
  static const double formatButtonRadius = AppDimens.radiusSmall;

  // ───────────────────── Send Button ─────────────────────

  /// Diameter of the send button.
  static const double sendButtonSize = 36.0;

  /// Icon size inside the send button.
  static const double sendIconSize = AppDimens.iconSmall;

  // ───────────────────── Context Bar ─────────────────────

  /// Height of the reply/edit context bar above the editor.
  static const double contextBarHeight = 44.0;

  // ───────────────────── Attachment Tray ─────────────────────

  /// Height of one attachment preview card.
  static const double attachmentCardHeight = 64.0;

  // ───────────────────── Animation ─────────────────────

  /// Duration for toolbar expand/collapse.
  static const Duration toolbarToggleDuration =
      Duration(milliseconds: AppDimens.durationMedium);

  /// Duration for send-button morph (mic ↔ send).
  static const Duration sendButtonMorphDuration =
      Duration(milliseconds: AppDimens.durationFast);

  /// Curve for toolbar animations.
  static const String toolbarCurveName = 'easeInOut';

  // ───────────────────── Desktop ─────────────────────

  /// Minimum height of the editor on desktop (starts as single line,
  /// expands as user types — Zalo-style).
  static const double desktopEditorMinHeight = 48.0;

  /// Maximum height of the editor on desktop before scrolling.
  static const double desktopEditorMaxHeight = 300.0;

  /// Height of the desktop action toolbar row.
  static const double desktopToolbarHeight = 40.0;

  /// Icon size in the desktop toolbar.
  static const double desktopToolbarIconSize = AppDimens.iconSmall;

  // ───────────────────── Mobile ─────────────────────

  /// Minimum height of the editor on mobile — kept compact so a single-line
  /// message reads tight inside the rounded input pill (Messenger/Zalo style).
  static const double mobileEditorMinHeight = 40.0;

  /// Maximum height of the editor on mobile before scrolling.
  static const double mobileEditorMaxHeight = 150.0;

  // ───────────────────── Limits ─────────────────────

  /// Maximum number of lines before the editor scrolls internally.
  static const int editorMaxVisibleLines = 8;

  /// Debounce delay for draft save after typing stops.
  static const Duration draftSaveDebounce = Duration(milliseconds: 500);
}
