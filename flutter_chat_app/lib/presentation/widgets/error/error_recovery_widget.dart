/// **ERROR RECOVERY WIDGET - UI-LEVEL RECOVERY ACTIONS**
///
/// Professional error recovery UI component following Flutter best practices:
/// - Manual retry buttons với Vietnamese labels
/// - Progress indicators cho recovery operations
/// - User guidance messages với actionable instructions
/// - Smooth animations và 60fps performance
///
/// **Architecture:** Clean Architecture + Flutter Best Practices + Material Design 3

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:flutter_chat_app/core/constants/app_icons.dart';
import 'package:flutter_chat_app/core/error/failures.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/media/app_icon.dart';

/// **Error Recovery Action Type**
enum ErrorRecoveryActionType {
  retry,
  reconnect,
  refresh,
  reauthenticate,
  goOffline,
  contactSupport,
}

/// **Error Recovery Action Model**
class ErrorRecoveryAction {
  /// Action type
  final ErrorRecoveryActionType type;
  
  /// Vietnamese label for button
  final String label;
  
  /// Icon for button
  final String icon;
  
  /// Callback function
  final VoidCallback onPressed;
  
  /// Whether action is primary (emphasized)
  final bool isPrimary;
  
  /// Whether action is loading
  final bool isLoading;

  const ErrorRecoveryAction({
    required this.type,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.isPrimary = false,
    this.isLoading = false,
  });
}

/// **ERROR RECOVERY WIDGET**
///
/// Comprehensive error recovery UI với Vietnamese messages và smooth animations
class ErrorRecoveryWidget extends StatelessWidget {
  /// Failure object containing error details
  final Failure failure;
  
  /// Recovery actions available to user
  final List<ErrorRecoveryAction> actions;
  
  /// Whether to show detailed error information
  final bool showDetails;
  
  /// Custom illustration widget
  final Widget? illustration;
  
  /// Additional context message
  final String? contextMessage;

  const ErrorRecoveryWidget({
    super.key,
    required this.failure,
    required this.actions,
    this.showDetails = false,
    this.illustration,
    this.contextMessage,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // **Error Illustration**
          _buildErrorIllustration(context),
          
          const SizedBox(height: 24),
          
          // **Error Title**
          _buildErrorTitle(context),
          
          const SizedBox(height: 12),
          
          // **Error Message**
          _buildErrorMessage(context),
          
          if (contextMessage != null) ...[
            const SizedBox(height: 8),
            _buildContextMessage(context),
          ],
          
          const SizedBox(height: 32),
          
          // **Recovery Actions**
          _buildRecoveryActions(context),
          
          if (showDetails) ...[
            const SizedBox(height: 24),
            _buildErrorDetails(context),
          ],
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.1, end: 0);
  }

