import 'package:flutter/material.dart';
import 'package:flutter_chat_app/features/chat/presentation/widgets/composer/action_row.dart';
import 'package:flutter_chat_app/features/chat/presentation/widgets/composer/composer_constants.dart';
import 'package:flutter_chat_app/features/chat/presentation/widgets/composer/formatting_panel.dart';
import 'package:flutter_quill/flutter_quill.dart';

/// Orchestrates the 2-layer toolbar: [ActionRow] (always visible) and
/// [FormattingPanel] (expandable).
///
/// Manages the expand/collapse animation and wires callbacks from the
/// parent composer widget to the child toolbar layers.
class ToolbarOrchestrator extends StatefulWidget {
  const ToolbarOrchestrator({
    required this.controller,
    required this.onEmojiPressed,
    required this.onAttachPressed,
    required this.onInsertLink,
    super.key,
  });

  final QuillController controller;
  final VoidCallback onEmojiPressed;
  final VoidCallback onAttachPressed;
  final VoidCallback onInsertLink;

  @override
  State<ToolbarOrchestrator> createState() => _ToolbarOrchestratorState();
}

class _ToolbarOrchestratorState extends State<ToolbarOrchestrator>
    with SingleTickerProviderStateMixin {
  bool _isFormattingExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── Layer A: Quick actions (always visible) ──
        ActionRow(
          onEmojiPressed: widget.onEmojiPressed,
          onAttachPressed: widget.onAttachPressed,
          onFormatToggle: _toggleFormatting,
          isFormattingExpanded: _isFormattingExpanded,
        ),

        // ── Layer B: Formatting panel (expandable) ──
        AnimatedCrossFade(
          firstChild: const SizedBox.shrink(),
          secondChild: FormattingPanel(
            controller: widget.controller,
            onInsertLink: widget.onInsertLink,
          ),
          crossFadeState: _isFormattingExpanded
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          duration: ComposerConstants.toolbarToggleDuration,
          sizeCurve: Curves.easeInOut,
        ),
      ],
    );
  }

  void _toggleFormatting() {
    setState(() {
      _isFormattingExpanded = !_isFormattingExpanded;
    });
  }
}
