import 'dart:io';
import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart' show immutable, kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_chat_app/core/base/base_widget.dart';
import 'package:flutter_chat_app/core/constants/app_dimens.dart';
import 'package:flutter_chat_app/core/theme/app_colors.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/feedback/app_progress_indicator.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/typography/app_text.dart';

final Map<String, double> _chatImageAspectRatioCache = {};

/// Image source model for chat attachment gallery.
@immutable
class AppChatImageGalleryItem {
  final String id;
  final String url;
  final String? localPath;
  final Uint8List? localBytes;
  final bool isUploading;
  final double uploadProgress;

  const AppChatImageGalleryItem({
    required this.id,
    required this.url,
    this.localPath,
    this.localBytes,
    this.isUploading = false,
    this.uploadProgress = 0.0,
  });

  bool get hasLocalPath => localPath != null && localPath!.isNotEmpty;
  bool get hasLocalBytes => localBytes != null && localBytes!.isNotEmpty;
  bool get hasUrl => url.trim().isNotEmpty;
}

/// Shared chat image gallery pattern used by message bubbles.
///
/// Layout:
/// - 1 image: smart single-tile with adaptive aspect ratio.
/// - 2 images: two columns.
/// - 3 images: one large tile + two stacked tiles.
/// - 4+ images: 2x2 with +N overlay.
class AppChatImageGallery extends BaseStatelessWidget {
  const AppChatImageGallery({
    super.key,
    required this.images,
    required this.onImageTap,
    this.spacing = AppDimens.spaceXSmall,
    this.borderRadius =
        const BorderRadius.all(Radius.circular(AppDimens.radiusSmall)),
  });

  final List<AppChatImageGalleryItem> images;
  final ValueChanged<int> onImageTap;
  final double spacing;
  final BorderRadius borderRadius;

