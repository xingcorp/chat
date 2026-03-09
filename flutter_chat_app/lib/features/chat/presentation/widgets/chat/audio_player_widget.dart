import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_chat_app/core/services/audio/chat_audio_player_factory.dart';
import 'package:flutter_chat_app/core/services/audio/i_chat_audio_player.dart';

/// Inline audio player widget for chat message bubbles.
///
/// Uses [IChatAudioPlayer] abstraction so the correct backend is selected per
/// platform: `just_audio` on mobile/macOS/Linux, `audioplayers` on Windows.
class AudioPlayerWidget extends StatefulWidget {
  final String url;
  final bool isFromCurrentUser;

  const AudioPlayerWidget({
    Key? key,
    required this.url,
    this.isFromCurrentUser = false,
  }) : super(key: key);

  @override
  State<AudioPlayerWidget> createState() => _AudioPlayerWidgetState();
}

class _AudioPlayerWidgetState extends State<AudioPlayerWidget> {
  late final IChatAudioPlayer _player;
  bool _isLoading = true;
  bool _hasError = false;
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  final List<StreamSubscription<dynamic>> _subs = <StreamSubscription<dynamic>>[];

  @override
  void initState() {
    super.initState();
    _player = createChatAudioPlayer();
    _initPlayer();
  }

  Future<void> _initPlayer() async {
    try {
      final duration = await _player.setSource(widget.url);
      if (mounted) {
        setState(() {
          _duration = duration ?? Duration.zero;
          _isLoading = false;
        });
      }

      _subs.add(_player.positionStream.listen((position) {
        if (mounted) setState(() => _position = position);
      }));

      _subs.add(_player.durationStream.listen((duration) {
        if (mounted && duration != null && duration > Duration.zero) {
          setState(() => _duration = duration);
        }
      }));

      _subs.add(_player.playerStateStream.listen((state) {
        if (!mounted) return;
        setState(() => _isPlaying = state.isPlaying);
        if (state.isCompleted) {
          _player.seek(Duration.zero);
          _player.pause();
        }
      }));
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    for (final sub in _subs) {
      sub.cancel();
    }
    _player.dispose();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final iconColor = widget.isFromCurrentUser ? Colors.white : theme.colorScheme.primary;
    final sliderColor = widget.isFromCurrentUser ? Colors.white70 : theme.colorScheme.primary;
    final textColor = widget.isFromCurrentUser
        ? Colors.white.withValues(alpha: 0.8)
        : theme.textTheme.bodySmall?.color;

    if (_hasError) {
      return Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, color: Colors.red[300], size: 20),
            const SizedBox(width: 8),
            Text('Error loading audio', style: TextStyle(color: textColor, fontSize: 12)),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Play/Pause button
          _isLoading
              ? SizedBox(
                  width: 36,
                  height: 36,
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: CircularProgressIndicator(strokeWidth: 2, color: iconColor),
                  ),
                )
              : IconButton(
                  icon: Icon(_isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled),
                  iconSize: 36,
                  color: iconColor,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () {
                    if (_isPlaying) {
                      _player.pause();
                    } else {
                      _player.play();
                    }
                  },
                ),
          const SizedBox(width: 8),
          // Slider + time
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SliderTheme(
                  data: SliderThemeData(
                    trackHeight: 3,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                    activeTrackColor: sliderColor,
                    inactiveTrackColor: sliderColor.withValues(alpha: 0.3),
                    thumbColor: sliderColor,
                  ),
                  child: Slider(
                    value: _duration.inMilliseconds > 0
                        ? _position.inMilliseconds.toDouble().clamp(0, _duration.inMilliseconds.toDouble())
                        : 0,
                    max: _duration.inMilliseconds > 0 ? _duration.inMilliseconds.toDouble() : 1,
                    onChanged: (value) {
                      _player.seek(Duration(milliseconds: value.toInt()));
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    _isLoading
                        ? '--:--'
                        : '${_formatDuration(_position)} / ${_formatDuration(_duration)}',
                    style: TextStyle(fontSize: 10, color: textColor),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
