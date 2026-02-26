/// **CONNECTION STATUS WIDGET - REAL-TIME CONNECTION MONITORING**
///
/// Professional connection status UI component following Flutter best practices:
/// - Real-time connection state monitoring
/// - Vietnamese status messages với visual indicators
/// - Smooth animations và connection quality indicators
/// - Actionable recovery guidance
///
/// **Architecture:** Clean Architecture + Flutter Best Practices + Material Design 3

import 'package:flutter/material.dart';
import 'package:flutter_chat_app/l10n/l10n.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:flutter_chat_app/core/network/websocket_client.dart' as ws;
import 'package:flutter_chat_app/core/services/messaging_service.dart';

/// **Connection Quality Levels**
enum ConnectionQuality {
  excellent,
  good,
  poor,
  disconnected,
}

/// **CONNECTION STATUS WIDGET**
///
/// Real-time connection monitoring với Vietnamese messages
class ConnectionStatusWidget extends StatelessWidget {
  /// Whether to show detailed connection info
  final bool showDetails;
  
  /// Whether to show as banner (top of screen)
  final bool isBanner;
  
  /// Custom retry callback
  final VoidCallback? onRetry;

  const ConnectionStatusWidget({
    super.key,
    this.showDetails = false,
    this.isBanner = false,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<ws.ConnectionState>(
      stream: context.read<MessagingService>().connectionState,
      builder: (context, snapshot) {
        final connectionState = snapshot.data ?? ws.ConnectionState.disconnected;
        
        if (connectionState == ws.ConnectionState.connected && !showDetails) {
          return const SizedBox.shrink();
        }

        return _buildConnectionStatus(context, connectionState);
      },
    );
  }

  /// **Build Connection Status**
  Widget _buildConnectionStatus(BuildContext context, ws.ConnectionState state) {
    if (isBanner) {
      return _buildBannerStatus(context, state);
    } else {
      return _buildCardStatus(context, state);
    }
  }

  /// **Build Banner Status**
  Widget _buildBannerStatus(BuildContext context, ws.ConnectionState state) {
    final statusInfo = _getConnectionStatusInfo(context, state);

    if (state == ws.ConnectionState.connected) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: statusInfo.color.withOpacity(0.1),
        border: Border(
          bottom: BorderSide(
            color: statusInfo.color.withOpacity(0.3),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // **Status Icon**
          _buildStatusIcon(statusInfo),
          
          const SizedBox(width: 12),
          
          // **Status Message**
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  statusInfo.title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: statusInfo.color,
                  ),
                ),
                if (statusInfo.subtitle != null)
                  Text(
                    statusInfo.subtitle!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: statusInfo.color.withOpacity(0.8),
                    ),
                  ),
              ],
            ),
          ),
          
          // **Action Button**
          if (statusInfo.showRetry && onRetry != null)
            TextButton(
              onPressed: onRetry,
              style: TextButton.styleFrom(
                foregroundColor: statusInfo.color,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              ),
              child: const Text('Thử lại'),
            ),
        ],
      ),
    ).animate().slideY(begin: -1, end: 0, duration: 300.ms);
  }

  /// **Build Card Status**
  Widget _buildCardStatus(BuildContext context, ws.ConnectionState state) {
    final statusInfo = _getConnectionStatusInfo(context, state);
    
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // **Status Header**
            Row(
              children: [
                _buildStatusIcon(statusInfo),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        statusInfo.title,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: statusInfo.color,
                        ),
                      ),
                      if (statusInfo.subtitle != null)
                        Text(
                          statusInfo.subtitle!,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            
            if (showDetails) ...[
              const SizedBox(height: 16),
              _buildConnectionDetails(context, state),
            ],
            
            if (statusInfo.showRetry && onRetry != null) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Thử kết nối lại'),
                ),
              ),
            ],
          ],
        ),
      ),
    ).animate().fadeIn(duration: 300.ms).scale(begin: const Offset(0.95, 0.95), end: const Offset(1.0, 1.0));
  }

  /// **Build Status Icon**
  Widget _buildStatusIcon(ConnectionStatusInfo statusInfo) {
    Widget icon = Icon(
      statusInfo.icon,
      color: statusInfo.color,
      size: 24,
    );

    if (statusInfo.isAnimated) {
      icon = icon.animate(onPlay: (controller) => controller.repeat())
          .rotate(duration: 2000.ms);
    }

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: statusInfo.color.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: icon,
    );
  }

  /// **Build Connection Details**
  Widget _buildConnectionDetails(BuildContext context, ws.ConnectionState state) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          _buildDetailRow(
            context,
            'Trạng thái kết nối:',
            _getConnectionStateText(context, state),
          ),
          _buildDetailRow(
            context,
            'Chất lượng mạng:',
            _getConnectionQualityText(_getConnectionQuality(state)),
          ),
          _buildDetailRow(
            context,
            'Thời gian kết nối:',
            _getConnectionDuration(),
          ),
        ],
      ),
    );
  }

  /// **Build Detail Row**
  Widget _buildDetailRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w500,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  /// **Get Connection Status Info**
  ConnectionStatusInfo _getConnectionStatusInfo(BuildContext context, ws.ConnectionState state) {
    switch (state) {
      case ws.ConnectionState.connected:
        return ConnectionStatusInfo(
          title: 'Đã kết nối',
          subtitle: 'Kết nối ổn định',
          icon: Icons.wifi_rounded,
          color: Colors.green,
          isAnimated: false,
          showRetry: false,
        );

      case ws.ConnectionState.connecting:
        return ConnectionStatusInfo(
          title: 'Đang kết nối...',
          subtitle: 'Vui lòng chờ trong giây lát',
          icon: Icons.sync_rounded,
          color: Colors.blue,
          isAnimated: true,
          showRetry: false,
        );

      case ws.ConnectionState.reconnecting:
        return ConnectionStatusInfo(
          title: context.l10n.reconnecting,
          subtitle: 'Đang thử khôi phục kết nối',
          icon: Icons.sync_rounded,
          color: Colors.orange,
          isAnimated: true,
          showRetry: true,
        );

      case ws.ConnectionState.disconnected:
        return ConnectionStatusInfo(
          title: context.l10n.connectionLost,
          subtitle: 'Không thể kết nối đến server',
          icon: Icons.wifi_off_rounded,
          color: Colors.red,
          isAnimated: false,
          showRetry: true,
        );

      case ws.ConnectionState.error:
        return ConnectionStatusInfo(
          title: 'Lỗi kết nối',
          subtitle: 'Có lỗi xảy ra với kết nối',
          icon: Icons.error_outline_rounded,
          color: Colors.red,
          isAnimated: false,
          showRetry: true,
        );

      case ws.ConnectionState.disposed:
        return ConnectionStatusInfo(
          title: 'Kết nối đã đóng',
          subtitle: 'Kết nối đã được đóng',
          icon: Icons.close_rounded,
          color: Colors.grey,
          isAnimated: false,
          showRetry: false,
        );
    }
  }

  /// **Get Connection State Text**
  String _getConnectionStateText(BuildContext context, ws.ConnectionState state) {
    switch (state) {
      case ws.ConnectionState.connected:
        return 'Đã kết nối';
      case ws.ConnectionState.connecting:
        return 'Đang kết nối';
      case ws.ConnectionState.reconnecting:
        return 'Đang kết nối lại';
      case ws.ConnectionState.disconnected:
        return context.l10n.connectionLost;
      case ws.ConnectionState.error:
        return 'Lỗi kết nối';
      case ws.ConnectionState.disposed:
        return 'Đã đóng';
    }
  }

  /// **Get Connection Quality**
  ConnectionQuality _getConnectionQuality(ws.ConnectionState state) {
    switch (state) {
      case ws.ConnectionState.connected:
        return ConnectionQuality.excellent;
      case ws.ConnectionState.connecting:
      case ws.ConnectionState.reconnecting:
        return ConnectionQuality.poor;
      case ws.ConnectionState.disconnected:
      case ws.ConnectionState.error:
      case ws.ConnectionState.disposed:
        return ConnectionQuality.disconnected;
    }
  }

  /// **Get Connection Quality Text**
  String _getConnectionQualityText(ConnectionQuality quality) {
    switch (quality) {
      case ConnectionQuality.excellent:
        return 'Tuyệt vời';
      case ConnectionQuality.good:
        return 'Tốt';
      case ConnectionQuality.poor:
        return 'Kém';
      case ConnectionQuality.disconnected:
        return 'Không có';
    }
  }

  /// **Get Connection Duration**
  String _getConnectionDuration() {
    // TODO: Implement actual connection duration tracking
    return 'N/A';
  }
}

/// **Connection Status Info Model**
class ConnectionStatusInfo {
  final String title;
  final String? subtitle;
  final IconData icon;
  final Color color;
  final bool isAnimated;
  final bool showRetry;

  const ConnectionStatusInfo({
    required this.title,
    this.subtitle,
    required this.icon,
    required this.color,
    required this.isAnimated,
    required this.showRetry,
  });
}

/// **Connection Status Banner**
///
/// Simplified banner version for app bar
class ConnectionStatusBanner extends StatelessWidget {
  const ConnectionStatusBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return const ConnectionStatusWidget(
      isBanner: true,
    );
  }
}

/// **Connection Status Card**
///
/// Detailed card version for full screen display
class ConnectionStatusCard extends StatelessWidget {
  final VoidCallback? onRetry;

  const ConnectionStatusCard({
    super.key,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return ConnectionStatusWidget(
      showDetails: true,
      onRetry: onRetry,
    );
  }
}
