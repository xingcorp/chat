import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:logger/logger.dart';
import 'base_state.dart';
import '../../../core/services/error_reporting_service.dart';
import '../../../core/services/analytics_service.dart';
import '../../../core/services/state_persistence_service.dart';
import '../../../core/services/performance_monitoring_service.dart';
import '../../../core/services/connectivity_service.dart';
import '../../../core/monitoring/crash_reporter.dart';

/// Lớp cơ sở trừu tượng cho tất cả các BLoC.
/// EventType là kiểu dữ liệu cho các sự kiện mà BLoC này xử lý.
abstract class BaseBloc<EventType, StateType extends BaseState> extends Bloc<EventType, StateType> {
  // Danh sách các subscription cần hủy khi đóng BLoC
  final _subscriptions = <StreamSubscription>{};
  
  // Logger chuyên nghiệp thay vì print()
  final _logger = Logger();

  // Service locator cho DI
  final GetIt _serviceLocator = GetIt.instance;
  
  // Services
  late final ErrorReportingService _errorReportingService;
  late final AnalyticsService _analyticsService;
  late final StatePersistenceService _stateRepository;
  late final PerformanceMonitoringService _performanceMonitor;
  late final ConnectivityService _connectivityService;
  late final CrashReporter _crashReporter;

  // Khởi tạo BLoC với trạng thái ban đầu.
  BaseBloc(StateType initialState) : super(initialState) {
    // Khởi tạo services từ DI container
    _initServices();
    
    // Đăng ký xử lý lỗi
    super.onError = _handleError;
    
    // Lắng nghe sự kiện thay đổi kết nối mạng
    _setupConnectivityListener();
  }
  
  /// Khởi tạo các services cần thiết
  void _initServices() {
    try {
      _errorReportingService = _serviceLocator<ErrorReportingService>();
      _analyticsService = _serviceLocator<AnalyticsService>();
      _stateRepository = _serviceLocator<StatePersistenceService>();
      _performanceMonitor = _serviceLocator<PerformanceMonitoringService>();
      _connectivityService = _serviceLocator<ConnectivityService>();
      _crashReporter = _serviceLocator<CrashReporter>();
    } catch (e) {
      _logger.w('Một số services không khả dụng: $e');
    }
  }
  
  /// Theo dõi sự thay đổi kết nối mạng
  void _setupConnectivityListener() {
    try {
      final subscription = _connectivityService.onConnectivityChanged.listen((hasConnection) {
        if (hasConnection && state is BaseError && (state as BaseError).type == ErrorType.network) {
          // Tự động thử lại khi có kết nối trở lại
          _handleConnectivityRestored();
        }
      });
      
      _subscriptions.add(subscription);
    } catch (e) {
      _logger.w('Không thể thiết lập theo dõi kết nối: $e');
    }
  }
  
  /// Phương thức được gọi khi kết nối mạng được khôi phục
  void _handleConnectivityRestored() {
    // Subclasses có thể ghi đè phương thức này để thực hiện các hành động
    // khi kết nối được khôi phục
  }

  /// Xử lý lỗi với báo cáo lỗi, phân loại và logging
  void _handleError(Object error, StackTrace stackTrace) {
    // Phân loại lỗi
    ErrorType errorType = _classifyError(error);
    
    // Ghi log lỗi
    _logger.e('[${runtimeType.toString()}] Error: $error');
    
    // Báo cáo lỗi đến dịch vụ theo dõi lỗi từ xa
    try {
      _crashReporter.recordError(error, stackTrace, reason: "BLoC Error");
    } catch (e) {
      _logger.w('Không thể báo cáo lỗi: $e');
    }

    // Phát ra trạng thái BaseError nếu trạng thái hiện tại chưa phải là lỗi
    if (state is! BaseError) {
      String errorMessage = _extractUserFriendlyMessage(error, errorType);
      emit(BaseError(
        errorMessage, 
        error: error, 
        stackTrace: stackTrace,
        type: errorType,
        shouldRetry: errorType == ErrorType.network || errorType == ErrorType.timeout
      ) as StateType);
    }

    // Tracking analytics
    try {
      _analyticsService.trackError('${runtimeType.toString()}_${errorType.toString()}', 
        error.toString());
    } catch (e) {
      _logger.w('Không thể ghi nhận analytics: $e');
    }
  }
  
