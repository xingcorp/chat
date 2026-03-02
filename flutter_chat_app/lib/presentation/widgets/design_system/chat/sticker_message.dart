import 'package:flutter/material.dart';
import 'package:flutter_chat_app/core/base/base_widget.dart';
import 'package:flutter_chat_app/core/constants/app_dimens.dart';
import 'package:flutter_chat_app/core/theme/app_colors.dart';
import 'package:flutter_chat_app/domain/repositories/i_sticker_repository.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/media/app_image.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/typography/app_text.dart';
import 'package:get_it/get_it.dart';

/// Renders a sticker message from sticker code.
///
/// The message content is expected to contain sticker code. If content is already
/// a direct URL or asset path, it will be rendered directly.
class StickerMessageWidget extends BaseStatefulWidget {
  const StickerMessageWidget({
    required this.stickerCode,
    this.size = AppDimens.avatarHuge,
    super.key,
  });

  /// Sticker code from message content.
  final String stickerCode;

  /// Sticker size in logical pixels.
  final double size;

  @override
  State<StickerMessageWidget> createState() => _StickerMessageWidgetState();
}

class _StickerMessageWidgetState extends BaseState<StickerMessageWidget> {
  late final IStickerRepository _stickerRepository;

  String? _resolvedImageUrl;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _stickerRepository = GetIt.I<IStickerRepository>();
    _resolveStickerImage();
  }

  @override
  void didUpdateWidget(covariant StickerMessageWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.stickerCode != widget.stickerCode) {
      _resolveStickerImage();
    }
  }

  Future<void> _resolveStickerImage() async {
    safeSetState(() {
      _isLoading = true;
      _resolvedImageUrl = null;
    });

    String? imageUrl = _tryParseDirectPath(widget.stickerCode);

    if (imageUrl == null) {
      final resolved = _stickerRepository.resolveSticker(widget.stickerCode);
      imageUrl = resolved?.imageUrl;
    }

    if (imageUrl == null) {
      final packsResult = await _stickerRepository.getAvailablePacks();
      if (packsResult.isRight) {
        imageUrl =
            _stickerRepository.resolveSticker(widget.stickerCode)?.imageUrl;
      }
    }

    if (!mounted) {
      return;
    }

    safeSetState(() {
      _resolvedImageUrl = imageUrl;
      _isLoading = false;
    });
  }

  String? _tryParseDirectPath(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return null;
    }
    if (trimmed.startsWith('http://') ||
        trimmed.startsWith('https://') ||
        trimmed.startsWith('assets/')) {
      return trimmed;
    }
    return null;
  }

  bool _isAssetPath(String imagePath) {
    return imagePath.startsWith('assets/');
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingPlaceholder();
    }

    final imageUrl = _resolvedImageUrl;
    if (imageUrl == null || imageUrl.isEmpty) {
      return _buildErrorPlaceholder(showCode: true);
    }

    final imageWidget = _isAssetPath(imageUrl)
        ? AppImage.asset(
            assetPath: imageUrl,
            width: widget.size,
            height: widget.size,
            fit: BoxFit.contain,
            errorWidget: _buildErrorPlaceholder(showCode: true),
          )
        : AppImage.network(
            imageUrl: imageUrl,
            width: widget.size,
            height: widget.size,
            fit: BoxFit.contain,
            placeholder: _buildLoadingPlaceholder(),
            errorWidget: _buildErrorPlaceholder(showCode: true),
          );

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: imageWidget,
    );
  }

  Widget _buildLoadingPlaceholder() {
    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(AppDimens.radiusSmall),
      ),
      child: const Center(
        child: SizedBox(
          width: AppDimens.iconSizeMedium,
          height: AppDimens.iconSizeMedium,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }

  Widget _buildErrorPlaceholder({required bool showCode}) {
    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(AppDimens.radiusSmall),
      ),
      padding: const EdgeInsets.all(AppDimens.paddingSmall),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.broken_image_outlined,
            size: AppDimens.iconSizeLarge,
            color: AppColors.textSecondary,
          ),
          if (showCode) ...[
            const SizedBox(height: AppDimens.spaceXSmall),
            AppText(
              widget.stickerCode,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}
