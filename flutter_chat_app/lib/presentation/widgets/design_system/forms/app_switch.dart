import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_chat_app/core/base/base_widget.dart';
import 'package:flutter_chat_app/core/constants/app_dimens.dart';
import 'package:flutter_chat_app/core/theme/app_colors.dart';
import 'package:flutter_chat_app/generated/l10n/app_localizations.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/forms/form_enums.dart';

/// **APP SWITCH**
///
/// Toggle switch component for binary on/off states.
/// Extends [BaseStatelessWidget] for lifecycle management.
///
/// **Features**:
/// - Smooth toggle animation (300ms)
/// - Haptic feedback on toggle
/// - Label and description support
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
/// // Basic switch
/// AppSwitch(
///   value: _isEnabled,
///   onChanged: (value) => setState(() => _isEnabled = value),
///   label: context.l10n.enabled,
/// )
///
/// // Switch with description
/// AppSwitch(
///   value: _notificationsEnabled,
///   onChanged: (value) => setState(() => _notificationsEnabled = value),
///   label: 'Push Notifications',
///   description: 'Receive notifications when you get new messages',
/// )
///
/// // Disabled switch
/// AppSwitch(
///   value: true,
///   onChanged: null,
///   label: 'Cannot toggle',
/// )
///
/// // Custom size and colors
/// AppSwitch(
///   value: _isEnabled,
///   onChanged: (value) => setState(() => _isEnabled = value),
///   size: SwitchSize.large,
///   activeColor: Colors.green,
///   activeTrackColor: Colors.green.withValues(alpha: 0.5),
/// )
/// ```
///
/// **Accessibility**:
/// - Semantic label from [label] property
/// - On/off state announced to screen readers
/// - Minimum touch target of 48dp
/// - Keyboard navigation support
///
/// **Performance**:
/// - Const constructor for efficient rebuilds
/// - Minimal widget tree depth
/// - Smooth 300ms animation
class AppSwitch extends BaseStatelessWidget {
  /// Creates a toggle switch with optional label and description.
  ///
  /// The [value] parameter determines the switch state (on/off).
  /// The [onChanged] callback is called when the user toggles the switch.
  /// If null, the switch is disabled.
  const AppSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    this.label,
    this.description,
    this.activeColor,
    this.activeTrackColor,
    this.inactiveThumbColor,
    this.inactiveTrackColor,
    this.size = SwitchSize.medium,
  });

  /// Current switch value.
  ///
  /// - `true`: switch is on
  /// - `false`: switch is off
  final bool value;

  /// Callback when switch value changes.
  ///
  /// If null, the switch is disabled and cannot be toggled.
  final ValueChanged<bool>? onChanged;

  /// Optional label text displayed next to the switch.
  ///
  /// Uses [context.l10n] for localization when possible.
  final String? label;

  /// Optional description text displayed below the label.
  ///
  /// Provides additional context about what the switch controls.
  final String? description;

  /// Active (on) thumb color.
  ///
  /// Defaults to [ColorScheme.primary] from theme.
  final Color? activeColor;

  /// Active (on) track color.
  ///
  /// Defaults to [ColorScheme.primary] with 50% opacity.
  final Color? activeTrackColor;

  /// Inactive (off) thumb color.
  ///
  /// Defaults to theme-appropriate gray.
  final Color? inactiveThumbColor;

  /// Inactive (off) track color.
  ///
  /// Defaults to theme-appropriate gray with opacity.
  final Color? inactiveTrackColor;

  /// Switch size variant.
  ///
  /// Determines the size of the switch:
  /// - [SwitchSize.small]: 32dp width
  /// - [SwitchSize.medium]: 40dp width (default)
  /// - [SwitchSize.large]: 48dp width
  final SwitchSize size;

  @override
  Widget buildContent(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isDisabled = onChanged == null;

    final switchScale = _getSwitchScale(size);

    // Determine semantic label
    final semanticLabel = label ?? (value ? l10n.enabled : l10n.disabled);

    // Determine semantic state
    final semanticState = value ? l10n.enabled : l10n.disabled;

    return Semantics(
      label: semanticLabel,
      value: semanticState,
      toggled: value,
      enabled: !isDisabled,
      child: InkWell(
        onTap: isDisabled ? null : _handleToggle,
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
                if (label != null || description != null) ...[
                  Flexible(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (label != null)
                          Text(
                            label!,
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
                        if (description != null) ...[
                          const SizedBox(height: AppDimens.spaceXSmall),
                          Text(
                            description!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: isDisabled
                                  ? (isDark
                                      ? AppColors.textSecondaryDarkMode
                                          .withValues(alpha: 0.38)
                                      : AppColors.textSecondary
                                          .withValues(alpha: 0.38))
                                  : (isDark
                                      ? AppColors.textSecondaryDarkMode
                                      : AppColors.textSecondary),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: AppDimens.spaceSmall),
                ],
                Transform.scale(
                  scale: switchScale,
                  child: Switch(
                    value: value,
                    onChanged: onChanged,
                    activeColor: activeColor ?? theme.colorScheme.primary,
                    activeTrackColor: activeTrackColor ??
                        (activeColor ?? theme.colorScheme.primary)
                            .withValues(alpha: 0.5),
                    inactiveThumbColor: inactiveThumbColor ??
                        (isDark
                            ? AppColors.textSecondaryDarkMode
                            : AppColors.textSecondary),
                    inactiveTrackColor: inactiveTrackColor ??
                        (isDark
                            ? AppColors.borderDarkMode
                            : AppColors.border),
                    // Apply disabled styling
                    thumbColor: isDisabled
                        ? WidgetStateProperty.all(
                            isDark
                                ? AppColors.textSecondaryDarkMode
                                    .withValues(alpha: 0.12)
                                : AppColors.textSecondary
                                    .withValues(alpha: 0.12),
                          )
                        : null,
                    trackColor: isDisabled
                        ? WidgetStateProperty.all(
                            isDark
                                ? AppColors.borderDarkMode
                                    .withValues(alpha: 0.12)
                                : AppColors.border.withValues(alpha: 0.12),
                          )
                        : null,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Handles switch toggle with haptic feedback.
  ///
  /// Provides light haptic feedback for better UX.
  void _handleToggle() {
    if (onChanged == null) return;

    // Provide haptic feedback for better UX
    HapticFeedback.lightImpact();

    onChanged!(!value);
  }

  /// Gets switch scale factor based on size variant.
  double _getSwitchScale(SwitchSize size) {
    switch (size) {
      case SwitchSize.small:
        return 0.8;
      case SwitchSize.medium:
        return 1.0;
      case SwitchSize.large:
        return 1.2;
    }
  }
}
