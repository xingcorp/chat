import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_chat_app/core/base/base_widget.dart';
import 'package:flutter_chat_app/core/constants/app_dimens.dart';
import 'package:flutter_chat_app/core/theme/app_colors.dart';
import 'package:flutter_chat_app/l10n/l10n.dart';

/// **APP TAG INPUT**
///
/// Chip-based tag input component.
/// Extends [BaseStatefulWidget] for lifecycle management.
///
/// **Features**:
/// - Add tags by typing and pressing enter
/// - Display tags as chips
/// - Remove tags with backspace or chip close button
/// - Autocomplete suggestions
/// - Duplicate prevention
/// - Max tags limit
/// - Custom tag validation
/// - Dark mode support
///
/// **Usage**:
/// ```dart
/// AppTagInput(
///   tags: _tags,
///   onChanged: (tags) => setState(() => _tags = tags),
///   placeholder: context.l10n.addTag,
///   maxTags: 10,
/// )
/// ```
class AppTagInput extends BaseStatefulWidget {
  const AppTagInput({
    super.key,
    required this.tags,
    required this.onChanged,
    this.placeholder,
    this.suggestions,
    this.maxTags,
    this.allowDuplicates = false,
    this.validator,
    this.chipBuilder,
    this.isDisabled = false,
  });

  /// Current list of tags
  final List<String> tags;

  /// Callback when tags change
  final ValueChanged<List<String>> onChanged;

  /// Placeholder text
  final String? placeholder;

  /// Autocomplete suggestions
  final List<String>? suggestions;

  /// Maximum number of tags allowed
  final int? maxTags;

  /// Whether to allow duplicate tags
  final bool allowDuplicates;

  /// Custom tag validator
  final String? Function(String tag)? validator;

  /// Custom chip builder
  final Widget Function(String tag, VoidCallback onDelete)? chipBuilder;

  /// Whether input is disabled
  final bool isDisabled;

  @override
  AppTagInputState createState() => AppTagInputState();
}

