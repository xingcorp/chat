import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_chat_app/core/base/base_widget.dart';
import 'package:flutter_chat_app/core/constants/app_dimens.dart';
import 'package:flutter_chat_app/core/theme/app_colors.dart';
import 'package:flutter_chat_app/l10n/l10n.dart';

/// **APP OTP INPUT**
///
/// OTP/verification code input component.
/// Extends [BaseStatefulWidget] for lifecycle management.
///
/// **Features**:
/// - Individual boxes for each digit
/// - Auto-focus next box on input
/// - Auto-focus previous on backspace
/// - Paste support (splits code across boxes)
/// - Configurable length (4, 6, 8 digits)
/// - Numeric or alphanumeric
/// - Auto-submit on completion
/// - Dark mode support
///
/// **Usage**:
/// ```dart
/// AppOTPInput(
///   length: 6,
///   onCompleted: (code) => _verifyOTP(code),
///   onChanged: (code) => print('Current: $code'),
/// )
/// ```
class AppOTPInput extends BaseStatefulWidget {
  const AppOTPInput({
    super.key,
    this.length = 6,
    this.onChanged,
    this.onCompleted,
    this.isNumeric = true,
    this.autoSubmit = true,
    this.obscureText = false,
    this.isDisabled = false,
  });

  /// Number of OTP digits
  final int length;

  /// Callback when OTP changes
  final ValueChanged<String>? onChanged;

  /// Callback when OTP is completed
  final ValueChanged<String>? onCompleted;

  /// Whether to accept only numeric input
  final bool isNumeric;

  /// Whether to auto-submit on completion
  final bool autoSubmit;

  /// Whether to obscure text
  final bool obscureText;

  /// Whether input is disabled
  final bool isDisabled;

  @override
  AppOTPInputState createState() => AppOTPInputState();
}

class AppOTPInputState extends BaseState<AppOTPInput> {
  late List<TextEditingController> _controllers;
  late List<FocusNode> _focusNodes;
  String _currentCode = '';

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      widget.length,
      (_) => TextEditingController(),
    );
    _focusNodes = List.generate(
      widget.length,
      (_) => FocusNode(),
    );

    // Add listeners to all controllers
    for (var i = 0; i < _controllers.length; i++) {
      final index = i;
      _controllers[i].addListener(() => _onTextChanged(index));
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    for (final focusNode in _focusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  void _onTextChanged(int index) {
    final text = _controllers[index].text;

    if (text.isNotEmpty) {
      // Move to next field if not last
      if (index < widget.length - 1) {
        _focusNodes[index + 1].requestFocus();
      } else {
        // Last field - unfocus and check completion
        _focusNodes[index].unfocus();
        _checkCompletion();
      }
    }

    _updateCurrentCode();
  }

  void _updateCurrentCode() {
    final code = _controllers.map((c) => c.text).join();
    _currentCode = code;
    widget.onChanged?.call(code);
  }

  void _checkCompletion() {
    final code = _controllers.map((c) => c.text).join();
    if (code.length == widget.length) {
      widget.onCompleted?.call(code);
    }
  }

  void _handleKeyEvent(int index, KeyEvent event) {
    if (event is KeyDownEvent) {
      // Handle Backspace
      if (event.logicalKey == LogicalKeyboardKey.backspace) {
        if (_controllers[index].text.isEmpty && index > 0) {
          // Move to previous field and clear it
          _focusNodes[index - 1].requestFocus();
          _controllers[index - 1].clear();
        }
      }
      // Handle Paste
      else if (event.logicalKey == LogicalKeyboardKey.keyV &&
          (event.character == 'v' || event.character == 'V') &&
          HardwareKeyboard.instance.isMetaPressed) {
        _handlePaste();
      }
    }
  }

  Future<void> _handlePaste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null) {
      final pastedText = data!.text!;
      _fillWithPastedText(pastedText);
    }
  }

  void _fillWithPastedText(String text) {
    // Remove non-alphanumeric characters
    final cleanText = widget.isNumeric
        ? text.replaceAll(RegExp('[^0-9]'), '')
        : text.replaceAll(RegExp('[^a-zA-Z0-9]'), '');

    // Fill boxes with pasted text
    for (var i = 0; i < widget.length && i < cleanText.length; i++) {
      _controllers[i].text = cleanText[i];
    }

    // Focus last filled box or first empty box
    final lastFilledIndex = cleanText.length < widget.length
        ? cleanText.length
        : widget.length - 1;
    _focusNodes[lastFilledIndex].requestFocus();

    _updateCurrentCode();
    _checkCompletion();
  }

  void clear() {
    for (final controller in _controllers) {
      controller.clear();
    }
    _focusNodes[0].requestFocus();
    _updateCurrentCode();
  }

  String get code => _currentCode;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = context.l10n;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(
            widget.length,
            (index) => _buildOTPBox(index, isDark),
          ),
        ),
        const SizedBox(height: AppDimens.spaceSmall),
        Center(
          child: Text(
            l10n.pasteCode,
            style: TextStyle(
              color: isDark
                  ? AppColors.textSecondaryDarkMode
                  : AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOTPBox(int index, bool isDark) {
    const boxSize = 48.0;

    return SizedBox(
      width: boxSize,
      height: boxSize,
      child: KeyboardListener(
        focusNode: FocusNode(),
        onKeyEvent: (event) => _handleKeyEvent(index, event),
        child: TextField(
          controller: _controllers[index],
          focusNode: _focusNodes[index],
          enabled: !widget.isDisabled,
          textAlign: TextAlign.center,
          keyboardType: widget.isNumeric
              ? TextInputType.number
              : TextInputType.text,
          maxLength: 1,
          obscureText: widget.obscureText,
          inputFormatters: [
            LengthLimitingTextInputFormatter(1),
            if (widget.isNumeric) FilteringTextInputFormatter.digitsOnly,
          ],
          decoration: InputDecoration(
            counterText: '',
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
            filled: true,
            fillColor: isDark ? AppColors.surfaceDarkMode : AppColors.surface,
            contentPadding: EdgeInsets.zero,
          ),
          style: TextStyle(
            color: isDark
                ? AppColors.textPrimaryDarkMode
                : AppColors.textPrimary,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
          onChanged: (value) {
            if (value.isNotEmpty) {
              // Ensure only one character
              if (value.length > 1) {
                _controllers[index].text = value[0];
              }
            }
          },
        ),
      ),
    );
  }
}
