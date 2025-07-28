/// **ERROR DISPLAY WIDGET - VIETNAMESE LOCALIZED ERROR UI**
///
/// Professional error display widget following enterprise standards:
/// - Vietnamese localized error messages
/// - Context-aware error information
/// - Recovery guidance and actions
/// - Consistent Material Design 3 styling
///
/// **Architecture:** Clean Architecture + Material Design + Localization

import 'package:flutter/material.dart';
import 'package:flutter_chat_app/core/constants/app_dimensions.dart';
import 'package:flutter_chat_app/core/error/failures.dart';
import 'package:flutter_chat_app/core/localization/error_localization_service.dart';

import '../../../core/theme/app_colors.dart';

/// **ERROR DISPLAY WIDGET**
class ErrorDisplayWidget extends StatelessWidget {
  /// The failure to display
  final Failure failure;

  /// Additional context for error formatting
  final Map<String, dynamic>? context;

  /// Whether to show recovery guidance
  final bool showRecoveryGuidance;

  /// Whether to show technical details (for debugging)
  final bool showTechnicalDetails;

  /// Primary action callback (usually retry)
  final VoidCallback? onPrimaryAction;

  /// Secondary action callback (usually view guidance)
  final VoidCallback? onSecondaryAction;

  /// Dismiss callback
  final VoidCallback? onDismiss;

  /// Custom primary action text
  final String? primaryActionText;

  /// Custom secondary action text
  final String? secondaryActionText;

  const ErrorDisplayWidget({
    super.key,
    required this.failure,
    this.context,
    this.showRecoveryGuidance = true,
    this.showTechnicalDetails = false,
    this.onPrimaryAction,
    this.onSecondaryAction,
    this.onDismiss,
    this.primaryActionText,
    this.secondaryActionText,
  });

