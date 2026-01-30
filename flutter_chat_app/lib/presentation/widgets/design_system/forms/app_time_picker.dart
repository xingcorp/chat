import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_chat_app/core/base/base_widget.dart';
import 'package:flutter_chat_app/core/constants/app_dimens.dart';
import 'package:flutter_chat_app/core/theme/app_colors.dart';
import 'package:flutter_chat_app/core/theme/app_text_styles.dart';
import 'package:flutter_chat_app/generated/l10n/app_localizations.dart';

/// **APP TIME PICKER**
///
/// Time picker component that integrates with Flutter's native time picker.
/// Extends [BaseStatelessWidget] for lifecycle management.
///
/// **Features**:
/// - Native platform time picker integration
/// - 12-hour and 24-hour format support
/// - Locale-aware formatting
/// - Disabled state support
/// - Haptic feedback on interaction
/// - Accessibility labels
/// - Dark mode support
/// - Touch target >= 48dp (WCAG compliance)
///
/// **Architecture**: Clean Architecture + Design System
/// **Pattern**: Stateless widget with callback-based state management
///
/// **Usage**:
/// ```dart
/// // Basic time picker
/// AppTimePicker(
///   selectedTime: _selectedTime,
///   onTimeSelected: (time) => setState(() => _selectedTime = time),
///   label: context.l10n.selectTime,
/// )
///
/// // 24-hour format time picker
/// AppTimePicker(
///   selectedTime: _selectedTime,
///   onTimeSelected: (time) => setState(() => _selectedTime = time),
///   use24HourFormat: true,
/// )
///
/// // Time picker with custom hint
/// AppTimePicker(
///   selectedTime: _selectedTime,
///   onTimeSelected: (time) => setState(() => _selectedTime = time),
///   hint: 'Pick a time',
/// )
///
/// // Disabled time picker
/// AppTimePicker(
///   selectedTime: _selectedTime,
///   onTimeSelected: null,
///   label: 'Cannot change',
/// )
/// ```
///
/// **Accessibility**:
/// - Semantic label from [label] property
/// - Selected time announced to screen readers
/// - Minimum touch target of 48dp
/// - Keyboard navigation support
///
/// **Performance**:
/// - Const constructor for efficient rebuilds
/// - Minimal widget tree depth
/// - Native picker for optimal UX
class AppTimePicker extends BaseStatelessWidget {
  /// Creates a time picker.
  ///
  /// The [selectedTime] is the currently selected time.
  /// The [onTimeSelected] callback is called when a time is selected.
  /// If null, the time picker is disabled.
  const AppTimePicker({
    super.key,
    this.selectedTime,
    required this.onTimeSelected,
    this.label,
    this.hint,
    this.use24HourFormat = false,
    this.helpText,
    this.cancelText,
    this.confirmText,
  });

  /// Currently selected time.
  final TimeOfDay? selectedTime;

  /// Callback when a time is selected.
  ///
  /// If null, the time picker is disabled.
  final ValueChanged<TimeOfDay?>? onTimeSelected;

  /// Optional label text displayed above the picker.
  final String? label;

  /// Hint text displayed when no time is selected.
  final String? hint;

  /// Whether to use 24-hour format.
  ///
  /// Defaults to false (12-hour format with AM/PM).
  final bool use24HourFormat;

  /// Help text shown in the time picker dialog.
  final String? helpText;

  /// Cancel button text in the time picker dialog.
  final String? cancelText;

  /// Confirm button text in the time picker dialog.
  final String? confirmText;

