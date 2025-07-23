import 'dart:io';
import 'package:isar/isar.dart';
import 'lib/data/models/isar/chat_isar_model.dart';
import 'lib/data/models/isar/chat_message_isar_model.dart';

/// **ISAR V4.0.0-DEV.14 COMPREHENSIVE TEST SCRIPT**
///
/// This script tests Isar v4 functionality and discovers API patterns.

Future<void> main() async {
  print('🚀 Testing Isar v4.0.0-dev.14 API Discovery...');

  try {
    // Test model creation with proper v4 syntax
    final chatModel = ChatIsarModel();
    chatModel.chatId = 'test-chat-1';
    chatModel.name = 'Test Chat';
    chatModel.type = ChatTypeIsar.direct;
    chatModel.createdAt = DateTime.now();
    chatModel.updatedAt = DateTime.now();
    chatModel.isArchived = false;
    chatModel.participantIds = ['user1', 'user2'];
    chatModel.lastMessageTime = DateTime.now();
    // chatModel.lastMessageContent = 'Hello Isar v4!';  // Field doesn't exist
    chatModel.unreadCount = 0;

    final messageModel = ChatMessageIsarModel();
    messageModel.messageId = 'test-message-1';
    messageModel.chatId = 'test-chat-1';
    messageModel.content = 'Hello Isar v4!';
    messageModel.contentType = ContentTypeIsar.text;
    messageModel.status = MessageStatusIsar.sent;
    messageModel.createdAt = DateTime.now();
    messageModel.updatedAt = DateTime.now();
    messageModel.isFromCurrentUser = true;
    messageModel.isRead = false;
    messageModel.isDeleted = false;

    // Create sender
    messageModel.sender = MessageSenderIsar()
      ..id = 'user1'
      ..name = 'Test User'
      ..avatar = 'https://example.com/avatar.jpg';
    
    print('✅ Models created successfully');
    print('Chat: ${chatModel.chatId} - ${chatModel.name}');
    print('Message: ${messageModel.messageId} - ${messageModel.content}');
    
    // Test domain conversion
    final chatDomain = chatModel.toDomain();
    final messageDomain = messageModel.toDomain();
    
    print('✅ Domain conversion successful');
    print('Chat Domain: ${chatDomain.id} - ${chatDomain.name}');
    print('Message Domain: ${messageDomain.id} - ${messageDomain.content}');
    
    // Try to initialize Isar (this should trigger schema generation)
    print('🔧 Attempting to initialize Isar v4...');
    
    final tempDir = Directory.systemTemp.createTempSync('isar_test');
    print('Temp directory: ${tempDir.path}');
    
    // This should trigger schema generation in Isar v4
    final isar = await Isar.openAsync(
      schemas: [
        ChatIsarModelSchema,
        ChatMessageIsarModelSchema,
      ],
      directory: tempDir.path,
      name: 'test_db',
    );
    
    print('✅ Isar v4 initialized successfully!');
    print('Collections: ${isar.schemas.length}');
    
    // Test basic operations
    await isar.writeAsync((isar) async {
      await isar.chatIsarModels.put(chatModel);
      await isar.chatMessageIsarModels.put(messageModel);
    });
    
    print('✅ Write operations successful');
    
    // Test read operations
    final chats = await isar.chatIsarModels.where().findAll();
    final messages = await isar.chatMessageIsarModels.where().findAll();
    
    print('✅ Read operations successful');
    print('Chats found: ${chats.length}');
    print('Messages found: ${messages.length}');
    
    // Cleanup
    await isar.close();
    tempDir.deleteSync(recursive: true);
    
    print('🎉 Isar v4.0.0-dev.14 test completed successfully!');
    
  } catch (e, stackTrace) {
    print('❌ Isar v4 test failed: $e');
    print('Stack trace: $stackTrace');
    exit(1);
  }
}
