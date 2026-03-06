import 'package:flutter_chat_app/data/dtos/chat_dto.dart';
import 'package:flutter_chat_app/shared/domain/entities/chat.dart';
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

  test('prioritizes user statusActive/offlineAt for member presence mapping',
      () {
    final dto = ChatDto.fromJson(<String, dynamic>{
      'id': 'chat_2',
      'name': 'Direct',
      'type': 'direct',
      'createdAt': 1700000000000,
      'members': <dynamic>[
        <String, dynamic>{
          'id': 'mem_1',
          'userId': 'user_1',
          'connected': false,
          'viewMessagesFrom': 1700000000000,
          'user': <String, dynamic>{
            'id': 'user_1',
            'fullname': 'User One',
            'statusActive': 'online',
            'offlineAt': 1705000000000,
            'imageUrls': <String>[],
          },
        },
      ],
    });

    final chat = dto.toDomain();
    final member = chat.members.first;

    expect(member.isConnected, isTrue);
    expect(
      member.viewMessagesFrom,
      DateTime.fromMillisecondsSinceEpoch(1705000000000),
    );
  });

  test('maps description, group type and creator metadata for group chats', () {
    final dto = ChatDto.fromJson(<String, dynamic>{
      'id': 'chat_3',
      'name': 'Platform Guild',
      'type': 'group',
      'description': 'Architecture decisions',
      'groupType': 'Public',
      'createdAt': 1700000000000,
      'creator': <String, dynamic>{
        'id': 'user_admin',
        'fullname': 'Tech Lead',
        'imageUrls': <String>[],
      },
      'members': <dynamic>[
        <String, dynamic>{
          'id': 'member_1',
          'userId': 'user_admin',
          'admin': true,
          'user': <String, dynamic>{
            'id': 'user_admin',
            'fullname': 'Tech Lead',
            'imageUrls': <String>[],
            'departments': <dynamic>[],
          },
        },
      ],
    });

    final chat = dto.toDomain();

    expect(chat.description, 'Architecture decisions');
    expect(chat.groupType, GroupType.public);
    expect(chat.creatorId, 'user_admin');
    expect(chat.creatorName, 'Tech Lead');
  });
}
