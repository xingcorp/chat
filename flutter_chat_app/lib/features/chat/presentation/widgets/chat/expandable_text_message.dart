import 'package:flutter/material.dart';
import 'package:flutter_chat_app/l10n/l10n.dart';

/// Widget hiển thị text message có thể expand/collapse
///
/// Pattern giống WhatsApp, Telegram, Slack:
/// - Show first N lines với "Read more" button
/// - Tap để expand full message
/// - "Show less" button để collapse
class ExpandableTextMessage extends StatefulWidget {
  /// Text content to display
  final String text;

  /// Maximum lines before truncation (default: 5 like WhatsApp)
  final int maxLines;

  /// Maximum characters before truncation (fallback)
  final int maxChars;

  /// Text style for the message
  final TextStyle? style;

  /// Callback when message is expanded/collapsed
  final void Function(bool isExpanded)? onToggle;

  const ExpandableTextMessage({
    super.key,
    required this.text,
    this.maxLines = 5,
    this.maxChars = 500,
    this.style,
    this.onToggle,
  });

  @override
  State<ExpandableTextMessage> createState() => _ExpandableTextMessageState();
}

class _ExpandableTextMessageState extends State<ExpandableTextMessage> {
  bool _isExpanded = false;
  bool _needsExpansion = false;

  @override
  void initState() {
    super.initState();
    _checkIfNeedsExpansion();
  }

  @override
  void didUpdateWidget(ExpandableTextMessage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      _checkIfNeedsExpansion();
    }
  }

  void _checkIfNeedsExpansion() {
    // Check by line count
    final lines = widget.text.split('\n');
    final lineCount = lines.length;

    // Check by character count (fallback)
    final charCount = widget.text.length;

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
    // If no expansion needed, show full text
    if (!_needsExpansion) {
      return Text(
        widget.text,
        style: widget.style,
      );
    }

    // If expanded, show full text with "Show less" button
    if (_isExpanded) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.text,
            style: widget.style,
          ),
          GestureDetector(
            onTap: _toggleExpansion,
            child: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                context.l10n.showLess,
                style: widget.style?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w500,
                ) ?? TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      );
    }

    // Collapsed: show truncated text with "Read more" button
    // Calculate truncated text
    final lines = widget.text.split('\n');
    String truncatedText;

    if (lines.length > widget.maxLines) {
      // Truncate by lines
      truncatedText = lines.take(widget.maxLines).join('\n');
    } else {
      // Truncate by characters
      truncatedText = widget.text.substring(0, widget.maxChars);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          truncatedText,
          style: widget.style,
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
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w500,
              ) ?? TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