  /// Phân loại lỗi thành các loại khác nhau
  ErrorType _classifyError(dynamic error) {
    // Phân loại lỗi dựa trên thông điệp
    if (error.toString().contains('timeout') || error.toString().contains('timed out')) {
      return ErrorType.timeout;
    } else if (error.toString().contains('network') || 
               error.toString().contains('socket') ||
               error.toString().contains('connection')) {
      return ErrorType.network;
    } else if (error.toString().contains('authentication') || 
               error.toString().contains('unauthenticated') ||
               error.toString().contains('401')) {
      return ErrorType.authentication;
    } else if (error.toString().contains('permission') || 
               error.toString().contains('403') ||
               error.toString().contains('forbidden')) {
      return ErrorType.authorization;
    } else if (error.toString().contains('not found') || 
               error.toString().contains('404')) {
      return ErrorType.notFound;
    } else if (error.toString().contains('validation') || 
               error.toString().contains('422')) {
      return ErrorType.validation;
    } else if (error.toString().contains('server') || 
               error.toString().contains('500')) {
      return ErrorType.server;
    }
    
    return ErrorType.general;
  }
  
  /// Trích xuất thông báo lỗi thân thiện với người dùng
  String _extractUserFriendlyMessage(dynamic error, ErrorType type) {
    switch (type) {
      case ErrorType.network:
        return "Không thể kết nối đến máy chủ. Vui lòng kiểm tra kết nối mạng và thử lại.";
      case ErrorType.authentication:
        return "Phiên đăng nhập của bạn đã hết hạn. Vui lòng đăng nhập lại.";
      case ErrorType.authorization:
        return "Bạn không có quyền truy cập chức năng này.";
      case ErrorType.validation:
        return "Dữ liệu không hợp lệ. Vui lòng kiểm tra lại thông tin đã nhập.";
      case ErrorType.server:
        return "Máy chủ đang gặp sự cố. Vui lòng thử lại sau.";
      case ErrorType.timeout:
        return "Yêu cầu quá thời gian. Vui lòng thử lại sau.";
      case ErrorType.notFound:
        return "Không tìm thấy thông tin yêu cầu.";
      default:
        return "Đã có lỗi xảy ra. Vui lòng thử lại.";
    }
  }

  /// Phương thức tiện ích để phát ra trạng thái Loading.
  void emitLoading({String? message, double? progress}) {
    if (state is! BaseLoading) { // Tránh phát ra loading liên tiếp
      emit(BaseLoading(message: message, progress: progress) as StateType);
    } else if (progress != null) {
      // Cập nhật tiến độ nếu đã ở trạng thái loading
      final currentState = state as BaseLoading;
      if (currentState.progress != progress || currentState.message != message) {
        emit(BaseLoading(message: message ?? currentState.message, progress: progress) as StateType);
      }
    }
  }

  /// Phương thức tiện ích để phát ra trạng thái Error.
  void emitError(
    String message, 
    {
      dynamic error, 
      StackTrace? stackTrace, 
      ErrorType type = ErrorType.general,
      bool shouldRetry = false,
      Duration retryAfter = const Duration(seconds: 5),
    }
  ) {
    if (state is! BaseError) {
      final errorState = BaseError(
        message,
        error: error,
        stackTrace: stackTrace,
        type: type,
        shouldRetry: shouldRetry,
        retryAfter: retryAfter,
      );
      
      emit(errorState as StateType);
      
      // Báo cáo lỗi đến dịch vụ theo dõi lỗi từ xa
      try {
        _crashReporter.recordError(error, stackTrace, reason: message);
      } catch (e) {
        _logger.w('Không thể báo cáo lỗi: $e');
      }
    }
  }
  
