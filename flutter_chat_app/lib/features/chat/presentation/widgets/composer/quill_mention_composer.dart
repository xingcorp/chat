import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_chat_app/core/services/emoji_shortcode_service.dart';
import 'package:flutter_chat_app/features/chat/presentation/models/chat_slash_command_engine.dart';
import 'package:flutter_chat_app/features/chat/presentation/models/mention_tracker.dart';
import 'package:flutter_chat_app/features/chat/presentation/models/suggestion_trigger_detector.dart';
import 'package:flutter_chat_app/features/chat/presentation/widgets/chat/suggestion_overlay_panel.dart';
import 'package:flutter_chat_app/features/chat/presentation/widgets/composer/composer_constants.dart';
import 'package:flutter_chat_app/features/chat/presentation/widgets/composer/composer_theme.dart';
import 'package:flutter_chat_app/features/chat/presentation/widgets/composer/quill_composer_controller.dart';
import 'package:flutter_chat_app/l10n/l10n.dart';
import 'package:flutter_chat_app/shared/domain/entities/chat.dart';
import 'package:flutter_portal/flutter_portal.dart';
import 'package:flutter_quill/flutter_quill.dart';

/// Rich text input with @mention, /slash command, and :emoji shortcode support.
///
/// Replaces [MentionTextField] by combining:
/// - [QuillEditor] for rich text editing (bold, italic, lists, links, etc.)
/// - [SuggestionTriggerDetector] for @mention, /slash, :shortcode detection
/// - [SuggestionOverlayPanel] for autocomplete overlay
/// - [MentionTracker] for mention tracking
///
/// The parent must provide a [QuillComposerController] and [MentionTracker]
/// so that send/draft/edit logic can access them externally.
class QuillMentionComposer extends StatefulWidget {
  const QuillMentionComposer({
    required this.composerController,
    required this.mentionTracker,
    required this.focusNode,
    required this.members,
    this.currentUserId,
    this.slashCommands = const <SlashCommandOption>[],
    this.placeholder,
    this.onChanged,
    this.onSend,
    this.minHeight = ComposerConstants.desktopEditorMinHeight,
    this.maxHeight = ComposerConstants.desktopEditorMaxHeight,
    super.key,
  });

  /// The Quill controller that wraps [QuillController].
  final QuillComposerController composerController;

  /// Tracks mentions for backend format conversion.
  final MentionTracker mentionTracker;

  /// Focus node for the editor — owned by the parent.
  final FocusNode focusNode;

  /// Members available for @mention autocomplete.
  final List<ConversationMember> members;

  /// Current user ID — excluded from mention suggestions.
  final String? currentUserId;

  /// Slash commands available for /command autocomplete.
  final List<SlashCommandOption> slashCommands;

  /// Placeholder text shown when editor is empty.
  final String? placeholder;

  /// Called whenever the editor content changes.
  final VoidCallback? onChanged;

  /// Called when user presses Enter to send (desktop only).
  /// If null, Enter-to-send is disabled.
  final VoidCallback? onSend;

  /// Minimum height constraint for the editor.
  final double minHeight;

  /// Maximum height constraint for the editor.
  final double maxHeight;

  @override
  State<QuillMentionComposer> createState() => _QuillMentionComposerState();
}

class _QuillMentionComposerState extends State<QuillMentionComposer> {
  final _triggerDetector = const SuggestionTriggerDetector();

  StreamSubscription<void>? _changeSub;

  // Suggestion state
  bool _showSuggestions = false;
  SuggestionTriggerResult? _currentTrigger;
  List<ConversationMember> _filteredMembers = [];
  List<SlashCommandOption> _filteredSlashCommands = [];
  List<EmojiShortcodeMatch> _filteredShortcodes = [];
  int _selectedIndex = 0;

  QuillController get _quillController =>
      widget.composerController.quillController;

  /// Whether the current platform uses desktop-style Enter-to-send.
  static bool get _isDesktopPlatform =>
      defaultTargetPlatform == TargetPlatform.windows ||
      defaultTargetPlatform == TargetPlatform.macOS ||
      defaultTargetPlatform == TargetPlatform.linux;

  @override
  void initState() {
    super.initState();
    _changeSub = widget.composerController.onDocumentChanged.listen((_) {
      _onContentChanged();
    });
  }

