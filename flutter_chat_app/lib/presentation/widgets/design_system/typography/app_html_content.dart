import 'package:flutter/material.dart';
import 'package:flutter_chat_app/core/base/base_widget.dart';
import 'package:flutter_chat_app/core/constants/app_dimens.dart';
import 'package:flutter_chat_app/core/theme/app_colors.dart';
import 'package:flutter_chat_app/core/theme/app_text_styles.dart';
import 'package:flutter_html/flutter_html.dart';

/// A design-system HTML content widget for rendering HTML strings.
///
/// Wraps [flutter_html]'s `Html` widget with design-system defaults:
/// - Uses [AppTextStyles] for base typography
/// - Uses [AppColors] for text, link, and highlight colors
/// - Supports dark mode automatically
/// - Handles backend highlight tags (`<em>`) with primary color styling
///
/// Usage:
/// ```dart
/// AppHtmlContent(
///   data: '<em style="color: #00B1D2">matched</em> text',
/// )
///
/// AppHtmlContent(
///   data: htmlString,
///   baseStyle: AppTextStyles.bodySmall,
///   maxLines: 3,
///   onLinkTap: (url, _, __) => launchUrl(url),
/// )
/// ```
class AppHtmlContent extends BaseStatelessWidget {
  /// The HTML string to render.
  final String data;

  /// Base [TextStyle] applied to the root element.
  /// Defaults to [AppTextStyles.bodyMedium] with theme-aware color.
  final TextStyle? baseStyle;

  /// Maximum number of lines before truncation.
  /// When set, wraps content in a constrained box.
  final int? maxLines;

  /// Whether the widget should shrink-wrap its content.
  final bool shrinkWrap;

  /// Callback when a link (`<a href>`) is tapped.
  final OnTap? onLinkTap;

  /// Additional style overrides per HTML tag.
  /// Merged on top of the default design-system styles.
  final Map<String, Style>? styleOverrides;

  const AppHtmlContent({
    super.key,
    required this.data,
    this.baseStyle,
    this.maxLines,
    this.shrinkWrap = true,
    this.onLinkTap,
    this.styleOverrides,
  });

  @override
  Widget buildContent(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor =
        isDark ? AppColors.textPrimaryDarkMode : AppColors.textPrimary;
    final linkColor = AppColors.primary;

    final resolvedBaseStyle = (baseStyle ?? AppTextStyles.bodyMedium).copyWith(
      color: textColor,
    );

    // Build design-system default styles
    final defaultStyles = <String, Style>{
      'body': Style(
        margin: Margins.zero,
        padding: HtmlPaddings.zero,
        fontSize: FontSize(resolvedBaseStyle.fontSize ?? 14),
        fontWeight: resolvedBaseStyle.fontWeight,
        fontFamily: resolvedBaseStyle.fontFamily,
        color: textColor,
        lineHeight: resolvedBaseStyle.height != null
            ? LineHeight(resolvedBaseStyle.height!)
            : const LineHeight(1.4),
      ),
      'em': Style(
        backgroundColor: AppColors.primary.withValues(alpha: 0.15),
        color: linkColor,
        fontWeight: FontWeight.w600,
        fontStyle: FontStyle.normal,
      ),
      'b': Style(fontWeight: FontWeight.bold),
      'strong': Style(fontWeight: FontWeight.bold),
      'i': Style(fontStyle: FontStyle.italic),
      'a': Style(
        color: linkColor,
        textDecoration: TextDecoration.underline,
      ),
      'p': Style(
        margin: Margins.zero,
        padding: HtmlPaddings.zero,
      ),
    };

    // Merge user overrides on top of defaults
    if (styleOverrides != null) {
      defaultStyles.addAll(styleOverrides!);
    }

    Widget htmlWidget = Html(
      data: data,
      style: defaultStyles,
      shrinkWrap: shrinkWrap,
      onLinkTap: onLinkTap,
    );

    // Apply maxLines constraint via a sized + clipped container
    if (maxLines != null) {
      final lineHeight = resolvedBaseStyle.height ?? 1.4;
      final fontSize = resolvedBaseStyle.fontSize ?? 14.0;
      final maxHeight = fontSize * lineHeight * maxLines! +
          AppDimens.paddingXSmall; // small buffer

      htmlWidget = ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: ClipRect(child: htmlWidget),
      );
    }

    return htmlWidget;
  }
}