  @override
  Widget buildContent(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isDisabled = onTimeSelected == null;

    // Determine display text
    final displayText = selectedTime != null
        ? _formatTime(selectedTime!, context)
        : (hint ?? l10n.selectTime);

    // Determine semantic label
    final semanticLabel = label ?? l10n.selectTime;
    final semanticValue = selectedTime != null
        ? _formatTime(selectedTime!, context)
        : l10n.selectTime;

    return Semantics(
      label: semanticLabel,
      value: semanticValue,
      enabled: !isDisabled,
      button: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (label != null) ...[
            Text(
              label!,
              style: AppTextStyles.bodyMedium.copyWith(
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
          InkWell(
            onTap: isDisabled ? null : () => _showTimePicker(context),
            borderRadius: BorderRadius.circular(AppDimens.radiusSmall),
            child: Container(
              constraints: const BoxConstraints(
                minHeight: AppDimens.touchTargetMin,
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimens.paddingMedium,
                vertical: AppDimens.paddingSmall,
              ),
              decoration: BoxDecoration(
                border: Border.all(
                  color: isDisabled
                      ? (isDark
                          ? AppColors.borderDarkMode.withValues(alpha: 0.38)
                          : AppColors.border.withValues(alpha: 0.38))
                      : (isDark ? AppColors.borderDarkMode : AppColors.border),
                ),
                borderRadius: BorderRadius.circular(AppDimens.radiusSmall),
                color: isDisabled
                    ? (isDark
                        ? AppColors.inputBackgroundDarkMode
                            .withValues(alpha: 0.38)
                        : AppColors.inputBackground.withValues(alpha: 0.38))
                    : (isDark
                        ? AppColors.inputBackgroundDarkMode
                        : AppColors.inputBackground),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: AppDimens.iconSmall,
                    color: isDisabled
                        ? (isDark
                            ? AppColors.iconDarkMode.withValues(alpha: 0.38)
                            : AppColors.icon.withValues(alpha: 0.38))
                        : (isDark ? AppColors.iconDarkMode : AppColors.icon),
                  ),
                  const SizedBox(width: AppDimens.spaceSmall),
                  Expanded(
                    child: Text(
                      displayText,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: selectedTime == null
                            ? (isDark
                                ? AppColors.textHintDarkMode
                                : AppColors.textHint)
                            : (isDisabled
                                ? (isDark
                                    ? AppColors.textSecondaryDarkMode
                                        .withValues(alpha: 0.38)
                                    : AppColors.textSecondary
                                        .withValues(alpha: 0.38))
                                : null),
                      ),
                    ),
                  ),
                  if (selectedTime != null && !isDisabled) ...[
                    const SizedBox(width: AppDimens.spaceSmall),
                    InkWell(
                      onTap: _clearTime,
                      borderRadius: BorderRadius.circular(AppDimens.radiusSmall),
                      child: Padding(
                        padding: const EdgeInsets.all(AppDimens.paddingXSmall),
                        child: Icon(
                          Icons.clear,
                          size: AppDimens.iconSmall,
                          color: isDark
                              ? AppColors.iconDarkMode
                              : AppColors.icon,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Shows the native time picker dialog.
  Future<void> _showTimePicker(BuildContext context) async {
    HapticFeedback.lightImpact();

    final l10n = AppLocalizations.of(context);
    final now = TimeOfDay.now();

    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: selectedTime ?? now,
      helpText: helpText ?? l10n.selectTime,
      cancelText: cancelText ?? l10n.cancel,
      confirmText: confirmText ?? l10n.ok,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            alwaysUse24HourFormat: use24HourFormat,
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != selectedTime) {
      HapticFeedback.selectionClick();
      onTimeSelected?.call(picked);
    }
  }

  /// Clears the selected time.
  void _clearTime() {
    HapticFeedback.lightImpact();
    onTimeSelected?.call(null);
  }

  /// Formats the time using locale-aware formatting.
  String _formatTime(TimeOfDay time, BuildContext context) {
    if (use24HourFormat) {
      // 24-hour format: HH:mm
      final hour = time.hour.toString().padLeft(2, '0');
      final minute = time.minute.toString().padLeft(2, '0');
      return '$hour:$minute';
    } else {
      // 12-hour format with AM/PM
      return time.format(context);
    }
  }
}