  @override
  void didUpdateWidget(covariant QuillMentionComposer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.composerController != widget.composerController) {
      _changeSub?.cancel();
      _changeSub = widget.composerController.onDocumentChanged.listen((_) {
        _onContentChanged();
      });
    }
  }

  @override
  void dispose() {
    _changeSub?.cancel();
    super.dispose();
  }

  void _onContentChanged() {
    widget.onChanged?.call();
    _checkForTriggers();
    // Trigger rebuild for parent widgets that depend on isEmpty.
    if (mounted) setState(() {});
  }

  void _checkForTriggers() {
    final plainText = _quillController.document.toPlainText();
    final cursorPos = _quillController.selection.baseOffset;

    final result = _triggerDetector.detect(plainText, cursorPos);
    if (result == null) {
      _hideSuggestions();
      return;
    }

    switch (result.mode) {
      case SuggestionMode.mention:
        _showMentionSuggestions(result);
      case SuggestionMode.slashCommand:
        _showSlashCommandSuggestions(result);
      case SuggestionMode.shortcode:
        _showShortcodeSuggestions(result);
    }
  }

  void _showMentionSuggestions(SuggestionTriggerResult result) {
    final query = result.query;
    final allMembers = <ConversationMember>[];
    if (widget.members.length >= 3 &&
        (query.isEmpty || 'all'.startsWith(query))) {
      allMembers.add(AllConversationMember());
    }

    final filtered = widget.members
        .where((member) =>
            member.userId != widget.currentUserId &&
            _matchesMemberQuery(member, query))
        .toList(growable: false);
    final combinedMembers = <ConversationMember>[...allMembers, ...filtered];

    if (combinedMembers.isEmpty) {
      _hideSuggestions();
      return;
    }

    setState(() {
      _showSuggestions = true;
      _currentTrigger = result;
      _filteredMembers = combinedMembers;
      _filteredSlashCommands = const <SlashCommandOption>[];
      _filteredShortcodes = const <EmojiShortcodeMatch>[];
      _selectedIndex = 0;
    });
  }

  void _showSlashCommandSuggestions(SuggestionTriggerResult result) {
    if (widget.slashCommands.isEmpty) {
      _hideSuggestions();
      return;
    }

    final filtered = widget.slashCommands
        .where(
            (command) => command.name.toLowerCase().contains(result.query))
        .toList(growable: false);

    if (filtered.isEmpty) {
      _hideSuggestions();
      return;
    }

    setState(() {
      _showSuggestions = true;
      _currentTrigger = result;
      _filteredMembers = const <ConversationMember>[];
      _filteredSlashCommands = filtered;
      _filteredShortcodes = const <EmojiShortcodeMatch>[];
      _selectedIndex = 0;
    });
  }

  void _showShortcodeSuggestions(SuggestionTriggerResult result) {
    final results = EmojiShortcodeService.search(result.query, limit: 6);
    if (results.isEmpty) {
      _hideSuggestions();
      return;
    }

    setState(() {
      _showSuggestions = true;
      _currentTrigger = result;
      _filteredMembers = const <ConversationMember>[];
      _filteredSlashCommands = const <SlashCommandOption>[];
      _filteredShortcodes = results;
      _selectedIndex = 0;
    });
  }

  void _hideSuggestions() {
    if (!_showSuggestions) return;
    setState(() {
      _showSuggestions = false;
      _currentTrigger = null;
      _filteredMembers = const <ConversationMember>[];
      _filteredSlashCommands = const <SlashCommandOption>[];
      _filteredShortcodes = const <EmojiShortcodeMatch>[];
      _selectedIndex = 0;
    });
  }

  // ─────────────────── Insertion ───────────────────

  void _insertMention(ConversationMember member) {
    final trigger = _currentTrigger;
    if (trigger == null) return;

    final localizedAllName = context.l10n.mentionAllDisplayName;
    final name = member is AllConversationMember
        ? localizedAllName
        : (member.fullName ?? member.displayName ?? '').trim();
    final display = name.isNotEmpty ? '@$name' : '@${member.userId}';
    final mentionText = '$display ';

    _replaceRange(trigger, mentionText);

    // Track mention for backend format conversion.
    if (name.isNotEmpty) {
      widget.mentionTracker.upsertMention(member.userId, name);
    }
  }

  void _insertSlashCommand(SlashCommandOption command) {
    final trigger = _currentTrigger;
    if (trigger == null) return;
    _replaceRange(trigger, '/${command.name} ');
  }

  void _insertShortcode(EmojiShortcodeMatch match) {
    final trigger = _currentTrigger;
    if (trigger == null) return;
    _replaceRange(trigger, '${match.emoji} ');
  }

  /// Replace the trigger range in the Quill document with [replacement].
  void _replaceRange(SuggestionTriggerResult trigger, String replacement) {
    final start = trigger.triggerStartIndex;
    final length = trigger.triggerEndIndex - start;

    _quillController.replaceText(
      start,
      length,
      replacement,
      TextSelection.collapsed(offset: start + replacement.length),
    );

    _hideSuggestions();

    // Restore focus to the editor.
    if (!widget.focusNode.hasFocus) {
      FocusScope.of(context).requestFocus(widget.focusNode);
    }
  }

  // ─────────────────── Keyboard ───────────────────

  /// Handles keyboard events with the following priority:
  ///
  /// 1. When suggestions are visible:
  ///    - Arrow Up/Down: navigate suggestions
  ///    - Enter: select suggestion
  ///    - Escape: dismiss suggestions
  ///
  /// 2. When suggestions are NOT visible (desktop only):
  ///    - Enter (no Shift): send message
  ///    - Shift+Enter: insert newline (passed to QuillEditor)
  KeyEventResult _handleKeyEvent(FocusNode _, KeyEvent event) {
    if (event is! KeyDownEvent) {
      return KeyEventResult.ignored;
    }

    // Priority 1: Suggestion overlay keyboard handling.
    if (_showSuggestions) {
      final trigger = _currentTrigger;
      if (trigger == null) return KeyEventResult.ignored;

      final totalItems = switch (trigger.mode) {
        SuggestionMode.mention => _filteredMembers.length,
        SuggestionMode.slashCommand => _filteredSlashCommands.length,
        SuggestionMode.shortcode => _filteredShortcodes.length,
      };
      if (totalItems == 0) return KeyEventResult.ignored;

      if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
        setState(() {
          _selectedIndex = (_selectedIndex + 1) % totalItems;
        });
        return KeyEventResult.handled;
      }

      if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
        setState(() {
          _selectedIndex = (_selectedIndex - 1 + totalItems) % totalItems;
        });
        return KeyEventResult.handled;
      }

      if (event.logicalKey == LogicalKeyboardKey.escape) {
        _hideSuggestions();
        return KeyEventResult.handled;
      }

      if (event.logicalKey == LogicalKeyboardKey.enter &&
          !HardwareKeyboard.instance.isShiftPressed) {
        switch (trigger.mode) {
          case SuggestionMode.mention:
            _insertMention(_filteredMembers[_selectedIndex]);
          case SuggestionMode.slashCommand:
            _insertSlashCommand(_filteredSlashCommands[_selectedIndex]);
          case SuggestionMode.shortcode:
            _insertShortcode(_filteredShortcodes[_selectedIndex]);
        }
        return KeyEventResult.handled;
      }
    }

    // Priority 2: Desktop Enter-to-send.
    if (_isDesktopPlatform &&
        widget.onSend != null &&
        event.logicalKey == LogicalKeyboardKey.enter &&
        !HardwareKeyboard.instance.isShiftPressed) {
      widget.onSend?.call();
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  // ─────────────────── Helpers ───────────────────

  bool _matchesMemberQuery(ConversationMember member, String rawQuery) {
    if (rawQuery.isEmpty) return true;
    final query = rawQuery.trim().toLowerCase();
    if (query.isEmpty) return true;

    final fullName = (member.fullName ?? '').toLowerCase();
    final userId = member.userId.toLowerCase();
    final departmentName = (member.departmentName ?? '').toLowerCase();
    final titleName = (member.titleName ?? '').toLowerCase();
    final code = (member.code ?? '').toLowerCase();

    return fullName.contains(query) ||
        userId.contains(query) ||
        departmentName.contains(query) ||
        titleName.contains(query) ||
        code.contains(query);
  }

  // ─────────────────── Build ───────────────────

  @override
  Widget build(BuildContext context) {
    final trigger = _currentTrigger;
    final shouldShow = _showSuggestions && trigger != null;

    return PortalTarget(
      visible: shouldShow,
      anchor: const Aligned(
        follower: Alignment.bottomLeft,
        target: Alignment.topLeft,
        widthFactor: 1,
      ),
      portalFollower: shouldShow
          ? SuggestionOverlayPanel(
              mode: trigger.mode,
              query: trigger.query,
              filteredMembers: _filteredMembers,
              filteredSlashCommands: _filteredSlashCommands,
              filteredShortcodes: _filteredShortcodes,
              selectedIndex: _selectedIndex,
              onMentionSelected: _insertMention,
              onSlashCommandSelected: _insertSlashCommand,
              onShortcodeSelected: _insertShortcode,
            )
          : null,
      child: Focus(
        onKeyEvent: _handleKeyEvent,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: widget.minHeight,
            maxHeight: widget.maxHeight,
          ),
          child: QuillEditor(
            controller: _quillController,
            focusNode: widget.focusNode,
            scrollController: ScrollController(),
            config: QuillEditorConfig(
              placeholder: widget.placeholder,
              autoFocus: false,
              expands: false,
              padding: const EdgeInsets.symmetric(
                horizontal: 12.0,
                vertical: 8.0,
              ),
              customStyles: ComposerTheme.composerStyles(context),
            ),
          ),
        ),
      ),
    );
  }
}
