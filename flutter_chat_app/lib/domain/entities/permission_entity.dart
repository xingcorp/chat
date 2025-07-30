// Domain Entity: Permission
// Định nghĩa core business logic cho permissions trong messaging app
// Tuân thủ Clean Architecture principles

import 'package:equatable/equatable.dart';

/// Enum định nghĩa các loại permission cần thiết cho messaging app
/// Phân loại theo mức độ quan trọng và use case
enum PermissionType {
  // CRITICAL - Core functionality
  camera,           // Chụp ảnh, quay video
  microphone,       // Ghi âm voice message
  storage,          // Lưu trữ media và files
  notification,     // Push notifications
  
  // IMPORTANT - Enhanced features  
  contacts,         // Đồng bộ danh bạ
  location,         // Chia sẻ vị trí
  phone,           // Tích hợp cuộc gọi
  
  // OPTIONAL - Advanced features
  calendar,         // Tích hợp lịch
  sms,             // Backup/restore qua SMS
  biometric,       // Bảo mật sinh trắc học
  bluetooth,       // Kết nối thiết bị
}

/// Trạng thái permission theo platform standards
enum PermissionStatus {
  granted,          // Đã cấp quyền
  denied,           // Từ chối
  permanentlyDenied, // Từ chối vĩnh viễn (cần vào Settings)
  restricted,       // Bị hạn chế (iOS parental controls)
  limited,          // Quyền hạn chế (iOS 14+)
  unknown,          // Chưa xác định
}

/// Mức độ ưu tiên của permission request
enum PermissionPriority {
  critical,    // Bắt buộc cho core functionality
  important,   // Cần thiết cho UX tốt
  optional,    // Tính năng bổ sung
}

/// Timing strategy cho permission request
enum PermissionRequestTiming {
  onAppLaunch,     // Khi khởi động app
  onFeatureUse,    // Khi sử dụng tính năng
  onUserInitiated, // Khi user chủ động
  progressive,     // Dần dần theo flow
}

/// Entity đại diện cho một permission request
class PermissionEntity extends Equatable {
  const PermissionEntity({
    required this.type,
    required this.status,
    required this.priority,
    required this.timing,
    required this.title,
    required this.description,
    required this.rationale,
    this.isRequired = false,
    this.canDefer = true,
    this.requestCount = 0,
    this.lastRequestTime,
    this.grantedTime,
  });

  /// Loại permission
  final PermissionType type;
  
  /// Trạng thái hiện tại
  final PermissionStatus status;
  
  /// Mức độ ưu tiên
  final PermissionPriority priority;
  
  /// Thời điểm request
  final PermissionRequestTiming timing;
  
  /// Tiêu đề hiển thị cho user (localized)
  final String title;
  
  /// Mô tả chi tiết (localized)
  final String description;
  
  /// Lý do cần permission (localized)
  final String rationale;
  
  /// Có bắt buộc không
  final bool isRequired;
  
  /// Có thể hoãn request không
  final bool canDefer;
  
  /// Số lần đã request
  final int requestCount;
  
  /// Thời gian request cuối
  final DateTime? lastRequestTime;
  
  /// Thời gian được cấp quyền
  final DateTime? grantedTime;

  /// Kiểm tra permission đã được cấp
  bool get isGranted => status == PermissionStatus.granted;
  
  /// Kiểm tra permission bị từ chối vĩnh viễn
  bool get isPermanentlyDenied => status == PermissionStatus.permanentlyDenied;
  
  /// Kiểm tra có thể request lại không
  bool get canRequest => 
      status != PermissionStatus.granted && 
      status != PermissionStatus.permanentlyDenied &&
      status != PermissionStatus.restricted;
  
  /// Kiểm tra có nên hiển thị rationale không
  bool get shouldShowRationale => 
      requestCount > 0 && 
      status == PermissionStatus.denied &&
      canRequest;

  /// Copy với các thay đổi
  PermissionEntity copyWith({
    PermissionType? type,
    PermissionStatus? status,
    PermissionPriority? priority,
    PermissionRequestTiming? timing,
    String? title,
    String? description,
    String? rationale,
    bool? isRequired,
    bool? canDefer,
    int? requestCount,
    DateTime? lastRequestTime,
    DateTime? grantedTime,
  }) {
    return PermissionEntity(
      type: type ?? this.type,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      timing: timing ?? this.timing,
      title: title ?? this.title,
      description: description ?? this.description,
      rationale: rationale ?? this.rationale,
      isRequired: isRequired ?? this.isRequired,
      canDefer: canDefer ?? this.canDefer,
      requestCount: requestCount ?? this.requestCount,
      lastRequestTime: lastRequestTime ?? this.lastRequestTime,
      grantedTime: grantedTime ?? this.grantedTime,
    );
  }

  @override
  List<Object?> get props => [
        type,
        status,
        priority,
        timing,
        title,
        description,
        rationale,
        isRequired,
        canDefer,
        requestCount,
        lastRequestTime,
        grantedTime,
      ];
}

/// Kết quả của permission request batch
class PermissionBatchResult extends Equatable {
  const PermissionBatchResult({
    required this.results,
    required this.allGranted,
    required this.criticalGranted,
    required this.deniedPermissions,
    required this.permanentlyDeniedPermissions,
  });

  /// Kết quả từng permission
  final Map<PermissionType, PermissionEntity> results;
  
  /// Tất cả permissions đã được cấp
  final bool allGranted;
  
  /// Các permissions critical đã được cấp
  final bool criticalGranted;
  
  /// Danh sách permissions bị từ chối
  final List<PermissionType> deniedPermissions;
  
  /// Danh sách permissions bị từ chối vĩnh viễn
  final List<PermissionType> permanentlyDeniedPermissions;

  @override
  List<Object?> get props => [
        results,
        allGranted,
        criticalGranted,
        deniedPermissions,
        permanentlyDeniedPermissions,
      ];
}
