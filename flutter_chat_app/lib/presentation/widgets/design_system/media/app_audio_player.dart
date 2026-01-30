library;

/// **APP AUDIO PLAYER**
///
/// Audio player component with playback controls and progress tracking.
/// Extends [BaseStatefulWidget] for lifecycle management.
///
/// **Features**:
/// - Play/pause controls
/// - Progress bar with seek
/// - Current time and duration display
/// - Volume control
/// - Playback speed control (0.5x, 1x, 1.5x, 2x)
/// - Loop toggle
/// - Loading and error states
/// - Dark mode support
/// - Accessibility labels
///
/// **Architecture**: Clean Architecture + Design System
/// **Pattern**: Stateful widget with audio playback management
///
/// **Usage**:
/// ```dart
/// AppAudioPlayer(
///   audioUrl: 'https://example.com/audio.mp3',
///   autoPlay: false,
///   showVolumeControl: true,
///   onError: (error) => print('Error: $error'),
/// )
/// ```

import 'package:flutter/material.dart';
import 'package:flutter_chat_app/core/base/base_widget.dart';
import 'package:flutter_chat_app/core/constants/app_dimens.dart';
import 'package:flutter_chat_app/core/theme/app_colors.dart';
import 'package:flutter_chat_app/core/theme/app_text_styles.dart';
import 'package:flutter_chat_app/l10n/l10n.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/buttons/app_button.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/buttons/button_enums.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/media/media_enums.dart';

/// App Audio Player widget
class AppAudioPlayer extends BaseStatefulWidget {
  const AppAudioPlayer({
    super.key,
    required this.audioUrl,
    this.title,
    this.artist,
    this.albumArt,
    this.autoPlay = false,
    this.loop = false,
    this.showVolumeControl = true,
    this.showSpeedControl = true,
    this.initialVolume = 1.0,
    this.initialSpeed = PlaybackSpeed.x100,
    this.onPlaybackComplete,
    this.onPositionChanged,
    this.onError,
  });

  /// URL of the audio file
  final String audioUrl;

  /// Audio title (optional)
  final String? title;

  /// Artist name (optional)
  final String? artist;

  /// Album art URL (optional)
  final String? albumArt;

  /// Whether to start playing automatically
  final bool autoPlay;

  /// Whether to loop the audio
  final bool loop;

  /// Whether to show volume control
  final bool showVolumeControl;

  /// Whether to show playback speed control
  final bool showSpeedControl;

  /// Initial volume (0.0 to 1.0)
  final double initialVolume;

  /// Initial playback speed
  final PlaybackSpeed initialSpeed;

  /// Callback when playback completes
  final VoidCallback? onPlaybackComplete;

  /// Callback when playback position changes
  final ValueChanged<Duration>? onPositionChanged;

  /// Callback when error occurs
  final ValueChanged<String>? onError;

  @override
  AppAudioPlayerState createState() => AppAudioPlayerState();
}

class AppAudioPlayerState extends BaseState<AppAudioPlayer> {
  bool _isPlaying = false;
  bool _isLoading = false;
  bool _hasError = false;
  String? _errorMessage;
  bool _isLooping = false;

  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;
  double _volume = 1.0;
  PlaybackSpeed _playbackSpeed = PlaybackSpeed.x100;

  @override
  void initState() {
    super.initState();
    _volume = widget.initialVolume;
    _playbackSpeed = widget.initialSpeed;
    _isLooping = widget.loop;

    if (widget.autoPlay) {
      _loadAndPlay();
    } else {
      _loadAudio();
    }
  }

