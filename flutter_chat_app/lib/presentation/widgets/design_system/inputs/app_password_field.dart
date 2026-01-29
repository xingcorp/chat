import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/inputs/app_text_field.dart';

/// **APP PASSWORD FIELD**
///
/// A specialized text field for password input.
/// Includes show/hide toggle and password-specific keyboard.
///
/// **Features**:
/// - Obscured text by default
/// - Show/hide password toggle
/// - Password keyboard
/// - All AppTextField features
///
/// **Usage**:
/// ```dart
/// AppPasswordField(
///   label: 'Password',
///   hint: 'Enter your password',
///   validator: (value) {
///     if (value == null || value.length < 8) {
///       return 'Password must be at least 8 characters';
///     }
///     return null;
///   },
/// )
/// ```
class AppPasswordField extends AppTextField {
  /// Creates a password field
  const AppPasswordField({
    super.controller,
    super.label,
    super.hint,
    super.helperText,
    super.errorText,
    super.validator,
    super.onChanged,
    super.onSubmitted,
    super.textInputAction,
    super.inputFormatters,
    super.maxLength,
    super.enabled,
    super.readOnly,
    super.autofocus,
    super.autovalidateMode,
    super.key,
  }) : super(
          obscureText: true,
          keyboardType: TextInputType.visiblePassword,
          prefixIcon: Icons.lock_outline,
        );
}
