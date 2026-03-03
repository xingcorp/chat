import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_chat_app/core/base/base_widget.dart';
import 'package:flutter_chat_app/core/constants/app_dimens.dart';
import 'package:flutter_chat_app/core/services/voice_note_playback_manager.dart';
import 'package:flutter_chat_app/core/theme/app_colors.dart';
import 'package:flutter_chat_app/core/theme/app_text_styles.dart';
import 'package:flutter_chat_app/l10n/l10n.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/buttons/app_icon_button.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/buttons/button_enums.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/typography/app_text.dart';
import 'package:get_it/get_it.dart';

class VoiceNotePlayerWidget extends BaseStatefulWidget {
  const VoiceNotePlayerWidget({
    super.key,
    required this.messageId,
    required this.audioUrl,
    this.duration,
    this.isCurrentUser = false,
    this.isFailed = false,
    this.onRetry,
  });

  final String messageId;
  final String audioUrl;
  final Duration? duration;
  final bool isCurrentUser;
  final bool isFailed;
  final VoidCallback? onRetry;

  @override
  State<VoiceNotePlayerWidget> createState() => _VoiceNotePlayerWidgetState();
}

class _VoiceNotePlayerWidgetState extends BaseState<VoiceNotePlayerWidget> {
  late final VoiceNotePlaybackManager _playbackManager;
  late final List<double> _waveformPattern;

  bool _isTogglingPlayback = false;

  @override
  void initState() {
    super.initState();
    _playbackManager = GetIt.I<VoiceNotePlaybackManager>();
    _waveformPattern = _buildWaveformPattern(widget.messageId);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<VoiceNotePlaybackState>(
      stream: _playbackManager.getPlaybackStream(widget.messageId),
      initialData:
          VoiceNotePlaybackState(duration: widget.duration ?? Duration.zero),
      builder: (context, snapshot) {
        final state = snapshot.data ?? const VoiceNotePlaybackState();
        final resolvedDuration = state.duration > Duration.zero
            ? state.duration
            : (widget.duration ?? Duration.zero);
        final progress = resolvedDuration.inMilliseconds <= 0
            ? 0.0
            : (state.position.inMilliseconds / resolvedDuration.inMilliseconds)
                .clamp(0.0, 1.0);

        final activeColor = widget.isCurrentUser
            ? AppColors.textPrimaryDarkMode
            : AppColors.primary;
        final inactiveColor = widget.isCurrentUser
            ? AppColors.textPrimaryDarkMode.withValues(alpha: 0.28)
            : AppColors.border;
        final timestampColor = widget.isCurrentUser
            ? AppColors.textPrimaryDarkMode.withValues(alpha: 0.82)
            : AppColors.textSecondary;

        return Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimens.paddingSmall,
            vertical: AppDimens.paddingXSmall,
          ),
          child: Row(
            children: [
              AppIconButton(
                icon: state.isPlaying
                    ? Icons.pause_rounded
                    : Icons.play_arrow_rounded,
                onPressed: _isTogglingPlayback || widget.audioUrl.isEmpty
                    ? null
                    : () => _togglePlayback(state),
                size: ButtonSize.small,
                tooltip:
                    state.isPlaying ? context.l10n.pause : context.l10n.play,
              ),
              const SizedBox(width: AppDimens.spaceSmall),
              Expanded(
                child: SizedBox(
                  height: AppDimens.iconMedium,
                  child: CustomPaint(
                    painter: _VoiceWaveformPainter(
                      bars: _waveformPattern,
                      progress: progress,
                      activeColor: activeColor,
                      inactiveColor: inactiveColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppDimens.spaceSmall),
              AppText(
                _formatDuration(
                  state.isPlaying ? state.position : resolvedDuration,
                ),
                style: AppTextStyles.labelSmall.copyWith(color: timestampColor),
              ),
              if (widget.isFailed && widget.onRetry != null) ...[
                const SizedBox(width: AppDimens.spaceXSmall),
                AppIconButton(
                  icon: Icons.refresh_rounded,
                  onPressed: widget.onRetry,
                  size: ButtonSize.small,
                  tooltip: context.l10n.retryUpload,
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Future<void> _togglePlayback(VoiceNotePlaybackState state) async {
    safeSetState(() => _isTogglingPlayback = true);
    try {
      if (state.isPlaying) {
        await _playbackManager.pause();
      } else {
        await _playbackManager.play(widget.messageId, widget.audioUrl);
      }
    } finally {
      if (mounted) {
        safeSetState(() => _isTogglingPlayback = false);
      }
    }
  }

  List<double> _buildWaveformPattern(String seed) {
    final random = Random(seed.hashCode);
    return List<double>.generate(26, (index) {
      final base = 0.24 + (random.nextDouble() * 0.7);
      final curve = sin((index / 26) * pi * 2).abs() * 0.22;
      return (base + curve).clamp(0.12, 1.0);
    });
  }

  String _formatDuration(Duration duration) {
    final totalSeconds = duration.inSeconds < 0 ? 0 : duration.inSeconds;
    final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}

class _VoiceWaveformPainter extends CustomPainter {
  const _VoiceWaveformPainter({
    required this.bars,
    required this.progress,
    required this.activeColor,
    required this.inactiveColor,
  });

  final List<double> bars;
  final double progress;
  final Color activeColor;
  final Color inactiveColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (bars.isEmpty || size.width <= 0 || size.height <= 0) return;

    final barCount = bars.length;
    const spacing = AppDimens.spaceXSmall * 0.6;
    final totalSpacing = spacing * (barCount - 1);
    final barWidth = (size.width - totalSpacing) / barCount;
    const radius = Radius.circular(AppDimens.radiusSmall);

    for (var i = 0; i < barCount; i++) {
      final amplitude = bars[i];
      final barHeight = max(2.0, size.height * amplitude);
      final top = (size.height - barHeight) / 2;
      final left = i * (barWidth + spacing);
      final right = left + barWidth;
      final color =
          ((i + 1) / barCount) <= progress ? activeColor : inactiveColor;

      final rect = RRect.fromRectAndRadius(
        Rect.fromLTRB(left, top, right, top + barHeight),
        radius,
      );
      final paint = Paint()..color = color;
      canvas.drawRRect(rect, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _VoiceWaveformPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.activeColor != activeColor ||
        oldDelegate.inactiveColor != inactiveColor ||
        oldDelegate.bars != bars;
  }
}
