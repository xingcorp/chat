import 'package:flutter/material.dart';
import 'package:flutter_chat_app/core/base/base_widget.dart';
import 'package:flutter_chat_app/core/constants/app_dimens.dart';
import 'package:flutter_chat_app/l10n/l10n.dart';

/// A customizable no connection state widget.
///
/// Features:
/// - No connection icon
/// - Informative message
/// - Retry button
/// - Accessibility compliant
/// - Dark mode support
///
/// Example:
/// ```dart
/// AppNoConnection(
///   onRetry: () {},
/// )
/// ```
class AppNoConnection extends BaseStatelessWidget {
  /// Creates an [AppNoConnection].
  const AppNoConnection({
    this.title,
    this.message,
    this.onRetry,
    this.retryLabel,
    super.key,
  });

  /// The title text.
  final String? title;

  /// The message text.
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
            // No connection icon
            Icon(
              Icons.wifi_off,
              size: AppDimens.iconSizeXXLarge,
              color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
            ),

            SizedBox(height: AppDimens.spaceLarge),

            // Title
            Text(
              title ?? l10n.noInternetConnection,
              style: theme.textTheme.titleLarge?.copyWith(
                color: theme.colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),

            SizedBox(height: AppDimens.spaceSmall),

            // Message
            Text(
              message ?? l10n.checkInternetConnection,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),

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
