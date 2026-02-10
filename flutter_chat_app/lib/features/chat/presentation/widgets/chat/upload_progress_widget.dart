import 'package:flutter/material.dart';
import 'package:flutter_chat_app/generated/l10n/app_localizations.dart';
import 'package:flutter_chat_app/l10n/l10n.dart';

/// Upload progress indicator widget for message attachments
///
/// Features:
/// - Progress percentage display
/// - Status text (compressing, uploading, failed)
/// - Circular progress indicator
/// - Cancel upload button
/// - Theme-aware styling
class UploadProgressIndicator extends StatelessWidget {
  /// Upload progress (0.0 to 1.0)
  final double progress;

  /// Upload status
  final UploadStatus status;

  /// Callback when cancel button is tapped
  final VoidCallback? onCancel;

  /// File name being uploaded
  final String? fileName;

  const UploadProgressIndicator({
    Key? key,
    required this.progress,
    required this.status,
    this.onCancel,
    this.fileName,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;

    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4.0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Progress indicator
          _buildProgressIndicator(context),

          const SizedBox(width: 12.0),

          // Status text and file name
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _getStatusText(l10n),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: _getStatusColor(theme),
                  ),
                ),
                if (fileName != null && fileName!.isNotEmpty) ...[
                  const SizedBox(height: 4.0),
                  Text(
                    fileName!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),

          // Cancel button
          if (status == UploadStatus.uploading && onCancel != null) ...[
            const SizedBox(width: 8.0),
            IconButton(
              icon: const Icon(Icons.close, size: 20),
              onPressed: onCancel,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(
                minWidth: 32,
                minHeight: 32,
              ),
            ),
          ],

          // Retry button for failed uploads
          if (status == UploadStatus.failed && onCancel != null) ...[
            const SizedBox(width: 8.0),
            IconButton(
              icon: const Icon(Icons.refresh, size: 20),
              onPressed: onCancel,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(
                minWidth: 32,
                minHeight: 32,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProgressIndicator(BuildContext context) {
    final theme = Theme.of(context);

    switch (status) {
      case UploadStatus.compressing:
      case UploadStatus.uploading:
        return SizedBox(
          width: 40,
          height: 40,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CircularProgressIndicator(
                value: progress,
                strokeWidth: 3.0,
                backgroundColor: theme.dividerColor,
                valueColor: AlwaysStoppedAnimation<Color>(
                  theme.colorScheme.primary,
                ),
              ),
              Text(
                '${(progress * 100).toInt()}%',
                style: theme.textTheme.labelSmall?.copyWith(
                  fontSize: 10.0,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );

      case UploadStatus.completed:
        return Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.check,
            color: Colors.green,
            size: 24,
          ),
        );

      case UploadStatus.failed:
        return Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: theme.colorScheme.error.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.error_outline,
            color: theme.colorScheme.error,
            size: 24,
          ),
        );
    }
  }

  String _getStatusText(AppLocalizations l10n) {
    switch (status) {
      case UploadStatus.compressing:
        return l10n.compressing;
      case UploadStatus.uploading:
        return l10n.uploadProgress((progress * 100).toInt());
      case UploadStatus.completed:
        return l10n.sent;
      case UploadStatus.failed:
        return l10n.uploadFailed;
    }
  }

  Color _getStatusColor(ThemeData theme) {
    switch (status) {
      case UploadStatus.compressing:
      case UploadStatus.uploading:
        return theme.colorScheme.primary;
      case UploadStatus.completed:
        return Colors.green;
      case UploadStatus.failed:
        return theme.colorScheme.error;
    }
  }
}

/// Upload status enum
enum UploadStatus {
  compressing,
  uploading,
  completed,
  failed,
}

/// Compact upload progress indicator for message bubble
///
/// Used to show upload progress directly in the message bubble
class CompactUploadProgress extends StatelessWidget {
  /// Upload progress (0.0 to 1.0)
  final double progress;

  /// Upload status
  final UploadStatus status;

  const CompactUploadProgress({
    Key? key,
    required this.progress,
    required this.status,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
        borderRadius: BorderRadius.circular(4.0),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              value: status == UploadStatus.uploading ? progress : null,
              strokeWidth: 2.0,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          const SizedBox(width: 6.0),
          Text(
            status == UploadStatus.compressing
                ? l10n.compressing
                : l10n.uploadProgress((progress * 100).toInt()),
            style: theme.textTheme.labelSmall?.copyWith(
              color: Colors.white,
              fontSize: 11.0,
            ),
          ),
        ],
      ),
    );
  }
}