  @override
  Widget build(BuildContext context) {
    final errorService = ErrorLocalizationService.instance;
    final displayError = errorService.formatErrorForDisplay(
      failure,
      context: this.context,
      includeRecovery: showRecoveryGuidance,
    );

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(AppDimensions.marginDefault),
      padding: const EdgeInsets.all(AppDimensions.paddingDefault),
      decoration: BoxDecoration(
        color: _getBackgroundColor(displayError.severity),
        borderRadius: BorderRadius.circular(AppDimensions.radiusDefault),
        border: Border.all(
          color: _getBorderColor(displayError.severity),
          width: AppDimensions.borderDefault,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(displayError),
          const SizedBox(height: AppDimensions.spacingDefault),
          _buildMessage(displayError),
          if (showRecoveryGuidance && displayError.recoverySteps != null) ...[
            const SizedBox(height: AppDimensions.spacingLarge),
            _buildRecoveryGuidance(displayError.recoverySteps!),
          ],
          if (showTechnicalDetails) ...[
            const SizedBox(height: AppDimensions.spacingLarge),
            _buildTechnicalDetails(),
          ],
          const SizedBox(height: AppDimensions.spacingLarge),
          _buildActions(displayError),
        ],
      ),
    );
  }

  /// **Build Header**
  Widget _buildHeader(DisplayError displayError) {
    return Row(
      children: [
        Text(
          displayError.icon,
          style: const TextStyle(fontSize: AppDimensions.iconLarge),
        ),
        const SizedBox(width: AppDimensions.spacingSmall),
        Expanded(
          child: Text(
            displayError.title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        if (onDismiss != null)
          IconButton(
            onPressed: onDismiss,
            icon: Icon(
              Icons.close,
              size: AppDimensions.iconDefault,
              color: Colors.grey,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(
              minWidth: AppDimensions.touchTargetSmall,
              minHeight: AppDimensions.touchTargetSmall,
            ),
          ),
      ],
    );
  }

  /// **Build Message**
  Widget _buildMessage(DisplayError displayError) {
    return Text(
      displayError.message,
      style: TextStyle(
        fontSize: 16,
        color: AppColors.textPrimary,
        height: 1.4,
      ),
    );
  }

  /// **Build Recovery Guidance**
  Widget _buildRecoveryGuidance(List<String> recoverySteps) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Hướng dẫn khắc phục:',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppDimensions.spacingSmall),
        ...recoverySteps.asMap().entries.map((entry) {
          final index = entry.key;
          final step = entry.value;
          return Padding(
            padding: EdgeInsets.only(bottom: 4.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppDimensions.spacingSmall),
                Expanded(
                  child: Text(
                    step,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  /// **Build Technical Details**
  Widget _buildTechnicalDetails() {
    final summary = ErrorLocalizationService.instance.getErrorSummary(failure);
    
    return ExpansionTile(
      title: Text(
        'Chi tiết kỹ thuật',
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.grey.shade600,
        ),
      ),
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppDimensions.paddingSmall),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
          ),
          child: Text(
            summary.technicalDetails,
            style: TextStyle(
              fontSize: 12,
              fontFamily: 'monospace',
              color: Colors.grey.shade600,
            ),
          ),
        ),
      ],
    );
  }

  /// **Build Actions**
  Widget _buildActions(DisplayError displayError) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (displayError.secondaryAction != null && onSecondaryAction != null)
          TextButton(
            onPressed: onSecondaryAction,
            child: Text(
              secondaryActionText ?? displayError.secondaryAction!,
              style: TextStyle(
                color: Colors.grey.shade600,
              ),
            ),
          ),
        if (displayError.secondaryAction != null && onSecondaryAction != null)
          const SizedBox(width: AppDimensions.spacingSmall),
        ElevatedButton(
          onPressed: onPrimaryAction,
          style: ElevatedButton.styleFrom(
            backgroundColor: _getPrimaryActionColor(displayError.severity),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.paddingLarge,
              vertical: AppDimensions.paddingSmall,
            ),
          ),
          child: Text(
            primaryActionText ?? displayError.primaryAction,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  /// **Helper Methods**

  /// Get background color based on severity
  Color _getBackgroundColor(ErrorSeverity severity) {
    switch (severity) {
      case ErrorSeverity.low:
        return Colors.blue.shade100;
      case ErrorSeverity.medium:
        return Colors.orange.shade100;
      case ErrorSeverity.high:
        return Colors.red.shade100;
      case ErrorSeverity.critical:
        return Colors.red.shade100;
    }
  }

  /// Get border color based on severity
  Color _getBorderColor(ErrorSeverity severity) {
    switch (severity) {
      case ErrorSeverity.low:
        return AppColors.info;
      case ErrorSeverity.medium:
        return AppColors.warning;
      case ErrorSeverity.high:
        return AppColors.error;
      case ErrorSeverity.critical:
        return Colors.red.shade800;
    }
  }

  /// Get primary action color based on severity
  Color _getPrimaryActionColor(ErrorSeverity severity) {
    switch (severity) {
      case ErrorSeverity.low:
        return AppColors.info;
      case ErrorSeverity.medium:
        return AppColors.warning;
      case ErrorSeverity.high:
        return AppColors.error;
      case ErrorSeverity.critical:
        return Colors.red.shade800;
    }
  }
}

/// **Compact Error Display Widget**
/// 
/// Simplified error display for inline usage
class CompactErrorDisplayWidget extends StatelessWidget {
  final Failure failure;
  final Map<String, dynamic>? context;
  final VoidCallback? onRetry;
  final VoidCallback? onDismiss;

  const CompactErrorDisplayWidget({
    super.key,
    required this.failure,
    this.context,
    this.onRetry,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final errorService = ErrorLocalizationService.instance;
    final message = errorService.getErrorMessageWithContext(
      failure,
      context: this.context,
    );

    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingSmall),
      decoration: BoxDecoration(
        color: Colors.red.shade100,
        borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
        border: Border.all(color: AppColors.error),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            color: AppColors.error,
            size: AppDimensions.iconDefault,
          ),
          const SizedBox(width: AppDimensions.spacingSmall),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: Colors.red.shade800,
                fontSize: 14,
              ),
            ),
          ),
          if (onRetry != null && failure.isRecoverable)
            IconButton(
              onPressed: onRetry,
              icon: Icon(
                Icons.refresh,
                color: AppColors.error,
                size: AppDimensions.iconSmall,
              ),
              constraints: const BoxConstraints(
                minWidth: AppDimensions.touchTargetSmall,
                minHeight: AppDimensions.touchTargetSmall,
              ),
            ),
          if (onDismiss != null)
            IconButton(
              onPressed: onDismiss,
              icon: Icon(
                Icons.close,
                color: AppColors.error,
                size: AppDimensions.iconSmall,
              ),
              constraints: const BoxConstraints(
                minWidth: AppDimensions.touchTargetSmall,
                minHeight: AppDimensions.touchTargetSmall,
              ),
            ),
        ],
      ),
    );
  }
}

/// **Usage Examples:**
/// 
/// ```dart
/// // Full error display
/// ErrorDisplayWidget(
///   failure: networkFailure,
///   context: {'operation': 'send_message'},
///   showRecoveryGuidance: true,
///   onPrimaryAction: () => _retryOperation(),
///   onSecondaryAction: () => _showHelp(),
/// )
/// 
/// // Compact error display
/// CompactErrorDisplayWidget(
///   failure: validationFailure,
///   onRetry: () => _retryValidation(),
///   onDismiss: () => _dismissError(),
/// )
/// ```
