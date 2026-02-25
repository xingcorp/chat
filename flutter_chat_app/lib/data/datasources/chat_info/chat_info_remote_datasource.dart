import 'package:injectable/injectable.dart';
import 'package:flutter_chat_app/data/models/chat_info/shared_media_model.dart';
import 'package:flutter_chat_app/data/models/chat_info/notification_settings_model.dart';
import 'package:flutter_chat_app/core/network/api_client.dart';
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
@LazySingleton(as: IChatInfoRemoteDataSource)
class ChatInfoRemoteDataSource implements IChatInfoRemoteDataSource {
  final ApiClient _apiClient;

  ChatInfoRemoteDataSource(this._apiClient);

  @override
  Future<List<SharedMediaModel>> getSharedMedia({
    required String chatId,
    required String type,
    int? limit,
    int? offset,
  }) async {
    try {
      // TODO: Implement GraphQL query hoặc REST endpoint
      // Tạm thời return mock data để test
      return [];
    } catch (e) {
      throw ServerException(message: 'Failed to get shared media: $e');
    }
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
