import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';
import 'package:flutter_chat_app/domain/entities/chat.dart';

/// Interface trừu tượng cho dịch vụ analytics
/// Giúp tách biệt code khỏi các triển khai cụ thể (Firebase, Mixpanel, etc.)
abstract class AnalyticsManager {
  /// Khởi tạo analytics manager
  Future<void> initialize();
  
  /// Đặt ID người dùng
  Future<void> setUserId(String userId);
  
  /// Đặt thuộc tính người dùng
  Future<void> setUserProperty(String name, String value);
  
  /// Ghi nhận sự kiện
  Future<void> logEvent(String name, [Map<String, Object>? parameters]);
  
  /// Ghi nhận sự kiện đăng nhập
  Future<void> logLogin(String method);
  
  /// Ghi nhận sự kiện xem màn hình
  Future<void> logScreenView(String screenName, [String? screenClass]);
  
  /// Bật/tắt thu thập analytics
  Future<void> setEnabled(bool enabled);
}

/// Triển khai analytics không làm gì cả (cho dev/test)
@Injectable(as: AnalyticsManager, env: ['test', 'dev'])
class NoOpAnalyticsManager implements AnalyticsManager {
  final _logger = Logger();
  
  @override
  Future<void> initialize() async {
    _logger.i('Khởi tạo NoOp Analytics Manager');
  }
  
  @override
  Future<void> setUserId(String userId) async {
    _logger.d('NoOp Analytics: setUserId($userId)');
  }
  
  @override
  Future<void> setUserProperty(String name, String value) async {
    _logger.d('NoOp Analytics: setUserProperty($name, $value)');
  }
  
  @override
  Future<void> logEvent(String name, [Map<String, Object>? parameters]) async {
    _logger.d('NoOp Analytics: logEvent($name, $parameters)');
  }
  
  @override
  Future<void> logLogin(String method) async {
    _logger.d('NoOp Analytics: logLogin($method)');
  }
  
  @override
  Future<void> logScreenView(String screenName, [String? screenClass]) async {
    _logger.d('NoOp Analytics: logScreenView($screenName, $screenClass)');
  }
  
  @override
  Future<void> setEnabled(bool enabled) async {
    _logger.d('NoOp Analytics: setEnabled($enabled)');
  }
}

/// Triển khai thực tế (sẽ sử dụng Firebase hoặc dịch vụ khác)
@Injectable(as: AnalyticsManager, env: ['staging', 'prod'])
class DefaultAnalyticsManager implements AnalyticsManager {
  final _logger = Logger();
  final List<AnalyticsManager> _providers = [];
  bool _isEnabled = true;
  
  /// Constructor cho phép đăng ký nhiều analytics providers
  DefaultAnalyticsManager({List<AnalyticsManager>? providers}) {
    if (providers != null) {
      _providers.addAll(providers);
    }
  }
  
  /// Thêm một analytics provider
  void addProvider(AnalyticsManager provider) {
    _providers.add(provider);
  }
  
  @override
  Future<void> initialize() async {
    _logger.i('Khởi tạo Default Analytics Manager với ${_providers.length} providers');
    
    // Chỉ thu thập analytics trong môi trường non-debug
    _isEnabled = !kDebugMode;
    
    // Khởi tạo tất cả providers
    for (final provider in _providers) {
      await provider.initialize();
      await provider.setEnabled(_isEnabled);
    }
  }
  
  @override
  Future<void> setUserId(String userId) async {
    if (!_isEnabled) return;
    
    for (final provider in _providers) {
      await provider.setUserId(userId);
    }
  }
  
  @override
  Future<void> setUserProperty(String name, String value) async {
    if (!_isEnabled) return;
    
    for (final provider in _providers) {
      await provider.setUserProperty(name, value);
    }
  }
  
  @override
  Future<void> logEvent(String name, [Map<String, Object>? parameters]) async {
    if (!_isEnabled) return;
    
    for (final provider in _providers) {
      await provider.logEvent(name, parameters);
    }
  }
  
  @override
  Future<void> logLogin(String method) async {
    if (!_isEnabled) return;
    
    for (final provider in _providers) {
      await provider.logLogin(method);
    }
  }
  
  @override
  Future<void> logScreenView(String screenName, [String? screenClass]) async {
    if (!_isEnabled) return;
    
    for (final provider in _providers) {
      await provider.logScreenView(screenName, screenClass);
    }
  }
  
  @override
  Future<void> setEnabled(bool enabled) async {
    _isEnabled = enabled;
    
    for (final provider in _providers) {
      await provider.setEnabled(enabled);
    }
    
    _logger.i('Analytics collection ${enabled ? 'enabled' : 'disabled'}');
  }
}

/// Tiện ích mở rộng cho analytics với các sự kiện cụ thể
extension AnalyticsManagerExtensions on AnalyticsManager {
  /// Ghi nhận sự kiện tạo chat
  Future<void> logCreateChat(String chatId, ChatType type, int participants) {
    return logEvent('create_chat', {
      'chat_id': chatId,
      'chat_type': type.toString().split('.').last,
      'participants_count': participants,
    });
  }
  
  /// Ghi nhận sự kiện gửi tin nhắn
  Future<void> logSendMessage(String chatId, String messageId, String contentType) {
    return logEvent('send_message', {
      'chat_id': chatId,
      'message_id': messageId,
      'content_type': contentType,
    });
  }
  
  /// Ghi nhận sự kiện tải tin nhắn
  Future<void> logLoadMessages(String chatId, int count) {
    return logEvent('load_messages', {
      'chat_id': chatId,
      'message_count': count,
    });
  }
  
  /// Ghi nhận sự kiện lỗi
  Future<void> logError(String errorType, String errorMessage) {
    return logEvent('app_error', {
      'error_type': errorType,
      'error_message': errorMessage,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }
  
  /// Ghi nhận thông tin hiệu suất
  Future<void> logPerformanceMetric(String metricName, num value) {
    return logEvent('performance_metric', {
      'metric_name': metricName,
      'value': value,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }
} 