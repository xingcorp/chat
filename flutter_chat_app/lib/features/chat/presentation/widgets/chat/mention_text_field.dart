import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_chat_app/core/services/emoji_shortcode_service.dart';
import 'package:flutter_chat_app/features/chat/presentation/models/chat_slash_command_engine.dart';
import 'package:flutter_chat_app/l10n/l10n.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/media/app_avatar.dart';
import 'package:flutter_chat_app/shared/domain/entities/chat.dart';
import 'package:flutter_portal/flutter_portal.dart';

/// Special member class for "@all" mention - mentions everyone in the group
class _AllConversationMember extends ConversationMember {
  _AllConversationMember()
      : super(
          id: 'all',
          userId: 'all',
          fullName: 'All',
        );
}

enum _SuggestionMode {
  mention,
  slashCommand,
  shortcode,
}

class MentionTextEditingController extends TextEditingController {
  MentionTextEditingController({
    super.text,
    Map<String, String> mentionNameById = const <String, String>{},
  }) : _mentionNameById = Map<String, String>.from(mentionNameById);

  Map<String, String> _mentionNameById;

  void updateMentions(Map<String, String> mentionNameById) {
    _mentionNameById = Map<String, String>.from(mentionNameById);
    notifyListeners();
  }

  void upsertMention(String userId, String fullName) {
    final id = userId.trim();
    final name = fullName.trim();
    if (id.isEmpty || name.isEmpty) return;
    _mentionNameById[id] = name;
    notifyListeners();
  }

  Map<String, String> get mentionNameById =>
      Map<String, String>.unmodifiable(_mentionNameById);

  String toBackendMentionFormat(String input) {
    var result = input;

    final entries = _mentionNameById.entries.toList()
      ..sort((a, b) => b.value.length.compareTo(a.value.length));

    for (final e in entries) {
      final name = e.value.trim();
      if (name.isEmpty) continue;

      final escaped = RegExp.escape('@$name');
      result = result.replaceAllMapped(
        RegExp('(^|\\s)($escaped)(?=\\s|)'),
        (m) => '${m.group(1)}[@${e.key}]',
      );
    }

    return result;
  }
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
  static const double _kOverlayMaxHeight = 200;
  static const double _kTileHeight = 62;

