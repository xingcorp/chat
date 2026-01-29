import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_chat_app/core/base/base_widget.dart';
import 'package:flutter_chat_app/core/constants/app_dimens.dart';
import 'package:flutter_chat_app/core/theme/app_colors.dart';
import 'package:flutter_chat_app/core/theme/app_text_styles.dart';
import 'package:flutter_chat_app/generated/l10n/app_localizations.dart';
import 'package:intl/intl.dart';

/// **APP DATE PICKER**
///
/// Date picker component that integrates with Flutter's native date picker.
/// Extends [BaseStatelessWidget] for lifecycle management.
///
/// **Features**:
/// - Native platform date picker integration
/// - Min/max date constraints
/// - Custom date format
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
/// // Basic date picker
/// AppDatePicker(
///   selectedDate: _selectedDate,
///   onDateSelected: (date) => setState(() => _selectedDate = date),
///   label: context.l10n.selectDate,
/// )
///
/// // Date picker with constraints
/// AppDatePicker(
///   selectedDate: _selectedDate,
///   onDateSelected: (date) => setState(() => _selectedDate = date),
///   firstDate: DateTime(2020),
///   lastDate: DateTime(2030),
///   label: 'Select Birth Date',
/// )
///
/// // Date picker with custom format
/// AppDatePicker(
///   selectedDate: _selectedDate,
///   onDateSelected: (date) => setState(() => _selectedDate = date),
///   dateFormat: DateFormat('dd/MM/yyyy'),
/// )
///
/// // Disabled date picker
/// AppDatePicker(
///   selectedDate: _selectedDate,
///   onDateSelected: null,
///   label: 'Cannot change',
/// )
/// ```
///
/// **Accessibility**:
/// - Semantic label from [label] property
/// - Selected date announced to screen readers
/// - Minimum touch target of 48dp
/// - Keyboard navigation support
///
/// **Performance**:
/// - Const constructor for efficient rebuilds
/// - Minimal widget tree depth
/// - Native picker for optimal UX
class AppDatePicker extends BaseStatelessWidget {
  /// Creates a date picker.
  ///
  /// The [selectedDate] is the currently selected date.
  /// The [onDateSelected] callback is called when a date is selected.
  /// If null, the date picker is disabled.
  const AppDatePicker({
    super.key,
    this.selectedDate,
    required this.onDateSelected,
    this.label,
    this.hint,
    this.firstDate,
    this.lastDate,
    this.dateFormat,
    this.helpText,
    this.cancelText,
    this.confirmText,
  });

  /// Currently selected date.
  final DateTime? selectedDate;

  /// Callback when a date is selected.
  ///
  /// If null, the date picker is disabled.
  final ValueChanged<DateTime?>? onDateSelected;

  /// Optional label text displayed above the picker.
  final String? label;

  /// Hint text displayed when no date is selected.
  final String? hint;

  /// Earliest selectable date.
  ///
  /// Defaults to 100 years ago.
  final DateTime? firstDate;

  /// Latest selectable date.
  ///
  /// Defaults to 100 years from now.
  final DateTime? lastDate;

  /// Custom date format.
  ///
  /// Defaults to locale-aware medium date format.
  final DateFormat? dateFormat;

  /// Help text shown in the date picker dialog.
  final String? helpText;

  /// Cancel button text in the date picker dialog.
  final String? cancelText;

  /// Confirm button text in the date picker dialog.
  final String? confirmText;

  @override
  Widget buildContent(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isDisabled = onDateSelected == null;

    // Determine display text
    final displayText = selectedDate != null
        ? _formatDate(selectedDate!, context)
        : (hint ?? l10n.selectDate);

    // Determine semantic label
    final semanticLabel = label ?? l10n.selectDate;
    final semanticValue = selectedDate != null
        ? _formatDate(selectedDate!, context)
        : l10n.selectDate;

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
          InkWell(
            onTap: isDisabled ? null : () => _showDatePicker(context),
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
                    Icons.calendar_today,
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
                      style: AppTextStyles.bodyMedium(context).copyWith(
                        color: selectedDate == null
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
                  if (selectedDate != null && !isDisabled) ...[
                    const SizedBox(width: AppDimens.spaceSmall),
                    InkWell(
                      onTap: _clearDate,
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

  /// Shows the native date picker dialog.
  Future<void> _showDatePicker(BuildContext context) async {
    HapticFeedback.lightImpact();

    final l10n = AppLocalizations.of(context);
    final now = DateTime.now();

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? now,
      firstDate: firstDate ?? DateTime(now.year - 100),
      lastDate: lastDate ?? DateTime(now.year + 100),
      helpText: helpText ?? l10n.selectDate,
      cancelText: cancelText ?? l10n.cancel,
      confirmText: confirmText ?? l10n.ok,
    );

    if (picked != null && picked != selectedDate) {
      HapticFeedback.selectionClick();
      onDateSelected?.call(picked);
    }
  }

  /// Clears the selected date.
  void _clearDate() {
    HapticFeedback.lightImpact();
    onDateSelected?.call(null);
  }

  /// Formats the date using the specified format or locale default.
  String _formatDate(DateTime date, BuildContext context) {
    if (dateFormat != null) {
      return dateFormat!.format(date);
    }

    // Use locale-aware medium date format
    final locale = Localizations.localeOf(context);
    return DateFormat.yMMMd(locale.toString()).format(date);
  }
}
