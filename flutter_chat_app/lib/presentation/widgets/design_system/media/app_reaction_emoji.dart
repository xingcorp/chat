import 'package:flutter/material.dart';

/// Design system component to render high-quality 3D reaction emojis.
///
/// Maps common unicode emoji strings to Microsoft 3D Fluent UI Emoji assets
/// in high-efficiency WebP format, falling back to system emojis automatically.
class AppReactionEmoji extends StatelessWidget {
  /// The emoji string to render (e.g. '👍', '❤️')
  final String emoji;

  /// Width/height size of the emoji image
  final double size;

  const AppReactionEmoji({
    Key? key,
    required this.emoji,
    this.size = 24.0,
  }) : super(key: key);

  static final Map<String, String> _emojiAssets = {
    '👍': 'assets/images/reactions/thumbs_up_3d.webp',
    '❤️': 'assets/images/reactions/red_heart_3d.webp',
    '😂': 'assets/images/reactions/face_with_tears_of_joy_3d.webp',
    '😮': 'assets/images/reactions/astonished_face_3d.webp',
    '😢': 'assets/images/reactions/crying_face_3d.webp',
    '😡': 'assets/images/reactions/enraged_face_3d.webp',
    '🎉': 'assets/images/reactions/party_popper_3d.webp',
    '🔥': 'assets/images/reactions/fire_3d.webp',
    '👏': 'assets/images/reactions/clapping_hands_3d.webp',
    '🙏': 'assets/images/reactions/folded_hands_3d.webp',
    '🤔': 'assets/images/reactions/thinking_face_3d.webp',
    '🥳': 'assets/images/reactions/partying_face_3d.webp',
    '😎': 'assets/images/reactions/smiling_face_with_sunglasses_3d.webp',
    '👀': 'assets/images/reactions/eyes_3d.webp',
    '💯': 'assets/images/reactions/hundred_points_3d.webp',
    '🤩': 'assets/images/reactions/star_struck_3d.webp',
    '😍': 'assets/images/reactions/smiling_face_with_heart_eyes_3d.webp',
    '🤭': 'assets/images/reactions/face_with_hand_over_mouth_3d.webp',
    '😱': 'assets/images/reactions/face_screaming_in_fear_3d.webp',
    '🤯': 'assets/images/reactions/exploding_head_3d.webp',
    '🤫': 'assets/images/reactions/shushing_face_3d.webp',
    '🤤': 'assets/images/reactions/drooling_face_3d.webp',
    '💩': 'assets/images/reactions/pile_of_poo_3d.webp',
    '💡': 'assets/images/reactions/light_bulb_3d.webp',
  };

  @override
  Widget build(BuildContext context) {
    final assetPath = _emojiAssets[emoji];
    if (assetPath != null) {
      return Image.asset(
        assetPath,
        width: size,
        height: size,
        fit: BoxFit.contain,
        package: 'flutter_chat_app',
        errorBuilder: (context, error, stackTrace) => Text(
          emoji,
          style: TextStyle(
            fontSize: size * 0.8,
          ),
        ),
      );
    }
    return Text(
      emoji,
      style: TextStyle(fontSize: size * 0.8),
    );
  }
}
