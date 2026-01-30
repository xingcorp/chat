import 'package:flutter/material.dart';
import 'package:flutter_chat_app/core/base/base_widget.dart';
import 'package:flutter_chat_app/core/constants/app_dimens.dart';
import 'package:flutter_chat_app/core/theme/app_text_styles.dart';
import 'package:flutter_chat_app/l10n/l10n.dart';

/// A customizable error state widget.
///
/// Features:
/// - Error icon
/// - Error message
/// - Retry button
/// - Accessibility compliant
/// - Dark mode support
///
/// Example:
/// ```dart
/// AppErrorState(
///   message: 'Failed to load data',
///   onRetry: () {},
/// )
/// ```
class AppErrorState extends BaseStatelessWidget {
  /// Creates an [AppErrorState].
  const AppErrorState({
    this.icon,
    this.title,
    this.message,
    this.onRetry,
    this.retryLabel,
    super.key,
  });

  /// The error icon.
  final IconData? icon;

  /// The error title.
  final String? title;

  /// The error message.
  final String? message;

  /// Called when retry button is pressed.
  final VoidCallback? onRetry;

  /// The retry button label.
  final String? retryLabel;

  @override
  Widget buildContent(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;

    return Center(
      child: Padding(
        padding: EdgeInsets.all(AppDimens.paddingXLarge),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Error icon
            Icon(
              icon ?? Icons.error_outline,
              size: AppDimens.iconSizeXXLarge,
              color: theme.colorScheme.error,
            ),

            SizedBox(height: AppDimens.spaceLarge),

            // Title
            Text(
              title ?? l10n.errorOccurred,
              style: AppTextStyles.titleLarge.copyWith(
                color: theme.colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),

            if (message != null) ...[
              SizedBox(height: AppDimens.spaceSmall),
              Text(
                message!,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],

            // Retry button
            if (onRetry != null) ...[
              SizedBox(height: AppDimens.spaceLarge),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: Text(retryLabel ?? l10n.retry),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
