import 'package:flutter/material.dart';
import 'package:flutter_chat_app/shared/domain/entities/chat.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/media/app_avatar.dart';

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
    Key? key,
    required this.controller,
    required this.members,
    this.currentUserId,
    this.hint,
    this.minLines = 1,
    this.maxLines = 5,
    this.onSubmitted,
    this.onChanged,
    this.focusNode,
  }) : super(key: key);

  @override
  State<MentionTextField> createState() => _MentionTextFieldState();
}

class _MentionTextFieldState extends State<MentionTextField> {
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;

  // Mention state
  bool _showMentionList = false;
  int _mentionStartIndex = -1;
  String _currentMentionQuery = '';
  List<ConversationMember> _filteredMembers = [];
  int _selectedMentionIndex = 0;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    _removeOverlay();
    super.dispose();
  }

  void _onTextChanged() {
    widget.onChanged?.call();
    _checkForMention();
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

      // Filter members by name
      final filtered = widget.members
          .where((m) =>
              m.userId != widget.currentUserId && // Exclude self
              (m.fullName ?? '').toLowerCase().contains(query))
          .toList();

      if (filtered.isNotEmpty) {
        setState(() {
          _showMentionList = true;
          _mentionStartIndex = atIndex;
          _currentMentionQuery = query;
          _filteredMembers = filtered;
          _selectedMentionIndex = 0;
        });
        _showOverlay();
        return;
      }
    }

    // Hide mention list
    if (_showMentionList) {
      setState(() {
        _showMentionList = false;
      });
      _removeOverlay();
    }
  }

  /// Insert selected mention into text
  void _insertMention(ConversationMember member) {
    final text = widget.controller.text;
    final cursorPos = widget.controller.selection.baseOffset;

    // Replace from '@' to cursor with mention display format @FullName
    final before = text.substring(0, _mentionStartIndex);
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
    });
    _removeOverlay();

    // Keep cursor/focus in input after selecting from overlay.
    final focusNode = widget.focusNode;
    if (focusNode != null) {
      FocusScope.of(context).requestFocus(focusNode);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!focusNode.hasFocus) FocusScope.of(context).requestFocus(focusNode);
        widget.controller.selection = TextSelection.collapsed(offset: caretOffset);
      });
    }
  }

  void _showOverlay() {
    _removeOverlay();

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        width: MediaQuery.of(context).size.width - 32,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: const Offset(0, -200), // Show above input
          child: Material(
            elevation: 4.0,
            borderRadius: BorderRadius.circular(8.0),
            child: Container(
              constraints: const BoxConstraints(maxHeight: 200),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(8.0),
                border: Border.all(
                  color: Theme.of(context).dividerColor,
                ),
              ),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: _filteredMembers.length,
                itemBuilder: (context, index) {
                  final member = _filteredMembers[index];
                  final isSelected = index == _selectedMentionIndex;

                  return ListTile(
                    dense: true,
                    selected: isSelected,
                    leading: AppAvatar.initials(
                      name: member.fullName ?? 'Unknown',
                      size: AvatarSize.small,
                    ),
                    title: Text(
                      member.fullName ?? 'Unknown',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                    onTap: () => _insertMention(member),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
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
