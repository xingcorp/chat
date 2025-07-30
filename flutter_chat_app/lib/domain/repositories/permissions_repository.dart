// Domain Repository Interface: Permissions
// Định nghĩa contract cho permissions management
// Tuân thủ Dependency Inversion Principle

import '../entities/permission_entity.dart';

/// Repository interface cho permissions management
/// Được implement bởi data layer
abstract class PermissionsRepository {
  /// Kiểm tra trạng thái của một permission
  /// 
  /// [type] - Loại permission cần kiểm tra
  /// Returns [PermissionEntity] với trạng thái hiện tại
  Future<PermissionEntity> checkPermission(PermissionType type);

  /// Kiểm tra trạng thái của nhiều permissions
  /// 
  /// [types] - Danh sách permissions cần kiểm tra
  /// Returns Map với trạng thái từng permission
  Future<Map<PermissionType, PermissionEntity>> checkPermissions(
    List<PermissionType> types,
  );

  /// Request một permission từ user
  /// 
  /// [type] - Loại permission cần request
  /// [showRationale] - Có hiển thị rationale trước khi request không
  /// Returns [PermissionEntity] với trạng thái sau khi request
  Future<PermissionEntity> requestPermission(
    PermissionType type, {
    bool showRationale = false,
  });

  /// Request nhiều permissions cùng lúc
  /// 
  /// [types] - Danh sách permissions cần request
  /// [showRationale] - Có hiển thị rationale không
  /// Returns [PermissionBatchResult] với kết quả tổng hợp
  Future<PermissionBatchResult> requestPermissions(
    List<PermissionType> types, {
    bool showRationale = false,
  });

  /// Mở Settings để user cấp permission thủ công
  /// 
  /// [type] - Permission cần cấp (optional, mở app settings nếu null)
  /// Returns true nếu mở Settings thành công
  Future<bool> openAppSettings({PermissionType? type});

  /// Kiểm tra permission có thể request không
  /// 
  /// [type] - Loại permission
  /// Returns true nếu có thể request
  Future<bool> canRequestPermission(PermissionType type);

  /// Kiểm tra có nên hiển thị rationale không
  /// 
  /// [type] - Loại permission
  /// Returns true nếu nên hiển thị rationale
  Future<bool> shouldShowRequestRationale(PermissionType type);

  /// Lưu trạng thái permission vào local storage
  /// 
  /// [permission] - Permission entity cần lưu
  Future<void> savePermissionState(PermissionEntity permission);

  /// Lấy lịch sử permission requests
  /// 
  /// [type] - Loại permission (optional, lấy tất cả nếu null)
  /// Returns danh sách lịch sử requests
  Future<List<PermissionEntity>> getPermissionHistory({
    PermissionType? type,
  });

  /// Xóa lịch sử permission (cho testing hoặc reset)
  /// 
  /// [type] - Loại permission (optional, xóa tất cả nếu null)
  Future<void> clearPermissionHistory({PermissionType? type});

  /// Stream theo dõi thay đổi permission status
  /// 
  /// [type] - Loại permission cần theo dõi
  /// Returns Stream với trạng thái permission
  Stream<PermissionEntity> watchPermission(PermissionType type);

  /// Stream theo dõi thay đổi nhiều permissions
  /// 
  /// [types] - Danh sách permissions cần theo dõi
  /// Returns Stream với Map trạng thái permissions
  Stream<Map<PermissionType, PermissionEntity>> watchPermissions(
    List<PermissionType> types,
  );

  /// Kiểm tra platform có hỗ trợ permission không
  /// 
  /// [type] - Loại permission
  /// Returns true nếu platform hỗ trợ
  Future<bool> isPermissionSupported(PermissionType type);

  /// Lấy thông tin chi tiết về permission requirements
  /// 
  /// [type] - Loại permission
  /// Returns thông tin chi tiết về permission
  Future<PermissionEntity> getPermissionInfo(PermissionType type);

  /// Kiểm tra app có đang chạy trên emulator không
  /// (Một số permissions có thể không hoạt động trên emulator)
  /// 
  /// Returns true nếu đang chạy trên emulator
  Future<bool> isRunningOnEmulator();

  /// Lấy platform-specific permission name
  /// 
  /// [type] - Loại permission
  /// Returns tên permission theo platform
  String getPlatformPermissionName(PermissionType type);

  /// Kiểm tra permission có bị restricted bởi enterprise policy không
  /// 
  /// [type] - Loại permission
  /// Returns true nếu bị restricted
  Future<bool> isPermissionRestrictedByPolicy(PermissionType type);
}
