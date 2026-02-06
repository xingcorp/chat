// Data Source: Permissions
// Platform-specific implementation cho permissions
// Sử dụng permission_handler package

import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart' as ph;
import 'package:app_settings/app_settings.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:injectable/injectable.dart';
import '../../shared/domain/entities/permission_entity.dart';

/// Abstract datasource interface
abstract class PermissionsDataSource {
  Future<PermissionStatus> checkPermission(PermissionType type);
  Future<Map<PermissionType, PermissionStatus>> checkPermissions(List<PermissionType> types);
  Future<PermissionStatus> requestPermission(PermissionType type);
  Future<Map<PermissionType, PermissionStatus>> requestPermissions(List<PermissionType> types);
  Future<bool> openAppSettings();
  Future<bool> canRequestPermission(PermissionType type);
  Future<bool> shouldShowRequestRationale(PermissionType type);
  Future<bool> isPermissionSupported(PermissionType type);
  Future<bool> isRunningOnEmulator();
  String getPlatformPermissionName(PermissionType type);
}

/// Implementation cho mobile platforms (Android/iOS)
@Injectable(as: PermissionsDataSource)
class MobilePermissionsDataSource implements PermissionsDataSource {
  
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  bool get _isAndroid => defaultTargetPlatform == TargetPlatform.android;
  bool get _isIOS => defaultTargetPlatform == TargetPlatform.iOS;

  @override
  Future<PermissionStatus> checkPermission(PermissionType type) async {
    if (kIsWeb) {
      return PermissionStatus.unknown;
    }

    final permission = _mapToPermissionHandler(type);
    if (permission == null) {
      return PermissionStatus.unknown;
    }

    try {
      final status = await permission.status;
      return _mapFromPermissionHandler(status);
    } catch (_) {
      return PermissionStatus.unknown;
    }
  }

  @override
  Future<Map<PermissionType, PermissionStatus>> checkPermissions(
    List<PermissionType> types,
  ) async {
    final result = <PermissionType, PermissionStatus>{};
    
    for (final type in types) {
      result[type] = await checkPermission(type);
    }
    
    return result;
  }

  @override
  Future<PermissionStatus> requestPermission(PermissionType type) async {
    if (kIsWeb) {
      return PermissionStatus.unknown;
    }

    final permission = _mapToPermissionHandler(type);
    if (permission == null) {
      return PermissionStatus.unknown;
    }
    
    // Kiểm tra platform-specific requirements
    if (!kIsWeb && _isAndroid && type == PermissionType.notification) {
      final androidInfo = await _deviceInfo.androidInfo;
      if (androidInfo.version.sdkInt < 33) {
        // Android < 13 không cần request notification permission
        return PermissionStatus.granted;
      }
    }

    try {
      final status = await permission.request();
      return _mapFromPermissionHandler(status);
    } catch (_) {
      return PermissionStatus.unknown;
    }
  }

  @override
  Future<Map<PermissionType, PermissionStatus>> requestPermissions(
    List<PermissionType> types,
  ) async {
    final permissions = <ph.Permission>[];
    final typeMap = <ph.Permission, PermissionType>{};

    // Map permissions và filter những cái supported
    for (final type in types) {
      final permission = _mapToPermissionHandler(type);
      if (permission != null) {
        permissions.add(permission);
        typeMap[permission] = type;
      }
    }
    
    // Request batch
    final results = await permissions.request();
    
    // Map kết quả về
    final mappedResults = <PermissionType, PermissionStatus>{};
    for (final entry in results.entries) {
      final type = typeMap[entry.key];
      if (type != null) {
        mappedResults[type] = _mapFromPermissionHandler(entry.value);
      }
    }
    
    return mappedResults;
  }

