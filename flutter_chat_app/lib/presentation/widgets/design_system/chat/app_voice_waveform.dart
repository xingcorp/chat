import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_chat_app/core/base/base_widget.dart';
import 'package:flutter_chat_app/core/constants/app_dimens.dart';
import 'package:flutter_chat_app/core/theme/app_text_styles.dart';
import 'package:flutter_chat_app/generated/l10n/app_localizations.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/chat/chat_enums.dart';

/// **APP VOICE WAVEFORM**
///
/// Audio waveform visualization with playback controls.
/// Extends [BaseStatefulWidget] for state management.
///
/// **Features**:
/// - Waveform rendering from audio data
/// - Playback controls (play/pause, seek)
/// - Progress indicator
/// - Speed control (1x, 1.5x, 2x, 0.5x)
/// - Duration display
/// - Loading and error states
/// - Dark mode support
/// - Accessibility labels
///
/// **Architecture**: Clean Architecture + Design System
/// **Pattern**: Stateful widget with custom painter
///
/// **Usage**:
/// ```dart
/// AppVoiceWaveform(
///   audioUrl: 'https://example.com/audio.mp3',
///   waveformData: [0.2, 0.5, 0.8, 0.3, 0.6, ...],
///   duration: Duration(seconds: 45),
///   onPlayPause: (isPlaying) => _handlePlayPause(isPlaying),
/// )
/// ```
class AppVoiceWaveform extends BaseStatefulWidget {
  /// Creates a voice waveform component.
  const AppVoiceWaveform({
    super.key,
    required this.audioUrl,
    this.waveformData = const [],
    this.duration,
    this.onPlayPause,
    this.onSeek,
    this.onSpeedChange,
    this.initialSpeed = AudioPlaybackSpeed.normal,
    this.showSpeedControl = true,
    this.height = 48.0,
  });

  /// Audio file URL
  final String audioUrl;

  /// Waveform amplitude data (0.0 to 1.0)
  final List<double> waveformData;

  /// Total audio duration
  final Duration? duration;

  /// Callback when play/pause is tapped
  final ValueChanged<bool>? onPlayPause;

  /// Callback when user seeks to a position
  final ValueChanged<Duration>? onSeek;

  /// Callback when playback speed changes
  final ValueChanged<AudioPlaybackSpeed>? onSpeedChange;

  /// Initial playback speed
  final AudioPlaybackSpeed initialSpeed;

  /// Whether to show speed control button
  final bool showSpeedControl;

  /// Height of the waveform
  final double height;

  @override
  AppVoiceWaveformState createState() => AppVoiceWaveformState();
}

class AppVoiceWaveformState extends BaseState<AppVoiceWaveform> {
  bool _isPlaying = false;
  Duration _currentPosition = Duration.zero;
  AudioPlaybackSpeed _currentSpeed = AudioPlaybackSpeed.normal;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _currentSpeed = widget.initialSpeed;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (_errorMessage != null) {
      return _buildErrorState(context, theme, l10n);
    }

    if (_isLoading) {
      return _buildLoadingState(context, theme);
    }

