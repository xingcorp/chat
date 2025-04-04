import 'dart:async';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';
import 'package:flutter_chat_app/core/monitoring/crash_reporter.dart';
import 'package:flutter_chat_app/core/monitoring/performance_monitor.dart';
import 'package:flutter_chat_app/domain/entities/chat.dart';
import 'package:flutter_chat_app/domain/entities/user.dart';

/// Các sự kiện analytics được theo dõi
enum AnalyticsEvent {
  /// Đăng nhập
  login,
  
  /// Đăng ký
  signup,
  
  /// Đăng xuất
  logout,
  
  /// Tạo chat mới
  createChat,
  
  /// Tham gia vào chat
  joinChat,
  
  /// Rời chat
  leaveChat,
  
  /// Mời người dùng vào chat
  inviteUser,
  
  /// Gửi tin nhắn
  sendMessage,
  
  /// Tải tin nhắn
  loadMessages,
  
  /// Mở màn hình chat
  openChat,
  
  /// Xem profile người dùng
  viewUserProfile,
  
  /// Tìm kiếm
  search,
  
  /// Tải file
  downloadFile,
  
  /// Upload file
  uploadFile,
  
  /// Thực hiện cuộc gọi
  initiateCall,
  
  /// Trả lời cuộc gọi
  answerCall,
  
  /// Kết thúc cuộc gọi
  endCall,
  
  /// Sự kiện tùy chỉnh
  custom,
}

/// Lớp dịch vụ quản lý analytics
@singleton
class AnalyticsService {
  /// Logger
  final _logger = Logger();
  
  /// Firebase Analytics instance
  final FirebaseAnalytics _analytics;
  
  /// Crash reporter để liên kết thông tin
  final CrashReporter _crashReporter;
  
  /// Performance monitor để tạo traces
  final PerformanceMonitor _performanceMonitor;
  
  /// User ID hiện tại
  String? _currentUserId;
  
  /// Có đang thu thập analytics không
  bool _isAnalyticsEnabled = true;
  
  /// Properties mặc định cho tất cả sự kiện
  final Map<String, dynamic> _defaultProperties = {};
  
  /// Constructor
  AnalyticsService(
    this._analytics,
    this._crashReporter,
    this._performanceMonitor,
  );
  
  /// Khởi tạo analytics service
  Future<void> initialize() async {
    try {
      _logger.i('Khởi tạo Analytics Service');
      
      // Disable trong chế độ debug
      _isAnalyticsEnabled = !kDebugMode;
      
      // Cấu hình Firebase Analytics
      await _analytics.setAnalyticsCollectionEnabled(_isAnalyticsEnabled);
      
      // Thiết lập các properties mặc định
      _defaultProperties['app_version'] = '1.0.0'; // Thay bằng phiên bản thực tế
      _defaultProperties['platform'] = kIsWeb ? 'web' : defaultTargetPlatform.toString();
      
      _logger.i('Analytics Service đã được khởi tạo. Bật thu thập: $_isAnalyticsEnabled');
    } catch (e) {
      _logger.e('Lỗi khi khởi tạo Analytics Service: $e');
    }
  }
  
  /// Đặt user ID cho phiên hiện tại
  Future<void> setUserId(String userId) async {
    if (!_isAnalyticsEnabled) return;
    
    try {
      _currentUserId = userId;
      
      // Đặt user ID trong Firebase Analytics
      await _analytics.setUserId(id: userId);
      
      // Đồng bộ với Crash Reporter
      await _crashReporter.setUserIdentifier(userId);
      
      // Thêm user ID vào properties mặc định
      _defaultProperties['user_id'] = userId;
      
      // Thêm user ID vào tất cả các traces
      await _performanceMonitor.setGlobalAttributes({
        'user_id': userId,
      });
      
      _logger.i('Đã thiết lập user ID: $userId');
    } catch (e) {
      _logger.e('Lỗi khi thiết lập user ID: $e');
    }
  }
  
  /// Đặt user properties
  Future<void> setUserProperties({
    String? email,
    String? displayName,
    String? role,
    Map<String, dynamic>? customProperties,
  }) async {
    if (!_isAnalyticsEnabled) return;
    
    try {
      // Đặt user properties trong Firebase Analytics
      if (email != null) {
        await _analytics.setUserProperty(name: 'email', value: email);
      }
      
      if (displayName != null) {
        await _analytics.setUserProperty(name: 'display_name', value: displayName);
      }
      
      if (role != null) {
        await _analytics.setUserProperty(name: 'role', value: role);
      }
      
      // Đặt custom properties
      if (customProperties != null) {
        for (final entry in customProperties.entries) {
          await _analytics.setUserProperty(
            name: entry.key,
            value: entry.value.toString(),
          );
        }
      }
      
      _logger.i('Đã thiết lập user properties');
    } catch (e) {
      _logger.e('Lỗi khi thiết lập user properties: $e');
    }
  }
  
