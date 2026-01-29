import 'package:flutter/material.dart';
import 'package:flutter_chat_app/core/base/base_widget.dart';
import 'package:flutter_chat_app/core/constants/app_dimens.dart';
import 'package:flutter_chat_app/l10n/l10n.dart';

/// A customizable empty state widget.
///
/// Features:
/// - Customizable illustration/icon
/// - Title and message
/// - Optional action button
/// - Accessibility compliant
/// - Dark mode support
///
/// Example:
/// ```dart
/// AppEmptyState(
///   icon: Icons.inbox,
///   title: 'No messages',
///   message: 'Start a conversation',
///   actionLabel: 'New Message',
///   onAction: () {},
/// )
/// ```
class AppEmptyState extends BaseStatelessWidget {
  /// Creates an [AppEmptyState].
  const AppEmptyState({
    this.icon,
    this.illustration,
    this.title,
    this.message,
    this.actionLabel,
    this.onAction,
    super.key,
  });

  /// The icon to display.
  final IconData? icon;

  /// Custom illustration widget.
  final Widget? illustration;

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
            // Illustration or icon
            if (illustration != null)
              illustration!
            else if (icon != null)
              Icon(
                icon,
                size: AppDimens.iconXXLarge,
                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
              ),

            const SizedBox(height: AppDimens.spaceLarge),

            // Title
            if (title != null)
              Text(
                title!,
                style: theme.textTheme.titleLarge?.copyWith(
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
                style: theme.textTheme.bodyMedium?.copyWith(
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
