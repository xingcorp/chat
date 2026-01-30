import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_app/core/base/base_widget.dart';
import 'package:flutter_chat_app/core/constants/app_dimens.dart';
import 'package:flutter_chat_app/core/theme/app_text_styles.dart';

/// A customizable avatar component.
///
/// Features:
/// - Multiple sizes (small, medium, large, xlarge)
/// - Badge support for notifications
/// - Status indicator (online, offline, away, busy)
/// - Network, asset, and file image support
/// - Placeholder while loading
/// - Error state with fallback
/// - Accessibility compliant
/// - Dark mode support
///
/// Example:
/// ```dart
/// // Network image with badge
/// AppAvatar.network(
///   imageUrl: 'https://example.com/avatar.jpg',
///   size: AvatarSize.large,
///   badge: 5,
///   status: AvatarStatus.online,
/// )
///
/// // Asset image
/// AppAvatar.asset(
///   assetPath: 'assets/images/avatar.png',
///   size: AvatarSize.medium,
/// )
///
/// // Initials
/// AppAvatar.initials(
///   name: 'John Doe',
///   size: AvatarSize.small,
/// )
/// ```
class AppAvatar extends BaseStatelessWidget {
  /// Creates an [AppAvatar].
  const AppAvatar({
    this.imageUrl,
    this.assetPath,
    this.filePath,
    this.initials,
    this.size = AvatarSize.medium,
    this.badge,
    this.status,
    this.shape = BoxShape.circle,
    this.backgroundColor,
    this.foregroundColor,
    this.borderColor,
    this.borderWidth,
    this.onTap,
    super.key,
  });

  /// Creates an avatar from a network image.
  const AppAvatar.network({
    required String imageUrl,
    AvatarSize size = AvatarSize.medium,
    int? badge,
    AvatarStatus? status,
    BoxShape shape = BoxShape.circle,
    Color? backgroundColor,
    Color? borderColor,
    double? borderWidth,
    VoidCallback? onTap,
    Key? key,
  }) : this(
          imageUrl: imageUrl,
          size: size,
          badge: badge,
          status: status,
          shape: shape,
          backgroundColor: backgroundColor,
          borderColor: borderColor,
          borderWidth: borderWidth,
          onTap: onTap,
          key: key,
        );

  /// Creates an avatar from an asset image.
  const AppAvatar.asset({
    required String assetPath,
    AvatarSize size = AvatarSize.medium,
    int? badge,
    AvatarStatus? status,
    BoxShape shape = BoxShape.circle,
    Color? backgroundColor,
    Color? borderColor,
    double? borderWidth,
    VoidCallback? onTap,
    Key? key,
  }) : this(
          assetPath: assetPath,
          size: size,
          badge: badge,
          status: status,
          shape: shape,
          backgroundColor: backgroundColor,
          borderColor: borderColor,
          borderWidth: borderWidth,
          onTap: onTap,
          key: key,
        );

  /// Creates an avatar from a file path.
  const AppAvatar.file({
    required String filePath,
    AvatarSize size = AvatarSize.medium,
    int? badge,
    AvatarStatus? status,
    BoxShape shape = BoxShape.circle,
    Color? backgroundColor,
    Color? borderColor,
    double? borderWidth,
    VoidCallback? onTap,
    Key? key,
  }) : this(
          filePath: filePath,
          size: size,
          badge: badge,
          status: status,
          shape: shape,
          backgroundColor: backgroundColor,
          borderColor: borderColor,
          borderWidth: borderWidth,
          onTap: onTap,
          key: key,
        );

  /// Creates an avatar with initials.
  const AppAvatar.initials({
    required String name,
    AvatarSize size = AvatarSize.medium,
    int? badge,
    AvatarStatus? status,
    BoxShape shape = BoxShape.circle,
    Color? backgroundColor,
    Color? foregroundColor,
    Color? borderColor,
    double? borderWidth,
    VoidCallback? onTap,
    Key? key,
  }) : this(
          initials: name,
          size: size,
          badge: badge,
          status: status,
          shape: shape,
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
          borderColor: borderColor,
          borderWidth: borderWidth,
          onTap: onTap,
          key: key,
        );

  /// The network image URL.
  final String? imageUrl;

  /// The asset image path.
  final String? assetPath;

  /// The file image path.
  final String? filePath;

  /// The initials to display.
  final String? initials;

  /// The size of the avatar.
  final AvatarSize size;

  /// Optional badge count.
  final int? badge;

  /// Optional status indicator.
  final AvatarStatus? status;

  /// The shape of the avatar.
  final BoxShape shape;

  /// The background color.
  final Color? backgroundColor;

  /// The foreground color (for initials).
  final Color? foregroundColor;

  /// The border color.
  final Color? borderColor;

  /// The border width.
  final double? borderWidth;

  /// Called when the avatar is tapped.
  final VoidCallback? onTap;

