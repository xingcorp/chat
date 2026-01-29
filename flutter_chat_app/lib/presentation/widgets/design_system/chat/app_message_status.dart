import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_chat_app/core/base/base_widget.dart';
import 'package:flutter_chat_app/core/constants/app_dimens.dart';
import 'package:flutter_chat_app/core/theme/app_colors.dart';
import 'package:flutter_chat_app/core/theme/app_text_styles.dart';
import 'package:flutter_chat_app/generated/l10n/app_localizations.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/chat/chat_enums.dart';

/// **APP MESSAGE STATUS**
///
/// Comprehensive message status display with retry functionality.
/// Extends [BaseStatelessWidget] for lifecycle management.
///
/// **Features**:
/// - Visual states: sending, sent, delivered, read, failed
/// - Retry button for failed messages
/// - Timestamp display
/// - Color coding (gray → blue for read)
/// - Accessibility labels
/// - Dark mode support
///
/// **Architecture**: Clean Architecture + Design System
/// **Pattern**: Stateless widget with callback-based interaction
///
/// **Usage**:
/// ```dart
/// // Sending state
/// AppMessageStatus(
///   status: MessageStatus.sending,
///   timestamp: DateTime.now(),
/// )
///
/// // Failed state with retry
/// AppMessageStatus(
///   status: MessageStatus.failed,
///   timestamp: DateTime.now(),
///   onRetry: () => _retryMessage(),
/// )
///
/// // Read state with timestamp
/// AppMessageStatus(
///   status: MessageStatus.read,
///   timestamp: DateTime.now(),
///   showTimestamp: true,
/// )
/// ```
///
/// **Accessibility**:
/// - Semantic labels for status
/// - Retry button with proper label
/// - Timestamp announced to screen readers
class AppMessageStatus extends BaseStatelessWidget {
  /// Creates a message status indicator.
  const AppMessageStatus({
    super.key,
    required this.status,
    required this.timestamp,
    this.onRetry,
    this.showTimestamp = true,
    this.compact = false,
  });

  /// Current message status
  final MessageStatus status;

  /// Message timestamp
  final DateTime timestamp;

  /// Callback when retry button is tapped (for failed messages)
  final VoidCallback? onRetry;

  /// Whether to show timestamp
  final bool showTimestamp;

  /// Whether to use compact layout (smaller icons, no timestamp)
  final bool compact;

