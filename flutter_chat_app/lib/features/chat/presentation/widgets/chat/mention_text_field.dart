import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_chat_app/core/services/emoji_shortcode_service.dart';
import 'package:flutter_chat_app/features/chat/presentation/models/chat_slash_command_engine.dart';
import 'package:flutter_chat_app/features/chat/presentation/models/mention_tracker.dart';
import 'package:flutter_chat_app/features/chat/presentation/models/suggestion_trigger_detector.dart';
import 'package:flutter_chat_app/features/chat/presentation/widgets/chat/suggestion_overlay_panel.dart';
import 'package:flutter_chat_app/l10n/l10n.dart';
import 'package:flutter_chat_app/shared/domain/entities/chat.dart';
import 'package:flutter_portal/flutter_portal.dart';

/// TextEditingController with mention tracking.
///
/// Delegates mention-related logic to [MentionTracker].
class MentionTextEditingController extends TextEditingController {
  MentionTextEditingController({
    super.text,
    Map<String, String> mentionNameById = const <String, String>{},
  }) : _tracker = MentionTracker(mentionNameById: mentionNameById);

  final MentionTracker _tracker;

  /// The underlying mention tracker — exposed for reuse.
  MentionTracker get tracker => _tracker;

  void updateMentions(Map<String, String> mentionNameById) {
    _tracker.updateMentions(mentionNameById);
    notifyListeners();
  }

  void upsertMention(String userId, String fullName) {
    _tracker.upsertMention(userId, fullName);
    notifyListeners();
  }

  Map<String, String> get mentionNameById => _tracker.mentionNameById;

  String toBackendMentionFormat(String input) =>
      _tracker.toBackendMentionFormat(input);
}

/// **MentionTextField - Autocomplete @mention support**
///
/// TextField with real-time mention detection and autocomplete dropdown.
///
/// **Features:**
/// - Detects '@' character and shows member list
/// - Fuzzy search by name
/// - Keyboard navigation (up/down/enter)
/// - Inserts mention as [@userId] format
/// - Supports multiple mentions in one message
/// - Responsive positioning (above/below input)
///
/// **Backend Format:**
/// - Input: "Hello @John, check [@user-id-123]"
/// - Sent to backend: "Hello [@user-id-123], check [@user-id-456]"
/// - Backend auto-parses and returns in `mentionTo` field
class MentionTextField extends StatefulWidget {
  final TextEditingController controller;
  final List<ConversationMember> members;
  final String? currentUserId;
  final String? hint;
  final int minLines;
  final int maxLines;
  final List<SlashCommandOption> slashCommands;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onChanged;
  final FocusNode? focusNode;

  const MentionTextField({
    super.key,
    required this.controller,
    required this.members,
    this.currentUserId,
    this.hint,
    this.minLines = 1,
    this.maxLines = 5,
    this.slashCommands = const <SlashCommandOption>[],
    this.onSubmitted,
    this.onChanged,
    this.focusNode,
  });

  @override
  State<MentionTextField> createState() => _MentionTextFieldState();
}

class _MentionTextFieldState extends State<MentionTextField> {
  final _triggerDetector = const SuggestionTriggerDetector();