  /// Thiết lập thông tin người dùng đầy đủ
  Future<void> setUser(User user) async {
    if (!_isAnalyticsEnabled) return;
    
    try {
      // Đặt user ID
      await setUserId(user.id);
      
      // Đặt user properties
      await setUserProperties(
        email: user.email,
        displayName: user.fullName,
        customProperties: {
          'last_login': DateTime.now().toIso8601String(),
        },
      );
      
      _logger.i('Đã thiết lập thông tin người dùng: ${user.id}');
    } catch (e) {
      _logger.e('Lỗi khi thiết lập thông tin người dùng: $e');
    }
  }
  
  /// Ghi nhận sự kiện
  Future<void> logEvent(
    AnalyticsEvent event, {
    Map<String, dynamic>? parameters,
    String? customEventName,
  }) async {
    if (!_isAnalyticsEnabled) return;
    
    try {
      // Xác định tên sự kiện
      String eventName;
      
      if (event == AnalyticsEvent.custom && customEventName != null) {
        eventName = customEventName;
      } else {
        eventName = _getEventName(event);
      }
      
      // Kết hợp parameters mặc định và tùy chỉnh
      final combinedParams = <String, dynamic>{
        ..._defaultProperties,
        'timestamp': DateTime.now().toIso8601String(),
      };
      
      if (parameters != null) {
        combinedParams.addAll(parameters);
      }
      
      // Chuyển đổi parameters để phù hợp với Firebase Analytics
      final convertedParams = _convertParameters(combinedParams);
      
      // Ghi nhận sự kiện
      await _analytics.logEvent(
        name: eventName,
        parameters: convertedParams,
      );
      
      _logger.v('Đã ghi nhận sự kiện: $eventName với ${convertedParams.length} parameters');
    } catch (e) {
      _logger.e('Lỗi khi ghi nhận sự kiện: $e');
    }
  }
  
  /// Ghi nhận sự kiện login
  Future<void> logLogin({required String method}) async {
    await logEvent(
      AnalyticsEvent.login,
      parameters: {
        'method': method,
      },
    );
    
    // Cũng ghi nhận bằng sự kiện login có sẵn
    await _analytics.logLogin(loginMethod: method);
  }
  
  /// Ghi nhận sự kiện signup
  Future<void> logSignUp({required String method}) async {
    await logEvent(
      AnalyticsEvent.signup,
      parameters: {
        'method': method,
      },
    );
    
    // Cũng ghi nhận bằng sự kiện signup có sẵn
    await _analytics.logSignUp(signUpMethod: method);
  }
  
  /// Ghi nhận sự kiện tạo chat
  Future<void> logCreateChat({
    required String chatId,
    required ChatType type,
    int participants = 0,
  }) async {
    await logEvent(
      AnalyticsEvent.createChat,
      parameters: {
        'chat_id': chatId,
        'chat_type': type.toString().split('.').last,
        'participants_count': participants,
      },
    );
  }
  
  /// Ghi nhận sự kiện gửi tin nhắn
  Future<void> logSendMessage({
    required String chatId,
    required String messageId,
    required String contentType,
    int? contentLength,
    bool hasAttachments = false,
  }) async {
    await logEvent(
      AnalyticsEvent.sendMessage,
      parameters: {
        'chat_id': chatId,
        'message_id': messageId,
        'content_type': contentType,
        if (contentLength != null) 'content_length': contentLength,
        'has_attachments': hasAttachments,
      },
    );
  }
  
  /// Ghi nhận sự kiện bắt đầu một màn hình
  Future<void> logScreenView({
    required String screenName,
    String? screenClass,
    Map<String, dynamic>? additionalParams,
  }) async {
    if (!_isAnalyticsEnabled) return;
    
    try {
      // Ghi nhận screen view trong Firebase Analytics
      await _analytics.logScreenView(
        screenName: screenName,
        screenClass: screenClass,
      );
      
      // Ghi nhận thêm thông tin chi tiết qua event tùy chỉnh
      final params = <String, dynamic>{
        'screen_name': screenName,
        if (screenClass != null) 'screen_class': screenClass,
      };
      
      if (additionalParams != null) {
        params.addAll(additionalParams);
      }
      
      await logEvent(
        AnalyticsEvent.custom,
        customEventName: 'screen_view_detailed',
        parameters: params,
      );
      
      _logger.v('Đã ghi nhận screen view: $screenName');
    } catch (e) {
      _logger.e('Lỗi khi ghi nhận screen view: $e');
    }
  }
  
