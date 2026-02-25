import 'package:injectable/injectable.dart';
import 'package:flutter_chat_app/data/models/chat_info/shared_media_model.dart';
import 'package:flutter_chat_app/data/models/chat_info/notification_settings_model.dart';
import 'package:flutter_chat_app/data/graphql/chat_operations.dart';
import 'package:flutter_chat_app/core/network/graphql_client.dart';
import 'package:flutter_chat_app/core/error/exceptions.dart';

/// Remote data source interface cho Chat Info
abstract class IChatInfoRemoteDataSource {
  Future<List<SharedMediaModel>> getSharedMedia({
    required String chatId,
    required String type,
    int? limit,
    int? offset,
  });

  Future<NotificationSettingsModel> getNotificationSettings({
    required String chatId,
  });

  Future<NotificationSettingsModel> updateNotificationSettings({
    required String chatId,
    required Map<String, dynamic> settings,
  });

  Future<void> blockUser({required String userId});
  Future<void> unblockUser({required String userId});
  Future<bool> isUserBlocked({required String userId});
  Future<void> reportChat({required String chatId, required String reason});
}

/// Implementation của IChatInfoRemoteDataSource
/// Sử dụng chatMessageList API để lấy shared media (same as frontend Angular)
@LazySingleton(as: IChatInfoRemoteDataSource)
class ChatInfoRemoteDataSource implements IChatInfoRemoteDataSource {
  final GraphQLClientWrapper _graphqlClient;

  ChatInfoRemoteDataSource(this._graphqlClient);

  @override
  Future<List<SharedMediaModel>> getSharedMedia({
    required String chatId,
    required String type,
    int? limit,
    int? offset,
  }) async {
    try {
      // Map type sang ChatMessageType (same as frontend)
      // type: 'photo' | 'video' | 'file' | 'link'
      final messageType = _mapToMessageType(type);
      
      final variables = <String, dynamic>{
        'filters': {
          'conversationId': chatId,
          'size': limit ?? 100,
          'type': messageType,
          'order': 'DESC',
        },
      };
      
      final result = await _graphqlClient.query(
        ChatQueries.getMessageList,
        variables: variables,
        operationName: 'GetMessageList',
      );
      
      final data = result['chatMessageList'] as Map<String, dynamic>?;
      if (data == null) {
        return [];
      }
      
      final messages = data['messages'] as List<dynamic>? ?? [];
      return _mapMessagesToSharedMedia(messages, type);
    } catch (e) {
      throw ServerException(message: 'Failed to get shared media: $e');
    }
  }
  
  /// Map UI type sang GraphQL message type
  String _mapToMessageType(String type) {
    switch (type.toLowerCase()) {
      case 'photo':
      case 'image':
        return 'IMAGE';
      case 'video':
        return 'VIDEO';
      case 'file':
      case 'document':
        return 'DOC';
      case 'link':
      case 'url':
        return 'TEXT'; // Links are in TEXT messages
      default:
        return 'IMAGE';
    }
  }
  
  /// Convert messages sang SharedMediaModel
  List<SharedMediaModel> _mapMessagesToSharedMedia(List<dynamic> messages, String type) {
    return messages.map((msg) {
      final m = msg as Map<String, dynamic>;
      final urls = (m['urls'] as List<dynamic>?)?.cast<String>() ?? [];
      final sender = m['sender'] as Map<String, dynamic>? ?? {};
      
      // For links, extract URLs from message text
      if (type.toLowerCase() == 'link') {
        final messageText = m['message'] as String? ?? '';
        // Simple URL extraction (could be improved with regex)
        final urlRegex = RegExp(r'https?://[^\s]+');
        final matches = urlRegex.allMatches(messageText);
        return matches.map((match) => SharedMediaModel(
          id: m['id'] as String,
          type: 'link',
          url: match.group(0) ?? '',
          createdAt: DateTime.fromMillisecondsSinceEpoch((m['createdAt'] as int?) ?? 0),
          senderId: sender['id'] as String? ?? '',
          senderName: sender['fullname'] as String? ?? '',
        )).toList();
      }
      
      // For images, videos, files - use urls array
      if (urls.isEmpty) return <SharedMediaModel>[];
      
      return urls.map((url) => SharedMediaModel(
        id: m['id'] as String,
        type: type.toLowerCase(),
        url: url,
        thumbnailUrl: type.toLowerCase() == 'video' ? urls.first : null,
        fileName: m['fileName'] as String?,
        createdAt: DateTime.fromMillisecondsSinceEpoch((m['createdAt'] as int?) ?? 0),
        senderId: sender['id'] as String? ?? '',
        senderName: sender['fullname'] as String? ?? '',
      )).toList();
    }).expand((e) => e is List ? e : [e]).cast<SharedMediaModel>().toList();
  }

  @override
  Future<NotificationSettingsModel> getNotificationSettings({
    required String chatId,
  }) async {
    try {
      // TODO: Implement API call
      // Tạm thời return default settings
      return NotificationSettingsModel(
        chatId: chatId,
        isMuted: false,
      );
    } catch (e) {
      throw ServerException(message: 'Failed to get notification settings: $e');
    }
  }

  @override
  Future<NotificationSettingsModel> updateNotificationSettings({
    required String chatId,
    required Map<String, dynamic> settings,
  }) async {
    try {
      // TODO: Implement API call
      return NotificationSettingsModel.fromJson(settings);
    } catch (e) {
      throw ServerException(
        message: 'Failed to update notification settings: $e',
      );
    }
  }

  @override
  Future<void> blockUser({required String userId}) async {
    try {
      // TODO: Implement API call
      // await _apiClient.post('/users/$userId/block');
    } catch (e) {
      throw ServerException(message: 'Failed to block user: $e');
    }
  }

  @override
  Future<void> unblockUser({required String userId}) async {
    try {
      // TODO: Implement API call
      // await _apiClient.delete('/users/$userId/block');
    } catch (e) {
      throw ServerException(message: 'Failed to unblock user: $e');
    }
  }

  @override
  Future<bool> isUserBlocked({required String userId}) async {
    try {
      // TODO: Implement API call
      return false;
    } catch (e) {
      throw ServerException(message: 'Failed to check block status: $e');
    }
  }

  @override
  Future<void> reportChat({
    required String chatId,
    required String reason,
  }) async {
    try {
      // TODO: Implement API call
      // await _apiClient.post('/chats/$chatId/report', body: {'reason': reason});
    } catch (e) {
      throw ServerException(message: 'Failed to report chat: $e');
    }
  }
}