  Future<void> _loadAudio() async {
    safeSetState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      // Simulate loading delay
      await Future.delayed(const Duration(seconds: 1));

      // In real implementation, initialize audio player here
      safeSetState(() {
        _isLoading = false;
        _totalDuration = const Duration(minutes: 3, seconds: 45); // Mock duration
      });
    } catch (e) {
      safeSetState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = e.toString();
      });
      widget.onError?.call(e.toString());
    }
  }

  Future<void> _loadAndPlay() async {
    await _loadAudio();
    if (!_hasError) {
      _play();
    }
  }

  void _play() {
    safeSetState(() {
      _isPlaying = true;
    });
    // In real implementation, start audio playback
  }

  void _pause() {
    safeSetState(() {
      _isPlaying = false;
    });
    // In real implementation, pause audio playback
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
    // In real implementation, seek audio to position
  }

  void _changeVolume(double volume) {
    safeSetState(() {
      _volume = volume;
    });
    // In real implementation, change audio volume
  }

  void _changeSpeed(PlaybackSpeed speed) {
    safeSetState(() {
      _playbackSpeed = speed;
    });
    // In real implementation, change playback speed
  }

  void _toggleLoop() {
    safeSetState(() {
      _isLooping = !_isLooping;
    });
    // In real implementation, toggle loop mode
  }

  void _retry() {
    _loadAndPlay();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(AppDimens.paddingMedium),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDarkMode : AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimens.radiusCard),
        border: Border.all(
          color: isDark ? AppColors.borderDarkMode : AppColors.border,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Album art and info
          if (widget.albumArt != null || widget.title != null)
            _buildHeader(context, isDark),

          // Error state
          if (_hasError)
            _buildErrorState(context, isDark)
          else ...[
            // Progress bar
            _buildProgressBar(context, isDark),

            const SizedBox(height: AppDimens.spaceSmall),

            // Time display
            _buildTimeDisplay(context, isDark),

            const SizedBox(height: AppDimens.spaceMedium),

            // Playback controls
            _buildPlaybackControls(context, isDark),

            // Additional controls
            if (widget.showVolumeControl || widget.showSpeedControl) ...[
              const SizedBox(height: AppDimens.spaceMedium),
              _buildAdditionalControls(context, isDark),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimens.paddingMedium),
      child: Row(
        children: [
          // Album art
          if (widget.albumArt != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(AppDimens.radiusSmall),
              child: Image.network(
                widget.albumArt!,
                width: AppDimens.iconXXLarge,
                height: AppDimens.iconXXLarge,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: AppDimens.iconXXLarge,
                    height: AppDimens.iconXXLarge,
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.backgroundDarkMode : AppColors.background,
                      borderRadius: BorderRadius.circular(AppDimens.radiusSmall),
                    ),
                    child: Icon(
                      Icons.music_note,
                      size: AppDimens.iconLarge,
                      color: isDark ? AppColors.iconDarkMode : AppColors.icon,
                    ),
                  );
                },
              ),
            ),

          if (widget.albumArt != null) const SizedBox(width: AppDimens.spaceMedium),

          // Title and artist
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.title != null)
                  Text(
                    widget.title!,
                    style: AppTextStyles.titleMedium.copyWith(
                      color: isDark ? AppColors.textPrimaryDarkMode : AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                if (widget.artist != null) ...[
                  const SizedBox(height: AppDimens.spaceXSmall),
                  Text(
                    widget.artist!,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: isDark ? AppColors.textSecondaryDarkMode : AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar(BuildContext context, bool isDark) {
    final progress = _totalDuration.inMilliseconds > 0
        ? _currentPosition.inMilliseconds / _totalDuration.inMilliseconds
        : 0.0;

    return SliderTheme(
      data: SliderThemeData(
        trackHeight: 4,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
        activeTrackColor: AppColors.primary,
        inactiveTrackColor: isDark 
            ? AppColors.borderDarkMode 
            : AppColors.border,
        thumbColor: AppColors.primary,
        overlayColor: AppColors.primary.withValues(alpha: 0.3),
      ),
      child: Slider(
        value: progress.clamp(0.0, 1.0),
        onChanged: _isLoading
            ? null
            : (value) {
                final position = Duration(
                  milliseconds: (value * _totalDuration.inMilliseconds).round(),
                );
                _seek(position);
              },
      ),
    );
  }

  Widget _buildTimeDisplay(BuildContext context, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          _formatDuration(_currentPosition),
          style: AppTextStyles.bodySmall.copyWith(
            color: isDark ? AppColors.textSecondaryDarkMode : AppColors.textSecondary,
          ),
        ),
        Text(
          _formatDuration(_totalDuration),
          style: AppTextStyles.bodySmall.copyWith(
            color: isDark ? AppColors.textSecondaryDarkMode : AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildPlaybackControls(BuildContext context, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Loop button
        IconButton(
          icon: Icon(
            _isLooping ? Icons.repeat_one : Icons.repeat,
            color: _isLooping 
                ? AppColors.primary 
                : (isDark ? AppColors.iconDarkMode : AppColors.icon),
          ),
          onPressed: _toggleLoop,
          tooltip: context.l10n.loop,
        ),

        const SizedBox(width: AppDimens.spaceMedium),

        // Rewind 10s
        IconButton(
          icon: Icon(
            Icons.replay_10,
            color: isDark ? AppColors.iconDarkMode : AppColors.icon,
          ),
          onPressed: _isLoading
              ? null
              : () {
                  final newPosition = _currentPosition - const Duration(seconds: 10);
                  _seek(newPosition.isNegative ? Duration.zero : newPosition);
                },
          tooltip: context.l10n.rewind10Seconds,
        ),

        const SizedBox(width: AppDimens.spaceSmall),

        // Play/Pause button
        Container(
          decoration: const BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
          ),
          child: _isLoading
              ? const Padding(
                  padding: EdgeInsets.all(AppDimens.paddingSmall),
                  child: SizedBox(
                    width: AppDimens.iconLarge,
                    height: AppDimens.iconLarge,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.textPrimaryDarkMode,
                      ),
                    ),
                  ),
                )
              : IconButton(
                  icon: Icon(
                    _isPlaying ? Icons.pause : Icons.play_arrow,
                    color: AppColors.textPrimaryDarkMode,
                    size: AppDimens.iconLarge,
                  ),
                  onPressed: _togglePlayPause,
                  tooltip: _isPlaying ? context.l10n.pause : context.l10n.play,
                ),
        ),

        const SizedBox(width: AppDimens.spaceSmall),

        // Forward 10s
        IconButton(
          icon: Icon(
            Icons.forward_10,
            color: isDark ? AppColors.iconDarkMode : AppColors.icon,
          ),
          onPressed: _isLoading
              ? null
              : () {
                  final newPosition = _currentPosition + const Duration(seconds: 10);
                  _seek(newPosition > _totalDuration ? _totalDuration : newPosition);
                },
          tooltip: context.l10n.forward10Seconds,
        ),

        const SizedBox(width: AppDimens.spaceMedium),

        // Speed control button
        if (widget.showSpeedControl)
          PopupMenuButton<PlaybackSpeed>(
            icon: Icon(
              Icons.speed,
              color: isDark ? AppColors.iconDarkMode : AppColors.icon,
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
          ),
      ],
    );
  }

  Widget _buildAdditionalControls(BuildContext context, bool isDark) {
    return Row(
      children: [
        // Volume control
        if (widget.showVolumeControl) ...[
          Icon(
            _volume == 0 ? Icons.volume_off : Icons.volume_up,
            size: AppDimens.iconMedium,
            color: isDark ? AppColors.iconDarkMode : AppColors.icon,
          ),
          Expanded(
            child: SliderTheme(
              data: SliderThemeData(
                trackHeight: 2,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 4),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 8),
                activeTrackColor: AppColors.primary,
                inactiveTrackColor: isDark 
                    ? AppColors.borderDarkMode 
                    : AppColors.border,
                thumbColor: AppColors.primary,
                overlayColor: AppColors.primary.withValues(alpha: 0.3),
              ),
              child: Slider(
                value: _volume,
                onChanged: _changeVolume,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildErrorState(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppDimens.paddingLarge),
      child: Column(
        children: [
          Icon(
            Icons.error_outline,
            size: AppDimens.iconXLarge,
            color: AppColors.error,
          ),
          const SizedBox(height: AppDimens.spaceMedium),
          Text(
            _errorMessage ?? context.l10n.errorLoadingAudio,
            style: AppTextStyles.bodyMedium.copyWith(
              color: isDark ? AppColors.textPrimaryDarkMode : AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppDimens.spaceMedium),
          AppButton.primary(
            text: context.l10n.retry,
            onPressed: _retry,
            size: ButtonSize.small,
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  String _getSpeedLabel(PlaybackSpeed speed) {
    switch (speed) {
      case PlaybackSpeed.x025:
        return '0.25x';
      case PlaybackSpeed.x050:
        return '0.5x';
      case PlaybackSpeed.x075:
        return '0.75x';
      case PlaybackSpeed.x100:
        return '1x';
      case PlaybackSpeed.x125:
        return '1.25x';
      case PlaybackSpeed.x150:
        return '1.5x';
      case PlaybackSpeed.x175:
        return '1.75x';
      case PlaybackSpeed.x200:
        return '2x';
    }
  }
}
