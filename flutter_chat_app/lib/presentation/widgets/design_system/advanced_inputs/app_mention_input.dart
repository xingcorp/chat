import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_chat_app/core/base/base_widget.dart';
import 'package:flutter_chat_app/core/constants/app_dimens.dart';
import 'package:flutter_chat_app/core/theme/app_colors.dart';
import 'package:flutter_chat_app/l10n/l10n.dart';

/// **Mention Item**
///
/// Represents a mentionable item (user, group, etc.)
class MentionItem {
  const MentionItem({
    required this.id,
    required this.displayName,
    this.avatarUrl,
    this.subtitle,
  });

  final String id;
  final String displayName;
  final String? avatarUrl;
  final String? subtitle;
}

/// **APP MENTION INPUT**
///
/// Text input with @ mention autocomplete.
/// Extends [BaseStatefulWidget] for lifecycle management.
///
/// **Features**:
/// - Detect @ symbol trigger
/// - Show user suggestions overlay
/// - Filter suggestions as user types
/// - Keyboard navigation
/// - Insert mention with formatting
/// - Support multiple mentions
/// - Custom mention rendering
/// - Dark mode support
///
/// **Usage**:
/// ```dart
/// AppMentionInput(
///   controller: _controller,
///   onSearch: (query) async => await _searchUsers(query),
///   onMentionSelected: (item) => _handleMention(item),
///   placeholder: context.l10n.typeMessage,
/// )
/// ```
class AppMentionInput extends BaseStatefulWidget {
  const AppMentionInput({
    super.key,
    this.controller,
    this.onChanged,
    this.onSearch,
    this.onMentionSelected,
    this.placeholder,
    this.minLines = 1,
    this.maxLines = 5,
    this.mentionTrigger = '@',
    this.mentionBuilder,
    this.maxSuggestions = 5,
    this.isDisabled = false,
  });

  /// Text editing controller
  final TextEditingController? controller;

  /// Callback when text changes
  final ValueChanged<String>? onChanged;

  /// Callback to search for mentions
  final Future<List<MentionItem>> Function(String query)? onSearch;

  /// Callback when mention is selected
  final ValueChanged<MentionItem>? onMentionSelected;

  /// Placeholder text
  final String? placeholder;

  /// Minimum number of lines
  final int minLines;

  /// Maximum number of lines
  final int maxLines;

  /// Trigger character for mentions
  final String mentionTrigger;

  /// Custom mention chip builder
  final Widget Function(MentionItem item)? mentionBuilder;

  /// Maximum number of suggestions to show
  final int maxSuggestions;

  /// Whether input is disabled
  final bool isDisabled;

  @override
  AppMentionInputState createState() => AppMentionInputState();
}

