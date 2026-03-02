import 'dart:math' as math;

import 'package:flutter/material.dart';
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
  List<ConversationMember> _filteredMembers = [];
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
      });
    }
  }

  /// Check if user is typing a mention (@username)
  void _checkForMention() {
    final text = widget.controller.text;
    final cursorPos = widget.controller.selection.baseOffset;

    if (cursorPos < 0) return;

    // Find the last '@' before cursor
    int atIndex = -1;
    for (int i = cursorPos - 1; i >= 0; i--) {
      if (text[i] == '@') {
        // Check if it's a new mention (not already completed)
        // Completed mentions look like [@userId]
        if (i == 0 || text[i - 1] != '[') {
          atIndex = i;
          break;
        }
      }
      // Stop if we hit a space or newline (mention ended)
      if (text[i] == ' ' || text[i] == '\n') {
        break;
      }
    }

    if (atIndex >= 0 && cursorPos > atIndex) {
      // Extract query after '@'
      final query = text.substring(atIndex + 1, cursorPos).toLowerCase();

      // Build member list with @all option (only for group chats)
      List<ConversationMember> allMembers = [];

      // Add @all option for group chats (3 or more members total)
      if (widget.members.length >= 3 &&
          (query.isEmpty || 'all'.startsWith(query))) {
        allMembers.add(_createAllMember());
      }

      // Filter members with query (exclude current user)
      final filtered = widget.members
          .where((m) =>
              m.userId != widget.currentUserId && // Exclude self
              _matchesMemberQuery(m, query))
          .toList();

      // Combine @all + filtered members
      final combinedMembers = [...allMembers, ...filtered];

      if (combinedMembers.isNotEmpty) {
        setState(() {
          _showMentionList = true;
          _mentionStartIndex = atIndex;
          _mentionEndIndex = cursorPos;
          _currentMentionQuery = query;
          _filteredMembers = combinedMembers;
          _selectedMentionIndex = 0;
        });
        return;
      }
    }

    // Hide mention list
    if (_showMentionList) {
      setState(() {
        _showMentionList = false;
        _mentionStartIndex = -1;
        _mentionEndIndex = -1;
        _currentMentionQuery = '';
      });
    }
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

    final name = (member.fullName ?? member.displayName ?? '').trim();
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

    // Hide overlay
    setState(() {
      _showMentionList = false;
      _mentionStartIndex = -1;
      _mentionEndIndex = -1;
      _currentMentionQuery = '';
    });

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

  Widget _buildSuggestionsPanel() {
    final double preferredHeight = math.min(
      _kOverlayMaxHeight,
      _filteredMembers.length * _kTileHeight,
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
            itemExtent: _kTileHeight,
            itemCount: _filteredMembers.length,
            itemBuilder: (context, index) {
              final member = _filteredMembers[index];
              final isSelected = index == _selectedMentionIndex;
              final isAllMention = member is _AllConversationMember;
              final avatarUrl = member.avatarUrl?.trim();
              final department = member.departmentName?.trim() ?? '';
              final title = member.titleName?.trim() ?? '';
              final subtitle = isAllMention
                  ? 'Mention everyone'
                  : [
                      if (department.isNotEmpty) department,
                      if (title.isNotEmpty) title,
                    ].join(' - ');
              final titleStyle =
                  Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.normal,
                      );

              final hasAllMention = _filteredMembers.isNotEmpty &&
                  _filteredMembers.first is _AllConversationMember;

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
                            name: member.fullName ?? 'Unknown',
                            size: AvatarSize.small,
                          )),
                title: _buildHighlightedName(
                  member.fullName ?? 'Unknown',
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
                  hasAllMention && index == 0
                      ? Icons.people_outline
                      : Icons.alternate_email,
                  size: 18,
                  color: Theme.of(context).colorScheme.primary,
                ),
                onTap: () => _insertMention(member),
              );
            },
          ),
        ),
      ),
    );
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
    final shouldShow = _showMentionList && _filteredMembers.isNotEmpty;

    return PortalTarget(
      visible: shouldShow,
      anchor: const Aligned(
        follower: Alignment.bottomLeft,
        target: Alignment.topLeft,
        widthFactor: 1,
      ),
      portalFollower: shouldShow ? _buildSuggestionsPanel() : null,
      child: TextField(
        controller: widget.controller,
        focusNode: widget.focusNode,
        minLines: widget.minLines,
        maxLines: widget.maxLines,
        decoration: InputDecoration(
          hintText: widget.hint,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12.0,
            vertical: 8.0,
          ),
        ),
        onSubmitted: widget.onSubmitted,
        textInputAction: TextInputAction.send,
      ),
    );
  }
}
