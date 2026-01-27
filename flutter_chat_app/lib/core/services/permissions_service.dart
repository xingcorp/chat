// Core Service: Enterprise Permissions Management
// High-level service cho permissions với analytics và error handling
// Tuân thủ Single Responsibility và Interface Segregation

// Dart imports
import 'dart:async';

// Third-party package imports
import 'package:injectable/injectable.dart';
import 'package:rxdart/rxdart.dart';

// App imports
import 'package:flutter_chat_app/core/error/failures.dart';
import 'package:flutter_chat_app/core/monitoring/analytics_service.dart';
import 'package:flutter_chat_app/core/utils/logger.dart';
import 'package:flutter_chat_app/domain/entities/permission_entity.dart';
import 'package:flutter_chat_app/domain/repositories/permissions_repository.dart';
import 'package:flutter_chat_app/domain/usecases/request_permission_usecase.dart';

/// Enterprise-grade permissions service
/// Cung cấp high-level API cho permissions management
@singleton
class PermissionsService {
  
  PermissionsService(
    this._repository,
    this._requestPermissionUseCase,
    this._analyticsService,
    this._logger,
  );

  final PermissionsRepository _repository;
  final RequestPermissionUseCase _requestPermissionUseCase;
  final AnalyticsService _analyticsService;
  final AppLogger _logger;

  // Cache cho permission states
  final Map<PermissionType, PermissionEntity> _permissionCache = {};
  
  // Streams cho real-time updates
  final BehaviorSubject<Map<PermissionType, PermissionEntity>> _permissionsStream = 
      BehaviorSubject<Map<PermissionType, PermissionEntity>>();

  // Flags để track initialization
  bool _isInitialized = false;
  final Completer<void> _initCompleter = Completer<void>();

  /// Initialize permissions service
  /// Gọi một lần khi app khởi động
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      _logger.info('Initializing PermissionsService...');
      
      // Load tất cả permissions hiện tại
      await _loadAllPermissions();
      
      // Setup analytics tracking
      await _setupAnalyticsTracking();
      
      // Setup permission monitoring
      _setupPermissionMonitoring();
      
      _isInitialized = true;
      _initCompleter.complete();
      
