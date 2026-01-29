import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_chat_app/core/base/base_widget.dart';
import 'package:flutter_chat_app/core/constants/app_dimens.dart';
import 'package:flutter_chat_app/core/theme/app_colors.dart';
import 'package:flutter_chat_app/core/theme/app_text_styles.dart';
import 'package:flutter_chat_app/generated/l10n/app_localizations.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/forms/form_enums.dart';

/// **APP SLIDER**
///
/// Slider component for selecting values from a continuous or discrete range.
/// Extends [BaseStatelessWidget] for lifecycle management.
///
/// **Features**:
/// - Continuous and discrete (stepped) modes
/// - Value label display
/// - Min/max value labels
/// - Haptic feedback on value change
/// - Disabled state support
/// - Custom colors and divisions
/// - Accessibility labels
/// - Dark mode support
/// - Touch target >= 48dp (WCAG compliance)
///
/// **Architecture**: Clean Architecture + Design System
/// **Pattern**: Stateless widget with callback-based state management
///
/// **Usage**:
/// ```dart
/// // Continuous slider
/// AppSlider(
///   value: _volume,
///   onChanged: (value) => setState(() => _volume = value),
///   min: 0,
///   max: 100,
///   label: context.l10n.volume,
/// )
///
/// // Discrete slider with divisions
/// AppSlider(
///   value: _rating,
///   onChanged: (value) => setState(() => _rating = value),
///   min: 0,
///   max: 5,
///   divisions: 5,
///   type: SliderType.discrete,
///   label: 'Rating',
/// )
///
/// // Slider with min/max labels
/// AppSlider(
///   value: _brightness,
///   onChanged: (value) => setState(() => _brightness = value),
///   min: 0,
///   max: 100,
///   showMinMaxLabels: true,
///   minLabel: 'Dark',
///   maxLabel: 'Bright',
/// )
///
/// // Disabled slider
/// AppSlider(
///   value: 50,
///   onChanged: null,
///   min: 0,
///   max: 100,
/// )
/// ```
///
/// **Accessibility**:
/// - Semantic label from [label] property
/// - Current value announced to screen readers
/// - Minimum touch target of 48dp
/// - Keyboard navigation support
///
/// **Performance**:
/// - Const constructor for efficient rebuilds
/// - Minimal widget tree depth
/// - Smooth value updates
class AppSlider extends BaseStatelessWidget {
  /// Creates a slider with value range.
  ///
  /// The [value] must be between [min] and [max].
  /// The [onChanged] callback is called when the user changes the value.
  /// If null, the slider is disabled.
  const AppSlider({
    super.key,
    required this.value,
    required this.onChanged,
    this.min = 0.0,
    this.max = 100.0,
    this.divisions,
    this.label,
    this.showMinMaxLabels = false,
    this.minLabel,
    this.maxLabel,
    this.activeColor,
    this.inactiveColor,
    this.thumbColor,
    this.type = SliderType.continuous,
  }) : assert(value >= min && value <= max, 'Value must be between min and max');

  /// Current slider value.
  ///
  /// Must be between [min] and [max].
  final double value;

  /// Callback when slider value changes.
  ///
  /// If null, the slider is disabled and cannot be interacted with.
  final ValueChanged<double>? onChanged;

  /// Minimum value of the slider.
  ///
  /// Defaults to 0.0.
  final double min;

  /// Maximum value of the slider.
  ///
  /// Defaults to 100.0.
  final double max;

  /// Number of discrete divisions.
  ///
  /// If null, the slider is continuous.
  /// If set, the slider will snap to discrete values.
  final int? divisions;

  /// Optional label text displayed above the slider.
  ///
  /// Uses [context.l10n] for localization when possible.
  final String? label;

  /// Whether to show min/max value labels.
  ///
  /// Displays [minLabel] and [maxLabel] at the ends of the slider.
  final bool showMinMaxLabels;

  /// Label for minimum value.
  ///
  /// Only displayed if [showMinMaxLabels] is true.
  final String? minLabel;

  /// Label for maximum value.
  ///
  /// Only displayed if [showMinMaxLabels] is true.
  final String? maxLabel;

  /// Active (filled) track color.
  ///
  /// Defaults to [ColorScheme.primary] from theme.
  final Color? activeColor;

