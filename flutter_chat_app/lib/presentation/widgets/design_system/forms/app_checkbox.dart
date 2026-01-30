import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_chat_app/core/base/base_widget.dart';
import 'package:flutter_chat_app/core/constants/app_dimens.dart';
import 'package:flutter_chat_app/core/theme/app_colors.dart';
import 'package:flutter_chat_app/core/theme/app_text_styles.dart';
import 'package:flutter_chat_app/generated/l10n/app_localizations.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/forms/form_enums.dart';

/// **APP CHECKBOX**
///
/// Checkbox component with three states: checked, unchecked, indeterminate.
/// Extends [BaseStatelessWidget] for lifecycle management.
///
/// **Features**:
/// - Three-state support (checked, unchecked, indeterminate)
/// - Haptic feedback on interaction
/// - Disabled state support
/// - Custom colors and sizes
/// - Accessibility labels
/// - Dark mode support
/// - Touch target >= 48dp (WCAG compliance)
///
/// **Architecture**: Clean Architecture + Design System
/// **Pattern**: Stateless widget with callback-based state management
///
/// **Usage**:
/// ```dart
/// // Basic checkbox
/// AppCheckbox(
///   value: _isChecked,
///   onChanged: (value) => setState(() => _isChecked = value),
///   label: context.l10n.agreeToTerms,
/// )
///
/// // Indeterminate state (tristate)
/// AppCheckbox(
///   value: null,
///   tristate: true,
///   onChanged: (value) => _handleChange(value),
///   label: 'Select all',
/// )
///
/// // Disabled checkbox
/// AppCheckbox(
///   value: true,
///   onChanged: null,
///   label: 'Cannot change',
/// )
///
/// // Custom size and colors
/// AppCheckbox(
///   value: _isChecked,
///   onChanged: (value) => setState(() => _isChecked = value),
///   size: CheckboxSize.large,
///   activeColor: Colors.green,
///   checkColor: Colors.white,
/// )
/// ```
///
/// **Accessibility**:
/// - Semantic label from [label] property
/// - Checked state announced to screen readers
/// - Minimum touch target of 48dp
/// - Keyboard navigation support
///
/// **Performance**:
/// - Const constructor for efficient rebuilds
/// - Minimal widget tree depth
/// - No unnecessary rebuilds
class AppCheckbox extends BaseStatelessWidget {
  /// Creates a checkbox with optional label.
  ///
  /// The [value] parameter determines the checkbox state:
  /// - `true`: checked
  /// - `false`: unchecked
  /// - `null`: indeterminate (requires [tristate] = true)
  ///
  /// The [onChanged] callback is called when the user taps the checkbox.
  /// If null, the checkbox is disabled.
  const AppCheckbox({
    super.key,
    required this.value,
    required this.onChanged,
    this.label,
    this.tristate = false,
    this.activeColor,
    this.checkColor,
    this.size = CheckboxSize.medium,
  });

  /// Current checkbox value.
  ///
  /// - `true`: checked
  /// - `false`: unchecked
  /// - `null`: indeterminate (only if [tristate] is true)
  final bool? value;

  /// Callback when checkbox value changes.
  ///
  /// If null, the checkbox is disabled and cannot be interacted with.
  final ValueChanged<bool?>? onChanged;

  /// Optional label text displayed next to the checkbox.
  ///
  /// Uses [context.l10n] for localization when possible.
  final String? label;

  /// Whether the checkbox supports three states.
  ///
  /// When true, the checkbox can be:
  /// - checked (true)
  /// - unchecked (false)
  /// - indeterminate (null)
  ///
  /// When false, only checked and unchecked states are allowed.
  final bool tristate;

  /// Active (checked) color.
  ///
  /// Defaults to [ColorScheme.primary] from theme.
  final Color? activeColor;

  /// Check mark color.
  ///
  /// Defaults to [ColorScheme.onPrimary] from theme.
  final Color? checkColor;

  /// Checkbox size variant.
  ///
  /// Determines the size of the checkbox:
  /// - [CheckboxSize.small]: 16dp
  /// - [CheckboxSize.medium]: 20dp (default)
  /// - [CheckboxSize.large]: 24dp
  final CheckboxSize size;

  @override
  Widget buildContent(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isDisabled = onChanged == null;

    final checkboxSize = _getCheckboxSize(size);

    // Determine semantic label
    final semanticLabel = label ?? _getDefaultSemanticLabel(l10n);

    // Determine semantic state
    final semanticState = value == null
        ? l10n.indeterminate
        : value!
            ? l10n.checked
            : l10n.unchecked;

    return Semantics(
      label: semanticLabel,
      value: semanticState,
      checked: value,
      enabled: !isDisabled,
      child: InkWell(
        onTap: isDisabled ? null : _handleTap,
        borderRadius: BorderRadius.circular(AppDimens.radiusSmall),
        // Ensure minimum touch target of 48dp
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minWidth: AppDimens.touchTargetMin,
            minHeight: AppDimens.touchTargetMin,
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppDimens.paddingSmall),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: checkboxSize,
                  height: checkboxSize,
                  child: Checkbox(
                    value: value,
                    onChanged: onChanged,
                    tristate: tristate,
                    activeColor: activeColor ?? theme.colorScheme.primary,
                    checkColor: checkColor ?? theme.colorScheme.onPrimary,
                    // Apply disabled styling
                    fillColor: isDisabled
                        ? WidgetStateProperty.all(
                            isDark
                                ? AppColors.textSecondaryDarkMode
                                    .withValues(alpha: 0.12)
                                : AppColors.textSecondary
                                    .withValues(alpha: 0.12),
                          )
                        : null,
                  ),
                ),
                if (label != null) ...[
                  const SizedBox(width: AppDimens.spaceSmall),
                  Flexible(
                    child: Text(
                      label!,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: isDisabled
                            ? (isDark
                                ? AppColors.textSecondaryDarkMode
                                    .withValues(alpha: 0.38)
                                : AppColors.textSecondary
                                    .withValues(alpha: 0.38))
                            : null,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Handles checkbox tap with haptic feedback.
  ///
  /// Cycles through states:
  /// - Tristate: false → true → null → false
  /// - Normal: false → true → false
  void _handleTap() {
    if (onChanged == null) return;

    // Provide haptic feedback for better UX
    HapticFeedback.lightImpact();

    if (tristate) {
      // Cycle through: false → true → null → false
      if (value == false) {
        onChanged!(true);
      } else if (value == true) {
        onChanged!(null);
      } else {
        onChanged!(false);
      }
    } else {
      // Toggle between true and false
      onChanged!(!(value ?? false));
    }
  }

  /// Gets checkbox size in dp based on size variant.
  double _getCheckboxSize(CheckboxSize size) {
    switch (size) {
      case CheckboxSize.small:
        return AppDimens.iconXSmall;
      case CheckboxSize.medium:
        return AppDimens.iconSmall;
      case CheckboxSize.large:
        return AppDimens.iconMedium;
    }
  }

  /// Gets default semantic label when no label is provided.
  String _getDefaultSemanticLabel(AppLocalizations l10n) {
    if (value == null) {
      return l10n.indeterminate;
    }
    return value! ? l10n.checked : l10n.unchecked;
  }
}
