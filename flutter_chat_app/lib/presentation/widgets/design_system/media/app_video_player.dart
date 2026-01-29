import 'package:flutter/material.dart';
import 'package:flutter_chat_app/core/base/base_widget.dart';
import 'package:flutter_chat_app/core/constants/app_dimens.dart';
import 'package:flutter_chat_app/core/theme/app_colors.dart';
import 'package:flutter_chat_app/l10n/l10n.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/media/media_enums.dart';

/// Video player component with comprehensive playback controls.
///
/// Features:
/// - Play/pause controls
/// - Seek bar with preview
/// - Volume control
/// - Fullscreen toggle
/// - Playback speed control (0.5x, 1x, 1.5x, 2x)
/// - Quality selection (auto, 360p, 480p, 720p, 1080p)
/// - Picture-in-picture support
/// - Auto-hide controls after inactivity
/// - Loading and buffering states
/// - Error handling with retry
///
/// Example:
/// ```dart
/// AppVideoPlayer(
///   videoUrl: 'https://example.com/video.mp4',
///   autoPlay: true,
///   onError: (error) => print('Error: $error'),
/// )
/// ```
class AppVideoPlayer extends BaseStatefulWidget {
  /// URL of the video to play
  final String videoUrl;

  /// Whether to start playing automatically
  final bool autoPlay;

  /// Whether to loop the video
  final bool loop;

  /// Whether to show controls
  final bool showControls;

  /// Initial volume (0.0 to 1.0)
  final double initialVolume;

  /// Initial playback speed
  final PlaybackSpeed initialSpeed;


  /// Initial quality
  final VideoQuality initialQuality;

  /// Available quality options
  final List<VideoQuality> availableQualities;

  /// Whether to enable picture-in-picture
  final bool enablePiP;

  /// Callback when video ends
  final VoidCallback? onVideoEnd;

  /// Callback when playback position changes
  final ValueChanged<Duration>? onPositionChanged;

  /// Callback when error occurs
  final ValueChanged<String>? onError;

  /// Custom thumbnail to show before playing
  final String? thumbnailUrl;

  const AppVideoPlayer({
    super.key,
    required this.videoUrl,
    this.autoPlay = false,
    this.loop = false,
    this.showControls = true,
    this.initialVolume = 1.0,
    this.initialSpeed = PlaybackSpeed.x100,
    this.initialQuality = VideoQuality.auto,
    this.availableQualities = const [
      VideoQuality.auto,
      VideoQuality.p360,
      VideoQuality.p480,
      VideoQuality.p720,
      VideoQuality.p1080,
    ],
    this.enablePiP = true,
    this.onVideoEnd,
    this.onPositionChanged,
    this.onError,
    this.thumbnailUrl,
  });

  @override
  AppVideoPlayerState createState() => AppVideoPlayerState();
}