  @override
  Widget buildContent(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (compact) {
      return _buildCompactStatus(context, theme, l10n, isDark);
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildStatusIndicator(context, theme, l10n, isDark),
        if (showTimestamp) ...[
          const SizedBox(width: AppDimens.spaceXSmall),
          _buildTimestamp(context, theme, isDark),
        ],
      ],
    );
  }

  Widget _buildCompactStatus(
    BuildContext context,
    ThemeData theme,
    AppLocalizations l10n,
    bool isDark,
  ) {
    return _buildStatusIndicator(context, theme, l10n, isDark);
  }

  Widget _buildStatusIndicator(
    BuildContext context,
    ThemeData theme,
    AppLocalizations l10n,
    bool isDark,
  ) {
    switch (status) {
      case MessageStatus.sending:
        return _buildSendingIndicator(context, theme, l10n);

      case MessageStatus.pending:
        return _buildPendingIndicator(context, theme, l10n, isDark);

      case MessageStatus.sent:
        return _buildSentIndicator(context, theme, l10n, isDark);

      case MessageStatus.delivered:
        return _buildDeliveredIndicator(context, theme, l10n, isDark);

      case MessageStatus.read:
        return _buildReadIndicator(context, theme, l10n);

      case MessageStatus.failed:
        return _buildFailedIndicator(context, theme, l10n);
    }
  }

  Widget _buildSendingIndicator(
    BuildContext context,
    ThemeData theme,
    AppLocalizations l10n,
  ) {
    final isDark = theme.brightness == Brightness.dark;
    
    return Semantics(
      label: l10n.sending,
      child: SizedBox(
        width: compact ? AppDimens.iconXSmall : AppDimens.iconSmall,
        height: compact ? AppDimens.iconXSmall : AppDimens.iconSmall,
        child: CircularProgressIndicator(
          strokeWidth: 1.5,
          valueColor: AlwaysStoppedAnimation<Color>(
            isDark 
                ? AppColors.textSecondaryDarkMode 
                : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildPendingIndicator(
    BuildContext context,
    ThemeData theme,
    AppLocalizations l10n,
    bool isDark,
  ) {
    return Semantics(
      label: l10n.pending,
      child: Icon(
        Icons.schedule,
        size: compact ? AppDimens.iconXSmall : AppDimens.iconSmall,
        color: isDark 
            ? AppColors.textSecondaryDarkMode 
            : AppColors.textSecondary,
      ),
    );
  }

  Widget _buildSentIndicator(
    BuildContext context,
    ThemeData theme,
    AppLocalizations l10n,
    bool isDark,
  ) {
    return Semantics(
      label: l10n.sent,
      child: Icon(
        Icons.check,
        size: compact ? AppDimens.iconXSmall : AppDimens.iconSmall,
        color: isDark 
            ? AppColors.textSecondaryDarkMode 
            : AppColors.textSecondary,
      ),
    );
  }

  Widget _buildDeliveredIndicator(
    BuildContext context,
    ThemeData theme,
    AppLocalizations l10n,
    bool isDark,
  ) {
    return Semantics(
      label: l10n.delivered,
      child: Icon(
        Icons.done_all,
        size: compact ? AppDimens.iconXSmall : AppDimens.iconSmall,
        color: isDark 
            ? AppColors.textSecondaryDarkMode 
            : AppColors.textSecondary,
      ),
    );
  }

  Widget _buildReadIndicator(
    BuildContext context,
    ThemeData theme,
    AppLocalizations l10n,
  ) {
    return Semantics(
      label: l10n.read,
      child: Icon(
        Icons.done_all,
        size: compact ? AppDimens.iconXSmall : AppDimens.iconSmall,
        color: AppColors.primary,
      ),
    );
  }

  Widget _buildFailedIndicator(
    BuildContext context,
    ThemeData theme,
    AppLocalizations l10n,
  ) {
    if (onRetry != null) {
      return Semantics(
        button: true,
        label: '${l10n.failed}. ${l10n.tapToRetry}',
        child: InkWell(
          onTap: onRetry,
          borderRadius: BorderRadius.circular(AppDimens.radiusCircular),
          child: Padding(
            padding: const EdgeInsets.all(AppDimens.paddingXSmall),
            child: Icon(
              Icons.error_outline,
              size: compact ? AppDimens.iconXSmall : AppDimens.iconSmall,
              color: AppColors.error,
            ),
          ),
        ),
      );
    }

    return Semantics(
      label: l10n.failed,
      child: Icon(
        Icons.error_outline,
        size: compact ? AppDimens.iconXSmall : AppDimens.iconSmall,
        color: AppColors.error,
      ),
    );
  }

  Widget _buildTimestamp(
    BuildContext context,
    ThemeData theme,
    bool isDark,
  ) {
    final l10n = AppLocalizations.of(context);
    final timeText = _formatTimestamp(timestamp, l10n);

    return Semantics(
      label: l10n.sentAt(timeText),
      child: Text(
        timeText,
        style: AppTextStyles.labelSmall(context).copyWith(
          color: isDark 
              ? AppColors.textSecondaryDarkMode 
              : AppColors.textSecondary,
          fontSize: 11,
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime dateTime, AppLocalizations l10n) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    // If today, show time only
    if (difference.inDays == 0) {
      return DateFormat.jm().format(dateTime); // e.g., "2:30 PM"
    }

    // If yesterday
    if (difference.inDays == 1) {
      return '${l10n.yesterday} ${DateFormat.jm().format(dateTime)}';
    }

    // If within a week, show day name
    if (difference.inDays < 7) {
      return DateFormat('EEE h:mm a').format(dateTime); // e.g., "Mon 2:30 PM"
    }

    // Otherwise show date
    return DateFormat('MMM d, h:mm a').format(dateTime); // e.g., "Jan 15, 2:30 PM"
  }
}

