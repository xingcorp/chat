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
import 'package:flutter_chat_app/core/constants/app_colors.dart';
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
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.TEXT_PRIMARY_LIGHT,
            ),
          ),
        ),
        if (onDismiss != null)
          IconButton(
            onPressed: onDismiss,
            icon: const Icon(
              Icons.close,
              size: AppDimensions.iconDefault,
              color: AppColors.TEXT_SECONDARY_LIGHT,
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
      style: const TextStyle(
        fontSize: 16,
        color: AppColors.TEXT_PRIMARY_LIGHT,
        height: 1.4,
      ),
    );
  }

  /// **Build Recovery Guidance**
  Widget _buildRecoveryGuidance(List<String> recoverySteps) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Hướng dẫn khắc phục:',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.TEXT_PRIMARY_LIGHT,
          ),
        ),
        const SizedBox(height: AppDimensions.spacingSmall),
        ...recoverySteps.asMap().entries.map((entry) {
          final index = entry.key;
          final step = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: AppDimensions.SPACING_TINY),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 20,
                  height: 20,
                  decoration: const BoxDecoration(
                    color: AppColors.PRIMARY_BLUE,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(
                        color: AppColors.WHITE,
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
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.TEXT_SECONDARY_LIGHT,
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
      title: const Text(
        'Chi tiết kỹ thuật',
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.TEXT_SECONDARY_LIGHT,
        ),
      ),
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppDimensions.paddingSmall),
          decoration: BoxDecoration(
            color: AppColors.GREY_100,
            borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
          ),
          child: Text(
            summary.technicalDetails,
            style: const TextStyle(
              fontSize: 12,
              fontFamily: 'monospace',
              color: AppColors.TEXT_SECONDARY_LIGHT,
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
              style: const TextStyle(
                color: AppColors.TEXT_SECONDARY_LIGHT,
              ),
            ),
          ),
        if (displayError.secondaryAction != null && onSecondaryAction != null)
          const SizedBox(width: AppDimensions.spacingSmall),
        ElevatedButton(
          onPressed: onPrimaryAction,
          style: ElevatedButton.styleFrom(
            backgroundColor: _getPrimaryActionColor(displayError.severity),
            foregroundColor: AppColors.WHITE,
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
        return AppColors.INFO_LIGHT;
      case ErrorSeverity.medium:
        return AppColors.WARNING_LIGHT;
      case ErrorSeverity.high:
        return AppColors.ERROR_LIGHT;
      case ErrorSeverity.critical:
        return AppColors.ERROR_LIGHT;
    }
  }

  /// Get border color based on severity
  Color _getBorderColor(ErrorSeverity severity) {
    switch (severity) {
      case ErrorSeverity.low:
        return AppColors.INFO;
      case ErrorSeverity.medium:
        return AppColors.WARNING;
      case ErrorSeverity.high:
        return AppColors.ERROR;
      case ErrorSeverity.critical:
        return AppColors.ERROR_DARK;
    }
  }

  /// Get primary action color based on severity
  Color _getPrimaryActionColor(ErrorSeverity severity) {
    switch (severity) {
      case ErrorSeverity.low:
        return AppColors.INFO;
      case ErrorSeverity.medium:
        return AppColors.WARNING;
      case ErrorSeverity.high:
        return AppColors.ERROR;
      case ErrorSeverity.critical:
        return AppColors.ERROR_DARK;
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
        color: AppColors.ERROR_LIGHT,
        borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
        border: Border.all(color: AppColors.ERROR),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline,
            color: AppColors.ERROR,
            size: AppDimensions.iconDefault,
          ),
          const SizedBox(width: AppDimensions.spacingSmall),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: AppColors.ERROR_DARK,
                fontSize: 14,
              ),
            ),
          ),
          if (onRetry != null && failure.isRecoverable)
            IconButton(
              onPressed: onRetry,
              icon: const Icon(
                Icons.refresh,
                color: AppColors.ERROR,
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
              icon: const Icon(
                Icons.close,
                color: AppColors.ERROR,
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
