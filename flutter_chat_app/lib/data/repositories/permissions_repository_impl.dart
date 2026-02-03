// Data Repository Implementation: Permissions
// Concrete implementation của PermissionsRepository
// Tuân thủ Clean Architecture và Dependency Inversion

// Dart imports
import 'dart:async';
import 'dart:convert';

// Third-party package imports
import 'package:injectable/injectable.dart';
import 'package:rxdart/rxdart.dart';
import 'package:shared_preferences/shared_preferences.dart';

// App imports
import 'package:flutter_chat_app/core/constants/storage_keys.dart';
import 'package:flutter_chat_app/core/utils/logger.dart';
import 'package:flutter_chat_app/data/datasources/permissions_datasource.dart';
import 'package:flutter_chat_app/shared/domain/entities/permission_entity.dart';
import 'package:flutter_chat_app/domain/repositories/permissions_repository.dart';

@Injectable(as: PermissionsRepository)
class PermissionsRepositoryImpl implements PermissionsRepository {
  
  PermissionsRepositoryImpl(
    this._dataSource,
    this._preferences,
    this._logger,
  );

  final PermissionsDataSource _dataSource;
  final SharedPreferences _preferences;
  final AppLogger _logger;

  // Streams để theo dõi permission changes
  final Map<PermissionType, BehaviorSubject<PermissionEntity>> _permissionStreams = {};
  final BehaviorSubject<Map<PermissionType, PermissionEntity>> _allPermissionsStream = 
      BehaviorSubject<Map<PermissionType, PermissionEntity>>();

  @override
  Future<PermissionEntity> checkPermission(PermissionType type) async {
    try {
      _logger.info('Checking permission: ${type.name}');
      
      // Lấy trạng thái từ platform
      final status = await _dataSource.checkPermission(type);
      
      // Lấy thông tin đã lưu từ local storage
      final savedPermission = await _getSavedPermission(type);
      
      // Tạo permission entity với thông tin đầy đủ
      final permission = _createPermissionEntity(type, status, savedPermission);
      
      // Cập nhật stream
      _updatePermissionStream(type, permission);
      
      _logger.info('Permission ${type.name} status: ${status.name}');
      return permission;
      
    } catch (e) {
      _logger.error('Error checking permission ${type.name}: $e');
      return _createDefaultPermissionEntity(type);
    }
  }

  @override
  Future<Map<PermissionType, PermissionEntity>> checkPermissions(
    List<PermissionType> types,
  ) async {
    try {
      _logger.info('Checking permissions: ${types.map((t) => t.name).join(', ')}');
      
      final results = <PermissionType, PermissionEntity>{};
      
      // Check từng permission
      for (final type in types) {
        results[type] = await checkPermission(type);
      }
      
      // Cập nhật all permissions stream
      _allPermissionsStream.add(results);
      
      return results;
      
    } catch (e) {
      _logger.error('Error checking permissions: $e');
      return {};
    }
  }

  @override
  Future<PermissionEntity> requestPermission(
    PermissionType type, {
    bool showRationale = false,
  }) async {
    try {
      _logger.info('Requesting permission: ${type.name}');
      
      // Lấy thông tin hiện tại
      final currentPermission = await checkPermission(type);
      
      // Request từ platform
      final status = await _dataSource.requestPermission(type);
      
      // Tạo permission entity mới với thông tin cập nhật
      final updatedPermission = currentPermission.copyWith(
        status: status,
        requestCount: currentPermission.requestCount + 1,
        lastRequestTime: DateTime.now(),
        grantedTime: status == PermissionStatus.granted ? DateTime.now() : null,
      );
      
      // Lưu vào local storage
      await savePermissionState(updatedPermission);
      
      // Cập nhật stream
      _updatePermissionStream(type, updatedPermission);
      
      _logger.info('Permission ${type.name} request result: ${status.name}');
      return updatedPermission;
      
    } catch (e) {
      _logger.error('Error requesting permission ${type.name}: $e');
      return checkPermission(type);
    }
  }