class AppMentionInputState extends BaseState<AppMentionInput> {
  late TextEditingController _controller;
  final FocusNode _focusNode = FocusNode();
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  List<MentionItem> _suggestions = [];
  int _selectedIndex = 0;
  bool _isSearching = false;
  String _currentQuery = '';

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _controller.addListener(_onTextChanged);
    _focusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _focusNode.removeListener(_onFocusChanged);
    if (widget.controller == null) {
      _controller.dispose();
    }
    _focusNode.dispose();
    _removeOverlay();
    super.dispose();
  }

  void _onTextChanged() {
    widget.onChanged?.call(_controller.text);
    _checkForMention();
  }

  void _onFocusChanged() {
    if (!_focusNode.hasFocus) {
      _removeOverlay();
    }
  }

  void _checkForMention() {
    final text = _controller.text;
    final selection = _controller.selection;

    if (!selection.isValid || selection.baseOffset == 0) {
      _removeOverlay();
      return;
    }

    final cursorPosition = selection.baseOffset;
    final textBeforeCursor = text.substring(0, cursorPosition);
    final lastAtIndex = textBeforeCursor.lastIndexOf(widget.mentionTrigger);

    if (lastAtIndex == -1) {
      _removeOverlay();
      return;
    }

    final textAfterAt = textBeforeCursor.substring(lastAtIndex + 1);
    if (textAfterAt.contains(' ')) {
      _removeOverlay();
      return;
    }

    _currentQuery = textAfterAt;
    _searchMentions(_currentQuery);
  }

  Future<void> _searchMentions(String query) async {
    if (widget.onSearch == null) return;

    safeSetState(() {
      _isSearching = true;
      _selectedIndex = 0;
    });

    try {
      final results = await widget.onSearch!(query);
      safeSetState(() {
        _suggestions = results.take(widget.maxSuggestions).toList();
        _isSearching = false;
      });

      if (_suggestions.isNotEmpty) {
        _showOverlay();
      } else {
        _removeOverlay();
      }
    } catch (e) {
      safeSetState(() {
        _suggestions = [];
        _isSearching = false;
      });
      _removeOverlay();
    }
  }

  void _showOverlay() {
    _removeOverlay();

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        width: MediaQuery.of(context).size.width - (AppDimens.paddingLarge * 2),
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: const Offset(0, AppDimens.spaceSmall),
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(AppDimens.radiusMedium),
            child: _buildSuggestionsList(),
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

  void _selectMention(MentionItem item) {
    final text = _controller.text;
    final selection = _controller.selection;
    final cursorPosition = selection.baseOffset;
    final textBeforeCursor = text.substring(0, cursorPosition);
    final lastAtIndex = textBeforeCursor.lastIndexOf(widget.mentionTrigger);

    if (lastAtIndex == -1) return;

    final mentionText = '${widget.mentionTrigger}${item.displayName} ';
    final newText = text.replaceRange(
      lastAtIndex,
      cursorPosition,
      mentionText,
    );

    safeSetState(() {
      _controller.text = newText;
      _controller.selection = TextSelection.collapsed(
        offset: lastAtIndex + mentionText.length,
      );
    });

    widget.onMentionSelected?.call(item);
    _removeOverlay();
  }

  void _handleKeyEvent(KeyEvent event) {
    if (_overlayEntry == null || _suggestions.isEmpty) return;

    if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      safeSetState(() {
        _selectedIndex = (_selectedIndex + 1) % _suggestions.length;
      });
    } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      safeSetState(() {
        _selectedIndex = (_selectedIndex - 1 + _suggestions.length) % _suggestions.length;
      });
    } else if (event.logicalKey == LogicalKeyboardKey.enter) {
      _selectMention(_suggestions[_selectedIndex]);
    } else if (event.logicalKey == LogicalKeyboardKey.escape) {
      _removeOverlay();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return CompositedTransformTarget(
      link: _layerLink,
      child: KeyboardListener(
        focusNode: FocusNode(),
        onKeyEvent: _handleKeyEvent,
        child: TextField(
          controller: _controller,
          focusNode: _focusNode,
          enabled: !widget.isDisabled,
          minLines: widget.minLines,
          maxLines: widget.maxLines,
          decoration: InputDecoration(
            hintText: widget.placeholder,
            hintStyle: TextStyle(
              color: isDark
                  ? AppColors.textSecondaryDarkMode
                  : AppColors.textSecondary,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimens.radiusMedium),
              borderSide: BorderSide(
                color: isDark ? AppColors.borderDarkMode : AppColors.border,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimens.radiusMedium),
              borderSide: BorderSide(
                color: isDark ? AppColors.borderDarkMode : AppColors.border,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimens.radiusMedium),
              borderSide: const BorderSide(
                color: AppColors.primary,
                width: 2,
              ),
            ),
            contentPadding: const EdgeInsets.all(AppDimens.paddingMedium),
          ),
          style: TextStyle(
            color: isDark
                ? AppColors.textPrimaryDarkMode
                : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }

  Widget _buildSuggestionsList() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (_isSearching) {
      return Container(
        padding: const EdgeInsets.all(AppDimens.paddingMedium),
        child: const Center(
          child: CircularProgressIndicator(
            color: AppColors.primary,
          ),
        ),
      );
    }

    if (_suggestions.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(AppDimens.paddingMedium),
        child: Text(
          context.l10n.loading,
          style: TextStyle(
            color: isDark
                ? AppColors.textSecondaryDarkMode
                : AppColors.textSecondary,
          ),
        ),
      );
    }

    return Container(
      constraints: const BoxConstraints(
        maxHeight: 200,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDarkMode : AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimens.radiusMedium),
      ),
      child: ListView.builder(
        shrinkWrap: true,
        padding: EdgeInsets.zero,
        itemCount: _suggestions.length,
        itemBuilder: (context, index) {
          final item = _suggestions[index];
          final isSelected = index == _selectedIndex;

          return InkWell(
            onTap: () => _selectMention(item),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimens.paddingMedium,
                vertical: AppDimens.paddingSmall,
              ),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary.withValues(alpha: 0.1)
                    : Colors.transparent,
              ),
              child: widget.mentionBuilder?.call(item) ??
                  Row(
                    children: [
                      if (item.avatarUrl != null)
                        CircleAvatar(
                          radius: 16,
                          backgroundImage: NetworkImage(item.avatarUrl!),
                        )
                      else
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: AppColors.primary,
                          child: Text(
                            item.displayName[0].toUpperCase(),
                            style: TextStyle(
                              color: isDark
                                  ? AppColors.textPrimaryDarkMode
                                  : Colors.white,
                            ),
                          ),
                        ),
                      const SizedBox(width: AppDimens.spaceSmall),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.displayName,
                              style: TextStyle(
                                color: isDark
                                    ? AppColors.textPrimaryDarkMode
                                    : AppColors.textPrimary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            if (item.subtitle != null)
                              Text(
                                item.subtitle!,
                                style: TextStyle(
                                  color: isDark
                                      ? AppColors.textSecondaryDarkMode
                                      : AppColors.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
            ),
          );
        },
      ),
    );
  }
}
