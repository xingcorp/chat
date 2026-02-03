// Domain UseCase: Request Permission
// Business logic cho permission requests với enterprise-grade error handling
// Tuân thủ Single Responsibility Principle

import 'package:injectable/injectable.dart';
import 'package:flutter_chat_app/core/error/failures.dart';
import 'package:flutter_chat_app/core/usecases/usecase.dart';
import 'package:flutter_chat_app/core/utils/result.dart';
import 'package:flutter_chat_app/shared/domain/entities/permission_entity.dart';
import 'package:flutter_chat_app/domain/repositories/permissions_repository.dart';

/// Parameters cho RequestPermissionUseCase
class RequestPermissionParams {
  const RequestPermissionParams({
    required this.type,
    this.showRationale = true,
    this.forceRequest = false,
    this.context,
  });

  /// Loại permission cần request
  final PermissionType type;
  
  /// Có hiển thị rationale trước khi request không
  final bool showRationale;
  
  /// Có force request ngay cả khi đã bị từ chối trước đó không
  final bool forceRequest;
  
  /// Context để hiển thị dialog (optional)
  final dynamic context;
}

/// UseCase để request permission từ user
/// Implement business logic phức tạp cho permission handling
@injectable
class RequestPermissionUseCase 
    implements UseCase<PermissionEntity, RequestPermissionParams> {
  
  const RequestPermissionUseCase(this._repository);

  final PermissionsRepository _repository;

  @override
  Future<Result<PermissionEntity>> call(
    RequestPermissionParams params,
  ) async {
    try {
      // 1. Kiểm tra permission hiện tại
      final currentPermission = await _repository.checkPermission(params.type);
      
      // 2. Nếu đã được cấp, return ngay
      if (currentPermission.isGranted) {
        return Result.success(currentPermission);
      }
      
      // 3. Kiểm tra có thể request không
      if (!params.forceRequest && !currentPermission.canRequest) {
        return Result.failure(PermissionFailure(
          type: params.type,
          reason: _getFailureReason(currentPermission.status),
          message: _getFailureMessage(params.type, currentPermission.status),
        ));
      }
      
      // 4. Kiểm tra platform support
      final isSupported = await _repository.isPermissionSupported(params.type);
      if (!isSupported) {
        return Result.failure(PermissionFailure(
          type: params.type,
          reason: PermissionFailureReason.notSupported,
          message: 'Permission ${params.type.name} không được hỗ trợ trên platform này',
        ));
      }
      
      // 5. Kiểm tra enterprise policy restrictions
      final isRestricted = await _repository.isPermissionRestrictedByPolicy(params.type);
      if (isRestricted) {
        return Result.failure(PermissionFailure(
          type: params.type,
          reason: PermissionFailureReason.restrictedByPolicy,
          message: 'Permission ${params.type.name} bị hạn chế bởi enterprise policy',
        ));
      }
      
      // 6. Hiển thị rationale nếu cần
      if (params.showRationale && currentPermission.shouldShowRationale) {
        final shouldContinue = await _showRationale(params.type, params.context);
        if (!shouldContinue) {
          return Result.failure(PermissionFailure(
            type: params.type,
            reason: PermissionFailureReason.userCancelled,
            message: 'User đã hủy permission request',
          ));
        }
      }
      
      // 7. Request permission
      final result = await _repository.requestPermission(
        params.type,
        showRationale: false, // Đã hiển thị ở bước 6
      );
      
      // 8. Lưu trạng thái mới
      await _repository.savePermissionState(result);
      
      // 9. Xử lý kết quả
      if (result.isGranted) {
        return Result.success(result);
      } else {
        return Result.failure(PermissionFailure(
          type: params.type,
          reason: _getFailureReason(result.status),
          message: _getFailureMessage(params.type, result.status),
        ));
      }
      
    } catch (e) {
      return Result.failure(PermissionFailure(
        type: params.type,
        reason: PermissionFailureReason.unknown,
        message: 'Lỗi không xác định khi request permission: $e',
      ));
    }
  }

  /// Hiển thị rationale dialog cho user
  Future<bool> _showRationale(PermissionType type, dynamic context) async {
    // TODO: Implement rationale dialog
    // Tạm thời return true, sẽ implement UI sau
    return true;
  }

  /// Lấy lý do failure từ permission status
  PermissionFailureReason _getFailureReason(PermissionStatus status) {
    switch (status) {
      case PermissionStatus.denied:
        return PermissionFailureReason.denied;
      case PermissionStatus.permanentlyDenied:
        return PermissionFailureReason.permanentlyDenied;
      case PermissionStatus.restricted:
        return PermissionFailureReason.restricted;
      case PermissionStatus.limited:
        return PermissionFailureReason.limited;
      default:
        return PermissionFailureReason.unknown;
    }
  }

  /// Lấy thông báo lỗi user-friendly
  String _getFailureMessage(PermissionType type, PermissionStatus status) {
    final permissionName = _getPermissionDisplayName(type);
    
    switch (status) {
      case PermissionStatus.denied:
        return 'Quyền $permissionName bị từ chối. Vui lòng thử lại.';
      case PermissionStatus.permanentlyDenied:
        return 'Quyền $permissionName bị từ chối vĩnh viễn. Vui lòng vào Cài đặt để cấp quyền.';
      case PermissionStatus.restricted:
        return 'Quyền $permissionName bị hạn chế bởi hệ thống.';
      case PermissionStatus.limited:
        return 'Quyền $permissionName chỉ được cấp một phần.';
      default:
        return 'Không thể cấp quyền $permissionName.';
    }
  }

  /// Lấy tên hiển thị của permission
  String _getPermissionDisplayName(PermissionType type) {
    switch (type) {
      case PermissionType.camera:
        return 'Camera';
      case PermissionType.microphone:
        return 'Microphone';
      case PermissionType.storage:
        return 'Lưu trữ';
      case PermissionType.notification:
        return 'Thông báo';
      case PermissionType.contacts:
        return 'Danh bạ';
      case PermissionType.location:
        return 'Vị trí';
      case PermissionType.phone:
        return 'Điện thoại';
      case PermissionType.calendar:
        return 'Lịch';
      case PermissionType.sms:
        return 'SMS';
      case PermissionType.biometric:
        return 'Sinh trắc học';
      case PermissionType.bluetooth:
        return 'Bluetooth';
    }
  }
}

/// Custom failure class cho permission errors
class PermissionFailure extends Failure {
  const PermissionFailure({
    required this.type,
    required this.reason,
    required super.message,
  });

  final PermissionType type;
  final PermissionFailureReason reason;

  @override
  String get userMessage => 'Lỗi quyền ${type.name}: $message';

  @override
  String get category => 'permission';

  @override
  bool get isRecoverable => reason != PermissionFailureReason.notSupported;

  @override
  List<Object?> get props => [type, reason, message];
}

/// Enum các lý do permission failure
enum PermissionFailureReason {
  denied,
  permanentlyDenied,
  restricted,
  limited,
  notSupported,
  restrictedByPolicy,
  userCancelled,
  unknown,
}
