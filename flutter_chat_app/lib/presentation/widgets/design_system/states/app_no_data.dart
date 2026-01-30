import 'package:flutter/material.dart';
import 'package:flutter_chat_app/core/base/base_widget.dart';
import 'package:flutter_chat_app/core/constants/app_dimens.dart';
import 'package:flutter_chat_app/core/theme/app_text_styles.dart';
import 'package:flutter_chat_app/l10n/l10n.dart';

/// A customizable no data state widget.
///
/// Features:
/// - No data icon
/// - Informative message
/// - Optional action button
/// - Accessibility compliant
/// - Dark mode support
///
/// Example:
/// ```dart
/// AppNoData(
///   message: 'No items found',
///   actionLabel: 'Add Item',
///   onAction: () {},
/// )
/// ```
class AppNoData extends BaseStatelessWidget {
  /// Creates an [AppNoData].
  const AppNoData({
    this.icon,
    this.title,
    this.message,
    this.actionLabel,
    this.onAction,
    super.key,
  });

  /// The icon to display.
  final IconData? icon;

  /// The title text.
  final String? title;

  /// The message text.
  final String? message;

  /// The action button label.
  final String? actionLabel;

  /// Called when action button is pressed.
  final VoidCallback? onAction;

  @override
  Widget buildContent(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimens.paddingXLarge),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            // No data icon
            Icon(
              icon ?? Icons.inbox_outlined,
              size: AppDimens.iconXXLarge,
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),

            const SizedBox(height: AppDimens.spaceLarge),

            // Title
            if (title != null)
              Text(
                title!,
                style: AppTextStyles.titleLarge.copyWith(
                  color: theme.colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),

            if (title != null && message != null)
              const SizedBox(height: AppDimens.spaceSmall),

            // Message
            if (message != null)
              Text(
                message!,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),

            // Action button
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: AppDimens.spaceLarge),
              ElevatedButton(
                onPressed: onAction,
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
