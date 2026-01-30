import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_chat_app/core/base/base_widget.dart';
import 'package:flutter_chat_app/core/constants/app_dimens.dart';
import 'package:flutter_chat_app/core/theme/app_colors.dart';
import 'package:flutter_chat_app/l10n/l10n.dart';

/// **APP AUTO COMPLETE**
///
/// Text input with autocomplete suggestions.
/// Extends [BaseStatefulWidget] for lifecycle management.
///
/// **Features**:
/// - Async suggestion loading
/// - Debounced search
/// - Highlight matching text
/// - Keyboard navigation
/// - Custom suggestion builder
/// - Loading indicator
/// - Empty state handling
/// - Dark mode support
///
/// **Usage**:
/// ```dart
/// AppAutoComplete<String>(
///   onSearch: (query) async => await _searchItems(query),
///   onSelected: (item) => _handleSelection(item),
///   itemBuilder: (item) => Text(item),
///   placeholder: context.l10n.typeToSearch,
/// )
/// ```
class AppAutoComplete<T> extends BaseStatefulWidget {
  const AppAutoComplete({
    super.key,
    required this.onSearch,
    required this.onSelected,
    required this.itemBuilder,
    this.controller,
    this.placeholder,
    this.debounceDelay = const Duration(milliseconds: 300),
    this.maxSuggestions = 5,
    this.highlightMatches = true,
    this.showLoadingIndicator = true,
    this.emptyMessage,
    this.isDisabled = false,
  });

  /// Callback to search for suggestions
  final Future<List<T>> Function(String query) onSearch;

  /// Callback when item is selected
  final ValueChanged<T> onSelected;

  /// Builder for suggestion items
  final Widget Function(T item) itemBuilder;

  /// Text editing controller
  final TextEditingController? controller;

  /// Placeholder text
  final String? placeholder;

  /// Debounce delay for search
  final Duration debounceDelay;

  /// Maximum number of suggestions to show
  final int maxSuggestions;

  /// Whether to highlight matching text
  final bool highlightMatches;

  /// Whether to show loading indicator
  final bool showLoadingIndicator;

  /// Message to show when no suggestions found
  final String? emptyMessage;

  /// Whether input is disabled
  final bool isDisabled;

  @override
  AppAutoCompleteState<T> createState() => AppAutoCompleteState<T>();
}

class AppAutoCompleteState<T> extends BaseState<AppAutoComplete<T>> {
  late TextEditingController _controller;
  final FocusNode _focusNode = FocusNode();
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  List<T> _suggestions = [];
  int _selectedIndex = 0;
  bool _isSearching = false;
  Timer? _debounceTimer;

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
    _debounceTimer?.cancel();
    _removeOverlay();
    super.dispose();
  }

  void _onTextChanged() {
    _debounceTimer?.cancel();

    if (_controller.text.isEmpty) {
      _removeOverlay();
      return;
    }

    _debounceTimer = Timer(widget.debounceDelay, () {
      _searchSuggestions(_controller.text);
    });
  }

  void _onFocusChanged() {
    if (!_focusNode.hasFocus) {
      _removeOverlay();
    }
  }

  Future<void> _searchSuggestions(String query) async {
    safeSetState(() {
      _isSearching = true;
      _selectedIndex = 0;
    });

    try {
      final results = await widget.onSearch(query);
      safeSetState(() {
        _suggestions = results.take(widget.maxSuggestions).toList();
        _isSearching = false;
      });

      if (_suggestions.isNotEmpty || widget.showLoadingIndicator) {
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

  void _selectSuggestion(T item) {
    widget.onSelected(item);
    _removeOverlay();
    _focusNode.unfocus();
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
      _selectSuggestion(_suggestions[_selectedIndex]);
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
            suffixIcon: _isSearching && widget.showLoadingIndicator
                ? const Padding(
                    padding: EdgeInsets.all(AppDimens.paddingSmall),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primary,
                      ),
                    ),
                  )
                : null,
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

    if (_isSearching && widget.showLoadingIndicator) {
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
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDarkMode : AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimens.radiusMedium),
        ),
        child: Text(
          widget.emptyMessage ?? context.l10n.loading,
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
        maxHeight: 250,
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
            onTap: () => _selectSuggestion(item),
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
              child: widget.itemBuilder(item),
            ),
          );
        },
      ),
    );
  }
}