  @override
  Future<PermissionBatchResult> requestPermissions(
    List<PermissionType> types, {
    bool showRationale = false,
  }) async {
    try {
      _logger.info('Requesting permissions batch: ${types.map((t) => t.name).join(', ')}');
      
      final results = <PermissionType, PermissionEntity>{};
      final deniedPermissions = <PermissionType>[];
      final permanentlyDeniedPermissions = <PermissionType>[];
      
      // Request từng permission
      for (final type in types) {
        final result = await requestPermission(type, showRationale: showRationale);
        results[type] = result;
        
        if (result.status == PermissionStatus.denied) {
          deniedPermissions.add(type);
        } else if (result.status == PermissionStatus.permanentlyDenied) {
          permanentlyDeniedPermissions.add(type);
        }
      }
      
      // Tính toán kết quả tổng hợp
      final allGranted = results.values.every((p) => p.isGranted);
      final criticalGranted = results.entries
          .where((e) => e.value.priority == PermissionPriority.critical)
          .every((e) => e.value.isGranted);
      
      final batchResult = PermissionBatchResult(
        results: results,
        allGranted: allGranted,
        criticalGranted: criticalGranted,
        deniedPermissions: deniedPermissions,
        permanentlyDeniedPermissions: permanentlyDeniedPermissions,
      );
      
      _logger.info('Permissions batch result - All granted: $allGranted, Critical granted: $criticalGranted');
      return batchResult;
      
    } catch (e) {
      _logger.error('Error requesting permissions batch: $e');
      return PermissionBatchResult(
        results: const {},
        allGranted: false,
        criticalGranted: false,
        deniedPermissions: types,
        permanentlyDeniedPermissions: const [],
      );
    }
  }

  @override
  Future<bool> openAppSettings({PermissionType? type}) async {
    try {
      _logger.info('Opening app settings for permission: ${type?.name ?? 'general'}');
      return await _dataSource.openAppSettings();
    } catch (e) {
      _logger.error('Error opening app settings: $e');
      return false;
    }
  }

  @override
  Future<bool> canRequestPermission(PermissionType type) async {
    try {
      return await _dataSource.canRequestPermission(type);
    } catch (e) {
      _logger.error('Error checking can request permission ${type.name}: $e');
      return false;
    }
  }

  @override
  Future<bool> shouldShowRequestRationale(PermissionType type) async {
    try {
      return await _dataSource.shouldShowRequestRationale(type);
    } catch (e) {
      _logger.error('Error checking should show rationale ${type.name}: $e');
      return false;
    }
  }

  @override
  Future<void> savePermissionState(PermissionEntity permission) async {
    try {
      final key = '${StorageKeys.permissionPrefix}${permission.type.name}';
      final json = _permissionToJson(permission);
      await _preferences.setString(key, jsonEncode(json));
      _logger.debug('Saved permission state: ${permission.type.name}');
    } catch (e) {
      _logger.error('Error saving permission state ${permission.type.name}: $e');
    }
  }

  @override
  Future<List<PermissionEntity>> getPermissionHistory({PermissionType? type}) async {
    try {
      final history = <PermissionEntity>[];
      final keys = _preferences.getKeys();
      
      for (final key in keys) {
        if (key.startsWith(StorageKeys.permissionPrefix)) {
          final permissionType = key.substring(StorageKeys.permissionPrefix.length);
          if (type == null || permissionType == type.name) {
            final jsonString = _preferences.getString(key);
            if (jsonString != null) {
              final permission = _permissionFromJson(jsonDecode(jsonString));
              if (permission != null) {
                history.add(permission);
              }
            }
          }
        }
      }
      
      return history;
    } catch (e) {
      _logger.error('Error getting permission history: $e');
      return [];
    }
  }