  /// Lưu trạng thái hiện tại nếu có thể
  void persistState() {
    if (state is Persistable) {
      try {
        _stateRepository.saveState(
          runtimeType.toString(), 
          (state as Persistable).toJson()
        );
      } catch (e) {
        _logger.w('Không thể lưu trữ trạng thái: $e');
      }
    }
  }
  
  /// Tải trạng thái đã lưu
  Future<StateType?> loadPersistedState() async {
    if (state is Persistable) {
      try {
        final json = await _stateRepository.loadState(runtimeType.toString());
        if (json != null) {
          // Cần triển khai logic chuyển đổi json -> State trong class con
          return null; // TODO: Implement in subclasses
        }
      } catch (e) {
        _logger.w('Không thể tải trạng thái: $e');
      }
    }
    return null;
  }
  
  /// Thực thi một thao tác với cơ chế thử lại tự động
  Future<T?> executeWithRetry<T>(
    Future<T> Function() operation,
    {
      int maxRetries = 3, 
      Duration retryDelay = const Duration(seconds: 2),
      bool emitLoadingState = true,
      String? loadingMessage,
    }
  ) async {
    int attempts = 0;
    
    if (emitLoadingState) {
      emitLoading(message: loadingMessage);
    }
    
    final stopwatch = Stopwatch()..start();
    
    while (attempts < maxRetries) {
      try {
        final result = await operation();
        stopwatch.stop();
        
        // Báo cáo hiệu suất nếu thao tác mất quá nhiều thời gian
        if (stopwatch.elapsedMilliseconds > 500) {
          _performanceMonitor.trackOperationTime(
            '${runtimeType.toString()}_operation',
            stopwatch.elapsedMilliseconds
          );
        }
        
        return result;
      } catch (e, stackTrace) {
        attempts++;
        _logger.w('Thao tác thất bại (lần thử $attempts/$maxRetries): $e');
        
        if (attempts >= maxRetries) {
          // Đã hết số lần thử, phát ra lỗi
          final errorType = _classifyError(e);
          emitError(
            _extractUserFriendlyMessage(e, errorType),
            error: e,
            stackTrace: stackTrace,
            type: errorType
          );
          return null;
        }
        
        // Chờ trước khi thử lại
        await Future.delayed(retryDelay * attempts);
      }
    }
    
    return null;
  }
  
  /// Thêm subscription để theo dõi và hủy khi BLoC đóng
  void addSubscription(StreamSubscription subscription) {
    _subscriptions.add(subscription);
  }

  @override
  void onChange(Change<StateType> change) {
    super.onChange(change);
    
    final String stateChangeSummary = 
        '${change.currentState.runtimeType} -> ${change.nextState.runtimeType}';
    
    // Ghi log thay đổi trạng thái
    _logger.d('[${runtimeType.toString()}] State change: $stateChangeSummary');
    
    // Analytics
    try {
      _analyticsService.trackStateTransition(
        '${runtimeType.toString()}_state_change',
        stateChangeSummary
      );
    } catch (e) {
      // Bỏ qua lỗi analytics
    }
  }

  @override
  void onTransition(Transition<EventType, StateType> transition) {
    super.onTransition(transition);
    
    final stopwatch = Stopwatch()..start();
    
    final String transitionSummary = 
        '${transition.event.runtimeType} caused ${transition.currentState.runtimeType} -> ${transition.nextState.runtimeType}';
    
    // Ghi log các transition
    _logger.d('[${runtimeType.toString()}] Transition: $transitionSummary');
    
    // Theo dõi thời gian xử lý transition
    stopwatch.stop();
    if (stopwatch.elapsedMilliseconds > 16) {  // 1 frame = ~16ms
      _performanceMonitor.trackOperationTime(
        '${runtimeType.toString()}_${transition.event.runtimeType}',
        stopwatch.elapsedMilliseconds
      );
    }
  }
  
  @override
  Future<void> close() {
    // Hủy tất cả subscription khi đóng BLoC
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    _subscriptions.clear();
    
    _logger.d('[${runtimeType.toString()}] Closed');
    return super.close();
  }
} 