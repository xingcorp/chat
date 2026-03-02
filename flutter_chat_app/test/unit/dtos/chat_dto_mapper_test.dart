import 'package:flutter_chat_app/data/dtos/chat_dto.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('maps sticker last message to sticker preview label', () {
    final dto = ChatDto.fromJson(<String, dynamic>{
      'id': 'chat_1',
      'name': 'Team',
      'type': 'group',
      'createdAt': 1700000000000,
      'lastMessageAt': 1700000000000,
      'lastMessage': <String, dynamic>{
        'id': 'msg_1',
        'type': 'STICKER',
        'message': 'animal_friends_cat_happy',
      },
      'members': <dynamic>[],
    });

    final chat = dto.toDomain();

    expect(chat.lastMessagePreview, '🎯 Sticker');
  });
}