      _logger.info('PermissionsService initialized successfully');
      
    } catch (e) {
      _logger.error('Failed to initialize PermissionsService: $e');
      _initCompleter.completeError(e);
      rethrow;
    }
  }

  /// Đảm bảo service đã được initialize
  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      await _initCompleter.future;
    }
  }

  /// Kiểm tra permission hiện tại
  Future<PermissionEntity> checkPermission(PermissionType type) async {
    await _ensureInitialized();
    
    try {
      // Kiểm tra cache trước
      if (_permissionCache.containsKey(type)) {
        final cached = _permissionCache[type]!;
        // Cache valid trong 5 phút
        if (cached.lastRequestTime != null && 
            DateTime.now().difference(cached.lastRequestTime!).inMinutes < 5) {
          return cached;
        }
      }
      
      // Lấy từ repository
      final permission = await _repository.checkPermission(type);
      
      // Cập nhật cache
      _permissionCache[type] = permission;
      
      // Track analytics
      await _trackPermissionCheck(permission);
      
      return permission;
      
    } catch (e) {
      _logger.error('Error checking permission ${type.name}: $e');
      rethrow;
    }
  }

  /// Request permission với enterprise-grade handling
  Future<PermissionRequestResult> requestPermission(
    PermissionType type, {
    bool showRationale = true,
    bool forceRequest = false,
    dynamic context,
  }) async {
    await _ensureInitialized();
    
    try {
      _logger.info('Requesting permission: ${type.name}');
      
      // Track request start
      await _trackPermissionRequestStart(type);
      
      // Sử dụng use case để request
      final result = await _requestPermissionUseCase(
        RequestPermissionParams(
          type: type,
          showRationale: showRationale,
          forceRequest: forceRequest,
          context: context,
        ),
      );
      
      if (result.isSuccess) {
        final permission = result.valueOrNull!;
        _logger.info('Permission request successful: ${type.name}');

        // Cập nhật cache
        _permissionCache[type] = permission;

        // Track success
        _trackPermissionRequestSuccess(permission);

        return PermissionRequestResult.success(permission);
      } else {
        final failure = result.failureOrNull!;
        _logger.warning('Permission request failed: ${failure.message}');
        _trackPermissionRequestFailure(type, failure);
        return PermissionRequestResult.failure(failure);
      }
      
    } catch (e) {
      _logger.error('Unexpected error requesting permission ${type.name}: $e');
      await _trackPermissionRequestError(type, e);
      return PermissionRequestResult.error(e);
    }
  }

  /// Request nhiều permissions cùng lúc
  Future<BatchPermissionRequestResult> requestPermissions(
    List<PermissionType> types, {
    bool showRationale = true,
    bool stopOnFirstFailure = false,
  }) async {
    await _ensureInitialized();
    
    try {
      _logger.info('Requesting permissions batch: ${types.map((t) => t.name).join(', ')}');
      
      final results = <PermissionType, PermissionRequestResult>{};
      final successful = <PermissionType, PermissionEntity>{};
      final failed = <PermissionType, Failure>{};
      
      for (final type in types) {
        final result = await requestPermission(
          type,
          showRationale: showRationale,
        );
        
        results[type] = result;
        
        if (result.isSuccess) {
          successful[type] = result.permission!;
        } else {
          failed[type] = result.failure!;
          
          if (stopOnFirstFailure) {
            break;
          }
        }
      }
      
      final batchResult = BatchPermissionRequestResult(
        results: results,
        successful: successful,
        failed: failed,
        allSuccessful: failed.isEmpty,
        criticalSuccessful: _checkCriticalPermissionsGranted(successful),
      );
      
      // Track batch result
      await _trackBatchPermissionRequest(batchResult);
      
      return batchResult;
      
    } catch (e) {
      _logger.error('Error requesting permissions batch: $e');
      return BatchPermissionRequestResult.error(types, e);
    }
  }

  /// Kiểm tra tất cả critical permissions
  Future<bool> checkCriticalPermissions() async {
    await _ensureInitialized();
    
    final criticalTypes = PermissionType.values
        .where(_isCriticalPermission)
        .toList();
    
    final results = await _repository.checkPermissions(criticalTypes);
    
    return results.values.every((permission) => permission.isGranted);
  }

  /// Request tất cả critical permissions
  Future<BatchPermissionRequestResult> requestCriticalPermissions({
    bool showRationale = true,
  }) async {
    final criticalTypes = PermissionType.values
        .where(_isCriticalPermission)
        .toList();
    
    return requestPermissions(
      criticalTypes,
      showRationale: showRationale,
      stopOnFirstFailure: false,
    );
  }

  /// Mở app settings
  Future<bool> openAppSettings({PermissionType? type}) async {
    await _ensureInitialized();
    
    try {
      _logger.info('Opening app settings for: ${type?.name ?? 'general'}');
      
      final success = await _repository.openAppSettings(type: type);
      
      // Track analytics
      await _analyticsService.track('permission_settings_opened', {
        'permission_type': type?.name,
        'success': success,
      });
      
      return success;
      
    } catch (e) {
      _logger.error('Error opening app settings: $e');
      return false;
    }
  }

  /// Lấy permission status summary
  Future<PermissionStatusSummary> getPermissionSummary() async {
    await _ensureInitialized();
    
    const allTypes = PermissionType.values;
    final results = await _repository.checkPermissions(allTypes);
    
    final granted = <PermissionType>[];
    final denied = <PermissionType>[];
    final permanentlyDenied = <PermissionType>[];
    final critical = <PermissionType>[];
    final important = <PermissionType>[];
    final optional = <PermissionType>[];
    
    for (final entry in results.entries) {
      final type = entry.key;
      final permission = entry.value;
      
      // Categorize by status
      if (permission.isGranted) {
        granted.add(type);
      } else if (permission.isPermanentlyDenied) {
        permanentlyDenied.add(type);
      } else {
        denied.add(type);
      }
      
      // Categorize by priority
      switch (permission.priority) {
        case PermissionPriority.critical:
          critical.add(type);
          break;
        case PermissionPriority.important:
          important.add(type);
          break;
        case PermissionPriority.optional:
          optional.add(type);
          break;
      }
    }
    
    return PermissionStatusSummary(
      granted: granted,
      denied: denied,
      permanentlyDenied: permanentlyDenied,
      critical: critical,
      important: important,
      optional: optional,
      allCriticalGranted: critical.every((type) => granted.contains(type)),
      allImportantGranted: important.every((type) => granted.contains(type)),
    );
  }

  /// Stream để theo dõi permission changes
  Stream<Map<PermissionType, PermissionEntity>> get permissionsStream => 
      _permissionsStream.stream;

  /// Stream cho specific permission
  Stream<PermissionEntity> watchPermission(PermissionType type) {
    return _repository.watchPermission(type);
  }

  /// Clear permission cache
  void clearCache() {
    _permissionCache.clear();
    _logger.debug('Permission cache cleared');
  }

  /// Reset permission history (for testing)
  Future<void> resetPermissionHistory() async {
    await _ensureInitialized();
    await _repository.clearPermissionHistory();
    clearCache();
    _logger.info('Permission history reset');
  }

  // Private helper methods

  Future<void> _loadAllPermissions() async {
    final allTypes = PermissionType.values;
    final results = await _repository.checkPermissions(allTypes);
    
    _permissionCache.addAll(results);
    _permissionsStream.add(results);
  }

  Future<void> _setupAnalyticsTracking() async {
    // Track permission service initialization
    await _analyticsService.track('permissions_service_initialized', {
      'timestamp': DateTime.now().toIso8601String(),
      'platform': await _repository.isRunningOnEmulator() ? 'emulator' : 'device',
    });
  }

  void _setupPermissionMonitoring() {
    // Monitor permission changes và update cache
    for (final type in PermissionType.values) {
      _repository.watchPermission(type).listen((permission) {
        _permissionCache[type] = permission;
        _permissionsStream.add(Map.from(_permissionCache));
      });
    }
  }

  bool _isCriticalPermission(PermissionType type) {
    switch (type) {
      case PermissionType.camera:
      case PermissionType.microphone:
      case PermissionType.storage:
      case PermissionType.notification:
        return true;
      default:
        return false;
    }
  }

  bool _checkCriticalPermissionsGranted(Map<PermissionType, PermissionEntity> permissions) {
    final criticalTypes = PermissionType.values.where(_isCriticalPermission);
    return criticalTypes.every((type) => 
        permissions.containsKey(type) && permissions[type]!.isGranted);
  }

  // Analytics tracking methods

  Future<void> _trackPermissionCheck(PermissionEntity permission) async {
    await _analyticsService.track('permission_checked', {
      'permission_type': permission.type.name,
      'status': permission.status.name,
      'priority': permission.priority.name,
    });
  }

  Future<void> _trackPermissionRequestStart(PermissionType type) async {
    await _analyticsService.track('permission_request_started', {
      'permission_type': type.name,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  Future<void> _trackPermissionRequestSuccess(PermissionEntity permission) async {
    await _analyticsService.track('permission_request_success', {
      'permission_type': permission.type.name,
      'status': permission.status.name,
      'request_count': permission.requestCount,
    });
  }

  Future<void> _trackPermissionRequestFailure(PermissionType type, Failure failure) async {
    await _analyticsService.track('permission_request_failure', {
      'permission_type': type.name,
      'failure_reason': failure.runtimeType.toString(),
      'failure_message': failure.toString(),
    });
  }

  Future<void> _trackPermissionRequestError(PermissionType type, dynamic error) async {
    await _analyticsService.track('permission_request_error', {
      'permission_type': type.name,
      'error': error.toString(),
    });
  }

  Future<void> _trackBatchPermissionRequest(BatchPermissionRequestResult result) async {
    await _analyticsService.track('batch_permission_request', {
      'total_count': result.results.length,
      'successful_count': result.successful.length,
      'failed_count': result.failed.length,
      'all_successful': result.allSuccessful,
      'critical_successful': result.criticalSuccessful,
    });
  }

  /// Dispose resources
  void dispose() {
    _permissionsStream.close();
  }
}

/// Kết quả của permission request
class PermissionRequestResult {
  const PermissionRequestResult._({
    this.permission,
    this.failure,
    this.error,
  });

  final PermissionEntity? permission;
  final Failure? failure;
  final dynamic error;

  bool get isSuccess => permission != null;
  bool get isFailure => failure != null;
  bool get isError => error != null;

  factory PermissionRequestResult.success(PermissionEntity permission) =>
      PermissionRequestResult._(permission: permission);

  factory PermissionRequestResult.failure(Failure failure) =>
      PermissionRequestResult._(failure: failure);

  factory PermissionRequestResult.error(dynamic error) =>
      PermissionRequestResult._(error: error);
}

/// Kết quả của batch permission request
class BatchPermissionRequestResult {
  const BatchPermissionRequestResult({
    required this.results,
    required this.successful,
    required this.failed,
    required this.allSuccessful,
    required this.criticalSuccessful,
  });

  final Map<PermissionType, PermissionRequestResult> results;
  final Map<PermissionType, PermissionEntity> successful;
  final Map<PermissionType, Failure> failed;
  final bool allSuccessful;
  final bool criticalSuccessful;

  factory BatchPermissionRequestResult.error(List<PermissionType> types, dynamic error) {
    final results = <PermissionType, PermissionRequestResult>{};
    final failed = <PermissionType, Failure>{};
    
    for (final type in types) {
      final failure = UnknownFailure(message: error.toString());
      results[type] = PermissionRequestResult.failure(failure);
      failed[type] = failure;
    }
    
    return BatchPermissionRequestResult(
      results: results,
      successful: {},
      failed: failed,
      allSuccessful: false,
      criticalSuccessful: false,
    );
  }
}

/// Tóm tắt trạng thái permissions
class PermissionStatusSummary {
  const PermissionStatusSummary({
    required this.granted,
    required this.denied,
    required this.permanentlyDenied,
    required this.critical,
    required this.important,
    required this.optional,
    required this.allCriticalGranted,
    required this.allImportantGranted,
  });

  final List<PermissionType> granted;
  final List<PermissionType> denied;
  final List<PermissionType> permanentlyDenied;
  final List<PermissionType> critical;
  final List<PermissionType> important;
  final List<PermissionType> optional;
  final bool allCriticalGranted;
  final bool allImportantGranted;
}