  // Mention state
  bool _showMentionList = false;
  int _mentionStartIndex = -1;
  int _mentionEndIndex = -1;
  String _currentMentionQuery = '';
  _SuggestionMode? _suggestionMode;
  List<ConversationMember> _filteredMembers = [];
  List<SlashCommandOption> _filteredSlashCommands = [];
  List<EmojiShortcodeMatch> _filteredShortcodes = [];
  int _selectedMentionIndex = 0;

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
    _checkForMention();
  }

  void _onFocusChanged() {
    final hasFocus = widget.focusNode?.hasFocus ?? false;
    if (!hasFocus && _showMentionList) {
      setState(() {
        _showMentionList = false;
        _currentMentionQuery = '';
        _suggestionMode = null;
        _filteredSlashCommands = const <SlashCommandOption>[];
        _filteredMembers = const <ConversationMember>[];
      });
    }
  }

  /// Check if user is typing a mention (@username) or slash command (/command)
  void _checkForMention() {
    final text = widget.controller.text;
    final cursorPos = widget.controller.selection.baseOffset;

    if (cursorPos < 0) return;

    if (_checkForMentionSuggestions(text, cursorPos)) return;
    if (_checkForSlashCommandSuggestions(text, cursorPos)) return;
    if (_checkForShortcodeSuggestions(text, cursorPos)) return;
    _hideSuggestions();
  }

  bool _checkForMentionSuggestions(String text, int cursorPos) {
    int atIndex = -1;
    for (int i = cursorPos - 1; i >= 0; i--) {
      if (text[i] == '@') {
        // Completed mentions look like [@userId]
        if (i == 0 || text[i - 1] != '[') {
          atIndex = i;
          break;
        }
      }

      if (text[i] == ' ' || text[i] == '\n') {
        break;
      }
    }

    if (atIndex < 0 || cursorPos <= atIndex) {
      return false;
    }

    final query = text.substring(atIndex + 1, cursorPos).toLowerCase();

    final allMembers = <ConversationMember>[];
    if (widget.members.length >= 3 &&
        (query.isEmpty || 'all'.startsWith(query))) {
      allMembers.add(_createAllMember());
    }

    final filtered = widget.members
        .where((member) =>
            member.userId != widget.currentUserId &&
            _matchesMemberQuery(member, query))
        .toList(growable: false);
    final combinedMembers = <ConversationMember>[...allMembers, ...filtered];

    if (combinedMembers.isEmpty) {
      return false;
    }

    setState(() {
      _showMentionList = true;
      _suggestionMode = _SuggestionMode.mention;
      _mentionStartIndex = atIndex;
      _mentionEndIndex = cursorPos;
      _currentMentionQuery = query;
      _filteredMembers = combinedMembers;
      _filteredSlashCommands = const <SlashCommandOption>[];
      _selectedMentionIndex = 0;
    });
    return true;
  }

  bool _checkForSlashCommandSuggestions(String text, int cursorPos) {
    if (widget.slashCommands.isEmpty) {
      return false;
    }

    final triggerMatch = _matchSlashCommandTrigger(text, cursorPos);
    if (triggerMatch == null) {
      return false;
    }

    final slashIndex = triggerMatch.key;
    final query = triggerMatch.value;
    final filtered = widget.slashCommands
        .where((command) => command.name.toLowerCase().contains(query))
        .toList(growable: false);

    if (filtered.isEmpty) {
      return false;
    }

    setState(() {
      _showMentionList = true;
      _suggestionMode = _SuggestionMode.slashCommand;
      _mentionStartIndex = slashIndex;
      _mentionEndIndex = cursorPos;
      _currentMentionQuery = query;
      _filteredMembers = const <ConversationMember>[];
      _filteredSlashCommands = filtered;
      _selectedMentionIndex = 0;
    });
    return true;
  }

  MapEntry<int, String>? _matchSlashCommandTrigger(String text, int cursorPos) {
    if (cursorPos <= 0 || text.isEmpty) return null;
    final lineStart = text.lastIndexOf('\n', cursorPos - 1);
    final segmentStart = lineStart == -1 ? 0 : lineStart + 1;
    if (segmentStart >= cursorPos) {
      return null;
    }

    final segment = text.substring(segmentStart, cursorPos);
    final match = RegExp(r'^\s*/([a-zA-Z]*)$').firstMatch(segment);
    if (match == null) {
      return null;
    }

    final slashOffset = segment.indexOf('/');
    if (slashOffset < 0) {
      return null;
    }

    final query = (match.group(1) ?? '').toLowerCase();
    return MapEntry<int, String>(segmentStart + slashOffset, query);
  }

  /// Check if user is typing a shortcode (:smile, :heart, ...)
  /// Pattern: Discord/Telegram/Slack — `:` + 2 chars → show emoji suggestions
  bool _checkForShortcodeSuggestions(String text, int cursorPos) {
    if (cursorPos <= 0) return false;

    // Tìm dấu `:` gần nhất phía trước cursor
    final textBeforeCursor = text.substring(0, cursorPos);
    final lastColonIndex = textBeforeCursor.lastIndexOf(':');

    if (lastColonIndex < 0) return false;

    // `:` phải ở đầu text hoặc sau whitespace (tránh match trong URL, time)
    if (lastColonIndex > 0 &&
        textBeforeCursor[lastColonIndex - 1] != ' ' &&
        textBeforeCursor[lastColonIndex - 1] != '\n') {
      return false;
    }

    // Lấy query (phần giữa `:` và cursor)
    final query = textBeforeCursor.substring(lastColonIndex + 1);

    // Không chứa space/newline (nếu có → không phải shortcode)
    if (query.contains(' ') || query.contains('\n')) return false;

    // Cần ít nhất 2 ký tự để search (Discord/Slack standard)
    if (query.length < 2) return false;

    final results = EmojiShortcodeService.search(query, limit: 6);
    if (results.isEmpty) return false;

    setState(() {
      _showMentionList = true;
      _suggestionMode = _SuggestionMode.shortcode;
      _mentionStartIndex = lastColonIndex;
      _mentionEndIndex = cursorPos;
      _currentMentionQuery = query;
      _filteredMembers = const <ConversationMember>[];
      _filteredSlashCommands = const <SlashCommandOption>[];
      _filteredShortcodes = results;
      _selectedMentionIndex = 0;
    });
    return true;
  }

  void _hideSuggestions() {
    if (!_showMentionList) return;
    setState(() {
      _showMentionList = false;
      _suggestionMode = null;
      _mentionStartIndex = -1;
      _mentionEndIndex = -1;
      _currentMentionQuery = '';
      _filteredMembers = const <ConversationMember>[];
      _filteredSlashCommands = const <SlashCommandOption>[];
      _filteredShortcodes = const <EmojiShortcodeMatch>[];
      _selectedMentionIndex = 0;
    });
  }

  /// Insert selected mention into text
  void _insertMention(ConversationMember member) {
    final text = widget.controller.text;
    var cursorPos = widget.controller.selection.baseOffset;
    if (cursorPos < 0 || cursorPos > text.length) {
      cursorPos = _mentionEndIndex;
    }

    final mentionStart = _mentionStartIndex;
    if (mentionStart < 0 || mentionStart > text.length) return;
    if (cursorPos < mentionStart || cursorPos > text.length) {
      cursorPos = text.length;
    }

    // Replace from '@' to cursor with mention display format @FullName
    final before = text.substring(0, mentionStart);
    final after = text.substring(cursorPos);

    final localizedAllName = context.l10n.mentionAllDisplayName;
    final name = member is _AllConversationMember
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
    final focusNode = widget.focusNode;
    if (focusNode != null) {
      FocusScope.of(context).requestFocus(focusNode);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!focusNode.hasFocus) FocusScope.of(context).requestFocus(focusNode);
        widget.controller.selection =
            TextSelection.collapsed(offset: caretOffset);
      });
    }
  }

  void _insertSlashCommand(SlashCommandOption command) {
    final text = widget.controller.text;
    var cursorPos = widget.controller.selection.baseOffset;
    if (cursorPos < 0 || cursorPos > text.length) {
      cursorPos = _mentionEndIndex;
    }

    final slashStart = _mentionStartIndex;
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

    final focusNode = widget.focusNode;
    if (focusNode != null) {
      FocusScope.of(context).requestFocus(focusNode);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!focusNode.hasFocus) FocusScope.of(context).requestFocus(focusNode);
        widget.controller.selection = TextSelection.collapsed(
          offset: caretOffset,
        );
      });
    }
  }

  /// Insert selected emoji shortcode into text
  /// Replace `:query` with emoji character + space
  void _insertShortcode(EmojiShortcodeMatch match) {
    final text = widget.controller.text;
    var cursorPos = widget.controller.selection.baseOffset;
    if (cursorPos < 0 || cursorPos > text.length) {
      cursorPos = _mentionEndIndex;
    }

    final colonStart = _mentionStartIndex;
    if (colonStart < 0 || colonStart > text.length) return;
    if (cursorPos < colonStart || cursorPos > text.length) {
      cursorPos = text.length;
    }

    // Replace `:query` bằng emoji character + space
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

    final focusNode = widget.focusNode;
    if (focusNode != null) {
      FocusScope.of(context).requestFocus(focusNode);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!focusNode.hasFocus) FocusScope.of(context).requestFocus(focusNode);
        widget.controller.selection =
            TextSelection.collapsed(offset: caretOffset);
      });
    }
  }

  KeyEventResult _handleSuggestionKeyEvent(FocusNode _, KeyEvent event) {
    if (!_showMentionList || event is! KeyDownEvent) {
      return KeyEventResult.ignored;
    }

    final totalItems = switch (_suggestionMode) {
      _SuggestionMode.mention => _filteredMembers.length,
      _SuggestionMode.slashCommand => _filteredSlashCommands.length,
      _SuggestionMode.shortcode => _filteredShortcodes.length,
      null => 0,
    };
    if (totalItems == 0) {
      return KeyEventResult.ignored;
    }

    if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      setState(() {
        _selectedMentionIndex = (_selectedMentionIndex + 1) % totalItems;
      });
      return KeyEventResult.handled;
    }

    if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      setState(() {
        _selectedMentionIndex =
            (_selectedMentionIndex - 1 + totalItems) % totalItems;
      });
      return KeyEventResult.handled;
    }

    if (event.logicalKey == LogicalKeyboardKey.escape) {
      _hideSuggestions();
      return KeyEventResult.handled;
    }

    if (event.logicalKey == LogicalKeyboardKey.enter &&
        !HardwareKeyboard.instance.isShiftPressed) {
      switch (_suggestionMode) {
        case _SuggestionMode.mention:
          _insertMention(_filteredMembers[_selectedMentionIndex]);
        case _SuggestionMode.slashCommand:
          _insertSlashCommand(_filteredSlashCommands[_selectedMentionIndex]);
        case _SuggestionMode.shortcode:
          _insertShortcode(_filteredShortcodes[_selectedMentionIndex]);
        case null:
          break;
      }
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  /// Create a special "all" member for mentioning everyone in the group
  ConversationMember _createAllMember() {
    return _AllConversationMember();
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

  static const double _kShortcodeTileHeight = 48;

  Widget _buildSuggestionsPanel() {
    final isShortcodeMode = _suggestionMode == _SuggestionMode.shortcode;
    final itemCount = switch (_suggestionMode) {
      _SuggestionMode.mention => _filteredMembers.length,
      _SuggestionMode.slashCommand => _filteredSlashCommands.length,
      _SuggestionMode.shortcode => _filteredShortcodes.length,
      null => 0,
    };
    final tileHeight = isShortcodeMode ? _kShortcodeTileHeight : _kTileHeight;
    final double preferredHeight = math.min(
      _kOverlayMaxHeight,
      itemCount * tileHeight,
    );

    return TextFieldTapRegion(
      child: Material(
        elevation: 4.0,
        borderRadius: BorderRadius.circular(8.0),
        color: Theme.of(context).cardColor,
        clipBehavior: Clip.antiAlias,
        child: SizedBox(
          height: preferredHeight,
          child: ListView.builder(
            padding: EdgeInsets.zero,
            itemExtent: tileHeight,
            itemCount: itemCount,
            itemBuilder: (context, index) => switch (_suggestionMode) {
              _SuggestionMode.mention => _buildMentionSuggestionTile(index),
              _SuggestionMode.slashCommand =>
                _buildSlashCommandSuggestionTile(index),
              _SuggestionMode.shortcode =>
                _buildShortcodeSuggestionTile(index),
              null => const SizedBox.shrink(),
            },
          ),
        ),
      ),
    );
  }

  Widget _buildMentionSuggestionTile(int index) {
    final member = _filteredMembers[index];
    final isSelected = index == _selectedMentionIndex;
    final isAllMention = member is _AllConversationMember;
    final displayName = isAllMention
        ? context.l10n.mentionAllDisplayName
        : (member.fullName ?? context.l10n.unknownUser);
    final avatarUrl = member.avatarUrl?.trim();
    final department = member.departmentName?.trim() ?? '';
    final title = member.titleName?.trim() ?? '';
    final subtitle = isAllMention
        ? context.l10n.mentionEveryone
        : [
            if (department.isNotEmpty) department,
            if (title.isNotEmpty) title,
          ].join(' - ');
    final titleStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        );

    return ListTile(
      dense: false,
      selected: isSelected,
      leading: isAllMention
          ? Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.people_outline,
                color: Colors.white,
                size: 18,
              ),
            )
          : ((avatarUrl?.isNotEmpty ?? false)
              ? AppAvatar.network(
                  imageUrl: avatarUrl!,
                  size: AvatarSize.small,
                )
              : AppAvatar.initials(
                  name: displayName,
                  size: AvatarSize.small,
                )),
      title: _buildHighlightedName(
        displayName,
        _currentMentionQuery,
        titleStyle,
        Theme.of(context).colorScheme.primary,
      ),
      subtitle: subtitle.isNotEmpty
          ? Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.color
                        ?.withValues(alpha: 0.7),
                  ),
            )
          : null,
      trailing: Icon(
        isAllMention ? Icons.people_outline : Icons.alternate_email,
        size: 18,
        color: Theme.of(context).colorScheme.primary,
      ),
      onTap: () => _insertMention(member),
    );
  }

  Widget _buildSlashCommandSuggestionTile(int index) {
    final command = _filteredSlashCommands[index];
    final isSelected = index == _selectedMentionIndex;
    final titleStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        );

    return ListTile(
      dense: false,
      selected: isSelected,
      leading: CircleAvatar(
        radius: 16,
        backgroundColor:
            Theme.of(context).colorScheme.primary.withValues(alpha: 0.14),
        child: Icon(
          _commandIconFor(command.name),
          size: 18,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
      title: _buildHighlightedName(
        '/${command.name}',
        _currentMentionQuery,
        titleStyle,
        Theme.of(context).colorScheme.primary,
      ),
      subtitle: Text(
        command.description,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.color
                  ?.withValues(alpha: 0.7),
            ),
      ),
      trailing: Text(
        command.usage,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
            ),
      ),
      onTap: () => _insertSlashCommand(command),
    );
  }

  Widget _buildShortcodeSuggestionTile(int index) {
    final match = _filteredShortcodes[index];
    final isSelected = index == _selectedMentionIndex;
    final theme = Theme.of(context);

    return InkWell(
      onTap: () => _insertShortcode(match),
      child: Container(
        color: isSelected
            ? theme.colorScheme.primary.withValues(alpha: 0.08)
            : null,
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
        child: Row(
          children: [
            Text(
              match.emoji,
              style: const TextStyle(fontSize: 24.0),
            ),
            const SizedBox(width: 10.0),
            Expanded(
              child: Text(
                ':${match.shortcode}:',
                style: TextStyle(
                  fontSize: 14.0,
                  fontWeight:
                      isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: theme.textTheme.bodyMedium?.color
                      ?.withValues(alpha: 0.7),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _commandIconFor(String commandName) {
    switch (commandName.trim().toLowerCase()) {
      case ChatSlashCommandEngine.shrugCommand:
        return Icons.sentiment_satisfied_alt_rounded;
      case ChatSlashCommandEngine.tableflipCommand:
        return Icons.flip;
      case ChatSlashCommandEngine.meCommand:
        return Icons.person_outline_rounded;
      case ChatSlashCommandEngine.muteCommand:
        return Icons.notifications_off_outlined;
      default:
        return Icons.bolt_rounded;
    }
  }

  Widget _buildHighlightedName(
    String fullName,
    String query,
    TextStyle? baseStyle,
    Color highlightColor,
  ) {
    final normalizedQuery = query.trim().toLowerCase();
    if (normalizedQuery.isEmpty) {
      return Text(
        fullName,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: baseStyle,
      );
    }

    final lowerName = fullName.toLowerCase();
    final matchIndex = lowerName.indexOf(normalizedQuery);
    if (matchIndex < 0) {
      return Text(
        fullName,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: baseStyle,
      );
    }

    final before = fullName.substring(0, matchIndex);
    final match = fullName.substring(
      matchIndex,
      matchIndex + normalizedQuery.length,
    );
    final after = fullName.substring(matchIndex + normalizedQuery.length);

    return RichText(
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      text: TextSpan(
        style: baseStyle,
        children: [
          TextSpan(text: before),
          TextSpan(
            text: match,
            style: baseStyle?.copyWith(
              color: highlightColor,
              fontWeight: FontWeight.w700,
            ),
          ),
          TextSpan(text: after),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final itemCount = switch (_suggestionMode) {
      _SuggestionMode.mention => _filteredMembers.length,
      _SuggestionMode.slashCommand => _filteredSlashCommands.length,
      _SuggestionMode.shortcode => _filteredShortcodes.length,
      null => 0,
    };
    final shouldShow = _showMentionList && itemCount > 0;

    return PortalTarget(
      visible: shouldShow,
      anchor: const Aligned(
        follower: Alignment.bottomLeft,
        target: Alignment.topLeft,
        widthFactor: 1,
      ),
      portalFollower: shouldShow ? _buildSuggestionsPanel() : null,
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
