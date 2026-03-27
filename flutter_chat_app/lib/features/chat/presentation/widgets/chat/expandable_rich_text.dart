import 'package:flutter/material.dart';
import 'package:flutter_chat_app/l10n/l10n.dart';

/// Widget hiển thị rich text (InlineSpan) có thể expand/collapse
///
/// Pattern giống WhatsApp, Telegram, Slack:
/// - Show first N lines với "Read more" button
/// - Tap để expand full message
/// - "Show less" button để collapse
///
/// Hỗ trợ cả plain text và rich text (mentions, URLs, HTML formatting)
///
/// ## Text Selection (Desktop/Web)
///
/// Khi [selectable] = true (desktop/web):
/// - Expanded / short messages: render [SelectableText.rich] → user drag-to-select + Ctrl+C
/// - Collapsed (truncated) state: vẫn dùng [RichText] (non-selectable) vì text bị cắt
///
/// Khi [selectable] = false (mobile, default):
/// - Mọi state đều dùng [RichText] như cũ → behavior 100% backward compatible
///
/// Pattern tham khảo: Stream Chat Flutter — `MarkdownBody(selectable: isDesktopDeviceOrWeb)`
class ExpandableRichText extends StatefulWidget {
  /// InlineSpan content to display (supports rich text)
  final List<InlineSpan> spans;

  /// Plain text version for length calculation
  final String plainText;

  /// Maximum lines before truncation (default: 5 like WhatsApp)
  final int maxLines;

  /// Maximum characters before truncation (fallback)
  final int maxChars;

  /// Default text style
  final TextStyle? style;

  /// Callback when message is expanded/collapsed
  final void Function(bool isExpanded)? onToggle;

  /// Bật text selection (Desktop/Web).
  ///
  /// - `true`: dùng [SelectableText.rich] cho expanded / non-truncated state
  /// - `false` (default): dùng [RichText] cho mọi state (backward compatible)
  ///
  /// Chỉ ảnh hưởng expanded state & short messages. Collapsed (truncated)
  /// state luôn dùng [RichText] vì [SelectableText] không hỗ trợ
  /// [TextOverflow.ellipsis].
  final bool selectable;

  /// Màu highlight khi user drag-to-select text.
  ///
  /// Cần thiết cho bubble tin nhắn của mình (background primary/blue):
  /// default selection color bị trùng với background → không thấy được.
  /// Truyền `Colors.white.withValues(alpha: 0.3)` cho own messages.
  /// Nếu null, dùng default từ theme.
  final Color? selectionColor;

  /// Màu cho nút "Xem thêm" / "Thu gọn".
  ///
  /// Khi bubble tin nhắn gửi đi có nền primary (xanh), mặc định
  /// `colorScheme.primary` bị trùng → không nhìn thấy.
  /// Truyền `Colors.white` cho own messages.
  /// Nếu null, dùng `colorScheme.primary`.
  final Color? toggleColor;

  const ExpandableRichText({
    super.key,
    required this.spans,
    required this.plainText,
    this.maxLines = 5,
    this.maxChars = 500,
    this.style,
    this.onToggle,
    this.selectable = false,
    this.selectionColor,
    this.toggleColor,
  });

  @override
  State<ExpandableRichText> createState() => _ExpandableRichTextState();
}

class _ExpandableRichTextState extends State<ExpandableRichText> {
  bool _isExpanded = false;
  bool _needsExpansion = false;

  @override
  void initState() {
    super.initState();
    _checkIfNeedsExpansion();
  }

  @override
  void didUpdateWidget(ExpandableRichText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.plainText != widget.plainText) {
      _checkIfNeedsExpansion();
    }
  }

  void _checkIfNeedsExpansion() {
    // Check by line count
    final lines = widget.plainText.split('\n');
    final lineCount = lines.length;

    // Check by character count (fallback)
    final charCount = widget.plainText.length;

    setState(() {
      _needsExpansion = lineCount > widget.maxLines || charCount > widget.maxChars;
    });
  }

  void _toggleExpansion() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
    widget.onToggle?.call(_isExpanded);
  }

  @override
  Widget build(BuildContext context) {
    final effectiveToggleColor =
        widget.toggleColor ?? Theme.of(context).colorScheme.primary;

    // If no expansion needed, show full rich text
    if (!_needsExpansion) {
      return _buildRichContent(widget.spans);
    }

    // If expanded, show full text with "Show less" button
    if (_isExpanded) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildRichContent(widget.spans),
          GestureDetector(
            onTap: _toggleExpansion,
            child: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                context.l10n.showLess,
                style: widget.style?.copyWith(
                      color: effectiveToggleColor,
                      fontWeight: FontWeight.w500,
                    ) ??
                    TextStyle(
                      color: effectiveToggleColor,
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ),
          ),
        ],
      );
    }

    // Collapsed: show truncated text with "Read more" button
    // LUÔN dùng RichText ở collapsed state — SelectableText không hỗ trợ
    // TextOverflow.ellipsis, và text bị cắt nên select cũng không ý nghĩa
    final truncatedSpans = _truncateSpans(widget.spans, widget.maxChars);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        RichText(
          text: TextSpan(children: truncatedSpans, style: widget.style),
          maxLines: widget.maxLines,
          overflow: TextOverflow.ellipsis,
        ),
        GestureDetector(
          onTap: _toggleExpansion,
          child: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              context.l10n.readMore,
              style: widget.style?.copyWith(
                    color: effectiveToggleColor,
                    fontWeight: FontWeight.w500,
                  ) ??
                  TextStyle(
                    color: effectiveToggleColor,
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ),
        ),
      ],
    );
  }

  /// Render rich text content — selectable trên desktop, RichText trên mobile.
  ///
  /// Khi [selectable] = true: dùng [SelectableText.rich] để user
  /// có thể drag-to-select text và copy (Ctrl+C / Cmd+C).
  /// Khi [selectable] = false: dùng [RichText] (behavior cũ, zero overhead).
  Widget _buildRichContent(List<InlineSpan> spans) {
    if (widget.selectable) {
      Widget selectableWidget = SelectableText.rich(
        TextSpan(children: spans, style: widget.style),
      );
      // Wrap với TextSelectionTheme nếu cần custom selection color
      // (ví dụ: own message bubble xanh cần selection highlight trắng)
      if (widget.selectionColor != null) {
        selectableWidget = TextSelectionTheme(
          data: TextSelectionThemeData(
            selectionColor: widget.selectionColor,
          ),
          child: selectableWidget,
        );
      }
      return selectableWidget;
    }
    return RichText(
      text: TextSpan(children: spans, style: widget.style),
    );
  }

  /// Truncate spans to fit within maxChars
  List<InlineSpan> _truncateSpans(List<InlineSpan> spans, int maxChars) {
    final result = <InlineSpan>[];
    var charCount = 0;

    for (final span in spans) {
      if (charCount >= maxChars) break;

      if (span is TextSpan) {
        final text = span.text ?? '';
        final remaining = maxChars - charCount;

        if (text.length <= remaining) {
          result.add(span);
          charCount += text.length;
        } else {
          // Truncate this span
          result.add(TextSpan(
            text: '${text.substring(0, remaining)}...',
            style: span.style,
            recognizer: span.recognizer,
            children: span.children,
            locale: span.locale,
            semanticsLabel: span.semanticsLabel,
          ));
          charCount = maxChars;
        }
      } else if (span is WidgetSpan) {
        // WidgetSpan không có text length, giữ nguyên
        result.add(span);
        charCount += 1; // Count as 1 character for simplicity
      }
    }

    return result;
  }
}
