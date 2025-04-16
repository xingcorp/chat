import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_chat_app/core/base/base_widget.dart';
import 'package:flutter_chat_app/core/constants/app_constants.dart';
import 'package:flutter_chat_app/core/theme/app_colors.dart';
import 'package:flutter_chat_app/core/utils/optimized_repaint_boundary.dart';

/// Widget hiển thị trước media (hình ảnh, video)
class MediaPreview extends BaseStatefulWidget {
  /// URL của media (ảnh hoặc video)
  final String mediaUrl;
  
  /// URL của thumbnail (chỉ cho video)
  final String? thumbnailUrl;
  
  /// Xác định media là ảnh hay video
  final bool isImage;
  
  /// Chiều rộng hiển thị, mặc định là 200
  final double? width;
  
  /// Chiều cao hiển thị, mặc định là 150
  final double? height;
  
  /// Độ bo góc
  final double? borderRadius;
  
  /// Callback khi nhấn vào media
  final VoidCallback? onTap;
  
  /// Constructor
  const MediaPreview({
    Key? key,
    required this.mediaUrl,
    this.thumbnailUrl,
    required this.isImage,
    this.width,
    this.height,
    this.borderRadius,
    this.onTap,
  }) : super(key: key);

  @override
  State<MediaPreview> createState() => _MediaPreviewState();
}

class _MediaPreviewState extends BaseState<MediaPreview> {
  bool _isLoading = true;
  bool _hasError = false;
  
  @override
  Widget build(BuildContext context) {
    return buildContent(context);
  }
  
  @override
  Widget buildContent(BuildContext context) {
    // Chiều rộng và cao mặc định
    const defaultWidth = 200.0;
    const defaultHeight = 150.0;
    
    return OptimizedRepaintBoundary(
      perfTag: 'media_preview_${widget.isImage ? 'image' : 'video'}',
      trackPerformance: true,
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          width: widget.width ?? defaultWidth,
          height: widget.height ?? defaultHeight,
          decoration: BoxDecoration(
            color: AppColors.greyLight,
            borderRadius: BorderRadius.circular(
              widget.borderRadius ?? AppConstants.kDefaultBorderRadius,
            ),
          ),
          child: _buildMedia(),
        ),
      ),
    );
  }
  
  /// Build widget hiển thị media
  Widget _buildMedia() {
    if (widget.isImage) {
      return _buildImagePreview();
    } else {
      return _buildVideoPreview();
    }
  }
  
  /// Build widget hiển thị hình ảnh
  Widget _buildImagePreview() {
    return Stack(
      children: [
        // Ảnh chính
        CachedNetworkImage(
          imageUrl: widget.mediaUrl,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          placeholder: (context, url) => _buildPlaceholder(),
          errorWidget: (context, url, error) => _buildErrorWidget(),
          fadeInDuration: const Duration(milliseconds: 300),
          fadeOutDuration: const Duration(milliseconds: 300),
          imageBuilder: (context, imageProvider) {
            safeSetState(() {
              _isLoading = false;
              _hasError = false;
            });
            return Image(
              image: imageProvider,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
            );
          },
        ),
        
        // Loading indicator
        if (_isLoading) _buildPlaceholder(),
        
        // Error widget
        if (_hasError) _buildErrorWidget(),
      ],
    );
  }
  
  /// Build widget hiển thị video
  Widget _buildVideoPreview() {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Thumbnail
        CachedNetworkImage(
          imageUrl: widget.thumbnailUrl ?? widget.mediaUrl,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          placeholder: (context, url) => _buildPlaceholder(),
          errorWidget: (context, url, error) => _buildErrorWidget(),
          fadeInDuration: const Duration(milliseconds: 300),
          fadeOutDuration: const Duration(milliseconds: 300),
          imageBuilder: (context, imageProvider) {
            safeSetState(() {
              _isLoading = false;
              _hasError = false;
            });
            return Image(
              image: imageProvider,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
            );
          },
        ),
        
        // Play button
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.5),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.play_arrow,
            color: Colors.white,
            size: 24,
          ),
        ),
        
        // Loading indicator
        if (_isLoading) _buildPlaceholder(),
        
        // Error widget
        if (_hasError) _buildErrorWidget(),
      ],
    );
  }
  
  /// Build widget placeholder khi đang tải
  Widget _buildPlaceholder() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: AppColors.greyLight,
      child: Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            strokeWidth: 2,
          ),
        ),
      ),
    );
  }
  
  /// Build widget khi có lỗi
  Widget _buildErrorWidget() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: AppColors.greyLight,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.grey,
              size: 32,
            ),
            const SizedBox(height: 8),
            const Text(
              'Không thể tải media',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
} 