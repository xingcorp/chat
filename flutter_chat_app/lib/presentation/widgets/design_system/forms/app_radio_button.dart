import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_chat_app/core/base/base_widget.dart';
import 'package:flutter_chat_app/core/constants/app_dimens.dart';
import 'package:flutter_chat_app/core/theme/app_colors.dart';
import 'package:flutter_chat_app/generated/l10n/app_localizations.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/forms/form_enums.dart';

/// **APP RADIO BUTTON**
///
/// Individual radio button component with label support.
/// Must be used within [AppRadioGroup] for proper state management.
///
/// **Features**:
/// - Generic type support for any value type
/// - Haptic feedback on selection
/// - Disabled state support
/// - Custom colors and sizes
/// - Accessibility labels
/// - Dark mode support
/// - Touch target >= 48dp (WCAG compliance)
///
/// **Architecture**: Clean Architecture + Design System
/// **Pattern**: Stateless widget with group-based state management
///
/// **Usage**:
/// ```dart
/// // Use within AppRadioGroup
/// AppRadioGroup<String>(
///   value: _selectedValue,
///   onChanged: (value) => setState(() => _selectedValue = value),
///   children: [
///     AppRadioButton(value: 'option1', label: 'Option 1'),
///     AppRadioButton(value: 'option2', label: 'Option 2'),
///     AppRadioButton(value: 'option3', label: 'Option 3'),
///   ],
/// )
/// ```
///
/// **Accessibility**:
/// - Semantic label from [label] property
/// - Selected state announced to screen readers
/// - Minimum touch target of 48dp
/// - Keyboard navigation support
class AppRadioButton<T> extends BaseStatelessWidget {
  /// Creates a radio button with a value and optional label.
  ///
  /// The [value] is the value this radio button represents.
  /// The [label] is displayed next to the radio button.
  const AppRadioButton({
    super.key,
    required this.value,
    required this.label,
    this.size = RadioButtonSize.medium,
  });

  /// The value this radio button represents.
  final T value;

  /// Label text displayed next to the radio button.
  final String label;

  /// Radio button size variant.
  final RadioButtonSize size;

  @override
  Widget buildContent(BuildContext context) {
    // This widget must be used within AppRadioGroup
    // The group provides the groupValue and onChanged callback
    return const SizedBox.shrink();
  }
}

/// **APP RADIO GROUP**
///
/// Radio button group component with mutual exclusion.
/// Manages state for multiple [AppRadioButton] widgets.
///
/// **Features**:
/// - Generic type support for any value type
/// - Automatic mutual exclusion
/// - Haptic feedback on selection
/// - Disabled state support
/// - Custom colors and sizes
/// - Accessibility support
/// - Dark mode support
///
/// **Architecture**: Clean Architecture + Design System
/// **Pattern**: Stateless widget with callback-based state management
///
/// **Usage**:
/// ```dart
/// // String values
/// AppRadioGroup<String>(
///   value: _selectedValue,
///   onChanged: (value) => setState(() => _selectedValue = value),
///   children: [
///     AppRadioButton(value: 'option1', label: context.l10n.option1),
///     AppRadioButton(value: 'option2', label: context.l10n.option2),
///     AppRadioButton(value: 'option3', label: context.l10n.option3),
///   ],
/// )
///
/// // Enum values
/// AppRadioGroup<ThemeMode>(
///   value: _themeMode,
///   onChanged: (value) => setState(() => _themeMode = value),
///   children: [
///     AppRadioButton(value: ThemeMode.light, label: 'Light'),
///     AppRadioButton(value: ThemeMode.dark, label: 'Dark'),
///     AppRadioButton(value: ThemeMode.system, label: 'System'),
///   ],
/// )
///
/// // Disabled group
/// AppRadioGroup<String>(
///   value: _selectedValue,
///   onChanged: null, // Disabled
///   children: [
///     AppRadioButton(value: 'option1', label: 'Option 1'),
///     AppRadioButton(value: 'option2', label: 'Option 2'),
///   ],
/// )
/// ```
///
/// **Accessibility**:
/// - Group semantic container
/// - Individual radio button labels
/// - Selected state announced
/// - Keyboard navigation support
///
/// **Performance**:
/// - Const constructor for efficient rebuilds
/// - Minimal widget tree depth
/// - No unnecessary rebuilds
class AppRadioGroup<T> extends BaseStatelessWidget {
  /// Creates a radio button group.
  ///
  /// The [value] is the currently selected value.
  /// The [onChanged] callback is called when a radio button is selected.
  /// The [children] are the radio buttons in this group.
  const AppRadioGroup({
    super.key,
    required this.value,
    required this.onChanged,
    required this.children,
    this.activeColor,
    this.size = RadioButtonSize.medium,
    this.spacing = AppDimens.spaceSmall,
  });

  /// Currently selected value.
  final T? value;

  /// Callback when a radio button is selected.
  ///
  /// If null, all radio buttons in the group are disabled.
  final ValueChanged<T?>? onChanged;

  /// List of radio buttons in this group.
  final List<AppRadioButton<T>> children;

  /// Active (selected) color.
  ///
  /// Defaults to [ColorScheme.primary] from theme.
  final Color? activeColor;

  /// Radio button size variant.
  final RadioButtonSize size;

  /// Spacing between radio buttons.
  final double spacing;

  @override
  Widget buildContent(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isDisabled = onChanged == null;

    final radioSize = _getRadioSize(size);

    return Semantics(
      container: true,
      label: l10n.selectOption,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children.map((radioButton) {
          final isSelected = value == radioButton.value;

          return Padding(
            padding: EdgeInsets.only(bottom: spacing),
            child: Semantics(
              label: radioButton.label,
              value: isSelected ? l10n.selected : l10n.unselected,
              selected: isSelected,
              enabled: !isDisabled,
              child: InkWell(
                onTap: isDisabled
                    ? null
                    : () => _handleSelection(radioButton.value),
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
                          width: radioSize,
                          height: radioSize,
                          child: Radio<T>(
                            value: radioButton.value,
                            groupValue: value,
                            onChanged: onChanged,
                            activeColor:
                                activeColor ?? theme.colorScheme.primary,
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
                        const SizedBox(width: AppDimens.spaceSmall),
                        Flexible(
                          child: Text(
                            radioButton.label,
                            style: theme.textTheme.bodyMedium?.copyWith(
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
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  /// Handles radio button selection with haptic feedback.
  void _handleSelection(T value) {
    if (onChanged == null) return;

    // Provide haptic feedback for better UX
    HapticFeedback.lightImpact();

    onChanged!(value);
  }

  /// Gets radio button size in dp based on size variant.
  double _getRadioSize(RadioButtonSize size) {
    switch (size) {
      case RadioButtonSize.small:
        return AppDimens.iconXSmall;
      case RadioButtonSize.medium:
        return AppDimens.iconSmall;
      case RadioButtonSize.large:
        return AppDimens.iconMedium;
    }
  }
}
