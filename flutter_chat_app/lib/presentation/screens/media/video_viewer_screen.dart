import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_app/core/constants/app_dimens.dart';
import 'package:flutter_chat_app/core/theme/app_colors.dart';
import 'package:flutter_chat_app/l10n/l10n.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/buttons/app_button.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/feedback/app_progress_indicator.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/typography/app_text.dart';
import 'package:video_player/video_player.dart';

/// Fullscreen video viewer shared across the app.
///
/// Pattern: preview in message/list -> open this page for playback.
class VideoViewerScreen extends StatefulWidget {
  final String videoUrl;
  final String? title;
  final bool autoPlay;
  final bool looping;

  const VideoViewerScreen({
    Key? key,
    required this.videoUrl,
    this.title,
    this.autoPlay = true,
    this.looping = false,
  }) : super(key: key);

  static Future<void> show(
    BuildContext context, {
    required String videoUrl,
    String? title,
    bool autoPlay = true,
    bool looping = false,
  }) {
    return Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => VideoViewerScreen(
          videoUrl: videoUrl,
          title: title,
          autoPlay: autoPlay,
          looping: looping,
        ),
      ),
    );
  }

  @override
  State<VideoViewerScreen> createState() => _VideoViewerScreenState();
}

class _VideoViewerScreenState extends State<VideoViewerScreen> {
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final videoController = VideoPlayerController.networkUrl(
        Uri.parse(widget.videoUrl),
      );
      await videoController.initialize();

      final chewieController = ChewieController(
        videoPlayerController: videoController,
        autoPlay: widget.autoPlay,
        looping: widget.looping,
        autoInitialize: false,
        showControls: true,
        showControlsOnInitialize: true,
        aspectRatio: _safeAspectRatio(videoController.value.aspectRatio),
        allowMuting: true,
        allowPlaybackSpeedChanging: true,
        customControls: const MaterialControls(),
        materialProgressColors: ChewieProgressColors(
          playedColor: AppColors.primary,
          handleColor: AppColors.primary,
          bufferedColor: AppColors.primary.withValues(alpha: 0.35),
          backgroundColor: AppColors.dividerDarkMode,
        ),
      );

      if (!mounted) {
        chewieController.dispose();
        videoController.dispose();
        return;
      }

      _videoController?.dispose();
      _chewieController?.dispose();

      setState(() {
        _videoController = videoController;
        _chewieController = chewieController;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = context.l10n.errorLoadingVideo;
        _isLoading = false;
      });
    }
  }

  double _safeAspectRatio(double value) {
    if (value.isNaN || value.isInfinite || value <= 0) return 16 / 9;
    return value;
  }

  @override
  void dispose() {
    _chewieController?.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  Widget _buildLoadingState() {
    return Center(
      child: AppProgressIndicator.circular(label: context.l10n.loading),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimens.paddingMedium),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              color: AppColors.error,
              size: AppDimens.iconSizeXLarge,
            ),
            const SizedBox(height: AppDimens.spaceMedium),
            AppText(
              _errorMessage ?? context.l10n.errorLoadingVideo,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textPrimaryDarkMode),
            ),
            const SizedBox(height: AppDimens.spaceMedium),
            AppButton.primary(
              text: context.l10n.retry,
              onPressed: _initializePlayer,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayer() {
    final chewieController = _chewieController;
    final videoController = _videoController;

    if (chewieController == null || videoController == null) {
      return _buildErrorState();
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimens.paddingSmall),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppDimens.radiusMedium),
          child: AspectRatio(
            aspectRatio: _safeAspectRatio(videoController.value.aspectRatio),
            child: Chewie(controller: chewieController),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = (widget.title?.trim().isNotEmpty ?? false)
        ? widget.title!.trim()
        : context.l10n.video;

    return Scaffold(
      backgroundColor: AppColors.backgroundDarkMode,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: AppColors.backgroundDarkMode,
        foregroundColor: AppColors.textPrimaryDarkMode,
        leading: IconButton(
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
          icon: const Icon(
            Icons.arrow_back,
            color: AppColors.textPrimaryDarkMode,
          ),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: AppText(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: AppColors.textPrimaryDarkMode),
        ),
      ),
      body: SafeArea(
        top: false,
        child: _isLoading
            ? _buildLoadingState()
            : (_errorMessage != null ? _buildErrorState() : _buildPlayer()),
      ),
    );
  }
}
