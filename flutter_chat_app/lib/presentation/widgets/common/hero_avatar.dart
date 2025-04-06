import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:get_it/get_it.dart';
import 'package:flutter_chat_app/core/services/animation_service.dart';

/// Widget hiển thị hình đại diện với Hero animation
class HeroAvatar extends StatelessWidget {
  /// ID của chat/user, dùng làm tag cho Hero
  final String id;
  
  /// URL của hình ảnh
  final String? imageUrl;
  
  /// Tên hiển thị khi không có hình ảnh
  final String? displayName;
  
  /// Kích thước avatar
  final double size;
  
  /// Có viền hay không
  final bool hasBorder;
  
  /// Màu viền
  final Color? borderColor;
  
  /// Độ dày viền
  final double borderWidth;

  /// Constructor
  const HeroAvatar({
    Key? key,
    required this.id,
    this.imageUrl,
    this.displayName,
    this.size = 40.0,
    this.hasBorder = true,
    this.borderColor,
    this.borderWidth = 2.0,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    // Lấy cấu hình animation từ service
    final AnimationService animationService = GetIt.I<AnimationService>();
    final filterQuality = animationService.config.imageFilterQuality;
    
    // Widget hiển thị khi không có ảnh
    Widget placeholderWidget() {
      final firstLetter = (displayName?.isNotEmpty == true) 
          ? displayName!.substring(0, 1).toUpperCase() 
          : '?';
          
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
          shape: BoxShape.circle,
          border: hasBorder ? Border.all(
            color: borderColor ?? Theme.of(context).colorScheme.primary,
            width: borderWidth,
          ) : null,
        ),
        child: Center(
          child: Text(
            firstLetter,
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
              fontSize: size * 0.4,
            ),
          ),
        ),
      );
    }
    
    // Widget hiển thị ảnh
    Widget avatarWidget() {
      if (imageUrl == null || imageUrl!.isEmpty) {
        return placeholderWidget();
      }
      
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: hasBorder ? Border.all(
            color: borderColor ?? Theme.of(context).colorScheme.primary,
            width: borderWidth,
          ) : null,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(size / 2),
          child: CachedNetworkImage(
            imageUrl: imageUrl!,
            fit: BoxFit.cover,
            filterQuality: filterQuality,
            placeholder: (context, url) => Container(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              child: Center(
                child: SizedBox(
                  width: size * 0.5,
                  height: size * 0.5,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.0,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Theme.of(context).colorScheme.primary.withOpacity(0.5),
                    ),
                  ),
                ),
              ),
            ),
            errorWidget: (context, url, error) => placeholderWidget(),
          ),
        ),
      );
    }
    
    // Tạo Hero tag duy nhất
    final heroTag = 'avatar-${id}';
    
    // Kiểm tra nếu thiết bị có hỗ trợ Hero animation không
    if (animationService.config.useHeroAnimations) {
      return Hero(
        tag: heroTag,
        child: avatarWidget(),
      );
    } else {
      // Trả về widget thông thường nếu không dùng Hero
      return avatarWidget();
    }
  }
} 