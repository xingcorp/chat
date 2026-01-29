import 'package:flutter/material.dart';
import 'package:flutter_chat_app/core/base/base_widget.dart';
import 'package:flutter_chat_app/core/constants/app_dimens.dart';
import 'package:flutter_chat_app/generated/l10n/app_localizations.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/chat/chat_enums.dart';

/// **APP READ RECEIPT**
///
/// Message delivery and read status indicator component.
/// Extends [BaseStatelessWidget] for lifecycle management.
///
/// **Features**:
/// - Support all status states (sending, sent, delivered, read, failed, pending)
/// - Icon-based indicators (checkmarks, spinner, error)
/// - Color coding (gray → blue for read)
/// - Animation on status change via AnimatedSwitcher
/// - Compact size for message bubbles
/// - Dark mode support
/// - Accessibility labels
///
/// **Architecture**: Clean Architecture + Design System
/// **Pattern**: Stateless widget with animated transitions
///
/// **Usage**:
/// ```dart
/// // Sending status
/// AppReadReceipt(status: MessageStatus.sending)
///
/// // Sent status
/// AppReadReceipt(status: MessageStatus.sent)
///
/// // Read status (blue checkmarks)
/// AppReadReceipt(status: MessageStatus.read)
///
/// // Failed status
/// AppReadReceipt(status: MessageStatus.failed)
/// ```
class AppReadReceipt extends BaseStatelessWidget {
  /// Creates a read receipt indicator.
  const AppReadReceipt({
    super.key,
    required this.status,
    this.size = 16.0,
    this.showAnimation = true,
  });

  /// Message status to display
  final MessageStatus status;

  /// Size of the status icon
  final double size;

  /// Whether to show animation on status change
  final bool showAnimation;

  @override
  Widget buildContent(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final statusWidget = _buildStatusIcon(context, theme, isDark);

    if (!showAnimation) {
      return Semantics(
        label: _getAccessibilityLabel(l10n),
        child: statusWidget,
      );
    }

    return Semantics(
      label: _getAccessibilityLabel(l10n),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: AppDimens.durationMedium),
        transitionBuilder: (child, animation) {
          return FadeTransition(
            opacity: animation,
            child: ScaleTransition(
              scale: animation,
              child: child,
            ),
          );
        },
        child: KeyedSubtree(
          key: ValueKey(status),
          child: statusWidget,
        ),
      ),
    );
  }

  Widget _buildStatusIcon(BuildContext context, ThemeData theme, bool isDark) {
    switch (status) {
      case MessageStatus.sending:
        return SizedBox(
          width: size,
          height: size,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(
              theme.colorScheme.onSurface.withOpacity(isDark ? 0.7 : 0.54),
            ),
          ),
        );

      case MessageStatus.pending:
        return Icon(
          Icons.schedule,
          size: size,
          color: theme.colorScheme.onSurface.withOpacity(isDark ? 0.7 : 0.54),
        );

      case MessageStatus.sent:
        return Icon(
          Icons.check,
          size: size,
          color: theme.colorScheme.onSurface.withOpacity(isDark ? 0.7 : 0.54),
        );

      case MessageStatus.delivered:
        return _buildDoubleCheck(
          size: size,
          color: theme.colorScheme.onSurface.withOpacity(isDark ? 0.7 : 0.54),
        );

      case MessageStatus.read:
        return _buildDoubleCheck(
          size: size,
          color: theme.colorScheme.primary,
        );

      case MessageStatus.failed:
        return Icon(
          Icons.error_outline,
          size: size,
          color: theme.colorScheme.error,
        );
    }
  }

  Widget _buildDoubleCheck({required double size, required Color color}) {
    return SizedBox(
      width: size * 1.2,
      height: size,
      child: Stack(
        children: [
          Positioned(
            left: 0,
            child: Icon(
              Icons.check,
              size: size,
              color: color,
            ),
          ),
          Positioned(
            left: size * 0.4,
            child: Icon(
              Icons.check,
              size: size,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  String _getAccessibilityLabel(AppLocalizations l10n) {
    switch (status) {
      case MessageStatus.sending:
        return l10n.sending;
      case MessageStatus.pending:
        return l10n.pending;
      case MessageStatus.sent:
        return l10n.sent;
      case MessageStatus.delivered:
        return l10n.delivered;
      case MessageStatus.read:
        return l10n.read;
      case MessageStatus.failed:
        return l10n.failed;
    }
  }
}
