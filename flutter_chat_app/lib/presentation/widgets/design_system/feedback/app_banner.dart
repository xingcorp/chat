import 'package:flutter/material.dart';
import 'package:flutter_chat_app/core/base/base_widget.dart';
import 'package:flutter_chat_app/core/constants/app_dimens.dart';
import 'package:flutter_chat_app/core/theme/app_text_styles.dart';
import 'package:flutter_chat_app/core/theme/app_theme_extensions.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/feedback/feedback_type.dart';

/// A persistent banner component for important messages.
///
/// Features:
/// - Multiple types (success, error, warning, info)
/// - Icon support
/// - Action button support
/// - Dismissible option
/// - Accessibility compliant
/// - Dark mode support
///
/// Example:
/// ```dart
/// AppBanner(
///   message: 'You are offline. Changes will sync when you reconnect.',
///   type: FeedbackType.warning,
///   action: TextButton(
///     onPressed: () => checkConnection(),
///     child: Text('Retry'),
///   ),
///   onDismiss: () => hideBanner(),
/// )
/// ```
class AppBanner extends BaseStatelessWidget {
  /// Creates an [AppBanner].
  const AppBanner({
    required this.message,
    this.type = FeedbackType.info,
    this.action,
    this.onDismiss,
    this.showIcon = true,
    super.key,
  });

  /// The message to display.
  final String message;

  /// The type of banner.
  final FeedbackType type;

  /// Optional action button.
  final Widget? action;

  /// Callback when banner is dismissed.
  final VoidCallback? onDismiss;

  /// Whether to show the icon.
  final bool showIcon;

  @override
  Widget buildContent(BuildContext context) {
    final theme = Theme.of(context);
    final extensions = theme.extension<AppThemeExtensions>();

    final (backgroundColor, foregroundColor, icon) = _getColorsAndIcon(
      theme,
      extensions,
      type,
    );

    return Material(
      color: backgroundColor,
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: AppDimens.paddingMedium,
          vertical: AppDimens.paddingSmall,
        ),
        child: Row(
          children: [
            if (showIcon) ...[
              Icon(
                icon,
                color: foregroundColor,
                size: AppDimens.iconSizeMedium,
              ),
              SizedBox(width: AppDimens.spaceSmall),
            ],
            Expanded(
              child: Text(
                message,
                style: AppTextStyles.bodyMedium(context).copyWith(
                  color: foregroundColor,
                ),
              ),
            ),
            if (action != null) ...[
              SizedBox(width: AppDimens.spaceSmall),
              action!,
            ],
            if (onDismiss != null) ...[
              SizedBox(width: AppDimens.spaceSmall),
              IconButton(
                icon: Icon(
                  Icons.close,
                  size: AppDimens.iconSizeSmall,
                ),
                color: foregroundColor,
                onPressed: onDismiss,
                tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  static (Color, Color, IconData) _getColorsAndIcon(
    ThemeData theme,
    AppThemeExtensions? extensions,
    FeedbackType type,
  ) {
    switch (type) {
      case FeedbackType.success:
        return (
          extensions?.successColor ?? Colors.green,
          extensions?.onSuccessColor ?? Colors.white,
          Icons.check_circle_outline,
        );
      case FeedbackType.error:
        return (
          theme.colorScheme.error,
          theme.colorScheme.onError,
          Icons.error_outline,
        );
      case FeedbackType.warning:
        return (
          extensions?.warningColor ?? Colors.orange,
          extensions?.onWarningColor ?? Colors.white,
          Icons.warning_amber_outlined,
        );
      case FeedbackType.info:
        return (
          extensions?.infoColor ?? theme.colorScheme.primary,
          extensions?.onInfoColor ?? theme.colorScheme.onPrimary,
          Icons.info_outline,
        );
    }
  }
}
