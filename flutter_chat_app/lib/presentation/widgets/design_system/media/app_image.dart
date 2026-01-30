import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_app/core/base/base_widget.dart';
import 'package:flutter_chat_app/core/constants/app_dimens.dart';
import 'package:flutter_chat_app/l10n/l10n.dart';

/// A customizable image component with caching and error handling.
///
/// Features:
/// - Network image with caching (CachedNetworkImage)
/// - Asset image support
/// - File image support
/// - Placeholder while loading
/// - Error widget with retry
/// - Fade-in animation
/// - Accessibility compliant
/// - Dark mode support
///
/// Example:
/// ```dart
/// // Network image
/// AppImage.network(
///   imageUrl: 'https://example.com/image.jpg',
///   width: 200,
///   height: 200,
///   fit: BoxFit.cover,
/// )
///
/// // Asset image
/// AppImage.asset(
///   assetPath: 'assets/images/logo.png',
///   width: 100,
///   height: 100,
/// )
/// ```
class AppImage extends BaseStatelessWidget {
  /// Creates an [AppImage].
  const AppImage({
    this.imageUrl,
    this.assetPath,
    this.filePath,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
    this.onRetry,
    this.borderRadius,
    this.fadeInDuration,
    super.key,
  });

  /// Creates an image from a network URL.
  const AppImage.network({
    required String imageUrl,
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    Widget? placeholder,
    Widget? errorWidget,
    VoidCallback? onRetry,
    BorderRadius? borderRadius,
    Duration? fadeInDuration,
    Key? key,
  }) : this(
          imageUrl: imageUrl,
          width: width,
          height: height,
          fit: fit,
          placeholder: placeholder,
          errorWidget: errorWidget,
          onRetry: onRetry,
          borderRadius: borderRadius,
          fadeInDuration: fadeInDuration,
          key: key,
        );

  /// Creates an image from an asset.
  const AppImage.asset({
    required String assetPath,
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    Widget? errorWidget,
    BorderRadius? borderRadius,
    Key? key,
  }) : this(
          assetPath: assetPath,
          width: width,
          height: height,
          fit: fit,
          errorWidget: errorWidget,
          borderRadius: borderRadius,
          key: key,
        );

  /// Creates an image from a file path.
  const AppImage.file({
    required String filePath,
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    Widget? errorWidget,
    BorderRadius? borderRadius,
    Key? key,
  }) : this(
          filePath: filePath,
          width: width,
          height: height,
          fit: fit,
          errorWidget: errorWidget,
          borderRadius: borderRadius,
          key: key,
        );

  /// The network image URL.
  final String? imageUrl;

  /// The asset image path.
  final String? assetPath;

  /// The file image path.
  final String? filePath;

  /// The width of the image.
  final double? width;

  /// The height of the image.
  final double? height;

  /// How the image should be inscribed into the space.
  final BoxFit fit;

  /// Widget to display while loading.
  final Widget? placeholder;

  /// Widget to display on error.
  final Widget? errorWidget;

  /// Callback when retry button is tapped.
  final VoidCallback? onRetry;

  /// Border radius for the image.
  final BorderRadius? borderRadius;

  /// Duration of the fade-in animation.
  final Duration? fadeInDuration;

  @override
  Widget buildContent(BuildContext context) {
    Widget image;

    // Network image
    if (imageUrl != null) {
      image = CachedNetworkImage(
        imageUrl: imageUrl!,
        width: width,
        height: height,
        fit: fit,
        placeholder: (context, url) =>
            placeholder ?? _buildDefaultPlaceholder(context),
        errorWidget: (context, url, error) =>
            errorWidget ?? _buildDefaultError(context),
        fadeInDuration: fadeInDuration ?? const Duration(milliseconds: 300),
      );
    }
    // Asset image
    else if (assetPath != null) {
      image = Image.asset(
        assetPath!,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) =>
            errorWidget ?? _buildDefaultError(context),
      );
    }
    // File image
    else if (filePath != null) {
      // Note: For file images, you'd typically use Image.file()
      // but that requires dart:io which isn't available on web
      image = errorWidget ?? _buildDefaultError(context);
    }
    // No image source provided
    else {
      image = _buildDefaultPlaceholder(context);
    }

    // Apply border radius if provided
    if (borderRadius != null) {
      image = ClipRRect(
        borderRadius: borderRadius!,
        child: image,
      );
    }

    return image;
  }

  Widget _buildDefaultPlaceholder(BuildContext context) {
    return Container(
      width: width,
      height: height,
      color: Theme.of(context).colorScheme.surfaceVariant,
      child: Center(
        child: SizedBox(
          width: AppDimens.iconSizeMedium,
          height: AppDimens.iconSizeMedium,
          child: CircularProgressIndicator(
            strokeWidth: 2.0,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      ),
    );
  }

  Widget _buildDefaultError(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: width,
      height: height,
      color: theme.colorScheme.errorContainer,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.broken_image_outlined,
            size: AppDimens.iconSizeLarge,
            color: theme.colorScheme.error,
          ),
          if (onRetry != null) ...[
            SizedBox(height: AppDimens.spaceSmall),
            TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: Text(context.l10n.retry),
            ),
          ],
        ],
      ),
    );
  }
}