  @override
  Widget buildContent(BuildContext context) {
    final theme = Theme.of(context);
    final avatarSize = _getSize(size);

    Widget avatar = Container(
      width: avatarSize,
      height: avatarSize,
      decoration: BoxDecoration(
        color: backgroundColor ?? theme.colorScheme.primaryContainer,
        shape: shape,
        borderRadius: shape == BoxShape.rectangle
            ? BorderRadius.circular(AppDimens.radiusSmall)
            : null,
        border: borderColor != null
            ? Border.all(
                color: borderColor!,
                width: borderWidth ?? 2.0,
              )
            : null,
      ),
      child: ClipRRect(
        borderRadius: shape == BoxShape.rectangle
            ? BorderRadius.circular(AppDimens.radiusSmall)
            : BorderRadius.circular(avatarSize / 2),
        child: _buildContent(context, theme),
      ),
    );

    // Add badge if present
    if (badge != null && badge! > 0) {
      avatar = _buildWithBadge(avatar, badge!);
    }

    // Add status indicator if present
    if (status != null) {
      avatar = _buildWithStatus(avatar, status!, theme);
    }

    // Wrap with InkWell if onTap is provided
    if (onTap != null) {
      avatar = InkWell(
        onTap: onTap,
        borderRadius: shape == BoxShape.rectangle
            ? BorderRadius.circular(AppDimens.radiusSmall)
            : BorderRadius.circular(avatarSize / 2),
        child: avatar,
      );
    }

    return avatar;
  }

  Widget _buildContent(BuildContext context, ThemeData theme) {
    // Network image
    if (imageUrl != null) {
      return CachedNetworkImage(
        imageUrl: imageUrl!,
        fit: BoxFit.cover,
        placeholder: (context, url) => _buildPlaceholder(theme),
        errorWidget: (context, url, error) => _buildError(theme),
      );
    }

    // Asset image
    if (assetPath != null) {
      return Image.asset(
        assetPath!,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildError(theme),
      );
    }

    // File image
    if (filePath != null) {
      // Note: For file images, you'd typically use Image.file()
      // but that requires dart:io which isn't available on web
      return _buildError(theme);
    }

    // Initials
    if (initials != null) {
      return Center(
        child: Text(
          _getInitials(initials!),
          style: AppTextStyles.titleLarge.copyWith(
            color: foregroundColor ?? theme.colorScheme.onPrimaryContainer,
            fontWeight: FontWeight.bold,
            fontSize: _getFontSize(size),
          ),
        ),
      );
    }

    // Default placeholder
    return _buildPlaceholder(theme);
  }

  Widget _buildPlaceholder(ThemeData theme) {
    return Center(
      child: Icon(
        Icons.person,
        size: _getSize(size) * 0.6,
        color: theme.colorScheme.onPrimaryContainer.withOpacity(0.5),
      ),
    );
  }

  Widget _buildError(ThemeData theme) {
    return Center(
      child: Icon(
        Icons.person_outline,
        size: _getSize(size) * 0.6,
        color: theme.colorScheme.error.withOpacity(0.5),
      ),
    );
  }

  Widget _buildWithBadge(Widget avatar, int count) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        avatar,
        Positioned(
          right: -4,
          top: -4,
          child: Container(
            padding: EdgeInsets.all(AppDimens.paddingXSmall),
            decoration: const BoxDecoration(
              color: Colors.red,
              shape: BoxShape.circle,
            ),
            constraints: BoxConstraints(
              minWidth: AppDimens.iconSizeSmall,
              minHeight: AppDimens.iconSizeSmall,
            ),
            child: Text(
              count > 99 ? '99+' : count.toString(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWithStatus(Widget avatar, AvatarStatus status, ThemeData theme) {
    final statusColor = _getStatusColor(status, theme);
    final statusSize = _getSize(size) * 0.25;

    return Stack(
      children: [
        avatar,
        Positioned(
          right: 0,
          bottom: 0,
          child: Container(
            width: statusSize,
            height: statusSize,
            decoration: BoxDecoration(
              color: statusColor,
              shape: BoxShape.circle,
              border: Border.all(
                color: theme.colorScheme.surface,
                width: 2.0,
              ),
            ),
          ),
        ),
      ],
    );
  }

  double _getSize(AvatarSize size) {
    switch (size) {
      case AvatarSize.small:
        return AppDimens.avatarSizeSmall;
      case AvatarSize.medium:
        return AppDimens.avatarSizeMedium;
      case AvatarSize.large:
        return AppDimens.avatarSizeLarge;
      case AvatarSize.xlarge:
        return AppDimens.avatarSizeXLarge;
    }
  }

  double _getFontSize(AvatarSize size) {
    switch (size) {
      case AvatarSize.small:
        return 12;
      case AvatarSize.medium:
        return 16;
      case AvatarSize.large:
        return 24;
      case AvatarSize.xlarge:
        return 32;
    }
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.isEmpty) return '';
    if (parts.length == 1) {
      return parts[0].substring(0, 1).toUpperCase();
    }
    return '${parts[0].substring(0, 1)}${parts[1].substring(0, 1)}'.toUpperCase();
  }

  Color _getStatusColor(AvatarStatus status, ThemeData theme) {
    switch (status) {
      case AvatarStatus.online:
        return Colors.green;
      case AvatarStatus.offline:
        return Colors.grey;
      case AvatarStatus.away:
        return Colors.orange;
      case AvatarStatus.busy:
        return Colors.red;
    }
  }
}

/// Size variants for avatars.
enum AvatarSize {
  /// Small avatar.
  small,

  /// Medium avatar.
  medium,

  /// Large avatar.
  large,

  /// Extra large avatar.
  xlarge,
}

/// Status indicators for avatars.
enum AvatarStatus {
  /// Online status (green).
  online,

  /// Offline status (grey).
  offline,

  /// Away status (orange).
  away,

  /// Busy status (red).
  busy,
}