  @override
  Widget buildContent(BuildContext context) {
    if (images.isEmpty) {
      return const SizedBox.shrink();
    }

    if (images.length == 1) {
      return _SmartSingleImageTile(
        image: images.first,
        borderRadius: borderRadius,
        onTap: () => onImageTap(0),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.of(context).size.width;
        final isDesktop = width >= AppDimens.breakpointDesktop;

        double clamp(double value, double min, double max) {
          if (value < min) return min;
          if (value > max) return max;
          return value;
        }

        final twoImageHeight = isDesktop
            ? clamp((width - spacing) * 0.46, 170, 300)
            : clamp((width - spacing) * 0.40, 150, 240);
        final threeImageHeight = isDesktop
            ? clamp(width * 0.58, 220, 340)
            : clamp(width * 0.62, 200, 300);
        final fourImageTileHeight = isDesktop
            ? clamp((width - spacing) * 0.34, 130, 220)
            : clamp((width - spacing) * 0.30, 120, 190);

        if (images.length == 2) {
          return SizedBox(
            height: twoImageHeight,
            child: Row(
              children: [
                Expanded(
                  child: _buildTile(
                    context,
                    images[0],
                    index: 0,
                    borderRadius: BorderRadius.only(
                      topLeft: borderRadius.topLeft,
                      bottomLeft: borderRadius.bottomLeft,
                    ),
                  ),
                ),
                SizedBox(width: spacing),
                Expanded(
                  child: _buildTile(
                    context,
                    images[1],
                    index: 1,
                    borderRadius: BorderRadius.only(
                      topRight: borderRadius.topRight,
                      bottomRight: borderRadius.bottomRight,
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        if (images.length == 3) {
          return SizedBox(
            height: threeImageHeight,
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: _buildTile(
                    context,
                    images[0],
                    index: 0,
                    borderRadius: BorderRadius.only(
                      topLeft: borderRadius.topLeft,
                      bottomLeft: borderRadius.bottomLeft,
                    ),
                  ),
                ),
                SizedBox(width: spacing),
                Expanded(
                  child: Column(
                    children: [
                      Expanded(
                        child: _buildTile(
                          context,
                          images[1],
                          index: 1,
                          borderRadius: BorderRadius.only(
                            topRight: borderRadius.topRight,
                          ),
                        ),
                      ),
                      SizedBox(height: spacing),
                      Expanded(
                        child: _buildTile(
                          context,
                          images[2],
                          index: 2,
                          borderRadius: BorderRadius.only(
                            bottomRight: borderRadius.bottomRight,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        final displayImages = images.take(4).toList(growable: false);
        final remainingCount = images.length - 4;

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: fourImageTileHeight,
              child: Row(
                children: [
                  Expanded(
                    child: _buildTile(
                      context,
                      displayImages[0],
                      index: 0,
                      borderRadius: BorderRadius.only(
                        topLeft: borderRadius.topLeft,
                      ),
                    ),
                  ),
                  SizedBox(width: spacing),
                  Expanded(
                    child: _buildTile(
                      context,
                      displayImages[1],
                      index: 1,
                      borderRadius: BorderRadius.only(
                        topRight: borderRadius.topRight,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: spacing),
            SizedBox(
              height: fourImageTileHeight,
              child: Row(
                children: [
                  Expanded(
                    child: _buildTile(
                      context,
                      displayImages[2],
                      index: 2,
                      borderRadius: BorderRadius.only(
                        bottomLeft: borderRadius.bottomLeft,
                      ),
                    ),
                  ),
                  SizedBox(width: spacing),
                  Expanded(
                    child: _buildTile(
                      context,
                      displayImages[3],
                      index: 3,
                      borderRadius: BorderRadius.only(
                        bottomRight: borderRadius.bottomRight,
                      ),
                      overlay: remainingCount > 0
                          ? Container(
                              color: AppColors.backgroundDarkMode
                                  .withValues(alpha: 0.54),
                              alignment: Alignment.center,
                              child: AppText(
                                '+$remainingCount',
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                      color: AppColors.textPrimaryDarkMode,
                                      fontWeight: FontWeight.w700,
                                    ) ??
                                    const TextStyle(
                                      color: AppColors.textPrimaryDarkMode,
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                            )
                          : null,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTile(
    BuildContext context,
    AppChatImageGalleryItem image, {
    required int index,
    required BorderRadius borderRadius,
    Widget? overlay,
  }) {
    return GestureDetector(
      key: ValueKey('chat_image_tile_$index'),
      onTap: image.isUploading ? null : () => onImageTap(index),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: Stack(
          fit: StackFit.expand,
          children: [
            _GalleryImageContent(image: image),
            if (image.isUploading)
              Positioned.fill(
                child: _UploadingOverlay(progress: image.uploadProgress),
              ),
            if (overlay != null) Positioned.fill(child: overlay),
          ],
        ),
      ),
    );
  }
}

class _SmartSingleImageTile extends StatefulWidget {
  final AppChatImageGalleryItem image;
  final BorderRadius borderRadius;
  final VoidCallback onTap;

  const _SmartSingleImageTile({
    required this.image,
    required this.borderRadius,
    required this.onTap,
  });

  @override
  State<_SmartSingleImageTile> createState() => _SmartSingleImageTileState();
}

class _SmartSingleImageTileState extends State<_SmartSingleImageTile> {
  double? _aspectRatio;

  @override
  void initState() {
    super.initState();
    _resolveAspectRatio();
  }

  @override
  void didUpdateWidget(covariant _SmartSingleImageTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldKey = _buildCacheKey(oldWidget.image);
    final newKey = _buildCacheKey(widget.image);
    if (oldKey != newKey) {
      _aspectRatio = null;
      _resolveAspectRatio();
    }
  }

  void _resolveAspectRatio() {
    final key = _buildCacheKey(widget.image);
    if (key.isEmpty) {
      return;
    }

    final cachedRatio = _chatImageAspectRatioCache[key];
    if (cachedRatio != null) {
      if (mounted) {
        setState(() => _aspectRatio = cachedRatio);
      }
      return;
    }

    final provider = _resolveImageProvider(widget.image);
    if (provider == null) {
      return;
    }

    final stream = provider.resolve(ImageConfiguration.empty);
    late final ImageStreamListener listener;
    listener = ImageStreamListener(
      (info, _) {
        final width = info.image.width.toDouble();
        final height = info.image.height.toDouble();
        if (width > 0 && height > 0) {
          final ratio = width / height;
          _chatImageAspectRatioCache[key] = ratio;
          if (mounted) {
            setState(() => _aspectRatio = ratio);
          }
        }
        stream.removeListener(listener);
      },
      onError: (_, __) {
        stream.removeListener(listener);
      },
    );
    stream.addListener(listener);
  }

  String _buildCacheKey(AppChatImageGalleryItem image) {
    if (image.hasLocalPath) {
      return image.localPath!;
    }
    if (image.hasUrl) {
      return image.url.trim();
    }
    if (image.hasLocalBytes) {
      return 'bytes_${image.localBytes.hashCode}';
    }
    return '';
  }

  ImageProvider? _resolveImageProvider(AppChatImageGalleryItem image) {
    if (!kIsWeb && image.hasLocalPath) {
      return FileImage(File(image.localPath!));
    }
    if (image.hasLocalBytes) {
      return MemoryImage(image.localBytes!);
    }
    if (image.hasUrl) {
      return CachedNetworkImageProvider(image.url.trim());
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final isUploading = widget.image.isUploading;
    final uploadProgress = widget.image.uploadProgress;

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.of(context).size.width;
        final isDesktop = availableWidth >= AppDimens.breakpointDesktop;
        final minWidth = isDesktop ? 220.0 : 150.0;
        final maxHeight = isDesktop ? 440.0 : 360.0;
        final clampedAspectRatio = (_aspectRatio ?? 1.0).clamp(0.72, 1.35);

        return GestureDetector(
          key: const ValueKey('chat_image_tile_0'),
          onTap: isUploading ? null : widget.onTap,
          child: ClipRRect(
            borderRadius: widget.borderRadius,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minWidth: minWidth < availableWidth ? minWidth : availableWidth,
                maxWidth: availableWidth,
                maxHeight: maxHeight,
              ),
              child: AspectRatio(
                aspectRatio: clampedAspectRatio,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _GalleryImageContent(image: widget.image),
                    if (isUploading)
                      Positioned.fill(
                        child: _UploadingOverlay(progress: uploadProgress),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _GalleryImageContent extends StatelessWidget {
  final AppChatImageGalleryItem image;

  const _GalleryImageContent({
    required this.image,
  });

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb && image.hasLocalPath) {
      return Image.file(
        File(image.localPath!),
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildErrorPlaceholder(),
      );
    }

    if (image.hasLocalBytes) {
      return Image.memory(
        image.localBytes!,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildErrorPlaceholder(),
      );
    }

    if (image.hasUrl) {
      return CachedNetworkImage(
        imageUrl: image.url.trim(),
        fit: BoxFit.cover,
        placeholder: (_, __) => _buildLoadingPlaceholder(),
        errorWidget: (_, __, ___) => _buildErrorPlaceholder(),
      );
    }

    return _buildLoadingPlaceholder();
  }

  Widget _buildLoadingPlaceholder() {
    return Container(
      color: AppColors.surfaceVariant,
      child: const Center(
        child: AppProgressIndicator.circular(
          size: ProgressSize.small,
        ),
      ),
    );
  }

  Widget _buildErrorPlaceholder() {
    return Container(
      color: AppColors.surfaceVariant,
      child: const Icon(
        Icons.broken_image,
        color: AppColors.icon,
      ),
    );
  }
}

class _UploadingOverlay extends StatelessWidget {
  final double progress;

  const _UploadingOverlay({
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    final percentage = (progress * 100).toInt();

    return Container(
      color: AppColors.backgroundDarkMode.withValues(alpha: 0.4),
      child: Center(
        child: Container(
          width: AppDimens.touchTargetMin,
          height: AppDimens.touchTargetMin,
          decoration: BoxDecoration(
            color: AppColors.backgroundDarkMode.withValues(alpha: 0.5),
            shape: BoxShape.circle,
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: AppDimens.avatarMedium,
                height: AppDimens.avatarMedium,
                child: AppProgressIndicator.circular(
                  value: progress > 0 ? progress : null,
                  size: ProgressSize.medium,
                  color: AppColors.textPrimaryDarkMode,
                  backgroundColor:
                      AppColors.textPrimaryDarkMode.withValues(alpha: 0.3),
                  strokeWidth: AppDimens.spaceXSmall,
                ),
              ),
              if (progress > 0)
                AppText(
                  '$percentage%',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textPrimaryDarkMode,
                        fontWeight: FontWeight.w600,
                      ) ??
                      const TextStyle(
                        color: AppColors.textPrimaryDarkMode,
                        fontWeight: FontWeight.w600,
                      ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
