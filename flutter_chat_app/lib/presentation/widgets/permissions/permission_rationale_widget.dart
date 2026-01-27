/// **PERMISSION RATIONALE WIDGET - ENTERPRISE UI COMPONENT**
///
/// Material Design 3 compliant rationale dialog với enterprise UX standards
/// - Clear explanation của permission necessity
/// - Action buttons với proper hierarchy
/// - Vietnamese localization
/// - Accessibility support
///
/// **Architecture:** Clean Architecture + Material Design 3 + Enterprise Standards

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:flutter_chat_app/core/theme/app_colors.dart';
import 'package:flutter_chat_app/core/theme/app_text_styles.dart';
import 'package:flutter_chat_app/core/utils/app_localizations.dart';
import 'package:flutter_chat_app/domain/entities/permission_entity.dart';

/// **Enterprise Permission Rationale Widget**
/// 
/// Shows detailed explanation why permission is needed với clear actions
class PermissionRationaleWidget extends StatelessWidget {
  /// Permission type to explain
  final PermissionType permissionType;
  
  /// Callback when user allows permission
  final VoidCallback? onAllow;
  
  /// Callback when user denies permission
  final VoidCallback? onDeny;
  
  /// Callback when user wants to skip
  final VoidCallback? onSkip;
  
  /// Whether to show skip option
  final bool showSkipOption;
  
  /// Whether the permission is critical
  final bool isCritical;
  
  /// Custom title (optional)
  final String? customTitle;
  
  /// Custom description (optional)
  final String? customDescription;

  const PermissionRationaleWidget({
    super.key,
    required this.permissionType,
    this.onAllow,
    this.onDeny,
    this.onSkip,
    this.showSkipOption = true,
    this.isCritical = false,
    this.customTitle,
    this.customDescription,
  });

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20.r),
      ),
      elevation: 8,
      child: Container(
        padding: EdgeInsets.all(24.w),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20.r),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(context, localizations),
            SizedBox(height: 20.h),
            _buildContent(context, localizations),
            SizedBox(height: 24.h),
            _buildActions(context, localizations),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AppLocalizations localizations) {
    return Column(
      children: [
        Container(
          width: 64.w,
          height: 64.w,
          decoration: BoxDecoration(
            color: isCritical ? AppColors.error.withOpacity(0.1) : AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16.r),
          ),
          child: Icon(
            _getPermissionIcon(permissionType),
            size: 32.sp,
            color: isCritical ? AppColors.error : AppColors.primary,
          ),
        ),
        SizedBox(height: 16.h),
        Text(
          customTitle ?? localizations.dialogPermissionRequired,
          style: AppTextStyles.headlineSmall.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 8.h),
        Text(
          localizations.getPermissionName(permissionType.name),
          style: AppTextStyles.titleMedium.copyWith(
            color: isCritical ? AppColors.error : AppColors.primary,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildContent(BuildContext context, AppLocalizations localizations) {
    final description = customDescription ?? 
        localizations.getPermissionDescription(permissionType.name);
    final rationale = localizations.permissionRequiredMessage(
      localizations.getPermissionName(permissionType.name)
    );
    
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant.withOpacity(0.5),
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: AppColors.outline.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 20.sp,
                    color: AppColors.info,
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    'Tại sao cần quyền này?',
                    style: AppTextStyles.titleSmall.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12.h),
              Text(
                description,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
        if (isCritical) ...[
          SizedBox(height: 16.h),
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: AppColors.error.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8.r),
              border: Border.all(
                color: AppColors.error.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.priority_high,
                  size: 20.sp,
                  color: AppColors.error,
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    'Quyền này rất quan trọng cho hoạt động của ứng dụng',
                    style: AppTextStyles.labelMedium.copyWith(
                      color: AppColors.error,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildActions(BuildContext context, AppLocalizations localizations) {
    return Column(
      children: [
        // Primary action - Allow
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: onAllow,
            style: ElevatedButton.styleFrom(
              backgroundColor: isCritical ? AppColors.error : AppColors.primary,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: 16.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
              elevation: 2,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.check_circle_outline,
                  size: 20.sp,
                ),
                SizedBox(width: 8.w),
                Text(
                  localizations.allow,
                  style: AppTextStyles.buttonLargeStyle.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
        
        SizedBox(height: 12.h),
        
        // Secondary actions row
        Row(
          children: [
            // Deny button
            Expanded(
              child: OutlinedButton(
                onPressed: onDeny,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textSecondary,
                  side: BorderSide(
                    color: AppColors.outline,
                    width: 1.5,
                  ),
                  padding: EdgeInsets.symmetric(vertical: 12.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
                child: Text(
                  localizations.deny,
                  style: AppTextStyles.buttonMediumStyle.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            
            if (showSkipOption && !isCritical) ...[
              SizedBox(width: 12.w),
              Expanded(
                child: TextButton(
                  onPressed: onSkip,
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.textSecondary,
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                  child: Text(
                    localizations.skip,
                    style: AppTextStyles.buttonMediumStyle.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
        
        // Additional info for critical permissions
        if (isCritical) ...[
          SizedBox(height: 16.h),
          Text(
            'Từ chối quyền này có thể làm ứng dụng không hoạt động đúng cách',
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.textSecondary,
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }

  IconData _getPermissionIcon(PermissionType type) {
    switch (type) {
      case PermissionType.camera:
        return Icons.camera_alt;
      case PermissionType.microphone:
        return Icons.mic;
      case PermissionType.storage:
        return Icons.storage;
      case PermissionType.notification:
        return Icons.notifications;
      case PermissionType.contacts:
        return Icons.contacts;
      case PermissionType.location:
        return Icons.location_on;
      case PermissionType.phone:
        return Icons.phone;
      case PermissionType.calendar:
        return Icons.calendar_today;
      case PermissionType.sms:
        return Icons.sms;
      case PermissionType.biometric:
        return Icons.fingerprint;
      case PermissionType.bluetooth:
        return Icons.bluetooth;
    }
  }

  /// Static method to show rationale dialog
  static Future<PermissionRationaleResult?> show({
    required BuildContext context,
    required PermissionType permissionType,
    bool showSkipOption = true,
    bool isCritical = false,
    String? customTitle,
    String? customDescription,
  }) {
    return showDialog<PermissionRationaleResult>(
      context: context,
      barrierDismissible: false,
      builder: (context) => PermissionRationaleWidget(
        permissionType: permissionType,
        showSkipOption: showSkipOption,
        isCritical: isCritical,
        customTitle: customTitle,
        customDescription: customDescription,
        onAllow: () => Navigator.of(context).pop(PermissionRationaleResult.allow),
        onDeny: () => Navigator.of(context).pop(PermissionRationaleResult.deny),
        onSkip: () => Navigator.of(context).pop(PermissionRationaleResult.skip),
      ),
    );
  }
}

/// Result of permission rationale dialog
enum PermissionRationaleResult {
  allow,
  deny,
  skip,
}