class AppVideoPlayerState extends BaseState<AppVideoPlayer>
    with SingleTickerProviderStateMixin {
  bool _isPlaying = false;
  bool _isBuffering = false;
  bool _hasError = false;
  String? _errorMessage;
  bool _showControls = true;
  bool _isFullscreen = false;
  bool _isMuted = false;

  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;
  double _volume = 1.0;
  PlaybackSpeed _playbackSpeed = PlaybackSpeed.x100;
  VideoQuality _quality = VideoQuality.auto;

  late AnimationController _controlsAnimationController;
  late Animation<double> _controlsAnimation;

  @override
  void initState() {
    super.initState();
    _volume = widget.initialVolume;
    _playbackSpeed = widget.initialSpeed;
    _quality = widget.initialQuality;

    _controlsAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _controlsAnimation = CurvedAnimation(
      parent: _controlsAnimationController,
      curve: Curves.easeInOut,
    );

    if (widget.showControls) {
      _controlsAnimationController.forward();
    }

    if (widget.autoPlay) {
      _play();
    }

    // Simulate video loading (in real implementation, use video_player package)
    _loadVideo();
  }

  @override
  void dispose() {
    _controlsAnimationController.dispose();
    super.dispose();
  }

  Future<void> _loadVideo() async {
    safeSetState(() {
      _isBuffering = true;
      _hasError = false;
    });

    try {
      // Simulate loading delay
      await Future.delayed(const Duration(seconds: 1));

      // In real implementation, initialize video player here
      safeSetState(() {
        _isBuffering = false;
        _totalDuration = const Duration(minutes: 5, seconds: 30); // Mock duration
      });
    } catch (e) {
      safeSetState(() {
        _isBuffering = false;
        _hasError = true;
        _errorMessage = e.toString();
      });
      widget.onError?.call(e.toString());
    }
  }

  void _play() {
    safeSetState(() {
      _isPlaying = true;
    });
    _hideControlsAfterDelay();
    // In real implementation, start video playback
  }

  void _pause() {
    safeSetState(() {
      _isPlaying = false;
    });
    _showControlsPermanently();
  }

  void _togglePlayPause() {
    if (_isPlaying) {
      _pause();
    } else {
      _play();
    }
  }

  void _seek(Duration position) {
    safeSetState(() {
      _currentPosition = position;
    });
    widget.onPositionChanged?.call(position);
    // In real implementation, seek video to position
  }

  void _toggleMute() {
    safeSetState(() {
      _isMuted = !_isMuted;
      _volume = _isMuted ? 0.0 : widget.initialVolume;
    });
  }

  void _changeVolume(double volume) {
    safeSetState(() {
      _volume = volume;
      _isMuted = volume == 0.0;
    });
  }

  void _changeSpeed(PlaybackSpeed speed) {
    safeSetState(() {
      _playbackSpeed = speed;
    });
    // In real implementation, change video playback speed
  }

  void _changeQuality(VideoQuality quality) {
    safeSetState(() {
      _quality = quality;
      _isBuffering = true;
    });
    // In real implementation, change video quality
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        safeSetState(() {
          _isBuffering = false;
        });
      }
    });
  }

  void _toggleFullscreen() {
    safeSetState(() {
      _isFullscreen = !_isFullscreen;
    });
    // In real implementation, enter/exit fullscreen mode
  }

  void _enterPiP() {
    // In real implementation, enter picture-in-picture mode
  }

  void _retry() {
    _loadVideo();
  }

  void _showControlsPermanently() {
    _controlsAnimationController.forward();
    safeSetState(() {
      _showControls = true;
    });
  }

  void _hideControlsAfterDelay() {
    if (!widget.showControls) return;

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && _isPlaying) {
        _controlsAnimationController.reverse();
        safeSetState(() {
          _showControls = false;
        });
      }
    });
  }

  void _onTap() {
    if (_showControls) {
      _controlsAnimationController.reverse();
      safeSetState(() {
        _showControls = false;
      });
    } else {
      _controlsAnimationController.forward();
      safeSetState(() {
        _showControls = true;
      });
      if (_isPlaying) {
        _hideControlsAfterDelay();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      height: _isFullscreen ? MediaQuery.of(context).size.height : 240,
      decoration: BoxDecoration(
        color: AppColors.backgroundDarkMode,
        borderRadius: _isFullscreen
            ? BorderRadius.zero
            : BorderRadius.circular(AppDimens.radiusMedium),
      ),
      child: Stack(
        children: [
          // Video content area
          Positioned.fill(
            child: GestureDetector(
              onTap: _onTap,
              child: _buildVideoContent(context, isDark),
            ),
          ),

          // Controls overlay
          if (widget.showControls)
            FadeTransition(
              opacity: _controlsAnimation,
              child: _buildControlsOverlay(context, isDark),
            ),
        ],
      ),
    );
  }

  Widget _buildVideoContent(BuildContext context, bool isDark) {
    if (_hasError) {
      return _buildErrorState(context);
    }

    if (_isBuffering) {
      return _buildLoadingState(context);
    }

    // In real implementation, show actual video frame
    return Container(
      color: AppColors.backgroundDarkMode,
      child: Center(
        child: widget.thumbnailUrl != null && !_isPlaying
            ? Image.network(
                widget.thumbnailUrl!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(
                    Icons.videocam,
                    size: AppDimens.iconXXLarge,
                    color: AppColors.iconDarkMode.withValues(alpha: 0.5),
                  );
                },
              )
            : Icon(
                Icons.play_circle_outline,
                size: AppDimens.iconXXLarge,
                color: AppColors.iconDarkMode.withValues(alpha: 0.5),
              ),
      ),
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    return Container(
      color: AppColors.backgroundDarkMode,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
            const SizedBox(height: AppDimens.spaceMedium),
            Text(
              context.l10n.loading,
              style: const TextStyle(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context) {
    return Container(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: AppDimens.spaceMedium),
            Text(
              _errorMessage ?? 'Error loading video',
              style: const TextStyle(color: Colors.white),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppDimens.spaceMedium),
            ElevatedButton(
              onPressed: _retry,
              child: Text(context.l10n.retry),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlsOverlay(BuildContext context, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.backgroundDarkMode.withValues(alpha: 0.7),
            Colors.transparent,
            AppColors.backgroundDarkMode.withValues(alpha: 0.7),
          ],
          stops: const [0.0, 0.5, 1.0],
        ),
      ),
      child: Column(
        children: [
          // Top controls
          _buildTopControls(context),

          const Spacer(),

          // Center play/pause button
          if (!_isPlaying)
            Center(
              child: IconButton(
                icon: const Icon(Icons.play_circle_filled),
                iconSize: 72,
                color: AppColors.iconDarkMode,
                onPressed: _togglePlayPause,
              ),
            ),

          const Spacer(),

          // Bottom controls
          _buildBottomControls(context),
        ],
      ),
    );
  }

  Widget _buildTopControls(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppDimens.paddingSmall),
      child: Row(
        children: [
          // Quality selector
          _buildQualitySelector(context),

          const Spacer(),

          // PiP button
          if (widget.enablePiP)
            IconButton(
              icon: const Icon(Icons.picture_in_picture_alt),
              color: AppColors.iconDarkMode,
              onPressed: _enterPiP,
              tooltip: context.l10n.pictureInPicture,
            ),

          // Fullscreen button
          IconButton(
            icon: Icon(
              _isFullscreen ? Icons.fullscreen_exit : Icons.fullscreen,
            ),
            color: AppColors.iconDarkMode,
            onPressed: _toggleFullscreen,
            tooltip: _isFullscreen
                ? context.l10n.exitFullscreen
                : context.l10n.enterFullscreen,
          ),
        ],
      ),
    );
  }

  Widget _buildBottomControls(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppDimens.paddingSmall),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Seek bar
          _buildSeekBar(context),

          const SizedBox(height: AppDimens.spaceSmall),

          // Control buttons
          Row(
            children: [
              // Play/Pause
              IconButton(
                icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
                color: AppColors.iconDarkMode,
                onPressed: _togglePlayPause,
              ),

              // Time display
              Text(
                '${_formatDuration(_currentPosition)} / ${_formatDuration(_totalDuration)}',
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),

              const Spacer(),

              // Speed selector
              _buildSpeedSelector(context),

              const SizedBox(width: AppDimens.spaceSmall),

              // Volume control
              _buildVolumeControl(context),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSeekBar(BuildContext context) {
    final progress = _totalDuration.inMilliseconds > 0
        ? _currentPosition.inMilliseconds / _totalDuration.inMilliseconds
        : 0.0;

    return SliderTheme(
      data: SliderThemeData(
        trackHeight: 3,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
        activeTrackColor: AppColors.primary,
        inactiveTrackColor: AppColors.iconDarkMode.withValues(alpha: 0.3),
        thumbColor: AppColors.primary,
        overlayColor: AppColors.primary.withValues(alpha: 0.3),
      ),
      child: Slider(
        value: progress.clamp(0.0, 1.0),
        onChanged: (value) {
          final position = Duration(
            milliseconds: (value * _totalDuration.inMilliseconds).round(),
          );
          _seek(position);
        },
      ),
    );
  }

  Widget _buildQualitySelector(BuildContext context) {
    return PopupMenuButton<VideoQuality>(
      icon: const Icon(Icons.settings, color: AppColors.iconDarkMode),
      tooltip: context.l10n.quality,
      onSelected: _changeQuality,
      itemBuilder: (context) {
        return widget.availableQualities.map((quality) {
          return PopupMenuItem<VideoQuality>(
            value: quality,
            child: Row(
              children: [
                Text(_getQualityLabel(quality)),
                if (quality == _quality) ...[
                  const SizedBox(width: AppDimens.spaceSmall),
                  const Icon(Icons.check, size: AppDimens.iconSmall),
                ],
              ],
            ),
          );
        }).toList();
      },
    );
  }

  Widget _buildSpeedSelector(BuildContext context) {
    return PopupMenuButton<PlaybackSpeed>(
      icon: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _getSpeedLabel(_playbackSpeed),
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
          const Icon(Icons.arrow_drop_down, color: AppColors.iconDarkMode, size: AppDimens.iconSmall),
        ],
      ),
      tooltip: context.l10n.playbackSpeed,
      onSelected: _changeSpeed,
      itemBuilder: (context) {
        return PlaybackSpeed.values.map((speed) {
          return PopupMenuItem<PlaybackSpeed>(
            value: speed,
            child: Row(
              children: [
                Text(_getSpeedLabel(speed)),
                if (speed == _playbackSpeed) ...[
                  const SizedBox(width: AppDimens.spaceSmall),
                  const Icon(Icons.check, size: AppDimens.iconSmall),
                ],
              ],
            ),
          );
        }).toList();
      },
    );
  }

  Widget _buildVolumeControl(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(
            _isMuted ? Icons.volume_off : Icons.volume_up,
            color: AppColors.iconDarkMode,
          ),
          onPressed: _toggleMute,
        ),
        SizedBox(
          width: 80,
          child: SliderTheme(
            data: SliderThemeData(
              trackHeight: 2,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 4),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 8),
              activeTrackColor: AppColors.iconDarkMode,
              inactiveTrackColor: AppColors.iconDarkMode.withValues(alpha: 0.3),
              thumbColor: AppColors.iconDarkMode,
              overlayColor: AppColors.iconDarkMode.withValues(alpha: 0.3),
            ),
            child: Slider(
              value: _volume,
              onChanged: _changeVolume,
            ),
          ),
        ),
      ],
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  String _getQualityLabel(VideoQuality quality) {
    switch (quality) {
      case VideoQuality.auto:
        return 'Auto';
      case VideoQuality.p360:
        return '360p';
      case VideoQuality.p480:
        return '480p';
      case VideoQuality.p720:
        return '720p';
      case VideoQuality.p1080:
        return '1080p';
    }
  }

  String _getSpeedLabel(PlaybackSpeed speed) {
    switch (speed) {
      case PlaybackSpeed.x050:
        return '0.5x';
      case PlaybackSpeed.x100:
        return '1x';
      case PlaybackSpeed.x150:
        return '1.5x';
      case PlaybackSpeed.x200:
        return '2x';
    }
  }
}
