/// **OFFLINE MODE INDICATOR - GRACEFUL DEGRADATION UI**
///
/// Professional offline mode UI component following Flutter best practices:
/// - Clear offline/degraded mode notifications
/// - Vietnamese recovery guidance messages
/// - Service availability indicators
/// - Actionable recovery steps
///
/// **Architecture:** Clean Architecture + Flutter Best Practices + Material Design 3

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:flutter_chat_app/core/constants/app_icons.dart';
import 'package:flutter_chat_app/core/network/websocket_client.dart' as ws;
import 'package:flutter_chat_app/core/services/messaging_service.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/media/app_icon.dart';

/// **Offline Mode Type**
enum OfflineModeType {
  /// Completely offline - no network
  completelyOffline,
  
  /// Partially offline - some services unavailable
  partiallyOffline,
  
  /// Degraded service - reduced functionality
  degradedService,
  
  /// Sync pending - waiting to sync data
  syncPending,
}

/// **Service Status**
enum ServiceStatus {
  available,
  unavailable,
  degraded,
  unknown,
}

/// **OFFLINE MODE INDICATOR**
///
/// Comprehensive offline mode indicator với Vietnamese guidance
class OfflineModeIndicator extends StatelessWidget {
  /// Type of offline mode
  final OfflineModeType mode;
  
  /// Whether to show as persistent banner
  final bool isPersistent;
  
  /// Whether to show detailed service status
  final bool showServiceStatus;
  
  /// Custom retry callback
  final VoidCallback? onRetry;
  
  /// Custom go online callback
  final VoidCallback? onGoOnline;

  const OfflineModeIndicator({
    super.key,
    required this.mode,
    this.isPersistent = false,
    this.showServiceStatus = false,
    this.onRetry,
    this.onGoOnline,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<ws.ConnectionState>(
      stream: context.read<MessagingService>().connectionState,
      builder: (context, snapshot) {
        final connectionState = snapshot.data ?? ws.ConnectionState.disconnected;
        final actualMode = _determineOfflineMode(connectionState);
        
        if (actualMode == null && !isPersistent) {
          return const SizedBox.shrink();
        }

        return _buildOfflineIndicator(context, actualMode ?? mode);
      },
    );
  }

  /// **Build Offline Indicator**
  Widget _buildOfflineIndicator(BuildContext context, OfflineModeType mode) {
    final modeInfo = _getOfflineModeInfo(mode);
    
    if (isPersistent) {
      return _buildPersistentBanner(context, modeInfo);
    } else {
      return _buildOfflineCard(context, modeInfo);
    }
  }

  /// **Build Persistent Banner**
  Widget _buildPersistentBanner(BuildContext context, OfflineModeInfo modeInfo) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: modeInfo.color.withOpacity(0.1),
        border: Border(
          bottom: BorderSide(
            color: modeInfo.color.withOpacity(0.3),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // **Mode Icon**
          AppIcon.svg(
            modeInfo.icon,
            color: modeInfo.color,
            size: 20,
          ),
          
          const SizedBox(width: 8),
          
          // **Mode Message**
          Expanded(
            child: Text(
              modeInfo.bannerMessage,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: modeInfo.color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          
          // **Action Button**
          if (modeInfo.showRetry && onRetry != null)
            TextButton(
              onPressed: onRetry,
              style: TextButton.styleFrom(
                foregroundColor: modeInfo.color,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text(
                'Thử lại',
                style: TextStyle(fontSize: 12),
              ),
            ),
        ],
      ),
    ).animate().slideY(begin: -1, end: 0, duration: 300.ms);
  }

  /// **Build Offline Card**
  Widget _buildOfflineCard(BuildContext context, OfflineModeInfo modeInfo) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // **Mode Icon**
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: modeInfo.color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: AppIcon.svg(
                modeInfo.icon,
                color: modeInfo.color,
                size: 32,
              ),
            ).animate().scale(delay: 100.ms, duration: 400.ms),
            
            const SizedBox(height: 16),
            
            // **Mode Title**
            Text(
              modeInfo.title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: modeInfo.color,
              ),
              textAlign: TextAlign.center,
            ).animate().fadeIn(delay: 200.ms),
            
            const SizedBox(height: 8),
            
            // **Mode Description**
            Text(
              modeInfo.description,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ).animate().fadeIn(delay: 300.ms),
            
            const SizedBox(height: 16),
            
            // **Recovery Guidance**
            _buildRecoveryGuidance(context, modeInfo),
            
