import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/inputs/app_text_field.dart';

/// **APP TEXT AREA**
///
/// A multi-line text input field that extends AppTextField.
/// Optimized for longer text input with configurable minimum and maximum lines.
///
/// **Features**:
/// - Multi-line text input
/// - Configurable min/max lines
/// - All AppTextField features
/// - Auto-expanding height
///
/// **Usage**:
/// ```dart
/// AppTextArea(
///   label: 'Description',
///   hint: 'Enter description...',
///   minLines: 3,
///   maxLines: 10,
///   onChanged: (value) => _handleDescriptionChange(value),
/// )
/// ```
class AppTextArea extends AppTextField {
  /// Creates a text area
  const AppTextArea({
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
    int minLines = 3,
    int maxLines = 10,
    super.enabled,
    super.readOnly,
    super.autofocus,
    super.autovalidateMode,
    super.key,
  }) : super(
          minLines: minLines,
          maxLines: maxLines,
          keyboardType: TextInputType.multiline,
        );
}
