import 'package:flutter/material.dart';
import 'package:flutter_chat_app/core/constants/app_dimens.dart';
import 'package:flutter_chat_app/core/theme/app_colors.dart';
import 'package:flutter_chat_app/l10n/l10n.dart';
import 'package:flutter_chat_app/presentation/screens/media/video_viewer_screen.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/feedback/app_progress_indicator.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/media/app_image.dart';
import 'package:video_player/video_player.dart';

/// Video preview card for chat.
///
/// Pattern: show thumbnail + play button in message bubble.
/// On tap: open fullscreen video viewer.
class VideoPlayerWidget extends StatefulWidget {
  final String url;
  final String? thumbnailUrl;
  final bool isFromCurrentUser;
  final double maxHeight;
  final double borderRadius;

  const VideoPlayerWidget({
    Key? key,
    required this.url,
    this.thumbnailUrl,
    this.isFromCurrentUser = false,
    this.maxHeight = 260.0,
    this.borderRadius = AppDimens.radiusSmall,
  }) : super(key: key);

  @override
  State<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  VideoPlayerController? _previewController;
  bool _isPreparingPreview = false;
  bool _isOpeningViewer = false;
  double _aspectRatio = 16 / 9;

  String? get _thumbnailUrl {
    final value = widget.thumbnailUrl?.trim();
    if (value == null || value.isEmpty) return null;
    return value;
  }

  bool get _hasThumbnail => _thumbnailUrl != null;

  @override
  void initState() {
    super.initState();
    _preparePreviewFrame();
  }

  @override
  void didUpdateWidget(covariant VideoPlayerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url == widget.url &&
        oldWidget.thumbnailUrl == widget.thumbnailUrl) {
      return;
    }

    _disposePreviewController();
    _isPreparingPreview = false;
    _isOpeningViewer = false;
    _aspectRatio = 16 / 9;
    _preparePreviewFrame();
  }

  Future<void> _preparePreviewFrame() async {
    if (_hasThumbnail || _previewController != null || _isPreparingPreview) {
      return;
    }

    setState(() => _isPreparingPreview = true);

    try {
      final controller =
          VideoPlayerController.networkUrl(Uri.parse(widget.url));
      await controller.initialize();

      if (!mounted) {
        controller.dispose();
        return;
      }

      _previewController = controller;

      setState(() {
        _aspectRatio = _safeAspectRatio(controller.value.aspectRatio);
        _isPreparingPreview = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isPreparingPreview = false);
    }
  }

  double _safeAspectRatio(double value) {
    if (value.isNaN || value.isInfinite || value <= 0) return 16 / 9;
    return value;
  }

  void _disposePreviewController() {
    _previewController?.dispose();
    _previewController = null;
  }

  Future<void> _openViewer() async {
    if (_isOpeningViewer) return;

    _isOpeningViewer = true;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => VideoViewerScreen(
          videoUrl: widget.url,
          title: context.l10n.videoMessage,
          autoPlay: true,
        ),
      ),
    );
    _isOpeningViewer = false;
  }

  @override
  void dispose() {
    _disposePreviewController();
    super.dispose();
  }

  Widget _buildPreviewContent() {
    if (_hasThumbnail) {
      return AppImage.network(
        imageUrl: _thumbnailUrl!,
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.cover,
      );
    }

    final controller = _previewController;
    if (controller != null && controller.value.isInitialized) {
      final size = controller.value.size;
      if (size.width > 0 && size.height > 0) {
        return SizedBox.expand(
          child: FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: size.width,
              height: size.height,
              child: VideoPlayer(controller),
            ),
          ),
        );
      }

      return SizedBox.expand(child: VideoPlayer(controller));
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.greyDark,
            AppColors.backgroundDarkMode,
          ],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.videocam,
          size: AppDimens.iconSizeLarge,
          color: AppColors.iconDarkMode.withValues(alpha: 0.75),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: widget.maxHeight),
      child: GestureDetector(
        onTap: _openViewer,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          child: AspectRatio(
            aspectRatio: _aspectRatio,
            child: Stack(
              fit: StackFit.expand,
              children: [
                _buildPreviewContent(),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Color(0x44000000)],
                    ),
                  ),
                ),
                Center(
                  child: _isPreparingPreview
                      ? const AppProgressIndicator.circular(
                          size: ProgressSize.small,
                        )
                      : Container(
                          width: AppDimens.iconSizeXXLarge,
                          height: AppDimens.iconSizeXXLarge,
                          decoration: BoxDecoration(
                            color: AppColors.backgroundDarkMode
                                .withValues(alpha: 0.55),
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Icon(
                            Icons.play_arrow,
                            color: AppColors.textPrimaryDarkMode,
                            size: AppDimens.iconSizeLarge,
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