  @override
  Future<void> clearPermissionHistory({PermissionType? type}) async {
    try {
      final keys = _preferences.getKeys().toList();
      
      for (final key in keys) {
        if (key.startsWith(StorageKeys.permissionPrefix)) {
          final permissionType = key.substring(StorageKeys.permissionPrefix.length);
          if (type == null || permissionType == type.name) {
            await _preferences.remove(key);
          }
        }
      }
      
      _logger.info('Cleared permission history for: ${type?.name ?? 'all'}');
    } catch (e) {
      _logger.error('Error clearing permission history: $e');
    }
  }

  @override
  Stream<PermissionEntity> watchPermission(PermissionType type) {
    if (!_permissionStreams.containsKey(type)) {
      _permissionStreams[type] = BehaviorSubject<PermissionEntity>();
      // Initialize với current state
      checkPermission(type).then((permission) {
        _permissionStreams[type]?.add(permission);
      });
    }
    return _permissionStreams[type]!.stream;
  }

  @override
  Stream<Map<PermissionType, PermissionEntity>> watchPermissions(
    List<PermissionType> types,
  ) {
    // Initialize streams cho tất cả types
    for (final type in types) {
      watchPermission(type);
    }
    
    return _allPermissionsStream.stream
        .map((allPermissions) => Map.fromEntries(
              allPermissions.entries.where((e) => types.contains(e.key)),
            ));
  }

  @override
  Future<bool> isPermissionSupported(PermissionType type) async {
    try {
      return await _dataSource.isPermissionSupported(type);
    } catch (e) {
      _logger.error('Error checking permission support ${type.name}: $e');
      return false;
    }
  }

  @override
  Future<PermissionEntity> getPermissionInfo(PermissionType type) async {
    return checkPermission(type);
  }

  @override
  Future<bool> isRunningOnEmulator() async {
    try {
      return await _dataSource.isRunningOnEmulator();
    } catch (e) {
      _logger.error('Error checking emulator status: $e');
      return false;
    }
  }

  @override
  String getPlatformPermissionName(PermissionType type) {
    return _dataSource.getPlatformPermissionName(type);
  }

  @override
  Future<bool> isPermissionRestrictedByPolicy(PermissionType type) async {
    // TODO: Implement enterprise policy checking
    // Tạm thời return false, sẽ implement sau
    return false;
  }

  // Helper methods

  Future<PermissionEntity?> _getSavedPermission(PermissionType type) async {
    try {
      final key = '${StorageKeys.permissionPrefix}${type.name}';
      final jsonString = _preferences.getString(key);
      if (jsonString != null) {
        return _permissionFromJson(jsonDecode(jsonString));
      }
    } catch (e) {
      _logger.error('Error getting saved permission ${type.name}: $e');
    }
    return null;
  }

  PermissionEntity _createPermissionEntity(
    PermissionType type,
    PermissionStatus status,
    PermissionEntity? savedPermission,
  ) {
    return PermissionEntity(
      type: type,
      status: status,
      priority: _getPermissionPriority(type),
      timing: _getPermissionTiming(type),
      title: _getPermissionTitle(type),
      description: _getPermissionDescription(type),
      rationale: _getPermissionRationale(type),
      isRequired: _isPermissionRequired(type),
      canDefer: _canPermissionDefer(type),
      requestCount: savedPermission?.requestCount ?? 0,
      lastRequestTime: savedPermission?.lastRequestTime,
      grantedTime: status == PermissionStatus.granted 
          ? (savedPermission?.grantedTime ?? DateTime.now())
          : null,
    );
  }

  PermissionEntity _createDefaultPermissionEntity(PermissionType type) {
    return PermissionEntity(
      type: type,
      status: PermissionStatus.unknown,
      priority: _getPermissionPriority(type),
      timing: _getPermissionTiming(type),
      title: _getPermissionTitle(type),
      description: _getPermissionDescription(type),
      rationale: _getPermissionRationale(type),
      isRequired: _isPermissionRequired(type),
      canDefer: _canPermissionDefer(type),
    );
  }