  /// **Build Error Illustration**
  Widget _buildErrorIllustration(BuildContext context) {
    if (illustration != null) {
      return illustration!;
    }

    final icon = _getErrorIcon();
    final color = _getErrorColor(context);

    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: AppIcon.svg(
        icon,
        size: 40,
        color: color,
      ),
    ).animate().scale(delay: 100.ms, duration: 400.ms);
  }

  /// **Build Error Title**
  Widget _buildErrorTitle(BuildContext context) {
    final title = _getErrorTitle();
    
    return Text(
      title,
      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
        fontWeight: FontWeight.bold,
        color: Theme.of(context).colorScheme.onSurface,
      ),
      textAlign: TextAlign.center,
    ).animate().fadeIn(delay: 200.ms);
  }

  /// **Build Error Message**
  Widget _buildErrorMessage(BuildContext context) {
    return Text(
      failure.userMessage,
      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
      textAlign: TextAlign.center,
    ).animate().fadeIn(delay: 300.ms);
  }

  /// **Build Context Message**
  Widget _buildContextMessage(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        contextMessage!,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          fontStyle: FontStyle.italic,
        ),
        textAlign: TextAlign.center,
      ),
    ).animate().fadeIn(delay: 400.ms);
  }

  /// **Build Recovery Actions**
  Widget _buildRecoveryActions(BuildContext context) {
    if (actions.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [
        // Primary actions (emphasized buttons)
        ...actions
            .where((action) => action.isPrimary)
            .map((action) => _buildPrimaryActionButton(context, action))
            .toList(),
        
        if (actions.where((action) => action.isPrimary).isNotEmpty &&
            actions.where((action) => !action.isPrimary).isNotEmpty)
          const SizedBox(height: 12),
        
        // Secondary actions (text buttons)
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: actions
              .where((action) => !action.isPrimary)
              .map((action) => _buildSecondaryActionButton(context, action))
              .toList(),
        ),
      ],
    ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.2, end: 0);
  }

  /// **Build Primary Action Button**
  Widget _buildPrimaryActionButton(BuildContext context, ErrorRecoveryAction action) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      child: FilledButton.icon(
        onPressed: action.isLoading ? null : action.onPressed,
        icon: action.isLoading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).colorScheme.onPrimary,
                  ),
                ),
              )
            : AppIcon.svg(
                action.icon,
                size: 20,
                color: Theme.of(context).colorScheme.onPrimary,
              ),
        label: Text(action.label),
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  /// **Build Secondary Action Button**
  Widget _buildSecondaryActionButton(BuildContext context, ErrorRecoveryAction action) {
    return TextButton.icon(
      onPressed: action.isLoading ? null : action.onPressed,
      icon: action.isLoading
          ? SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).colorScheme.primary,
                ),
              ),
            )
          : AppIcon.svg(
              action.icon,
              size: 18,
              color: Theme.of(context).colorScheme.primary,
            ),
      label: Text(action.label),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }

  /// **Build Error Details**
  Widget _buildErrorDetails(BuildContext context) {
    return ExpansionTile(
      title: Text(
        'Chi tiết lỗi',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w500,
        ),
      ),
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow(context, 'Loại lỗi:', failure.runtimeType.toString()),
              _buildDetailRow(context, 'Mã lỗi:', failure.code ?? 'N/A'),
              _buildDetailRow(context, 'Danh mục:', failure.category),
              _buildDetailRow(context, 'Có thể khôi phục:', failure.isRecoverable ? 'Có' : 'Không'),
              _buildDetailRow(context, 'Thông báo kỹ thuật:', failure.message),
            ],
          ),
        ),
      ],
    ).animate().fadeIn(delay: 600.ms);
  }

  /// **Build Detail Row**
  Widget _buildDetailRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// **Get Error Icon**
  String _getErrorIcon() {
    switch (failure.runtimeType) {
      case ConnectionFailure:
      case NetworkFailure:
        return AppIcons.wifiOff;
      case AuthenticationFailure:
        return AppIcons.lockOutline;
      case ServerFailure:
        return AppIcons.cloudOff;
      case ValidationFailure:
        return AppIcons.errorOutline;
      case TimeoutFailure:
        return AppIcons.statusPending;
      case RealtimeFailure:
        return AppIcons.statusConflict;
      case UploadFailure:
        return AppIcons.cloudUpload;
      case DownloadFailure:
        return AppIcons.updateReady;
      default:
        return AppIcons.statusConflict;
    }
  }

  /// **Get Error Color**
  Color _getErrorColor(BuildContext context) {
    switch (failure.runtimeType) {
      case ConnectionFailure:
      case NetworkFailure:
        return Colors.orange;
      case AuthenticationFailure:
        return Colors.red;
      case ServerFailure:
        return Colors.red;
      case ValidationFailure:
        return Colors.amber;
      case TimeoutFailure:
        return Colors.blue;
      case RealtimeFailure:
        return Colors.purple;
      default:
        return Theme.of(context).colorScheme.error;
    }
  }

  /// **Get Error Title**
  String _getErrorTitle() {
    switch (failure.runtimeType) {
      case ConnectionFailure:
      case NetworkFailure:
        return 'Lỗi kết nối mạng';
      case AuthenticationFailure:
        return 'Lỗi xác thực';
      case ServerFailure:
        return 'Lỗi server';
      case ValidationFailure:
        return 'Thông tin không hợp lệ';
      case TimeoutFailure:
        return 'Hết thời gian chờ';
      case RealtimeFailure:
        return 'Lỗi kết nối real-time';
      case UploadFailure:
        return 'Lỗi tải lên';
      case DownloadFailure:
        return 'Lỗi tải xuống';
      case CacheFailure:
        return 'Lỗi dữ liệu cục bộ';
      case ConflictFailure:
        return 'Xung đột dữ liệu';
      default:
        return 'Có lỗi xảy ra';
    }
  }

  /// **Create Retry Action**
  static ErrorRecoveryAction createRetryAction({
    required VoidCallback onRetry,
    bool isLoading = false,
  }) {
    return ErrorRecoveryAction(
      type: ErrorRecoveryActionType.retry,
      label: 'Thử lại',
      icon: AppIcons.refresh,
      onPressed: onRetry,
      isPrimary: true,
      isLoading: isLoading,
    );
  }

  /// **Create Reconnect Action**
  static ErrorRecoveryAction createReconnectAction({
    required VoidCallback onReconnect,
    bool isLoading = false,
  }) {
    return ErrorRecoveryAction(
      type: ErrorRecoveryActionType.reconnect,
      label: 'Kết nối lại',
      icon: AppIcons.wifiConnected,
      onPressed: onReconnect,
      isPrimary: true,
      isLoading: isLoading,
    );
  }

  /// **Create Refresh Action**
  static ErrorRecoveryAction createRefreshAction({
    required VoidCallback onRefresh,
    bool isLoading = false,
  }) {
    return ErrorRecoveryAction(
      type: ErrorRecoveryActionType.refresh,
      label: 'Làm mới',
      icon: AppIcons.refresh,
      onPressed: onRefresh,
      isPrimary: false,
      isLoading: isLoading,
    );
  }

  /// **Create Reauthenticate Action**
  static ErrorRecoveryAction createReauthenticateAction({
    required VoidCallback onReauthenticate,
    bool isLoading = false,
  }) {
    return ErrorRecoveryAction(
      type: ErrorRecoveryActionType.reauthenticate,
      label: 'Đăng nhập lại',
      icon: AppIcons.login,
      onPressed: onReauthenticate,
      isPrimary: true,
      isLoading: isLoading,
    );
  }

  /// **Create Go Offline Action**
  static ErrorRecoveryAction createGoOfflineAction({
    required VoidCallback onGoOffline,
  }) {
    return ErrorRecoveryAction(
      type: ErrorRecoveryActionType.goOffline,
      label: 'Chế độ offline',
      icon: AppIcons.lightning,
      onPressed: onGoOffline,
      isPrimary: false,
    );
  }

  /// **Create Contact Support Action**
  static ErrorRecoveryAction createContactSupportAction({
    required VoidCallback onContactSupport,
  }) {
    return ErrorRecoveryAction(
      type: ErrorRecoveryActionType.contactSupport,
      label: 'Liên hệ hỗ trợ',
      icon: AppIcons.support,
      onPressed: onContactSupport,
      isPrimary: false,
    );
  }
}
