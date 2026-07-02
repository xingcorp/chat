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
      // ── Block-level elements ──────────────────────────────
      'h1': Style(
        fontSize: FontSize(24),
        fontWeight: FontWeight.bold,
        margin: Margins.only(top: 8, bottom: 4),
        padding: HtmlPaddings.zero,
      ),
      'h2': Style(
        fontSize: FontSize(20),
        fontWeight: FontWeight.bold,
        margin: Margins.only(top: 8, bottom: 4),
        padding: HtmlPaddings.zero,
      ),
      'h3': Style(
        fontSize: FontSize(18),
        fontWeight: FontWeight.bold,
        margin: Margins.only(top: 6, bottom: 2),
        padding: HtmlPaddings.zero,
      ),
      'h4': Style(
        fontSize: FontSize(16),
        fontWeight: FontWeight.w600,
        margin: Margins.only(top: 4, bottom: 2),
        padding: HtmlPaddings.zero,
      ),
      'h5': Style(
        fontSize: FontSize(14),
        fontWeight: FontWeight.w600,
        margin: Margins.only(top: 4, bottom: 2),
        padding: HtmlPaddings.zero,
      ),
      'h6': Style(
        fontSize: FontSize(12),
        fontWeight: FontWeight.w600,
        margin: Margins.only(top: 4, bottom: 2),
        padding: HtmlPaddings.zero,
      ),
      'ol': Style(
        margin: Margins.only(top: 4, bottom: 4),
        padding: HtmlPaddings.only(left: 24),
      ),
      'ul': Style(
        margin: Margins.only(top: 4, bottom: 4),
        padding: HtmlPaddings.only(left: 24),
      ),
      'li': Style(
        margin: Margins.only(bottom: 2),
        padding: HtmlPaddings.zero,
      ),
      'code': Style(
        fontFamily: 'monospace',
        backgroundColor: isDark
            ? const Color(0xFF2D2D2D)
            : const Color(0xFFF5F5F5),
        padding: HtmlPaddings.symmetric(horizontal: 4, vertical: 1),
      ),
      'pre': Style(
        fontFamily: 'monospace',
        backgroundColor: isDark
            ? const Color(0xFF2D2D2D)
            : const Color(0xFFF5F5F5),
        padding: HtmlPaddings.all(8),
        margin: Margins.only(top: 4, bottom: 4),
      ),
      'blockquote': Style(
        border: Border(
          left: BorderSide(color: AppColors.primary, width: 3),
        ),
        padding: HtmlPaddings.only(left: 8),
        margin: Margins.only(top: 4, bottom: 4),
        fontStyle: FontStyle.italic,
      ),
      'u': Style(textDecoration: TextDecoration.underline),
      's': Style(textDecoration: TextDecoration.lineThrough),
      'del': Style(textDecoration: TextDecoration.lineThrough),
      'hr': Style(
        margin: Margins.symmetric(vertical: 8),
        border: Border(
          bottom: BorderSide(
            color: isDark ? const Color(0xFF555555) : const Color(0xFFDDDDDD),
          ),
        ),
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