    return Container(
      height: widget.height,
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimens.paddingSmall,
        vertical: AppDimens.paddingXSmall,
      ),
      child: Row(
        children: [
          // Play/Pause button
          _buildPlayPauseButton(context, theme),
          const SizedBox(width: AppDimens.spaceSmall),

          // Waveform
          Expanded(
            child: _buildWaveform(context, theme, isDark),
          ),
          const SizedBox(width: AppDimens.spaceSmall),

          // Duration
          _buildDuration(context, theme, isDark),

          // Speed control
          if (widget.showSpeedControl) ...[
            const SizedBox(width: AppDimens.spaceSmall),
            _buildSpeedControl(context, theme, l10n),
          ],
        ],
      ),
    );
  }

  Widget _buildPlayPauseButton(BuildContext context, ThemeData theme) {
    final l10n = AppLocalizations.of(context);
    
    return Semantics(
      button: true,
      label: _isPlaying ? l10n.pause : l10n.play,
      child: InkWell(
        onTap: _handlePlayPause,
        borderRadius: BorderRadius.circular(AppDimens.radiusCircular),
        child: Container(
          width: AppDimens.touchTargetMin * 0.75,
          height: AppDimens.touchTargetMin * 0.75,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary,
            shape: BoxShape.circle,
          ),
          child: Icon(
            _isPlaying ? Icons.pause : Icons.play_arrow,
            color: theme.colorScheme.onPrimary,
            size: AppDimens.iconMedium,
          ),
        ),
      ),
    );
  }

  Widget _buildWaveform(BuildContext context, ThemeData theme, bool isDark) {
    final waveformColor = isDark
        ? theme.colorScheme.primary.withOpacity(0.7)
        : theme.colorScheme.primary;

    final progressColor = theme.colorScheme.primary;

    return GestureDetector(
      onTapDown: (details) => _handleSeek(details, context),
      child: CustomPaint(
        painter: _WaveformPainter(
          waveformData: widget.waveformData.isNotEmpty
              ? widget.waveformData
              : _generateDummyWaveform(),
          progress: _getProgress(),
          waveformColor: waveformColor,
          progressColor: progressColor,
        ),
        child: Container(),
      ),
    );
  }

  Widget _buildDuration(BuildContext context, ThemeData theme, bool isDark) {
    final currentText = _formatDuration(_currentPosition);
    final totalText = widget.duration != null
        ? _formatDuration(widget.duration!)
        : '--:--';

    return Text(
      '$currentText / $totalText',
      style: AppTextStyles.labelSmall.copyWith(
        color: theme.colorScheme.onSurface.withOpacity(isDark ? 0.7 : 0.6),
        fontSize: 11,
      ),
    );
  }

  Widget _buildSpeedControl(
    BuildContext context,
    ThemeData theme,
    AppLocalizations l10n,
  ) {
    return PopupMenuButton<AudioPlaybackSpeed>(
      icon: Icon(
        Icons.speed,
        size: AppDimens.iconSmall,
        color: theme.colorScheme.primary,
      ),
      tooltip: l10n.playbackSpeed,
      onSelected: (speed) {
        safeSetState(() {
          _currentSpeed = speed;
        });
        widget.onSpeedChange?.call(speed);
      },
      itemBuilder: (context) => [
        _buildSpeedMenuItem(AudioPlaybackSpeed.slow, '0.5x', l10n),
        _buildSpeedMenuItem(AudioPlaybackSpeed.normal, '1.0x', l10n),
        _buildSpeedMenuItem(AudioPlaybackSpeed.fast, '1.5x', l10n),
        _buildSpeedMenuItem(AudioPlaybackSpeed.faster, '2.0x', l10n),
      ],
    );
  }

  PopupMenuItem<AudioPlaybackSpeed> _buildSpeedMenuItem(
    AudioPlaybackSpeed speed,
    String label,
    AppLocalizations l10n,
  ) {
    return PopupMenuItem<AudioPlaybackSpeed>(
      value: speed,
      child: Row(
        children: [
          if (_currentSpeed == speed)
            const Icon(Icons.check, size: AppDimens.iconSmall)
          else
            const SizedBox(width: AppDimens.iconSmall),
          const SizedBox(width: AppDimens.spaceSmall),
          Text(label),
        ],
      ),
    );
  }

  Widget _buildLoadingState(BuildContext context, ThemeData theme) {
    final l10n = AppLocalizations.of(context);
    
    return Container(
      height: widget.height,
      alignment: Alignment.center,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: AppDimens.iconSmall,
            height: AppDimens.iconSmall,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                theme.colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(width: AppDimens.spaceSmall),
          Text(
            l10n.loadingAudio,
            style: AppTextStyles.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(
    BuildContext context,
    ThemeData theme,
    AppLocalizations l10n,
  ) {
    return Container(
      height: widget.height,
      alignment: Alignment.center,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.error_outline,
            size: AppDimens.iconSmall,
            color: theme.colorScheme.error,
          ),
          const SizedBox(width: AppDimens.spaceSmall),
          Text(
            _errorMessage ?? l10n.errorOccurred,
            style: AppTextStyles.bodySmall.copyWith(
              color: theme.colorScheme.error,
            ),
          ),
        ],
      ),
    );
  }

  void _handlePlayPause() {
    safeSetState(() {
      _isPlaying = !_isPlaying;
    });
    widget.onPlayPause?.call(_isPlaying);
  }

  void _handleSeek(TapDownDetails details, BuildContext context) {
    if (widget.duration == null) return;

    final RenderBox box = context.findRenderObject() as RenderBox;
    final localPosition = box.globalToLocal(details.globalPosition);
    final progress = (localPosition.dx / box.size.width).clamp(0.0, 1.0);
    final seekPosition = widget.duration! * progress;

    safeSetState(() {
      _currentPosition = seekPosition;
    });

    widget.onSeek?.call(seekPosition);
  }

  double _getProgress() {
    if (widget.duration == null || widget.duration!.inMilliseconds == 0) {
      return 0.0;
    }
    return _currentPosition.inMilliseconds / widget.duration!.inMilliseconds;
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  List<double> _generateDummyWaveform() {
    // Generate dummy waveform data for demo purposes
    return List.generate(50, (index) {
      return 0.2 + (index % 5) * 0.15;
    });
  }

  /// Update current position (called from parent when audio position changes)
  void updatePosition(Duration position) {
    if (mounted) {
      safeSetState(() {
        _currentPosition = position;
      });
    }
  }

  /// Update playing state (called from parent when audio state changes)
  void updatePlayingState(bool isPlaying) {
    if (mounted) {
      safeSetState(() {
        _isPlaying = isPlaying;
      });
    }
  }
}

/// Custom painter for waveform visualization
class _WaveformPainter extends CustomPainter {
  _WaveformPainter({
    required this.waveformData,
    required this.progress,
    required this.waveformColor,
    required this.progressColor,
  });

  final List<double> waveformData;
  final double progress;
  final Color waveformColor;
  final Color progressColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (waveformData.isEmpty) return;

    final barWidth = size.width / waveformData.length;
    final barSpacing = barWidth * 0.3;
    final actualBarWidth = barWidth - barSpacing;

    for (int i = 0; i < waveformData.length; i++) {
      final amplitude = waveformData[i].clamp(0.0, 1.0);
      final barHeight = size.height * amplitude;
      final x = i * barWidth;
      final y = (size.height - barHeight) / 2;

      // Determine color based on progress
      final barProgress = (i + 1) / waveformData.length;
      final color = barProgress <= progress ? progressColor : waveformColor;

      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;

      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y, actualBarWidth, barHeight),
        const Radius.circular(2),
      );

      canvas.drawRRect(rect, paint);
    }
  }

  @override
  bool shouldRepaint(_WaveformPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.waveformData != waveformData ||
        oldDelegate.waveformColor != waveformColor ||
        oldDelegate.progressColor != progressColor;
  }
}
