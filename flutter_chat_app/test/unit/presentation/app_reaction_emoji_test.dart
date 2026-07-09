import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AppReactionEmoji Assets Validation', () {
    test('Verify all 24 mapped 3D WebP assets exist on disk', () {
      final emojiMap = {
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

      for (final entry in emojiMap.entries) {
        final emoji = entry.key;
        final file = File(entry.value);
        expect(
          file.existsSync(),
          isTrue,
          reason: 'Asset file for emoji "$emoji" does not exist at path: ${entry.value}',
        );
      }
    });
  });
}
