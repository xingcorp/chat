import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_chat_app/core/base/base_widget.dart';
import 'package:flutter_chat_app/core/constants/app_constants.dart';
import 'package:flutter_chat_app/core/theme/app_colors.dart';

/// Enum trạng thái người dùng
enum UserStatus {
  online, // Đang online
  offline, // Offline
  away, // Tạm thời vắng mặt
  busy, // Đang bận
  typing, // Đang nhập
}

/// Widget hiển thị avatar người dùng
class UserAvatar extends BaseStatelessWidget {
  /// URL hình ảnh đại diện
  final String? imageUrl;
  
  /// Tên hiển thị của người dùng (dùng để tạo chữ cái đầu khi không có hình)
  final String name;
  
  /// Kích thước avatar
  final double size;
  
  /// Trạng thái người dùng
  final UserStatus? status;
  
  /// Callback khi nhấn vào avatar
  final VoidCallback? onTap;
  
  /// Hiện badge đánh dấu status hay không
  final bool showStatusBadge;
  
  /// Constructor
  const UserAvatar({
    Key? key,
    this.imageUrl,
    required this.name,
    this.size = AppConstants.kProfileImageSize,
    this.status,
    this.onTap,
    this.showStatusBadge = true,
  }) : super(key: key);

  @override
  Widget buildContent(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size.r,
        height: size.r,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _getBackgroundColor(context),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow.withOpacity(0.2),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Avatar
            ClipOval(
              child: _buildAvatarContent(context),
            ),
            
            // Status badge
            if (status != null && showStatusBadge) 
              _buildStatusBadge(),
          ],
        ),
      ),
    );
  }
  
  /// Get background color cho avatar
  Color _getBackgroundColor(BuildContext context) {
    // Dùng màu gradient từ tên người dùng nếu không có avatar
    if (imageUrl == null || imageUrl!.isEmpty) {
      // Dùng tên để tạo mã màu
      final int nameHash = name.hashCode;
      final List<Color> backgroundColors = [
        Colors.blue[300]!,
        Colors.purple[300]!,
        Colors.teal[300]!,
        Colors.deepOrange[300]!,
        Colors.indigo[300]!,
        Colors.pink[300]!,
        Colors.green[300]!,
        Colors.amber[700]!,
      ];
      return backgroundColors[nameHash % backgroundColors.length];
    }
    return Colors.transparent;
  }
  
  /// Build avatar content (image hoặc text initials)
  Widget _buildAvatarContent(BuildContext context) {
    // Nếu có URL hình ảnh, tải và hiển thị
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: imageUrl!,
        fit: BoxFit.cover,
        width: size.r,
        height: size.r,
        placeholder: (context, url) => _buildInitials(),
        errorWidget: (context, url, error) => _buildInitials(),
        fadeInDuration: const Duration(milliseconds: 300),
      );
    }
    
    // Nếu không có URL, hiển thị tên viết tắt
    return _buildInitials();
  }
  
  /// Build initials từ tên
  Widget _buildInitials() {
    // Lấy chữ cái đầu của tên và họ
    final nameInitials = _getInitials(name);
    
    return Center(
      child: Text(
        nameInitials,
        style: TextStyle(
          fontSize: size / 2.5,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }
  
  /// Get initials từ tên
  String _getInitials(String name) {
    if (name.isEmpty) return '';
    
    final parts = name.trim().split(' ');
    if (parts.length == 1) {
      return parts[0].isNotEmpty ? parts[0][0].toUpperCase() : '';
    }
    
    final first = parts.first;
    final last = parts.last;
    return '${first[0]}${last[0]}'.toUpperCase();
  }
  
  /// Build status badge
  Widget _buildStatusBadge() {
    return Positioned(
      right: 0,
      bottom: 0,
      child: Container(
        width: size / 3.5,
        height: size / 3.5,
        decoration: BoxDecoration(
          color: _getStatusColor(),
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white,
            width: 2.r,
          ),
        ),
        child: status == UserStatus.typing
            ? _buildTypingIndicator()
            : null,
      ),
    );
  }
  
  /// Get color dựa vào trạng thái
  Color _getStatusColor() {
    switch (status) {
      case UserStatus.online:
        return AppColors.success; // Use success color for online
      case UserStatus.offline:
        return AppColors.textSecondary; // Use secondary text color for offline
      case UserStatus.away:
        return Colors.amber;
      case UserStatus.busy:
        return Colors.red;
      case UserStatus.typing:
        return AppColors.primary; // Use primary color for typing
      default:
        return AppColors.textSecondary; // Use secondary text color for default
    }
  }
  
  /// Build typing indicator (3 chấm nhấp nháy)
  Widget _buildTypingIndicator() {
    return Center(
      child: FittedBox(
        child: Icon(
          Icons.keyboard,
          color: Colors.white,
          size: size / 4,
        ),
      ),
    );
  }
} 