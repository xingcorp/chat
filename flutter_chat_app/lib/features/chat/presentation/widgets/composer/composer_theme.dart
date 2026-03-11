import 'package:flutter/material.dart';
import 'package:flutter_chat_app/core/constants/app_dimens.dart';
import 'package:flutter_chat_app/core/theme/app_colors.dart';
import 'package:flutter_quill/flutter_quill.dart';

/// Maps the application design-system tokens ([AppColors], [AppDimens])
/// to [DefaultStyles] used by [QuillEditor].
///
/// Two factories are provided:
/// - [composerStyles] — for the editable composer input.
/// - [bubbleStyles] — for read-only message bubbles (compact).
class ComposerTheme {
  const ComposerTheme._();

  // ─────────────────────────────────────────────────────────
  //  Editable composer styles
  // ─────────────────────────────────────────────────────────

  /// [DefaultStyles] for the editable composer (chat input).
  static DefaultStyles composerStyles(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;

    final baseTextColor = isDark
        ? AppColors.textPrimaryDarkMode
        : AppColors.textPrimary;

    final hintColor = isDark
        ? AppColors.textHintDarkMode
        : AppColors.textHint;

    final linkColor = AppColors.primary;

    final baseStyle = TextStyle(
      fontSize: 15.0,
      height: 1.4,
      color: baseTextColor,
    );

    return DefaultStyles(
      paragraph: DefaultTextBlockStyle(
        baseStyle,
        const HorizontalSpacing(0, 0),
        const VerticalSpacing(0, 0),
        const VerticalSpacing(0, 0),
        null,
      ),
      bold: const TextStyle(fontWeight: FontWeight.w700),
      italic: const TextStyle(fontStyle: FontStyle.italic),
      underline: const TextStyle(decoration: TextDecoration.underline),
      strikeThrough: const TextStyle(decoration: TextDecoration.lineThrough),
      link: TextStyle(
        color: linkColor,
        decoration: TextDecoration.underline,
        decorationColor: linkColor,
      ),
      placeHolder: DefaultTextBlockStyle(
        baseStyle.copyWith(color: hintColor),
        const HorizontalSpacing(0, 0),
        const VerticalSpacing(0, 0),
        const VerticalSpacing(0, 0),
        null,
      ),
      lists: DefaultListBlockStyle(
        baseStyle,
        const HorizontalSpacing(0, 0),
        const VerticalSpacing(4, 4),
        const VerticalSpacing(0, 0),
        null,
        null,
      ),
      leading: DefaultTextBlockStyle(
        baseStyle,
        const HorizontalSpacing(0, 0),
        const VerticalSpacing(0, 0),
        const VerticalSpacing(0, 0),
        null,
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  //  Read-only message bubble styles
  // ─────────────────────────────────────────────────────────

  /// [DefaultStyles] for read-only message bubbles (compact spacing).
  static DefaultStyles bubbleStyles(
    BuildContext context, {
    required bool isSender,
  }) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;

    final Color textColor;
    if (isSender) {
      textColor = isDark
          ? AppColors.textPrimaryDarkMode
          : AppColors.textPrimary;
    } else {
      textColor = isDark
          ? AppColors.textPrimaryDarkMode
          : AppColors.textPrimary;
    }

    final linkColor = AppColors.primary;

    final baseStyle = TextStyle(
      fontSize: 14.0,
      height: 1.35,
      color: textColor,
    );

    return DefaultStyles(
      paragraph: DefaultTextBlockStyle(
        baseStyle,
        const HorizontalSpacing(0, 0),
        const VerticalSpacing(0, 0),
        const VerticalSpacing(0, 0),
        null,
      ),
      bold: const TextStyle(fontWeight: FontWeight.w700),
      italic: const TextStyle(fontStyle: FontStyle.italic),
      underline: const TextStyle(decoration: TextDecoration.underline),
      strikeThrough: const TextStyle(decoration: TextDecoration.lineThrough),
      link: TextStyle(
        color: linkColor,
        decoration: TextDecoration.underline,
        decorationColor: linkColor,
      ),
      lists: DefaultListBlockStyle(
        baseStyle,
        const HorizontalSpacing(0, 0),
        const VerticalSpacing(2, 2),
        const VerticalSpacing(0, 0),
        null,
        null,
      ),
      leading: DefaultTextBlockStyle(
        baseStyle,
        const HorizontalSpacing(0, 0),
        const VerticalSpacing(0, 0),
        const VerticalSpacing(0, 0),
        null,
      ),
    );
  }
}
