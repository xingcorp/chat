import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_chat_app/data/dtos/message_dto.dart';
import 'package:flutter_chat_app/features/chat/presentation/models/message_list_transformer.dart';
import 'package:flutter_chat_app/shared/domain/entities/chat_message.dart';

void main() {
  group('Reaction Data Flow Test', () {
    test('DTO should parse reactions from backend response', () {
      // Mock backend GraphQL response
      final mockResponse = {
        'id': 'msg-123',
        'message': 'Hello World',
        'urls': [],
        'type': 'TEXT',
        'createdAt': 1707724800000,
        'senderId': 'user-1',
        'conversationId': 'conv-1',
        'readerIds': [],
        'reactions': [
          {
            'code': '👍',
            'reactorIds': ['user-2', 'user-3'],
            'reactors': [
              {'fullname': 'User Two', 'imageUrls': []},
              {'fullname': 'User Three', 'imageUrls': []},
            ]
          },
          {
            'code': '❤️',
            'reactorIds': ['user-1'],
            'reactors': [
              {'fullname': 'Current User', 'imageUrls': []},
            ]
          },
        ],
        'mentionTo': [],
      };

      // Parse DTO
      final dto = MessageDto.fromJson(mockResponse);

      // Verify DTO parsed reactions correctly
      expect(dto.reactions, hasLength(2));
      expect(dto.reactions[0].code, '👍');
      expect(dto.reactions[0].reactorIds, ['user-2', 'user-3']);
      expect(dto.reactions[1].code, '❤️');
      expect(dto.reactions[1].reactorIds, ['user-1']);
    });

    test('Entity should convert reactions from DTO', () {
      // Create DTO with reactions
      final dto = MessageDto(
        id: 'msg-123',
        content: 'Test message',
        urls: [],
        type: 'TEXT',
        createdAt: 1707724800000,
        senderId: 'user-1',
        chatId: 'conv-1',
        readerIds: [],
        reactions: [
          ReactionDto(
            code: '👍',
            reactorIds: ['user-2', 'user-3'],
            reactors: [
              UserReactionDto(fullName: 'User Two', imageUrls: []),
              UserReactionDto(fullName: 'User Three', imageUrls: []),
            ],
          ),
          ReactionDto(
            code: '❤️',
            reactorIds: ['user-1'],
            reactors: [
              UserReactionDto(fullName: 'Current User', imageUrls: []),
            ],
          ),
        ],
        mentionTo: [],
      );

      // Convert to domain entity
      final entity = dto.toDomain();

      // Verify entity has reactions
      expect(entity.reactions, hasLength(2));
      expect(entity.reactions[0].code, '👍');
      expect(entity.reactions[0].userId, 'user-2');
      expect(entity.reactions[0].userName, 'User Two');
      expect(entity.reactions[1].code, '❤️');
      expect(entity.reactions[1].userId, 'user-1');
    });

    test('MessageListTransformer should group reactions correctly', () {
      // Create message with reactions
      final message = ChatMessage(
        id: 'msg-123',
        chatId: 'conv-1',
        content: 'Test',
        contentType: ContentType.text,
        sender: MessageSender(id: 'user-1', name: 'User One'),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        reactions: [
          MessageReaction(
            code: '👍',
            userId: 'user-2',
            userName: 'User Two',
          ),
          MessageReaction(
            code: '👍',
            userId: 'user-3',
            userName: 'User Three',
          ),
          MessageReaction(
            code: '❤️',
            userId: 'user-1',
            userName: 'Current User',
          ),
        ],
      );

      // Transform to UI state
      final uiStates = MessageListTransformer.transform(
        messages: [message],
        currentUserId: 'user-1',
      );

      // Verify grouped reactions
      expect(uiStates, hasLength(1));
      final uiState = uiStates.first;

      expect(uiState.groupedReactions, hasLength(2));

      // Verify 👍 reaction (2 users)
      final thumbsUp = uiState.groupedReactions.firstWhere((r) => r.code == '👍');
      expect(thumbsUp.reactorIds, hasLength(2));
      expect(thumbsUp.reactorIds, containsAll(['user-2', 'user-3']));
      expect(thumbsUp.isReactedByCurrentUser, false);

      // Verify ❤️ reaction (current user)
      final heart = uiState.groupedReactions.firstWhere((r) => r.code == '❤️');
      expect(heart.reactorIds, ['user-1']);
      expect(heart.isReactedByCurrentUser, true);
    });
  });
}
