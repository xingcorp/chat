import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_chat_app/core/constants/app_dimens.dart';
import 'package:flutter_chat_app/core/theme/app_colors.dart';
import 'package:flutter_chat_app/features/chat/presentation/models/chat_slash_command_engine.dart';
import 'package:flutter_chat_app/features/chat/presentation/models/mention_tracker.dart';
import 'package:flutter_chat_app/features/chat/presentation/widgets/composer/composer_constants.dart';
import 'package:flutter_chat_app/features/chat/presentation/widgets/composer/desktop_composer_toolbar.dart';
import 'package:flutter_chat_app/features/chat/presentation/widgets/composer/formatting_panel.dart';
import 'package:flutter_chat_app/features/chat/presentation/widgets/composer/quill_composer_controller.dart';
import 'package:flutter_chat_app/features/chat/presentation/widgets/composer/quill_mention_composer.dart';
import 'package:flutter_chat_app/l10n/l10n.dart';
import 'package:flutter_chat_app/presentation/blocs/file_attachment/file_attachment_bloc.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/buttons/app_icon_button.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/cards/app_card.dart';
import 'package:flutter_chat_app/shared/domain/entities/chat.dart';

/// Zalo-style desktop message input area.
///
/// Layout (matches Zalo PC screenshot):
/// ```
/// ┌──────────────────────────────────────────────────────────┐
/// │ [Sticker] [Image] [File] [Screenshot] [Aa]   [...]      │
/// ├──────────────────────────────────────────────────────────┤
/// │ [B] [I] [U] [S] | [•] [1.] | [Link] [Clear]  (toggle)  │
/// ├──────────────────────────────────────────────────────────┤
/// │                                                          │
/// │  Nhập @, tin nhắn tới...                      [😊] [👍] │
/// │                                                          │
/// └──────────────────────────────────────────────────────────┘
/// ```
///
/// Desktop only. Mobile keeps the single-row layout.
class DesktopMessageInputArea extends StatefulWidget {
  const DesktopMessageInputArea({
    required this.composerController,
    required this.mentionTracker,
    required this.messageFocusNode,
    required this.members,
    required this.currentUserId,
    required this.onSendMessage,
    required this.onSendLike,
    required this.onImagePressed,
    required this.onCameraPressed,
    required this.onVideoPressed,
    required this.onFilePressed,
    required this.onLocationPressed,
    required this.onStickerPressed,
    required this.onEmojiPressed,
    required this.fileAttachmentBloc,
    required this.slashCommands,
    this.onScreenshotPressed,
    this.onMorePressed,
    this.isEditMode = false,
    super.key,
  });

  final QuillComposerController composerController;
  final MentionTracker mentionTracker;
  final FocusNode messageFocusNode;
  final List<ConversationMember> members;
  final String currentUserId;
  final VoidCallback onSendMessage;
  final VoidCallback onSendLike;
  final VoidCallback onImagePressed;
  final VoidCallback onCameraPressed;
  final VoidCallback onVideoPressed;
  final VoidCallback onFilePressed;
  final VoidCallback onLocationPressed;
  final VoidCallback onStickerPressed;
  final VoidCallback onEmojiPressed;
  final FileAttachmentBloc fileAttachmentBloc;
  final List<SlashCommandOption> slashCommands;
  final VoidCallback? onScreenshotPressed;
  final VoidCallback? onMorePressed;
  final bool isEditMode;

  @override
  State<DesktopMessageInputArea> createState() =>
      _DesktopMessageInputAreaState();
}

class _DesktopMessageInputAreaState extends State<DesktopMessageInputArea> {
  bool _isFormattingExpanded = false;

  void _toggleFormatting() {
    setState(() {
      _isFormattingExpanded = !_isFormattingExpanded;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppCard.outlined(
      margin: EdgeInsets.zero,
      padding: EdgeInsets.zero,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Layer 1: Toolbar (always visible) ──
          DesktopComposerToolbar(
            onStickerPressed: widget.onStickerPressed,
            onEmojiPressed: widget.onEmojiPressed,
            onImagePressed: widget.onImagePressed,
            onCameraPressed: widget.onCameraPressed,
            onVideoPressed: widget.onVideoPressed,
            onFilePressed: widget.onFilePressed,
            onLocationPressed: widget.onLocationPressed,
            onFormatToggle: _toggleFormatting,
            isFormattingExpanded: _isFormattingExpanded,
            onScreenshotPressed: widget.onScreenshotPressed,
            onMorePressed: widget.onMorePressed,
          ),

          // ── Layer 2: Formatting panel (toggle) ──
          // Now connected to the REAL QuillController (not orphaned!).
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: FormattingPanel(
              controller: widget.composerController.quillController,
              onInsertLink: () {},
            ),
            crossFadeState: _isFormattingExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: ComposerConstants.toolbarToggleDuration,
            sizeCurve: Curves.easeInOut,
          ),

          // ── Layer 3: Input area + emoji + like/send ──
          _DesktopInputRow(
            composerController: widget.composerController,
            mentionTracker: widget.mentionTracker,
            messageFocusNode: widget.messageFocusNode,
            members: widget.members,
            currentUserId: widget.currentUserId,
            slashCommands: widget.slashCommands,
            onEmojiPressed: widget.onEmojiPressed,
            onSendMessage: widget.onSendMessage,
            onSendLike: widget.onSendLike,
            fileAttachmentBloc: widget.fileAttachmentBloc,
            isEditMode: widget.isEditMode,
            isDark: isDark,
          ),
        ],
      ),
    );
  }
}

