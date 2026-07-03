import 'package:flutter/material.dart';
import 'package:flutter_chat_app/core/constants/app_icons.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/app_icon.dart';
import 'package:flutter_chat_app/l10n/l10n.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_chat_app/core/services/connectivity_analyzer_service.dart';
import 'package:flutter_chat_app/core/services/realtime_connection_service.dart' as realtime;

/// Widget hiển thị trạng thái kết nối trong ứng dụng
class ConnectionStatusWidget extends StatelessWidget {
  /// Constructor
  const ConnectionStatusWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<realtime.ConnectionState>(
      stream: context.read<realtime.RealtimeConnectionService>().connectionStateStream,
      builder: (context, connectionStateSnapshot) {
        final connectionState = connectionStateSnapshot.data;
        
        return StreamBuilder<realtime.ConnectionType>(
          stream: context.read<realtime.RealtimeConnectionService>().connectionTypeStream,
          builder: (context, connectionTypeSnapshot) {
            final connectionType = connectionTypeSnapshot.data;
            
            return StreamBuilder<NetworkQuality>(
              stream: context.read<ConnectivityAnalyzerService>().qualityStream,
              builder: (context, networkQualitySnapshot) {
                final networkQuality = networkQualitySnapshot.data;
                
                // Nếu không có dữ liệu hoặc đã kết nối, không hiển thị gì
                if (connectionState == null) {
                  return _buildConnectedStatus(connectionType, networkQuality);
                }

                final stateString = connectionState.toString().split('.').last;

                // Trạng thái đang kết nối
                if (stateString == 'connecting' || stateString == 'reconnecting') {
                  return _buildConnectingStatus(stateString);
                }

                // Trạng thái đã kết nối
                if (stateString == 'connected') {
                  return _buildConnectedStatus(connectionType, networkQuality);
                }
                
                // Trạng thái mất kết nối
                return _buildDisconnectedStatus(context);
              },
            );
          },
        );
      },
    );
  }
  
  /// Hiển thị trạng thái đã kết nối
  Widget _buildConnectedStatus(
    realtime.ConnectionType? connectionType,
    NetworkQuality? networkQuality,
  ) {
    // Không hiển thị gì nếu đã kết nối tốt
    if (connectionType == realtime.ConnectionType.webSocket && 
        (networkQuality == NetworkQuality.good || 
         networkQuality == NetworkQuality.excellent)) {
      return const SizedBox.shrink();
    }
    
    // Hiển thị thông tin loại kết nối
    final String typeText = connectionType == realtime.ConnectionType.webSocket 
        ? "WebSocket" 
        : connectionType == realtime.ConnectionType.longPolling 
            ? "Long Polling" 
            : "Không có kết nối";
    
    // Màu sắc dựa vào loại kết nối
    final Color color = connectionType == realtime.ConnectionType.webSocket 
        ? Colors.green 
        : Colors.orange;
    
    // Icon dựa vào loại kết nối
    final String iconPath = connectionType == realtime.ConnectionType.webSocket 
        ? AppIcons.wifiConnected 
        : AppIcons.networkCheck;
    
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 12.0),
      color: color.withOpacity(0.1),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppIcon(iconPath, size: 14.0, color: color),
          const SizedBox(width: 8.0),
          Text(
            typeText,
            style: TextStyle(color: color, fontSize: 12.0),
          ),
        ],
      ),
    );
  }
  
  /// Hiển thị trạng thái đang kết nối
  Widget _buildConnectingStatus(String connectionState) {
    final bool isReconnecting = connectionState == 'reconnecting';

    final String statusText = isReconnecting
        ? "Đang kết nối lại..."
        : "Đang kết nối...";
    
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 12.0),
      color: Colors.blue.withOpacity(0.1),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 12.0,
            height: 12.0,
            child: CircularProgressIndicator(
              strokeWidth: 2.0,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
            ),
          ),
          const SizedBox(width: 8.0),
          Text(
            statusText,
            style: TextStyle(color: Colors.blue, fontSize: 12.0),
          ),
        ],
      ),
    );
  }
  
  /// Hiển thị trạng thái mất kết nối
  Widget _buildDisconnectedStatus(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Thử kết nối lại khi người dùng nhấp vào
        context.read<realtime.RealtimeConnectionService>().connect();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 12.0),
        color: Colors.red.withOpacity(0.1),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AppIcon(AppIcons.cloudOff, size: 14.0, color: Colors.red),
            const SizedBox(width: 8.0),
            Text(
              "Mất kết nối - Nhấn để thử lại",
              style: TextStyle(color: Colors.red, fontSize: 12.0),
            ),
          ],
        ),
      ),
    );
  }
} 