  /// Ghi nhận lỗi cho analytics
  Future<void> logError({
    required String errorType,
    String? errorMessage,
    String? errorDetails,
    bool fatal = false,
  }) async {
    if (!_isAnalyticsEnabled) return;
    
    try {
      // Ghi nhận lỗi trong Firebase Analytics
      await _analytics.logEvent(
        name: 'app_error',
        parameters: {
          'error_type': errorType,
          if (errorMessage != null) 'error_message': errorMessage,
          if (errorDetails != null) 'error_details': errorDetails,
          'fatal': fatal,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
      
      _logger.v('Đã ghi nhận lỗi: $errorType');
    } catch (e) {
      _logger.e('Lỗi khi ghi nhận lỗi: $e');
    }
  }
  
  /// Theo dõi giá trị cho hiệu suất ứng dụng
  Future<void> trackValueMetric({
    required String metricName,
    required double value,
    Map<String, dynamic>? dimensions,
  }) async {
    if (!_isAnalyticsEnabled) return;
    
    try {
      // Ghi nhận metric trong Firebase Analytics
      final params = <String, dynamic>{
        'metric_name': metricName,
        'value': value,
        'timestamp': DateTime.now().toIso8601String(),
      };
      
      if (dimensions != null) {
        for (final entry in dimensions.entries) {
          params['dimension_${entry.key}'] = entry.value.toString();
        }
      }
      
      await _analytics.logEvent(
        name: 'app_metric',
        parameters: params,
      );
      
      _logger.v('Đã theo dõi metric: $metricName = $value');
    } catch (e) {
      _logger.e('Lỗi khi theo dõi metric: $e');
    }
  }
  
  /// Reset analytics data (thường gọi khi logout)
  Future<void> resetAnalyticsData() async {
    if (!_isAnalyticsEnabled) return;
    
    try {
      // Reset user ID
      await _analytics.setUserId(id: null);
      _currentUserId = null;
      
      // Reset thông tin liên kết
      _crashReporter.setUserIdentifier('anonymous');
      
      _logger.i('Đã reset analytics data');
    } catch (e) {
      _logger.e('Lỗi khi reset analytics data: $e');
    }
  }
  
  /// Bật/tắt thu thập analytics
  Future<void> setAnalyticsEnabled(bool enabled) async {
    try {
      _isAnalyticsEnabled = enabled;
      await _analytics.setAnalyticsCollectionEnabled(enabled);
      _logger.i('Đã ${enabled ? 'bật' : 'tắt'} thu thập analytics');
    } catch (e) {
      _logger.e('Lỗi khi thiết lập thu thập analytics: $e');
    }
  }
  
  /// Chuyển đổi tên sự kiện
  String _getEventName(AnalyticsEvent event) {
    switch (event) {
      case AnalyticsEvent.login:
        return 'login';
      case AnalyticsEvent.signup:
        return 'sign_up';
      case AnalyticsEvent.logout:
        return 'logout';
      case AnalyticsEvent.createChat:
        return 'create_chat';
      case AnalyticsEvent.joinChat:
        return 'join_chat';
      case AnalyticsEvent.leaveChat:
        return 'leave_chat';
      case AnalyticsEvent.inviteUser:
        return 'invite_user';
      case AnalyticsEvent.sendMessage:
        return 'send_message';
      case AnalyticsEvent.loadMessages:
        return 'load_messages';
      case AnalyticsEvent.openChat:
        return 'open_chat';
      case AnalyticsEvent.viewUserProfile:
        return 'view_user_profile';
      case AnalyticsEvent.search:
        return 'search';
      case AnalyticsEvent.downloadFile:
        return 'download_file';
      case AnalyticsEvent.uploadFile:
        return 'upload_file';
      case AnalyticsEvent.initiateCall:
        return 'initiate_call';
      case AnalyticsEvent.answerCall:
        return 'answer_call';
      case AnalyticsEvent.endCall:
        return 'end_call';
      case AnalyticsEvent.custom:
        return 'custom_event';
    }
  }
  
  /// Chuyển đổi parameters để phù hợp với Firebase Analytics
  Map<String, Object> _convertParameters(Map<String, dynamic> params) {
    final result = <String, Object>{};
    
    for (final entry in params.entries) {
      final key = entry.key;
      final value = entry.value;
      
      if (value is String || value is num || value is bool) {
        result[key] = value;
      } else {
        // Chuyển đổi các giá trị khác thành string
        result[key] = value.toString();
      }
    }
    
    return result;
  }
} 