class AppTagInputState extends BaseState<AppTagInput> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  List<String> _filteredSuggestions = [];
  int _selectedIndex = 0;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
    _focusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _focusNode.removeListener(_onFocusChanged);
    _controller.dispose();
    _focusNode.dispose();
    _removeOverlay();
    super.dispose();
  }

  void _onTextChanged() {
    if (widget.suggestions != null && _controller.text.isNotEmpty) {
      final query = _controller.text.toLowerCase();
      safeSetState(() {
        _filteredSuggestions = widget.suggestions!
            .where((s) => s.toLowerCase().contains(query))
            .toList();
        _selectedIndex = 0;
      });

      if (_filteredSuggestions.isNotEmpty) {
        _showOverlay();
      } else {
        _removeOverlay();
      }
    } else {
      _removeOverlay();
    }
  }

  void _onFocusChanged() {
    if (!_focusNode.hasFocus) {
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

  void _addTag(String tag) {
    final trimmedTag = tag.trim();

    if (trimmedTag.isEmpty) return;

    // Check max tags limit
    if (widget.maxTags != null && widget.tags.length >= widget.maxTags!) {
      safeSetState(() {
        _errorMessage = context.l10n.maxTagsReached;
      });
      return;
    }

    // Check duplicates
    if (!widget.allowDuplicates && widget.tags.contains(trimmedTag)) {
      safeSetState(() {
        _errorMessage = context.l10n.duplicateTag;
      });
      return;
    }

    // Custom validation
    if (widget.validator != null) {
      final error = widget.validator!(trimmedTag);
      if (error != null) {
        safeSetState(() {
          _errorMessage = error;
        });
        return;
      }
    }

    // Add tag
    final newTags = List<String>.from(widget.tags)..add(trimmedTag);
    widget.onChanged(newTags);

    // Clear input and error
    safeSetState(() {
      _controller.clear();
      _errorMessage = null;
    });
    _removeOverlay();
  }

  void _removeTag(String tag) {
    final newTags = List<String>.from(widget.tags)..remove(tag);
    widget.onChanged(newTags);
  }

  void _handleKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent) {
      // Handle Enter key
      if (event.logicalKey == LogicalKeyboardKey.enter) {
        if (_overlayEntry != null && _filteredSuggestions.isNotEmpty) {
          _addTag(_filteredSuggestions[_selectedIndex]);
        } else {
          _addTag(_controller.text);
        }
      }
      // Handle Backspace key
      else if (event.logicalKey == LogicalKeyboardKey.backspace) {
        if (_controller.text.isEmpty && widget.tags.isNotEmpty) {
          _removeTag(widget.tags.last);
        }
      }
      // Handle Arrow Down
      else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
        if (_overlayEntry != null && _filteredSuggestions.isNotEmpty) {
          safeSetState(() {
            _selectedIndex = (_selectedIndex + 1) % _filteredSuggestions.length;
          });
        }
      }
      // Handle Arrow Up
      else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
        if (_overlayEntry != null && _filteredSuggestions.isNotEmpty) {
          safeSetState(() {
            _selectedIndex = (_selectedIndex - 1 + _filteredSuggestions.length) %
                _filteredSuggestions.length;
          });
        }
      }
      // Handle Escape
      else if (event.logicalKey == LogicalKeyboardKey.escape) {
        _removeOverlay();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = context.l10n;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CompositedTransformTarget(
          link: _layerLink,
          child: Container(
            padding: const EdgeInsets.all(AppDimens.paddingSmall),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDarkMode : AppColors.surface,
              border: Border.all(
                color: _errorMessage != null
                    ? AppColors.error
                    : (isDark ? AppColors.borderDarkMode : AppColors.border),
              ),
              borderRadius: BorderRadius.circular(AppDimens.radiusMedium),
            ),
            child: Wrap(
              spacing: AppDimens.spaceSmall,
              runSpacing: AppDimens.spaceSmall,
              children: [
                ...widget.tags.map((tag) {
                  return widget.chipBuilder?.call(tag, () => _removeTag(tag)) ??
                      _buildDefaultChip(tag, isDark);
                }),
                IntrinsicWidth(
                  child: KeyboardListener(
                    focusNode: FocusNode(),
                    onKeyEvent: _handleKeyEvent,
                    child: TextField(
                      controller: _controller,
                      focusNode: _focusNode,
                      enabled: !widget.isDisabled,
                      decoration: InputDecoration(
                        hintText: widget.tags.isEmpty
                            ? (widget.placeholder ?? l10n.addTag)
                            : null,
                        hintStyle: TextStyle(
                          color: isDark
                              ? AppColors.textSecondaryDarkMode
                              : AppColors.textSecondary,
                        ),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: AppDimens.paddingSmall,
                          vertical: AppDimens.paddingSmall,
                        ),
                      ),
                      style: TextStyle(
                        color: isDark
                            ? AppColors.textPrimaryDarkMode
                            : AppColors.textPrimary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_errorMessage != null) ...[
          const SizedBox(height: AppDimens.spaceSmall),
          Text(
            _errorMessage!,
            style: const TextStyle(
              color: AppColors.error,
              fontSize: 12,
            ),
          ),
        ],
        if (widget.maxTags != null) ...[
          const SizedBox(height: AppDimens.spaceSmall),
          Text(
            '${widget.tags.length}/${widget.maxTags}',
            style: TextStyle(
              color: isDark
                  ? AppColors.textSecondaryDarkMode
                  : AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDefaultChip(String tag, bool isDark) {
    return Chip(
      label: Text(tag),
      deleteIcon: Icon(
        Icons.close,
        size: 18,
        color: isDark ? AppColors.iconDarkMode : AppColors.icon,
      ),
      onDeleted: widget.isDisabled ? null : () => _removeTag(tag),
      backgroundColor: AppColors.primary.withValues(alpha: 0.2),
      labelStyle: TextStyle(
        color: isDark ? AppColors.textPrimaryDarkMode : AppColors.textPrimary,
      ),
    );
  }

  Widget _buildSuggestionsList() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

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
        itemCount: _filteredSuggestions.length,
        itemBuilder: (context, index) {
          final suggestion = _filteredSuggestions[index];
          final isSelected = index == _selectedIndex;

          return InkWell(
            onTap: () => _addTag(suggestion),
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
              child: Text(
                suggestion,
                style: TextStyle(
                  color: isDark
                      ? AppColors.textPrimaryDarkMode
                      : AppColors.textPrimary,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
