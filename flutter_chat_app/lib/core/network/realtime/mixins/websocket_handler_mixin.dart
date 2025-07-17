import 'dart:async';
import 'dart:convert';

import 'package:logger/logger.dart';
import 'package:web_socket_channel/status.dart' as ws_status;
import 'package:web_socket_channel/web_socket_channel.dart';

import '../models/realtime_error.dart';
import '../models/realtime_error_type.dart';
import '../models/realtime_message.dart';

/// Mixin cung cấp các phương thức xử lý WebSocket
mixin WebSocketHandlerMixin {
  /// Đóng WebSocket hiện tại
  Future<void> closeWebSocket(WebSocketChannel? webSocketChannel, StreamSubscription? webSocketSubscription, Logger logger) async {
    if (webSocketChannel != null) {
      try {
        await webSocketChannel.sink.close(ws_status.normalClosure);
      } catch (e) {
        logger.e('Lỗi khi đóng WebSocket: $e');
      }
    }
    
    await webSocketSubscription?.cancel();
  }
  
  /// Tạo một WebSocket mới và kết nối
  Future<WebSocketChannel?> connectWebSocket(String url, {
    required Function(RealtimeError) onError,
    Logger? logger,
  }) async {
    logger?.d('Đang tạo kết nối WebSocket đến $url');
    
    try {
      // Khởi tạo WebSocket
      final wsChannel = WebSocketChannel.connect(Uri.parse(url));
      
      // Đợi một chút để đảm bảo kết nối đã được thiết lập
      await Future.delayed(const Duration(milliseconds: 100));
      
      logger?.d('Kết nối WebSocket thành công');
      return wsChannel;
    } catch (e, stackTrace) {
      logger?.e('Lỗi khi kết nối WebSocket: ${e.toString()}\n${stackTrace.toString()}');
      
      // Tạo lỗi
      final error = RealtimeError(
        code: RealtimeErrorCode.connectionError,
        message: e.toString(),
        details: {
          'exception': e.toString(),
          'stackTrace': stackTrace.toString(),
        },
        errorType: RealtimeErrorType.webSocketError,
        originalError: e,
      );
      
      // Gửi lỗi
      onError(error);
      
      return null;
    }
  }
  
  /// Xử lý tin nhắn từ WebSocket
  void handleWebSocketMessage({
    required dynamic data,
    required Function() onActivity,
    required Function(Map<String, dynamic>) onPong,
    required Function(RealtimeMessage) onMessage,
    required Function(RealtimeError) onError,
    required Function() onMessageReceived,
    Logger? logger,
  }) {
    try {
      // Đánh dấu có hoạt động
      onActivity();
      
      // Chuyển đổi dữ liệu thành JSON
      Map<String, dynamic> jsonData;
      
      if (data is String) {
        try {
          final decoded = json.decode(data);
          if (decoded is! Map<String, dynamic>) {
            logger?.e('Định dạng JSON không hợp lệ, không phải Map');
            return;
          }
          jsonData = decoded;
        } catch (e) {
          logger?.e('Lỗi khi parse tin nhắn JSON: $e');
          return;
        }
      } else if (data is Map<String, dynamic>) {
        jsonData = data;
      } else {
        logger?.e('Định dạng tin nhắn không hỗ trợ: ${data.runtimeType}');
        return;
      }
      
      // Kiểm tra xem có phải pong không
      if (jsonData['type'] == 'pong') {
        onPong(jsonData);
        return;
      }
      
      // Parse thành RealtimeMessage
      final message = RealtimeMessage.fromJson(jsonData);
      
      // Gửi tin nhắn
      onMessage(message);
      
      // Cập nhật metrics
      onMessageReceived();
      
    } catch (e, stackTrace) {
      logger?.e('Lỗi khi xử lý tin nhắn: ${e.toString()}\n${stackTrace.toString()}');
      
      final error = RealtimeError(
        code: RealtimeErrorCode.messageError,
        message: 'Lỗi khi xử lý tin nhắn: ${e.toString()}',
        details: {
          'exception': e.toString(),
          'stackTrace': stackTrace.toString(),
        },
        errorType: RealtimeErrorType.messageFormatError,
        originalError: e,
      );
      
      onError(error);
    }
  }
  
  /// Xử lý lỗi WebSocket
  void handleWebSocketError(
    dynamic error, {
    required Function(RealtimeError) onError,
    required Function(String) onConnectionError,
    Logger? logger,
  }) {
    final realtimeError = RealtimeError(
      code: RealtimeErrorCode.connectionError,
      message: 'Lỗi WebSocket: ${error.toString()}',
      errorType: RealtimeErrorType.webSocketError,
      originalError: error,
    );
    
    logger?.e('Lỗi WebSocket: ${realtimeError.message}');
    
    // Gửi lỗi 
    onError(realtimeError);
    
    // Báo cho state machine
    onConnectionError('Lỗi WebSocket: ${realtimeError.message}');
  }
}

/// Tiện ích để phân tích JSON
dynamic jsonDecode(String data) {
  try {
    return json.decode(data);
  } catch (_) {
    return null;
  }
} 