  // Suggestion state
  bool _showSuggestions = false;
  SuggestionTriggerResult? _currentTrigger;
  List<ConversationMember> _filteredMembers = [];
  List<SlashCommandOption> _filteredSlashCommands = [];
  List<EmojiShortcodeMatch> _filteredShortcodes = [];
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
    widget.focusNode?.addListener(_onFocusChanged);
  }

  @override
  void didUpdateWidget(covariant MentionTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onTextChanged);
      widget.controller.addListener(_onTextChanged);
    }

    if (oldWidget.focusNode != widget.focusNode) {
      oldWidget.focusNode?.removeListener(_onFocusChanged);
      widget.focusNode?.addListener(_onFocusChanged);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    widget.focusNode?.removeListener(_onFocusChanged);
    super.dispose();
  }

  void _onTextChanged() {
    widget.onChanged?.call();
    _checkForTriggers();
  }

  void _onFocusChanged() {
    final hasFocus = widget.focusNode?.hasFocus ?? false;
    if (!hasFocus && _showSuggestions) {
      _hideSuggestions();
    }
  }

  void _checkForTriggers() {
    final text = widget.controller.text;
    final cursorPos = widget.controller.selection.baseOffset;

    final result = _triggerDetector.detect(text, cursorPos);
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
        .where((command) =>
            command.name.toLowerCase().contains(result.query))
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

  /// Insert selected mention into text
  void _insertMention(ConversationMember member) {
    final trigger = _currentTrigger;
    if (trigger == null) return;

    final text = widget.controller.text;
    var cursorPos = widget.controller.selection.baseOffset;
    if (cursorPos < 0 || cursorPos > text.length) {
      cursorPos = trigger.triggerEndIndex;
    }

    final mentionStart = trigger.triggerStartIndex;
    if (mentionStart < 0 || mentionStart > text.length) return;
    if (cursorPos < mentionStart || cursorPos > text.length) {
      cursorPos = text.length;
    }

    // Replace from '@' to cursor with mention display format @FullName
    final before = text.substring(0, mentionStart);
    final after = text.substring(cursorPos);

    final localizedAllName = context.l10n.mentionAllDisplayName;
    final name = member is AllConversationMember
        ? localizedAllName
        : (member.fullName ?? member.displayName ?? '').trim();
    final display = name.isNotEmpty ? '@$name' : '@${member.userId}';
    final mentionText = '$display ';
    final newText = before + mentionText + after;

    if (widget.controller is MentionTextEditingController && name.isNotEmpty) {
      (widget.controller as MentionTextEditingController)
          .upsertMention(member.userId, name);
    }

    widget.controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(
        offset: before.length + mentionText.length,
      ),
    );

    final caretOffset = before.length + mentionText.length;

    _hideSuggestions();

    // Keep cursor/focus in input after selecting from overlay.
    _restoreFocus(caretOffset);
  }

  void _insertSlashCommand(SlashCommandOption command) {
    final trigger = _currentTrigger;
    if (trigger == null) return;

    final text = widget.controller.text;
    var cursorPos = widget.controller.selection.baseOffset;
    if (cursorPos < 0 || cursorPos > text.length) {
      cursorPos = trigger.triggerEndIndex;
    }

    final slashStart = trigger.triggerStartIndex;
    if (slashStart < 0 || slashStart > text.length) return;
    if (cursorPos < slashStart || cursorPos > text.length) {
      cursorPos = text.length;
    }

    final before = text.substring(0, slashStart);
    final after = text.substring(cursorPos);
    final commandText = '/${command.name} ';
    final newText = before + commandText + after;
    final caretOffset = before.length + commandText.length;

    widget.controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: caretOffset),
    );

    _hideSuggestions();
    _restoreFocus(caretOffset);
  }

  /// Insert selected emoji shortcode into text
  /// Replace `:query` with emoji character + space
  void _insertShortcode(EmojiShortcodeMatch match) {
    final trigger = _currentTrigger;
    if (trigger == null) return;

    final text = widget.controller.text;
    var cursorPos = widget.controller.selection.baseOffset;
    if (cursorPos < 0 || cursorPos > text.length) {
      cursorPos = trigger.triggerEndIndex;
    }

    final colonStart = trigger.triggerStartIndex;
    if (colonStart < 0 || colonStart > text.length) return;
    if (cursorPos < colonStart || cursorPos > text.length) {
      cursorPos = text.length;
    }

    final before = text.substring(0, colonStart);
    final after = text.substring(cursorPos);
    final emojiText = '${match.emoji} ';
    final newText = before + emojiText + after;
    final caretOffset = before.length + emojiText.length;

    widget.controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: caretOffset),
    );

    _hideSuggestions();
    _restoreFocus(caretOffset);
  }

  void _restoreFocus(int caretOffset) {
    final focusNode = widget.focusNode;
    if (focusNode != null) {
      FocusScope.of(context).requestFocus(focusNode);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!focusNode.hasFocus) {
          FocusScope.of(context).requestFocus(focusNode);
        }
        widget.controller.selection =
            TextSelection.collapsed(offset: caretOffset);
      });
    }
  }

  KeyEventResult _handleSuggestionKeyEvent(FocusNode _, KeyEvent event) {
    if (!_showSuggestions || event is! KeyDownEvent) {
      return KeyEventResult.ignored;
    }

    final trigger = _currentTrigger;
    if (trigger == null) return KeyEventResult.ignored;

    final totalItems = switch (trigger.mode) {
      SuggestionMode.mention => _filteredMembers.length,
      SuggestionMode.slashCommand => _filteredSlashCommands.length,
      SuggestionMode.shortcode => _filteredShortcodes.length,
    };
    if (totalItems == 0) {
      return KeyEventResult.ignored;
    }

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

    return KeyEventResult.ignored;
  }

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
        onKeyEvent: _handleSuggestionKeyEvent,
        child: TextField(
          controller: widget.controller,
          focusNode: widget.focusNode,
          minLines: widget.minLines,
          maxLines: widget.maxLines,
          keyboardType: TextInputType.multiline,
          decoration: InputDecoration(
            hintText: widget.hint,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12.0,
              vertical: 8.0,
            ),
          ),
          onSubmitted: widget.onSubmitted,
          textInputAction: TextInputAction.newline,
        ),
      ),
    );
  }
}
