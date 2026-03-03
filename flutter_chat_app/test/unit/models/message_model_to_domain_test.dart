import 'package:flutter_chat_app/data/models/message_model.dart';
import 'package:flutter_chat_app/shared/domain/entities/chat_message.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MessageModel.toDomain attachments mapping', () {
    test('maps all image urls to attachments instead of only first item', () {
      final model = MessageModel(
        localId: 'local-1',
        chatId: 'chat-1',
        senderId: 'user-1',
        content: '',
        type: MessageType.image,
        createdAt: DateTime(2026, 3, 3, 10),
        urls: const [
          'https://cdn.example.com/media/photo_1.jpg',
          'https://cdn.example.com/media/photo_2.jpg',
          'https://cdn.example.com/media/photo_3.jpg',
        ],
        fileName: 'cover.jpg',
      );

      final domain = model.toDomain();

      expect(domain.contentType, ContentType.image);
      expect(domain.attachments, hasLength(3));
      expect(
        domain.attachments.map((a) => a.url).toList(growable: false),
        equals(model.urls),
      );
      expect(domain.attachments.first.name, 'cover.jpg');
      expect(domain.attachments[1].name, 'photo_2.jpg');
      expect(domain.attachments[2].name, 'photo_3.jpg');
    });
  });
}
