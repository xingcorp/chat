/// **PERMISSION CARD WIDGET - ENTERPRISE UI COMPONENT**
///
/// Material Design 3 compliant permission card với enterprise UX standards
/// - Accessibility support với semantic labels
/// - Animation states cho user feedback
/// - Vietnamese localization
/// - WhatsApp/Telegram-level polish
///
/// **Architecture:** Clean Architecture + Material Design 3 + Enterprise Standards

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:flutter_chat_app/core/constants/app_icons.dart';
import 'package:flutter_chat_app/core/theme/app_colors.dart';
import 'package:flutter_chat_app/core/theme/app_text_styles.dart';
import 'package:flutter_chat_app/core/utils/app_localizations.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/media/app_icon.dart';
import 'package:flutter_chat_app/shared/domain/entities/permission_entity.dart';

/// **Enterprise Permission Card Widget**
/// 
/// Displays permission information với interactive states và accessibility support
class PermissionCardWidget extends StatefulWidget {
  /// Permission type to display
  final PermissionType permissionType;
  
  /// Current permission entity (optional)
  final PermissionEntity? permission;
  
  /// Callback when card is tapped
  final VoidCallback? onTap;
  
  /// Whether the card is in loading state
  final bool isLoading;
  
  /// Whether to show detailed description
  final bool showDescription;
  
  /// Custom icon (optional)
  final String? customIcon;
  
  /// Whether the card is disabled
  final bool isDisabled;

  const PermissionCardWidget({
    super.key,
    required this.permissionType,
    this.permission,
    this.onTap,
    this.isLoading = false,
    this.showDescription = true,
    this.customIcon,
    this.isDisabled = false,
  });

  @override
  State<PermissionCardWidget> createState() => _PermissionCardWidgetState();
}

