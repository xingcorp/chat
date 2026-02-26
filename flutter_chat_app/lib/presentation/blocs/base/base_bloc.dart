import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_chat_app/core/monitoring/i_analytics_service.dart';
import 'package:flutter_chat_app/core/monitoring/i_crash_reporter.dart';
import 'package:flutter_chat_app/core/monitoring/i_performance_monitor.dart';
import 'package:flutter_chat_app/presentation/blocs/base/base_state.dart';
import 'package:get_it/get_it.dart';
import 'package:logger/logger.dart';

/// Lớp cơ sở trừu tượng cho tất cả các BLoC.
///
/// Cung cấp: logging, error reporting, analytics, performance monitoring.
///
/// **QUAN TRỌNG**: Không emit BaseLoading/BaseError trực tiếp vì subclass
/// dùng freezed state (MessageState, ChatInfoState, ...) — BaseError/BaseLoading
/// không thể cast sang các freezed StateType. Subclass tự emit state phù hợp.
abstract class BaseBloc<EventType, StateType extends BaseState>
    extends Bloc<EventType, StateType> {
  final _subscriptions = <StreamSubscription>{};
  final _logger = Logger();
  final GetIt _serviceLocator = GetIt.instance;

  // Nullable services — tránh LateInitializationError
  ICrashReporter? _crashReporter;
  IAnalyticsService? _analyticsService;
  IPerformanceMonitor? _performanceMonitor;

  BaseBloc(super.initialState) {
    _initServices();
    _registerEventHandlers();
  }

  /// Đăng ký handlers cho các sự kiện, có thể ghi đè bởi lớp con
  @protected
  void _registerEventHandlers() {}

  /// Xử lý lỗi — public API cho subclass
  @protected
  void handleError(Object error, StackTrace stackTrace) {
    _handleError(error, stackTrace);
  }

  /// Phân loại lỗi — public API cho subclass
  ErrorType classifyError(dynamic error) => _classifyError(error);

  /// Trích xuất thông báo lỗi thân thiện với người dùng
  String extractUserFriendlyMessage(dynamic error, ErrorType type) {
    switch (type) {
      case ErrorType.network:
        return 'Không thể kết nối đến máy chủ. Vui lòng kiểm tra kết nối mạng.';
      case ErrorType.authentication:
        return 'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.';
      case ErrorType.authorization:
        return 'Bạn không có quyền truy cập chức năng này.';
      case ErrorType.validation:
        return 'Dữ liệu không hợp lệ. Vui lòng kiểm tra lại.';
      case ErrorType.server:
        return 'Máy chủ đang gặp sự cố. Vui lòng thử lại sau.';
      case ErrorType.timeout:
        return 'Yêu cầu quá thời gian. Vui lòng thử lại sau.';
      case ErrorType.notFound:
        return 'Không tìm thấy thông tin yêu cầu.';
      default:
        return 'Đã có lỗi xảy ra. Vui lòng thử lại.';
    }
  }

  // ═══════════════════════════════════════════
  // Private helpers
  // ═══════════════════════════════════════════

  /// Khởi tạo services — mỗi service init riêng để 1 fail không ảnh hưởng còn lại
  void _initServices() {
    try {
      _crashReporter = _serviceLocator.get<ICrashReporter>();
    } catch (_) {}
    try {
      _analyticsService = _serviceLocator.get<IAnalyticsService>();
    } catch (_) {}
    try {
      _performanceMonitor = _serviceLocator.get<IPerformanceMonitor>();
    } catch (_) {}
  }

  /// Xử lý lỗi: log + crash report + analytics. KHÔNG emit state.
  void _handleError(Object error, StackTrace stackTrace) {
    final errorType = _classifyError(error);
    _logger.e('[$runtimeType] Error ($errorType): $error');

    try {
      _crashReporter?.recordError(error, stackTrace, reason: 'BLoC Error');
    } catch (_) {}

    try {
      final analytics = _analyticsService;
      if (analytics != null) {
        analytics.logError(
          errorType: '${runtimeType}_error',
          errorMessage: error.toString(),
          errorDetails: stackTrace.toString(),
        );
      }
    } catch (_) {}
  }

  ErrorType _classifyError(dynamic error) {
    final msg = error.toString().toLowerCase();
    if (msg.contains('timeout') || msg.contains('timed out')) {
      return ErrorType.timeout;
    }
    if (msg.contains('network') ||
        msg.contains('socket') ||
        msg.contains('connection')) {
      return ErrorType.network;
    }
    if (msg.contains('authentication') ||
        msg.contains('unauthenticated') ||
        msg.contains('401')) {
      return ErrorType.authentication;
    }
    if (msg.contains('permission') ||
        msg.contains('403') ||
        msg.contains('forbidden')) {
      return ErrorType.authorization;
    }
    if (msg.contains('not found') || msg.contains('404')) {
      return ErrorType.notFound;
    }
    if (msg.contains('validation') || msg.contains('422')) {
      return ErrorType.validation;
    }
    if (msg.contains('server') || msg.contains('500')) {
      return ErrorType.server;
    }
    return ErrorType.general;
  }

  // ═══════════════════════════════════════════
  // Retry utility
  // ═══════════════════════════════════════════

  /// Thực thi operation với retry. Trả về null nếu thất bại.
  /// Subclass tự quyết định emit loading/error state phù hợp.
  Future<T?> executeWithRetry<T>(
    Future<T> Function() operation, {
    int maxRetries = 3,
    Duration retryDelay = const Duration(seconds: 2),
    String? operationLabel,
  }) async {
    final opName = operationLabel ?? '${runtimeType}_operation';
    var attempts = 0;

    try {
      _performanceMonitor?.startTrace(
        TraceType.custom,
        customTraceName: opName,
        attributes: {'retry_max': '$maxRetries', 'bloc': '$runtimeType'},
      );
    } catch (_) {}

    T? result;
    while (attempts < maxRetries) {
      try {
        result = await operation();
        try {
          _performanceMonitor?.addTraceAttribute(
            TraceType.custom,
            customTraceName: opName,
            attributeName: 'result',
            value: 'success',
          );
        } catch (_) {}
        break;
      } catch (e, stackTrace) {
        attempts++;
        _logger.w('Thao tác thất bại (lần thử $attempts/$maxRetries): $e');
        if (attempts >= maxRetries) {
          _handleError(e, stackTrace);
          try {
            _performanceMonitor?.addTraceAttribute(
              TraceType.custom,
              customTraceName: opName,
              attributeName: 'result',
              value: 'failed',
            );
          } catch (_) {}
          break;
        }
        await Future.delayed(retryDelay * attempts);
      }
    }

    try {
      _performanceMonitor?.stopTrace(
        TraceType.custom,
        customTraceName: opName,
      );
    } catch (_) {}

    return result;
  }

  /// Thêm subscription để tự hủy khi BLoC đóng
  void addSubscription(StreamSubscription subscription) {
    _subscriptions.add(subscription);
  }

  // ═══════════════════════════════════════════
  // Lifecycle overrides
  // ═══════════════════════════════════════════

  @override
  void onChange(Change<StateType> change) {
    super.onChange(change);
    final summary =
        '${change.currentState.runtimeType} -> ${change.nextState.runtimeType}';
    _logger.d('[$runtimeType] State change: $summary');

    try {
      _analyticsService?.logEvent(
        AnalyticsEvent.custom,
        customEventName: 'state_change',
        parameters: {'bloc': '$runtimeType', 'transition': summary},
      );
    } catch (_) {}
  }

  @override
  void onTransition(Transition<EventType, StateType> transition) {
    super.onTransition(transition);
    final summary =
        '${transition.event.runtimeType} caused '
        '${transition.currentState.runtimeType} -> ${transition.nextState.runtimeType}';
    _logger.d('[$runtimeType] Transition: $summary');

    final monitor = _performanceMonitor;
    if (monitor == null) return;

    final traceName = '${runtimeType}_transition';
    try {
      monitor.startTrace(
        TraceType.custom,
        customTraceName: traceName,
        attributes: {
          'event_type': '${transition.event.runtimeType}',
          'from_state': '${transition.currentState.runtimeType}',
          'to_state': '${transition.nextState.runtimeType}',
        },
      );
      // Stop trace sau 100ms — wrap trong try-catch riêng
      Future.delayed(const Duration(milliseconds: 100), () {
        try {
          monitor.stopTrace(TraceType.custom, customTraceName: traceName);
        } catch (_) {}
      });
    } catch (_) {}
  }

  @override
  void onError(Object error, StackTrace stackTrace) {
    _handleError(error, stackTrace);
    super.onError(error, stackTrace);
  }

  @override
  Future<void> close() {
    for (final sub in _subscriptions) {
      sub.cancel();
    }
    _subscriptions.clear();
    _logger.d('[$runtimeType] Closed');
    return super.close();
  }
}