            if (showServiceStatus) ...[
              const SizedBox(height: 20),
              _buildServiceStatus(context),
            ],
            
            const SizedBox(height: 20),
            
            // **Action Buttons**
            _buildActionButtons(context, modeInfo),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 300.ms).scale(begin: const Offset(0.95, 0.95), end: const Offset(1.0, 1.0));
  }

  /// **Build Recovery Guidance**
  Widget _buildRecoveryGuidance(BuildContext context, OfflineModeInfo modeInfo) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: modeInfo.color.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AppIcon.svg(
                AppIcons.lightbulb,
                color: modeInfo.color,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Hướng dẫn khôi phục',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: modeInfo.color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...modeInfo.recoverySteps.map((step) => _buildRecoveryStep(context, step)),
        ],
      ),
    ).animate().fadeIn(delay: 400.ms);
  }

  /// **Build Recovery Step**
  Widget _buildRecoveryStep(BuildContext context, String step) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.only(top: 6, right: 12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Text(
              step,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// **Build Service Status**
  Widget _buildServiceStatus(BuildContext context) {
    final services = _getServiceStatuses();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Trạng thái dịch vụ',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        ...services.entries.map((entry) => _buildServiceStatusRow(
          context,
          entry.key,
          entry.value,
        )),
      ],
    );
  }

  /// **Build Service Status Row**
  Widget _buildServiceStatusRow(
    BuildContext context,
    String serviceName,
    ServiceStatus status,
  ) {
    final statusInfo = _getServiceStatusInfo(status);
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          AppIcon.svg(
            statusInfo.icon,
            color: statusInfo.color,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              serviceName,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          Text(
            statusInfo.label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: statusInfo.color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// **Build Action Buttons**
  Widget _buildActionButtons(BuildContext context, OfflineModeInfo modeInfo) {
    return Column(
      children: [
        // Primary action
        if (modeInfo.showRetry && onRetry != null)
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onRetry,
              icon: AppIcon.svg(
                AppIcons.refresh,
                size: 18,
                color: Theme.of(context).colorScheme.onPrimary,
              ),
              label: const Text('Thử kết nối lại'),
            ),
          ),
        
        const SizedBox(height: 8),
        
        // Secondary actions
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            if (onGoOnline != null)
              TextButton.icon(
                onPressed: onGoOnline,
                icon: AppIcon.svg(
                  AppIcons.wifiConnected,
                  size: 18,
                  color: Theme.of(context).colorScheme.primary,
                ),
                label: const Text('Kết nối'),
              ),
            
            TextButton.icon(
              onPressed: () => _showOfflineHelp(context),
              icon: AppIcon.svg(
                AppIcons.help,
                size: 18,
                color: Theme.of(context).colorScheme.primary,
              ),
              label: const Text('Trợ giúp'),
            ),
          ],
        ),
      ],
    ).animate().fadeIn(delay: 500.ms);
  }

  /// **Determine Offline Mode**
  OfflineModeType? _determineOfflineMode(ws.ConnectionState connectionState) {
    switch (connectionState) {
      case ws.ConnectionState.disconnected:
        return OfflineModeType.completelyOffline;
      case ws.ConnectionState.error:
        return OfflineModeType.degradedService;
      case ws.ConnectionState.reconnecting:
        return OfflineModeType.syncPending;
      case ws.ConnectionState.connected:
      case ws.ConnectionState.connecting:
      case ws.ConnectionState.disposed:
        return null;
    }
  }

  /// **Get Offline Mode Info**
  OfflineModeInfo _getOfflineModeInfo(OfflineModeType mode) {
    switch (mode) {
      case OfflineModeType.completelyOffline:
        return OfflineModeInfo(
          title: 'Chế độ offline',
          description: 'Bạn đang ở chế độ offline. Một số tính năng có thể không khả dụng.',
          bannerMessage: 'Offline - Kiểm tra kết nối mạng',
          icon: AppIcons.wifiOff,
          color: Colors.orange,
          showRetry: true,
          recoverySteps: [
            'Kiểm tra kết nối Wi-Fi hoặc dữ liệu di động',
            'Thử tắt và bật lại Wi-Fi',
            'Khởi động lại ứng dụng',
            'Liên hệ nhà cung cấp dịch vụ nếu vấn đề vẫn tiếp tục',
          ],
        );
      
      case OfflineModeType.partiallyOffline:
        return OfflineModeInfo(
          title: 'Kết nối không ổn định',
          description: 'Một số dịch vụ có thể không khả dụng do kết nối không ổn định.',
          bannerMessage: 'Kết nối không ổn định',
          icon: AppIcons.wifiOff,
          color: Colors.amber,
          showRetry: true,
          recoverySteps: [
            'Di chuyển đến nơi có tín hiệu mạnh hơn',
            'Thử chuyển từ Wi-Fi sang dữ liệu di động hoặc ngược lại',
            'Đợi kết nối ổn định trở lại',
          ],
        );
      
      case OfflineModeType.degradedService:
        return OfflineModeInfo(
          title: 'Dịch vụ bị hạn chế',
          description: 'Một số tính năng tạm thời không khả dụng do sự cố kỹ thuật.',
          bannerMessage: 'Dịch vụ bị hạn chế',
          icon: AppIcons.statusConflict,
          color: Colors.red,
          showRetry: true,
          recoverySteps: [
            'Các tính năng cơ bản vẫn hoạt động bình thường',
            'Thử lại sau vài phút',
            'Kiểm tra thông báo từ nhà cung cấp dịch vụ',
          ],
        );
      
      case OfflineModeType.syncPending:
        return OfflineModeInfo(
          title: 'Đang đồng bộ dữ liệu',
          description: 'Đang đồng bộ dữ liệu với server. Vui lòng chờ trong giây lát.',
          bannerMessage: 'Đang đồng bộ...',
          icon: AppIcons.systemUpdate,
          color: Colors.blue,
          showRetry: false,
          recoverySteps: [
            'Dữ liệu đang được đồng bộ tự động',
            'Không đóng ứng dụng trong quá trình này',
            'Quá trình sẽ hoàn tất trong vài giây',
          ],
        );
    }
  }

  /// **Get Service Statuses**
  Map<String, ServiceStatus> _getServiceStatuses() {
    // TODO: Get actual service statuses from service layer
    return {
      'Tin nhắn': ServiceStatus.available,
      'Cuộc gọi': ServiceStatus.unavailable,
      'Chia sẻ file': ServiceStatus.degraded,
      'Thông báo': ServiceStatus.available,
    };
  }

  /// **Get Service Status Info**
  ServiceStatusInfo _getServiceStatusInfo(ServiceStatus status) {
    switch (status) {
      case ServiceStatus.available:
        return ServiceStatusInfo(
          label: 'Khả dụng',
          icon: AppIcons.checkCircle,
          color: Colors.green,
        );
      case ServiceStatus.unavailable:
        return ServiceStatusInfo(
          label: 'Không khả dụng',
          icon: AppIcons.statusCancelled,
          color: Colors.red,
        );
      case ServiceStatus.degraded:
        return ServiceStatusInfo(
          label: 'Hạn chế',
          icon: AppIcons.statusConflict,
          color: Colors.orange,
        );
      case ServiceStatus.unknown:
        return ServiceStatusInfo(
          label: 'Không rõ',
          icon: AppIcons.help,
          color: Colors.grey,
        );
    }
  }

  /// **Show Offline Help**
  void _showOfflineHelp(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Trợ giúp chế độ offline'),
        content: const Text(
          'Trong chế độ offline, bạn vẫn có thể:\n\n'
          '• Xem tin nhắn đã tải\n'
          '• Soạn tin nhắn (sẽ gửi khi có mạng)\n'
          '• Xem danh bạ\n'
          '• Truy cập cài đặt\n\n'
          'Tin nhắn sẽ được gửi tự động khi kết nối được khôi phục.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Đã hiểu'),
          ),
        ],
      ),
    );
  }
}

/// **Offline Mode Info Model**
class OfflineModeInfo {
  final String title;
  final String description;
  final String bannerMessage;
  final String icon;
  final Color color;
  final bool showRetry;
  final List<String> recoverySteps;

  const OfflineModeInfo({
    required this.title,
    required this.description,
    required this.bannerMessage,
    required this.icon,
    required this.color,
    required this.showRetry,
    required this.recoverySteps,
  });
}

/// **Service Status Info Model**
class ServiceStatusInfo {
  final String label;
  final String icon;
  final Color color;

  const ServiceStatusInfo({
    required this.label,
    required this.icon,
    required this.color,
  });
}

/// **Offline Mode Banner**
///
/// Simplified banner version
class OfflineModeBanner extends StatelessWidget {
  final VoidCallback? onRetry;

  const OfflineModeBanner({
    super.key,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return OfflineModeIndicator(
      mode: OfflineModeType.completelyOffline,
      isPersistent: true,
      onRetry: onRetry,
    );
  }
}