  @override
  Future<bool> openAppSettings() async {
    try {
      if (kIsWeb) {
        return false;
      }

      if (_isAndroid) {
        await AppSettings.openAppSettings();
        return true;
      } else if (_isIOS) {
        await AppSettings.openAppSettings();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<bool> canRequestPermission(PermissionType type) async {
    if (kIsWeb) {
      return false;
    }

    final permission = _mapToPermissionHandler(type);
    if (permission == null) return false;

    try {
      final status = await permission.status;
      return status != ph.PermissionStatus.granted &&
          status != ph.PermissionStatus.permanentlyDenied &&
          status != ph.PermissionStatus.restricted;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> shouldShowRequestRationale(PermissionType type) async {
    if (kIsWeb) return false;
    if (!_isAndroid) return false;
    
    final permission = _mapToPermissionHandler(type);
    if (permission == null) return false;
    
    return permission.shouldShowRequestRationale;
  }

  @override
  Future<bool> isPermissionSupported(PermissionType type) async {
    if (kIsWeb) {
      return false;
    }

    // Kiểm tra platform support
    if (_isAndroid) {
      return _isAndroidPermissionSupported(type);
    } else if (_isIOS) {
      return _isIOSPermissionSupported(type);
    }
    return false;
  }

  @override
  Future<bool> isRunningOnEmulator() async {
    try {
      if (kIsWeb) {
        return false;
      }

      if (_isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;
        return !androidInfo.isPhysicalDevice;
      } else if (_isIOS) {
        final iosInfo = await _deviceInfo.iosInfo;
        return !iosInfo.isPhysicalDevice;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  @override
  String getPlatformPermissionName(PermissionType type) {
    if (kIsWeb) {
      return type.name;
    }

    if (_isAndroid) {
      return _getAndroidPermissionName(type);
    } else if (_isIOS) {
      return _getIOSPermissionName(type);
    }
    return type.name;
  }

  /// Map từ domain PermissionType sang permission_handler Permission
  ph.Permission? _mapToPermissionHandler(PermissionType type) {
    switch (type) {
      case PermissionType.camera:
        return ph.Permission.camera;
      case PermissionType.microphone:
        return ph.Permission.microphone;
      case PermissionType.storage:
        if (kIsWeb) return null;
        return _isAndroid ? ph.Permission.storage : ph.Permission.photos;
      case PermissionType.notification:
        return ph.Permission.notification;
      case PermissionType.contacts:
        if (kIsWeb) return null;
        return ph.Permission.contacts;
      case PermissionType.location:
        return ph.Permission.location;
      case PermissionType.phone:
        if (kIsWeb) return null;
        return ph.Permission.phone;
      case PermissionType.calendar:
        if (kIsWeb) return null;
        return ph.Permission.calendarFullAccess;
      case PermissionType.sms:
        if (kIsWeb) return null;
        return ph.Permission.sms;
      case PermissionType.biometric:
        return null; // Handled separately
      case PermissionType.bluetooth:
        if (kIsWeb) return null;
        return ph.Permission.bluetooth;
    }
  }

  /// Map từ permission_handler PermissionStatus sang domain PermissionStatus
  PermissionStatus _mapFromPermissionHandler(ph.PermissionStatus status) {
    switch (status) {
      case ph.PermissionStatus.granted:
        return PermissionStatus.granted;
      case ph.PermissionStatus.denied:
        return PermissionStatus.denied;
      case ph.PermissionStatus.permanentlyDenied:
        return PermissionStatus.permanentlyDenied;
      case ph.PermissionStatus.restricted:
        return PermissionStatus.restricted;
      case ph.PermissionStatus.limited:
        return PermissionStatus.limited;
      case ph.PermissionStatus.provisional:
        return PermissionStatus.limited;
    }
  }

  /// Kiểm tra Android permission support
  bool _isAndroidPermissionSupported(PermissionType type) {
    switch (type) {
      case PermissionType.camera:
      case PermissionType.microphone:
      case PermissionType.storage:
      case PermissionType.notification:
      case PermissionType.contacts:
      case PermissionType.location:
      case PermissionType.phone:
      case PermissionType.calendar:
      case PermissionType.sms:
      case PermissionType.bluetooth:
        return true;
      case PermissionType.biometric:
        return true; // Handled by local_auth
    }
  }

  /// Kiểm tra iOS permission support
  bool _isIOSPermissionSupported(PermissionType type) {
    switch (type) {
      case PermissionType.camera:
      case PermissionType.microphone:
      case PermissionType.storage: // Photos on iOS
      case PermissionType.notification:
      case PermissionType.contacts:
      case PermissionType.location:
      case PermissionType.calendar:
      case PermissionType.biometric:
        return true;
      case PermissionType.phone:
      case PermissionType.sms:
      case PermissionType.bluetooth:
        return false; // Not available or restricted on iOS
    }
  }

  /// Lấy Android permission name
  String _getAndroidPermissionName(PermissionType type) {
    switch (type) {
      case PermissionType.camera:
        return 'android.permission.CAMERA';
      case PermissionType.microphone:
        return 'android.permission.RECORD_AUDIO';
      case PermissionType.storage:
        return 'android.permission.READ_EXTERNAL_STORAGE';
      case PermissionType.notification:
        return 'android.permission.POST_NOTIFICATIONS';
      case PermissionType.contacts:
        return 'android.permission.READ_CONTACTS';
      case PermissionType.location:
        return 'android.permission.ACCESS_FINE_LOCATION';
      case PermissionType.phone:
        return 'android.permission.READ_PHONE_STATE';
      case PermissionType.calendar:
        return 'android.permission.READ_CALENDAR';
      case PermissionType.sms:
        return 'android.permission.READ_SMS';
      case PermissionType.bluetooth:
        return 'android.permission.BLUETOOTH';
      case PermissionType.biometric:
        return 'android.permission.USE_BIOMETRIC';
    }
  }

  /// Lấy iOS permission name
  String _getIOSPermissionName(PermissionType type) {
    switch (type) {
      case PermissionType.camera:
        return 'NSCameraUsageDescription';
      case PermissionType.microphone:
        return 'NSMicrophoneUsageDescription';
      case PermissionType.storage:
        return 'NSPhotoLibraryUsageDescription';
      case PermissionType.notification:
        return 'Notifications';
      case PermissionType.contacts:
        return 'NSContactsUsageDescription';
      case PermissionType.location:
        return 'NSLocationWhenInUseUsageDescription';
      case PermissionType.calendar:
        return 'NSCalendarsUsageDescription';
      case PermissionType.biometric:
        return 'NSFaceIDUsageDescription';
      default:
        return type.name;
    }
  }
}
