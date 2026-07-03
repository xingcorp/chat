import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_chat_app/core/base/base_widget.dart';
import 'package:flutter_chat_app/core/constants/app_dimens.dart';
import 'package:flutter_chat_app/core/theme/app_colors.dart';
import 'package:flutter_chat_app/core/theme/app_text_styles.dart';
import 'package:flutter_chat_app/l10n/l10n.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/app_icon.dart';

/// **APP TEXT FIELD**
///
/// A customizable text input field that follows the app's design system.
/// Supports validation, prefix/suffix icons, helper text, and character counter.
///
/// **Features**:
/// - Custom validation with error messages
/// - Prefix and suffix icons
/// - Helper text and error text
/// - Character counter
/// - Auto-validation modes
/// - Keyboard type configuration
/// - Text input formatters
/// - Dark mode support
/// - Accessibility compliant
///
/// **Usage**:
/// ```dart
/// // Basic text field
/// AppTextField(
///   label: 'Email',
///   hint: 'Enter your email',
///   onChanged: (value) => _handleEmailChange(value),
/// )
///
/// // Text field with validation
/// AppTextField(
///   label: 'Password',
///   obscureText: true,
///   validator: (value) {
///     if (value == null || value.isEmpty) {
///       return 'Password is required';
///     }
///     return null;
///   },
/// )
///
/// // Text field with icons
/// AppTextField(
///   label: 'Search',
///   prefixIcon: AppIcons.search,
///   suffixIcon: IconButton(
///     icon: AppIcon(AppIcons.close),
///     onPressed: () => _handleClear(),
///   ),
/// )
/// ```
class AppTextField extends BaseStatefulWidget {
  /// Creates a text field
  const AppTextField({
    this.controller,
    this.label,
    this.hint,
    this.helperText,
    this.errorText,
    this.prefixIcon,
    this.suffixIcon,
    this.validator,
    this.onChanged,
    this.onSubmitted,
    this.keyboardType,
    this.textInputAction,
    this.inputFormatters,
    this.maxLength,
    this.maxLines = 1,
    this.minLines,
    this.obscureText = false,
    this.enabled = true,
    this.readOnly = false,
    this.autofocus = false,
    this.autovalidateMode,
    super.key,
  });

  /// Text editing controller
  final TextEditingController? controller;

  /// Label text displayed above field
  final String? label;

  /// Hint text displayed when field is empty
  final String? hint;

  /// Helper text displayed below field
  final String? helperText;

  /// Error text displayed below field (overrides helperText)
  final String? errorText;

  /// SVG icon asset path displayed at start of field (use [AppIcons] constants)
  final String? prefixIcon;

  /// Widget displayed at end of field
  final Widget? suffixIcon;

  /// Validation function
  final String? Function(String?)? validator;

  /// Callback when text changes
  final void Function(String)? onChanged;

  /// Callback when user submits field
  final void Function(String)? onSubmitted;

  /// Keyboard type
  final TextInputType? keyboardType;

  /// Text input action button
  final TextInputAction? textInputAction;

  /// Input formatters
  final List<TextInputFormatter>? inputFormatters;

  /// Maximum character length
  final int? maxLength;

  /// Maximum number of lines
  final int maxLines;

  /// Minimum number of lines
  final int? minLines;

  /// Whether to obscure text (for passwords)
  final bool obscureText;

  /// Whether field is enabled
  final bool enabled;

  /// Whether field is read-only
  final bool readOnly;

  /// Whether field should auto-focus
  final bool autofocus;

  /// Auto-validation mode
  final AutovalidateMode? autovalidateMode;

  @override
  AppTextFieldState createState() => AppTextFieldState();
}

