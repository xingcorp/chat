import '../../../shared/domain/entities/permission_entity.dart';
import '../permissions_datasource.dart';

/// Web implementation for permissions.
///
/// Flutter Web does not support most native permission_handler permissions
/// (contacts/phone/sms/calendar/storage/bluetooth). We treat them as unsupported
/// and return [PermissionStatus.unknown] to avoid exceptions and UI freezes.
class WebPermissionsDataSource implements PermissionsDataSource {
  @override
  Future<PermissionStatus> checkPermission(PermissionType type) async {
    return PermissionStatus.unknown;
  }

  @override
  Future<Map<PermissionType, PermissionStatus>> checkPermissions(
    List<PermissionType> types,
  ) async {
    return {for (final type in types) type: PermissionStatus.unknown};
  }

  @override
  Future<PermissionStatus> requestPermission(PermissionType type) async {
    return PermissionStatus.unknown;
  }

  @override
  Future<Map<PermissionType, PermissionStatus>> requestPermissions(
    List<PermissionType> types,
  ) async {
    return {for (final type in types) type: PermissionStatus.unknown};
  }

  @override
  Future<bool> openAppSettings() async {
    return false;
  }

  @override
  Future<bool> canRequestPermission(PermissionType type) async {
    return false;
  }

  @override
  Future<bool> shouldShowRequestRationale(PermissionType type) async {
    return false;
  }

  @override
  Future<bool> isPermissionSupported(PermissionType type) async {
    return false;
  }

  @override
  Future<bool> isRunningOnEmulator() async {
    return false;
  }

  @override
  String getPlatformPermissionName(PermissionType type) {
    return type.name;
  }
}