class _PermissionCardWidgetState extends State<PermissionCardWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _opacityAnimation = Tween<double>(
      begin: 1.0,
      end: 0.7,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final permissionName = localizations.getPermissionName(widget.permissionType.name);
    final permissionDescription = localizations.getPermissionDescription(widget.permissionType.name);
    
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Opacity(
            opacity: _opacityAnimation.value,
            child: _buildCard(context, permissionName, permissionDescription),
          ),
        );
      },
    );
  }

  Widget _buildCard(BuildContext context, String permissionName, String permissionDescription) {
    final isGranted = widget.permission?.status == PermissionStatus.granted;
    final isDenied = widget.permission?.status == PermissionStatus.denied;
    final isPermanentlyDenied = widget.permission?.status == PermissionStatus.permanentlyDenied;
    
    return Card(
      elevation: 2,
      shadowColor: AppColors.shadow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.r),
        side: BorderSide(
          color: _getBorderColor(isGranted, isDenied, isPermanentlyDenied),
          width: 1.5,
        ),
      ),
      child: InkWell(
        onTap: widget.isDisabled || widget.isLoading ? null : () {
          _handleTap();
          widget.onTap?.call();
        },
        onTapDown: widget.isDisabled || widget.isLoading ? null : (_) {
          _animationController.forward();
        },
        onTapUp: widget.isDisabled || widget.isLoading ? null : (_) {
          _animationController.reverse();
        },
        onTapCancel: widget.isDisabled || widget.isLoading ? null : () {
          _animationController.reverse();
        },
        borderRadius: BorderRadius.circular(16.r),
        child: Container(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context, permissionName, isGranted, isDenied, isPermanentlyDenied),
              if (widget.showDescription) ...[
                SizedBox(height: 8.h),
                _buildDescription(context, permissionDescription),
              ],
              SizedBox(height: 12.h),
              _buildStatusRow(context, isGranted, isDenied, isPermanentlyDenied),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, String permissionName, bool isGranted, bool isDenied, bool isPermanentlyDenied) {
    return Row(
      children: [
        Container(
          width: 48.w,
          height: 48.w,
          decoration: BoxDecoration(
            color: _getIconBackgroundColor(isGranted, isDenied, isPermanentlyDenied),
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: widget.isLoading
              ? _buildLoadingIndicator()
              : AppIcon.svg(
                  widget.customIcon ?? _getPermissionIcon(widget.permissionType),
                  color: _getIconColor(isGranted, isDenied, isPermanentlyDenied),
                  size: 24.sp,
                ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                permissionName,
                style: AppTextStyles.titleMedium.copyWith(
                  color: widget.isDisabled ? AppColors.textSecondary : AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 2.h),
              Text(
                _getPriorityText(widget.permissionType),
                style: AppTextStyles.labelSmall.copyWith(
                  color: _getPriorityColor(widget.permissionType),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        if (isGranted)
          AppIcon.svg(
            AppIcons.checkCircle,
            color: AppColors.success,
            size: 20.sp,
          )
        else if (isPermanentlyDenied)
          AppIcon.svg(
            AppIcons.blocked,
            color: AppColors.error,
            size: 20.sp,
          )
        else if (isDenied)
          AppIcon.svg(
            AppIcons.statusConflict,
            color: AppColors.warning,
            size: 20.sp,
          ),
      ],
    );
  }

  Widget _buildDescription(BuildContext context, String description) {
    return Text(
      description,
      style: AppTextStyles.bodySmall.copyWith(
        color: widget.isDisabled ? AppColors.textSecondary : AppColors.textSecondary,
        height: 1.4,
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildStatusRow(BuildContext context, bool isGranted, bool isDenied, bool isPermanentlyDenied) {
    final localizations = AppLocalizations.of(context);
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            _getStatusText(localizations, isGranted, isDenied, isPermanentlyDenied),
            style: AppTextStyles.labelMedium.copyWith(
              color: _getStatusColor(isGranted, isDenied, isPermanentlyDenied),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        if (!isGranted && !widget.isDisabled && !widget.isLoading)
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Text(
              localizations.allow,
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildLoadingIndicator() {
    return Center(
      child: SizedBox(
        width: 20.w,
        height: 20.w,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
        ),
      ),
    );
  }

  // Helper methods
  void _handleTap() {
    // Add haptic feedback
    // HapticFeedback.lightImpact();
  }

  Color _getBorderColor(bool isGranted, bool isDenied, bool isPermanentlyDenied) {
    if (isGranted) return AppColors.success.withOpacity(0.3);
    if (isPermanentlyDenied) return AppColors.error.withOpacity(0.3);
    if (isDenied) return AppColors.warning.withOpacity(0.3);
    return AppColors.outline;
  }

  Color _getIconBackgroundColor(bool isGranted, bool isDenied, bool isPermanentlyDenied) {
    if (isGranted) return AppColors.success.withOpacity(0.1);
    if (isPermanentlyDenied) return AppColors.error.withOpacity(0.1);
    if (isDenied) return AppColors.warning.withOpacity(0.1);
    return AppColors.surfaceVariant;
  }

  Color _getIconColor(bool isGranted, bool isDenied, bool isPermanentlyDenied) {
    if (isGranted) return AppColors.success;
    if (isPermanentlyDenied) return AppColors.error;
    if (isDenied) return AppColors.warning;
    return AppColors.primary;
  }

  Color _getStatusColor(bool isGranted, bool isDenied, bool isPermanentlyDenied) {
    if (isGranted) return AppColors.success;
    if (isPermanentlyDenied) return AppColors.error;
    if (isDenied) return AppColors.warning;
    return AppColors.textSecondary;
  }

  String _getStatusText(AppLocalizations localizations, bool isGranted, bool isDenied, bool isPermanentlyDenied) {
    if (isGranted) return localizations.successPermissionGranted;
    if (isPermanentlyDenied) return localizations.errorPermissionPermanentlyDenied;
    if (isDenied) return localizations.errorPermissionDenied;
    return 'Chưa được cấp';
  }

  String _getPriorityText(PermissionType type) {
    final priority = _getPermissionPriority(type);
    switch (priority) {
      case PermissionPriority.critical:
        return 'Quan trọng';
      case PermissionPriority.important:
        return 'Cần thiết';
      case PermissionPriority.optional:
        return 'Tùy chọn';
    }
  }

  Color _getPriorityColor(PermissionType type) {
    final priority = _getPermissionPriority(type);
    switch (priority) {
      case PermissionPriority.critical:
        return AppColors.error;
      case PermissionPriority.important:
        return AppColors.warning;
      case PermissionPriority.optional:
        return AppColors.info;
    }
  }

  PermissionPriority _getPermissionPriority(PermissionType type) {
    switch (type) {
      case PermissionType.notification:
      case PermissionType.camera:
      case PermissionType.microphone:
      case PermissionType.storage:
        return PermissionPriority.critical;
      case PermissionType.contacts:
      case PermissionType.location:
      case PermissionType.phone:
        return PermissionPriority.important;
      default:
        return PermissionPriority.optional;
    }
  }

  String _getPermissionIcon(PermissionType type) {
    switch (type) {
      case PermissionType.camera:
        return AppIcons.cameraAlt;
      case PermissionType.microphone:
        return AppIcons.mic;
      case PermissionType.storage:
        return AppIcons.storage;
      case PermissionType.notification:
        return AppIcons.notifications;
      case PermissionType.contacts:
        return AppIcons.navContacts;
      case PermissionType.location:
        return AppIcons.location;
      case PermissionType.phone:
        return AppIcons.phone;
      case PermissionType.calendar:
        return AppIcons.calendar;
      case PermissionType.sms:
        return AppIcons.chatText;
      case PermissionType.biometric:
        return AppIcons.fingerprint;
      case PermissionType.bluetooth:
        return AppIcons.bluetooth;
    }
  }
}