/// State for AppTextField
class AppTextFieldState extends BaseState<AppTextField> {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  String? _errorText;
  bool _isFocused = false;
  bool _obscureText = false;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _focusNode = FocusNode();
    _focusNode.addListener(_handleFocusChange);
    _obscureText = widget.obscureText;
  }

  @override
  void didUpdateWidget(AppTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      if (oldWidget.controller == null) {
        _controller.dispose();
      }
      _controller = widget.controller ?? TextEditingController();
    }
    if (widget.obscureText != oldWidget.obscureText) {
      _obscureText = widget.obscureText;
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChange);
    _focusNode.dispose();
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  /// Handle focus change
  void _handleFocusChange() {
    safeSetState(() {
      _isFocused = _focusNode.hasFocus;
    });
  }

  /// Validate field
  void _validate() {
    if (widget.validator != null) {
      safeSetState(() {
        _errorText = widget.validator!(_controller.text);
      });
    }
  }

  /// Toggle password visibility
  void _toggleObscureText() {
    safeSetState(() {
      _obscureText = !_obscureText;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.label != null) ...[
          Text(
            widget.label!,
            style: AppTextStyles.labelLarge.copyWith(
              color: isDark
                  ? AppColors.textPrimaryDarkMode
                  : AppColors.textPrimary,
            ),
          ),
          SizedBox(height: AppDimens.spaceSmall),
        ],
        TextField(
          controller: _controller,
          focusNode: _focusNode,
          decoration: _buildDecoration(context),
          style: AppTextStyles.inputText(
            color: isDark
                ? AppColors.textPrimaryDarkMode
                : AppColors.textPrimary,
          ),
          keyboardType: widget.keyboardType,
          textInputAction: widget.textInputAction,
          inputFormatters: widget.inputFormatters,
          maxLength: widget.maxLength,
          maxLines: widget.obscureText ? 1 : widget.maxLines,
          minLines: widget.minLines,
          obscureText: _obscureText,
          enabled: widget.enabled,
          readOnly: widget.readOnly,
          autofocus: widget.autofocus,
          onChanged: (value) {
            widget.onChanged?.call(value);
            if (widget.autovalidateMode == AutovalidateMode.always ||
                (widget.autovalidateMode ==
                        AutovalidateMode.onUserInteraction &&
                    _errorText != null)) {
              _validate();
            }
          },
          onSubmitted: widget.onSubmitted,
        ),
      ],
    );
  }

  /// Build input decoration
  InputDecoration _buildDecoration(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final effectiveErrorText = _errorText ?? widget.errorText;

    return InputDecoration(
      hintText: widget.hint,
      hintStyle: AppTextStyles.inputHint(
        color: isDark ? AppColors.textHintDarkMode : AppColors.textHint,
      ),
      helperText: effectiveErrorText == null ? widget.helperText : null,
      helperStyle: AppTextStyles.bodySmall.copyWith(
        color: isDark
            ? AppColors.textSecondaryDarkMode
            : AppColors.textSecondary,
      ),
      errorText: effectiveErrorText,
      errorStyle: AppTextStyles.bodySmall.copyWith(
        color: AppColors.error,
      ),
      prefixIcon: widget.prefixIcon != null
          ? AppIcon(
              widget.prefixIcon!,
              size: AppDimens.iconMedium,
              color: _isFocused
                  ? AppColors.primary
                  : (isDark ? AppColors.iconDarkMode : AppColors.icon),
            )
          : null,
      suffixIcon: _buildSuffixIcon(context),
      filled: true,
      fillColor: widget.enabled
          ? (isDark
              ? AppColors.inputBackgroundDarkMode
              : AppColors.inputBackground)
          : (isDark
                  ? AppColors.inputBackgroundDarkMode
                  : AppColors.inputBackground)
              .withOpacity(0.5),
      contentPadding: EdgeInsets.symmetric(
        horizontal: AppDimens.paddingMedium,
        vertical: AppDimens.paddingMedium,
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
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimens.radiusMedium),
        borderSide: const BorderSide(
          color: AppColors.error,
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimens.radiusMedium),
        borderSide: const BorderSide(
          color: AppColors.error,
          width: 2,
        ),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimens.radiusMedium),
        borderSide: BorderSide(
          color: (isDark ? AppColors.borderDarkMode : AppColors.border)
              .withOpacity(0.5),
        ),
      ),
      counterText: widget.maxLength != null ? null : '',
    );
  }

  /// Build suffix icon
  Widget? _buildSuffixIcon(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (widget.obscureText) {
      return IconButton(
        icon: Icon(
          _obscureText ? Icons.visibility_off : Icons.visibility,
          size: AppDimens.iconMedium,
          color: isDark ? AppColors.iconDarkMode : AppColors.icon,
        ),
        onPressed: _toggleObscureText,
        tooltip: _obscureText ? 'Show password' : 'Hide password',
      );
    }

    return widget.suffixIcon;
  }
}