/// The bottom input row: [QuillMentionComposer] + [Emoji] + [Like/Send].
///
/// Like Zalo: when text is empty → show 👍 Like button.
/// When text is present → show Send button.
class _DesktopInputRow extends StatefulWidget {
  const _DesktopInputRow({
    required this.composerController,
    required this.mentionTracker,
    required this.messageFocusNode,
    required this.members,
    required this.currentUserId,
    required this.slashCommands,
    required this.onEmojiPressed,
    required this.onSendMessage,
    required this.onSendLike,
    required this.fileAttachmentBloc,
    required this.isEditMode,
    required this.isDark,
  });

  final QuillComposerController composerController;
  final MentionTracker mentionTracker;
  final FocusNode messageFocusNode;
  final List<ConversationMember> members;
  final String currentUserId;
  final List<SlashCommandOption> slashCommands;
  final VoidCallback onEmojiPressed;
  final VoidCallback onSendMessage;
  final VoidCallback onSendLike;
  final FileAttachmentBloc fileAttachmentBloc;
  final bool isEditMode;
  final bool isDark;

  @override
  State<_DesktopInputRow> createState() => _DesktopInputRowState();
}

class _DesktopInputRowState extends State<_DesktopInputRow> {
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    widget.composerController.quillController.addListener(_onTextChanged);
    _hasText = !widget.composerController.isEmpty;
  }

  @override
  void didUpdateWidget(covariant _DesktopInputRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.composerController != widget.composerController) {
      oldWidget.composerController.quillController
          .removeListener(_onTextChanged);
      widget.composerController.quillController.addListener(_onTextChanged);
    }
  }

  @override
  void dispose() {
    widget.composerController.quillController.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onTextChanged() {
    final hasText = !widget.composerController.isEmpty;
    if (hasText != _hasText && mounted) {
      setState(() => _hasText = hasText);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // ── Text input (expands) ──
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(
              left: AppDimens.paddingSmall,
              bottom: AppDimens.paddingXSmall,
            ),
            child: QuillMentionComposer(
              composerController: widget.composerController,
              mentionTracker: widget.mentionTracker,
              focusNode: widget.messageFocusNode,
              members: widget.members,
              currentUserId: widget.currentUserId,
              slashCommands: widget.slashCommands,
              placeholder: context.l10n.typeMessage,
              onSend: widget.onSendMessage,
            ),
          ),
        ),

        // ── Right side: Emoji + Like/Send ──
        Padding(
          padding: const EdgeInsets.only(
            right: AppDimens.paddingXSmall,
            bottom: AppDimens.paddingSmall,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Emoji button
              _InputSideIcon(
                icon: Icons.emoji_emotions_outlined,
                tooltip: context.l10n.stickers,
                color: widget.isDark
                    ? AppColors.iconDarkMode
                    : AppColors.icon,
                onPressed: widget.onEmojiPressed,
              ),
              const SizedBox(height: AppDimens.spaceXSmall),
              // Like / Send button
              BlocBuilder<FileAttachmentBloc, FileAttachmentState>(
                bloc: widget.fileAttachmentBloc,
                buildWhen: (prev, curr) =>
                    prev.hasFiles != curr.hasFiles,
                builder: (context, attachState) {
                  final canSend = _hasText || attachState.hasFiles;

                  if (widget.isEditMode) {
                    return AppIconButton(
                      icon: Icons.check,
                      onPressed: canSend
                          ? widget.onSendMessage
                          : null,
                      tooltip: context.l10n.save,
                    );
                  }

                  if (canSend) {
                    return _InputSideIcon(
                      icon: Icons.send_rounded,
                      tooltip: context.l10n.send,
                      color: AppColors.primary,
                      onPressed: widget.onSendMessage,
                    );
                  }

                  // Empty → Like button (Zalo-style)
                  return _InputSideIcon(
                    icon: Icons.thumb_up,
                    tooltip: 'Like',
                    color: AppColors.primary,
                    onPressed: widget.onSendLike,
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Small icon button used inside the input row (emoji, like, send).
class _InputSideIcon extends StatelessWidget {
  const _InputSideIcon({
    required this.icon,
    required this.tooltip,
    required this.color,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final Color color;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(
          ComposerConstants.formatButtonRadius,
        ),
        child: SizedBox(
          width: ComposerConstants.formatButtonSize,
          height: ComposerConstants.formatButtonSize,
          child: Icon(
            icon,
            size: ComposerConstants.desktopToolbarIconSize,
            color: color,
          ),
        ),
      ),
    );
  }
}