  void _updatePermissionStream(PermissionType type, PermissionEntity permission) {
    if (_permissionStreams.containsKey(type)) {
      _permissionStreams[type]!.add(permission);
    }
  }

  // Permission configuration methods
  PermissionPriority _getPermissionPriority(PermissionType type) {
    switch (type) {
      case PermissionType.camera:
      case PermissionType.microphone:
      case PermissionType.storage:
      case PermissionType.notification:
        return PermissionPriority.critical;
      case PermissionType.contacts:
      case PermissionType.location:
      case PermissionType.phone:
        return PermissionPriority.important;
      default:
        return PermissionPriority.optional;
    }
  }

  PermissionRequestTiming _getPermissionTiming(PermissionType type) {
    switch (type) {
      case PermissionType.notification:
        return PermissionRequestTiming.onAppLaunch;
      case PermissionType.camera:
      case PermissionType.microphone:
      case PermissionType.storage:
        return PermissionRequestTiming.onFeatureUse;
      default:
        return PermissionRequestTiming.progressive;
    }
  }

  String _getPermissionTitle(PermissionType type) {
    switch (type) {
      case PermissionType.camera:
        return 'Quyền Camera';
      case PermissionType.microphone:
        return 'Quyền Microphone';
      case PermissionType.storage:
        return 'Quyền Lưu trữ';
      case PermissionType.notification:
        return 'Quyền Thông báo';
      case PermissionType.contacts:
        return 'Quyền Danh bạ';
      case PermissionType.location:
        return 'Quyền Vị trí';
      case PermissionType.phone:
        return 'Quyền Điện thoại';
      case PermissionType.calendar:
        return 'Quyền Lịch';
      case PermissionType.sms:
        return 'Quyền SMS';
      case PermissionType.biometric:
        return 'Quyền Sinh trắc học';
      case PermissionType.bluetooth:
        return 'Quyền Bluetooth';
    }
  }

  String _getPermissionDescription(PermissionType type) {
    switch (type) {
      case PermissionType.camera:
        return 'Cho phép chụp ảnh và quay video để chia sẻ trong cuộc trò chuyện';
      case PermissionType.microphone:
        return 'Cho phép ghi âm tin nhắn thoại và thực hiện cuộc gọi';
      case PermissionType.storage:
        return 'Cho phép lưu trữ và chia sẻ file, ảnh, video';
      case PermissionType.notification:
        return 'Cho phép nhận thông báo tin nhắn và cuộc gọi';
      case PermissionType.contacts:
        return 'Cho phép tìm và kết nối với bạn bè trong danh bạ';
      case PermissionType.location:
        return 'Cho phép chia sẻ vị trí hiện tại với bạn bè';
      case PermissionType.phone:
        return 'Cho phép thực hiện cuộc gọi trực tiếp từ ứng dụng';
      case PermissionType.calendar:
        return 'Cho phép tạo sự kiện và nhắc nhở từ cuộc trò chuyện';
      case PermissionType.sms:
        return 'Cho phép sao lưu và khôi phục tin nhắn qua SMS';
      case PermissionType.biometric:
        return 'Cho phép sử dụng vân tay/Face ID để bảo mật ứng dụng';
      case PermissionType.bluetooth:
        return 'Cho phép kết nối với tai nghe và thiết bị Bluetooth';
    }
  }

