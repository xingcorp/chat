import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:flutter_chat_app/core/services/animation_service.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/media/app_avatar.dart';

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

  /// Cờ cho phép sử dụng Hero animation
  final bool enableHero;

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
    this.enableHero = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Lấy cấu hình animation từ service
    final AnimationService animationService = GetIt.I<AnimationService>();

    final heroTag = 'avatar-$id';

    final Widget avatarWidget = AppHeroAvatar(
      id: id,
      imageUrl: imageUrl,
      displayName: displayName,
      size: _mapSizeToAvatarSize(size),
      hasBorder: hasBorder,
      borderColor: borderColor,
      borderWidth: borderWidth,
      enableHero: enableHero,
    );

    return avatarWidget;
  }

  AvatarSize _mapSizeToAvatarSize(double size) {
    if (size <= 28) return AvatarSize.small;
    if (size <= 44) return AvatarSize.medium;
    if (size <= 72) return AvatarSize.large;
    return AvatarSize.xlarge;
  }
} 

class AppHeroAvatar extends StatelessWidget {
  final String id;
  final String? imageUrl;
  final String? displayName;
  final AvatarSize size;
  final bool hasBorder;
  final bool enableHero;
  final Color? borderColor;
  final double borderWidth;

  const AppHeroAvatar({
    super.key,
    required this.id,
    this.imageUrl,
    this.displayName,
    this.size = AvatarSize.medium,
    this.hasBorder = false,
    this.borderColor,
    this.borderWidth = 2.0,
    this.enableHero = true,
  });

  @override
  Widget build(BuildContext context) {
    final AnimationService animationService = GetIt.I<AnimationService>();
    final heroTag = 'avatar-$id';
    final resolvedBorderColor = borderColor ?? Theme.of(context).colorScheme.primary;

    final Widget avatar = (imageUrl != null && imageUrl!.trim().isNotEmpty)
        ? AppAvatar.network(
            imageUrl: imageUrl!.trim(),
            size: size,
            borderColor: hasBorder ? resolvedBorderColor : null,
            borderWidth: hasBorder ? borderWidth : null,
          )
        : AppAvatar.initials(
            name: (displayName?.trim().isNotEmpty ?? false) ? displayName!.trim() : '?',
            size: size,
            borderColor: hasBorder ? resolvedBorderColor : null,
            borderWidth: hasBorder ? borderWidth : null,
          );

    if (enableHero && animationService.config.useHeroAnimations) {
      return Hero(
        tag: heroTag,
        child: avatar,
      );
    }

    return avatar;
  }
}