  /// Inactive (unfilled) track color.
  ///
  /// Defaults to theme-appropriate gray.
  final Color? inactiveColor;

  /// Thumb (handle) color.
  ///
  /// Defaults to [ColorScheme.primary] from theme.
  final Color? thumbColor;

  /// Slider type (continuous or discrete).
  final SliderType type;

  @override
  Widget buildContent(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isDisabled = onChanged == null;

    // Determine semantic label
    final semanticLabel = label ?? l10n.slider;

    // Determine semantic value
    final semanticValue = type == SliderType.discrete && divisions != null
        ? '${value.round()} ${l10n.outOf} ${max.round()}'
        : '${value.toStringAsFixed(1)} ${l10n.outOf} ${max.toStringAsFixed(1)}';

    return Semantics(
      label: semanticLabel,
      value: semanticValue,
      enabled: !isDisabled,
      slider: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (label != null) ...[
            Text(
              label!,
              style: AppTextStyles.bodyMedium(context).copyWith(
                color: isDisabled
                    ? (isDark
                        ? AppColors.textSecondaryDarkMode
                            .withValues(alpha: 0.38)
                        : AppColors.textSecondary.withValues(alpha: 0.38))
                    : null,
              ),
            ),
            const SizedBox(height: AppDimens.spaceSmall),
          ],
          Row(
            children: [
              if (showMinMaxLabels && minLabel != null) ...[
                Text(
                  minLabel!,
                  style: AppTextStyles.bodySmall(context).copyWith(
                    color: isDisabled
                        ? (isDark
                            ? AppColors.textSecondaryDarkMode
                                .withValues(alpha: 0.38)
                            : AppColors.textSecondary.withValues(alpha: 0.38))
                        : (isDark
                            ? AppColors.textSecondaryDarkMode
                            : AppColors.textSecondary),
                  ),
                ),
                const SizedBox(width: AppDimens.spaceSmall),
              ],
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor:
                        activeColor ?? theme.colorScheme.primary,
                    inactiveTrackColor: inactiveColor ??
                        (isDark
                            ? AppColors.borderDarkMode
                            : AppColors.border),
                    thumbColor: thumbColor ?? theme.colorScheme.primary,
                    overlayColor: (thumbColor ?? theme.colorScheme.primary)
                        .withValues(alpha: 0.12),
                    valueIndicatorColor:
                        thumbColor ?? theme.colorScheme.primary,
                    // Disabled styling
                    disabledActiveTrackColor: isDark
                        ? AppColors.textSecondaryDarkMode
                            .withValues(alpha: 0.12)
                        : AppColors.textSecondary.withValues(alpha: 0.12),
                    disabledInactiveTrackColor: isDark
                        ? AppColors.borderDarkMode.withValues(alpha: 0.12)
                        : AppColors.border.withValues(alpha: 0.12),
                    disabledThumbColor: isDark
                        ? AppColors.textSecondaryDarkMode
                            .withValues(alpha: 0.38)
                        : AppColors.textSecondary.withValues(alpha: 0.38),
                  ),
                  child: Slider(
                    value: value,
                    onChanged: isDisabled ? null : _handleValueChange,
                    min: min,
                    max: max,
                    divisions: type == SliderType.discrete ? divisions : null,
                    label: type == SliderType.discrete
                        ? value.round().toString()
                        : value.toStringAsFixed(1),
                  ),
                ),
              ),
              if (showMinMaxLabels && maxLabel != null) ...[
                const SizedBox(width: AppDimens.spaceSmall),
                Text(
                  maxLabel!,
                  style: AppTextStyles.bodySmall(context).copyWith(
                    color: isDisabled
                        ? (isDark
                            ? AppColors.textSecondaryDarkMode
                                .withValues(alpha: 0.38)
                            : AppColors.textSecondary.withValues(alpha: 0.38))
                        : (isDark
                            ? AppColors.textSecondaryDarkMode
                            : AppColors.textSecondary),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  /// Handles slider value change with haptic feedback.
  ///
  /// Provides light haptic feedback for better UX.
  void _handleValueChange(double newValue) {
    if (onChanged == null) return;

    // Provide haptic feedback for better UX
    HapticFeedback.selectionClick();

    onChanged!(newValue);
  }
}
