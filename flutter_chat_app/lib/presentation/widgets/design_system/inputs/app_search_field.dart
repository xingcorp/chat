import 'package:flutter/material.dart';
import 'package:flutter_chat_app/core/base/base_widget.dart';
import 'package:flutter_chat_app/core/constants/app_dimens.dart';
import 'package:flutter_chat_app/core/constants/app_icons.dart';
import 'package:flutter_chat_app/l10n/l10n.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/app_icon.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/inputs/app_text_field.dart';

/// **APP SEARCH FIELD**
///
/// A specialized text field for search functionality.
/// Includes search icon and clear button.
///
/// **Features**:
/// - Search icon prefix
/// - Clear button suffix
/// - Auto-clear on submit
/// - Search-optimized keyboard
///
/// **Usage**:
/// ```dart
/// AppSearchField(
///   hint: 'Search messages...',
///   onChanged: (value) => _handleSearch(value),
///   onSubmitted: (value) => _performSearch(value),
/// )
/// ```
class AppSearchField extends BaseStatefulWidget {
  /// Creates a search field
  const AppSearchField({
    this.controller,
    this.hint,
    this.onChanged,
    this.onSubmitted,
    this.autofocus = false,
    super.key,
  });

  /// Text editing controller
  final TextEditingController? controller;

  /// Hint text
  final String? hint;

  /// Callback when text changes
  final void Function(String)? onChanged;

  /// Callback when user submits
  final void Function(String)? onSubmitted;

  /// Whether field should auto-focus
  final bool autofocus;

  @override
  AppSearchFieldState createState() => AppSearchFieldState();
}

/// State for AppSearchField
class AppSearchFieldState extends BaseState<AppSearchField> {
  late TextEditingController _controller;
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _controller.addListener(_handleTextChange);
    _hasText = _controller.text.isNotEmpty;
  }

  @override
  void didUpdateWidget(AppSearchField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      _controller.removeListener(_handleTextChange);
      if (oldWidget.controller == null) {
        _controller.dispose();
      }
      _controller = widget.controller ?? TextEditingController();
      _controller.addListener(_handleTextChange);
      _hasText = _controller.text.isNotEmpty;
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_handleTextChange);
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  /// Handle text change
  void _handleTextChange() {
    final hasText = _controller.text.isNotEmpty;
    if (hasText != _hasText) {
      safeSetState(() {
        _hasText = hasText;
      });
    }
  }

  /// Clear search field
  void _handleClear() {
    _controller.clear();
    widget.onChanged?.call('');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return AppTextField(
      controller: _controller,
      hint: widget.hint ?? l10n.search,
      prefixIcon: AppIcons.search,
      suffixIcon: _hasText
          ? IconButton(
              icon: AppIcon(AppIcons.close, size: AppDimens.iconMedium),
              onPressed: _handleClear,
              tooltip: l10n.close,
            )
          : null,
      keyboardType: TextInputType.text,
      textInputAction: TextInputAction.search,
      onChanged: widget.onChanged,
      onSubmitted: widget.onSubmitted,
      autofocus: widget.autofocus,
    );
  }
}