  String _getPermissionRationale(PermissionType type) {
    switch (type) {
      case PermissionType.camera:
        return 'Camera cần thiết để chụp ảnh và quay video gửi cho bạn bè. Bạn có thể chụp ảnh trực tiếp trong cuộc trò chuyện.';
      case PermissionType.microphone:
        return 'Microphone cần thiết để ghi âm tin nhắn thoại và thực hiện cuộc gọi. Tin nhắn thoại giúp giao tiếp nhanh chóng hơn.';
      case PermissionType.storage:
        return 'Quyền lưu trữ cần thiết để lưu và chia sẻ file, ảnh, video. Chúng tôi chỉ truy cập những file bạn chọn chia sẻ.';
      case PermissionType.notification:
        return 'Thông báo giúp bạn không bỏ lỡ tin nhắn và cuộc gọi quan trọng ngay cả khi không mở ứng dụng.';
      case PermissionType.contacts:
        return 'Danh bạ giúp bạn tìm và kết nối với bạn bè đang sử dụng ứng dụng. Chúng tôi không lưu trữ danh bạ trên server.';
      case PermissionType.location:
        return 'Vị trí giúp bạn chia sẻ địa điểm hiện tại với bạn bè khi cần thiết. Vị trí chỉ được chia sẻ khi bạn chủ động.';
      case PermissionType.phone:
        return 'Quyền điện thoại cho phép thực hiện cuộc gọi trực tiếp từ ứng dụng mà không cần chuyển sang ứng dụng khác.';
      case PermissionType.calendar:
        return 'Lịch giúp bạn tạo sự kiện và nhắc nhở từ cuộc trò chuyện. Bạn có thể lên lịch hẹn trực tiếp từ tin nhắn.';
      case PermissionType.sms:
        return 'SMS giúp sao lưu và khôi phục tin nhắn khi chuyển thiết bị. Dữ liệu được mã hóa và bảo mật.';
      case PermissionType.biometric:
        return 'Sinh trắc học giúp bảo mật ứng dụng và xác thực danh tính. Dữ liệu sinh trắc học không được lưu trữ.';
      case PermissionType.bluetooth:
        return 'Bluetooth giúp kết nối với tai nghe và loa khi thực hiện cuộc gọi hoặc nghe tin nhắn thoại.';
    }
  }

  bool _isPermissionRequired(PermissionType type) {
    switch (type) {
      case PermissionType.notification:
        return true;
      default:
        return false;
    }
  }

  bool _canPermissionDefer(PermissionType type) {
    switch (type) {
      case PermissionType.notification:
        return false;
      default:
        return true;
    }
  }

  // JSON serialization methods
  Map<String, dynamic> _permissionToJson(PermissionEntity permission) {
    return {
      'type': permission.type.name,
      'status': permission.status.name,
      'priority': permission.priority.name,
      'timing': permission.timing.name,
      'title': permission.title,
      'description': permission.description,
      'rationale': permission.rationale,
      'isRequired': permission.isRequired,
      'canDefer': permission.canDefer,
      'requestCount': permission.requestCount,
      'lastRequestTime': permission.lastRequestTime?.toIso8601String(),
      'grantedTime': permission.grantedTime?.toIso8601String(),
    };
  }

  PermissionEntity? _permissionFromJson(Map<String, dynamic> json) {
    try {
      return PermissionEntity(
        type: PermissionType.values.firstWhere((e) => e.name == json['type']),
        status: PermissionStatus.values.firstWhere((e) => e.name == json['status']),
        priority: PermissionPriority.values.firstWhere((e) => e.name == json['priority']),
        timing: PermissionRequestTiming.values.firstWhere((e) => e.name == json['timing']),
        title: json['title'] ?? '',
        description: json['description'] ?? '',
        rationale: json['rationale'] ?? '',
        isRequired: json['isRequired'] ?? false,
        canDefer: json['canDefer'] ?? true,
        requestCount: json['requestCount'] ?? 0,
        lastRequestTime: json['lastRequestTime'] != null 
            ? DateTime.parse(json['lastRequestTime'])
            : null,
        grantedTime: json['grantedTime'] != null 
            ? DateTime.parse(json['grantedTime'])
            : null,
      );
    } catch (e) {
      _logger.error('Error parsing permission from JSON: $e');
      return null;
    }
  }

  // Cleanup resources
  void dispose() {
    for (final stream in _permissionStreams.values) {
      stream.close();
    }
    _allPermissionsStream.close();
  }
}
