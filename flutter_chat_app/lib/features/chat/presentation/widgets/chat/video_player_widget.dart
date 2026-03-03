import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/media/app_image.dart';

/// Lazy-init inline video player for chat messages.
///
/// Shows thumbnail + play overlay initially.
/// On tap play: initializes VideoPlayerController + ChewieController.
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
    this.borderRadius = 8.0,
  }) : super(key: key);

  @override
  State<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  bool _isPlaying = false;
  bool _isLoading = false;
  bool _isLoadingPreview = false;
  bool _hasError = false;
  double _aspectRatio = 16 / 9;

  String? get _thumbnailUrl {
    final raw = widget.thumbnailUrl?.trim();
    if (raw == null || raw.isEmpty) return null;
    return raw;
  }

  bool get _hasThumbnail => _thumbnailUrl != null;

  @override
  void initState() {
    super.initState();
    _preparePreview();
  }

  @override
  void didUpdateWidget(covariant VideoPlayerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url == widget.url &&
        oldWidget.thumbnailUrl == widget.thumbnailUrl) {
      return;
    }

    _disposeControllers();
    _isPlaying = false;
    _isLoading = false;
    _isLoadingPreview = false;
    _hasError = false;
    _aspectRatio = 16 / 9;
    _preparePreview();
  }

  Future<void> _preparePreview() async {
    if (_hasThumbnail || _videoController != null || _isLoadingPreview) return;

    setState(() => _isLoadingPreview = true);

    try {
      final controller =
          VideoPlayerController.networkUrl(Uri.parse(widget.url));
      await controller.initialize();

      if (!mounted) {
        controller.dispose();
        return;
      }

      setState(() {
        _videoController = controller;
        _aspectRatio = _safeAspectRatio(controller.value.aspectRatio);
        _isLoadingPreview = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoadingPreview = false);
    }
  }

  Future<void> _initVideo() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      _videoController ??=
          VideoPlayerController.networkUrl(Uri.parse(widget.url));
      if (!_videoController!.value.isInitialized) {
        await _videoController!.initialize();
      }

      _aspectRatio = _safeAspectRatio(_videoController!.value.aspectRatio);

      _chewieController?.dispose();

      _chewieController = ChewieController(
        videoPlayerController: _videoController!,
        autoPlay: true,
        looping: false,
        showControls: true,
        aspectRatio: _aspectRatio,
      );

      if (mounted) {
        setState(() {
          _isPlaying = true;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
      }
    }
  }

  double _safeAspectRatio(double value) {
    if (value.isNaN || value.isInfinite || value <= 0) return 16 / 9;
    return value;
  }

  void _disposeControllers() {
    _chewieController?.dispose();
    _chewieController = null;
    _videoController?.dispose();
    _videoController = null;
  }

  @override
  void dispose() {
    _disposeControllers();
    super.dispose();
  }

  Widget _buildErrorState(ThemeData theme) {
    return AspectRatio(
      aspectRatio: _aspectRatio,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[850],
          borderRadius: BorderRadius.circular(widget.borderRadius),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Colors.white60, size: 30),
              const SizedBox(height: 8),
              const Text(
                'Cannot load video',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () {
                  setState(() {
                    _hasError = false;
                    _isPlaying = false;
                  });
                  _preparePreview();
                },
                child: Text(
                  'Retry',
                  style: TextStyle(color: theme.colorScheme.primary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPreviewBackground() {
    if (_hasThumbnail) {
      return AppImage.network(
        imageUrl: _thumbnailUrl!,
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.cover,
      );
    }

    if (_videoController != null && _videoController!.value.isInitialized) {
      final size = _videoController!.value.size;
      if (size.width > 0 && size.height > 0) {
        return SizedBox.expand(
          child: FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: size.width,
              height: size.height,
              child: VideoPlayer(_videoController!),
            ),
          ),
        );
      }

      return SizedBox.expand(
        child: VideoPlayer(_videoController!),
      );
    }

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF545454), Color(0xFF2D2D2D)],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return _buildErrorState(Theme.of(context));
    }

    if (_isPlaying && _chewieController != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(widget.borderRadius),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: widget.maxHeight),
          child: AspectRatio(
            aspectRatio: _aspectRatio,
            child: Chewie(controller: _chewieController!),
          ),
        ),
      );
    }

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: widget.maxHeight),
      child: GestureDetector(
        onTap: _isLoading ? null : _initVideo,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          child: AspectRatio(
            aspectRatio: _aspectRatio,
            child: Stack(
              fit: StackFit.expand,
              children: [
                _buildPreviewBackground(),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Color(0x33000000)],
                    ),
                  ),
                ),
                Center(
                  child: (_isLoading || _isLoadingPreview)
                      ? const CircularProgressIndicator(color: Colors.white70)
                      : Container(
                          padding: const EdgeInsets.all(12),
                          decoration: const BoxDecoration(
                            color: Colors.black54,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.play_arrow,
                            color: Colors.white,
                            size: 32,
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
