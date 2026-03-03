import 'dart:convert';

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
  List<SharedMediaModel> _mapMessagesToSharedMedia(
    List<dynamic> messages,
    String type,
  ) {
    final normalizedType = type.toLowerCase();
    final results = <SharedMediaModel>[];

    for (final msg in messages) {
      final m = msg as Map<String, dynamic>;
      final sender = m['sender'] as Map<String, dynamic>? ?? {};
      final messageId = (m['id'] as String?) ?? '';
      final createdAt = DateTime.fromMillisecondsSinceEpoch(
        (m['createdAt'] as int?) ?? 0,
      );
      final senderId = (sender['id'] as String?) ?? '';
      final senderName = (sender['fullname'] as String?) ?? '';
      final fileName = m['fileName'] as String?;

      // For links, extract URLs from message text
      if (normalizedType == 'link') {
        final messageText = m['message'] as String? ?? '';
        final urlRegex = RegExp(r'https?://[^\s]+');
        final matches = urlRegex.allMatches(messageText);
        for (final match in matches) {
          final linkUrl = match.group(0) ?? '';
          if (linkUrl.isEmpty) {
            continue;
          }
          results.add(
            SharedMediaModel(
              id: messageId,
              type: 'link',
              url: linkUrl,
              createdAt: createdAt,
              senderId: senderId,
              senderName: senderName,
            ),
          );
        }
        continue;
      }

      final rawUrls = (m['urls'] as List<dynamic>?) ?? const <dynamic>[];
      final urls = rawUrls
          .map((url) => url.toString().trim())
          .where((url) => url.isNotEmpty)
          .toList();

      if (urls.isEmpty) {
        continue;
      }

      if (normalizedType == 'video') {
        final thumbnailCandidates = <String>[];
        final thumbnailFromMessage = _extractThumbnailFromMessage(
          m['message'],
        );
        if (thumbnailFromMessage != null) {
          thumbnailCandidates.add(thumbnailFromMessage);
        }
        thumbnailCandidates.addAll(urls.where(_isLikelyImageUrl));
        final thumbnailUrl =
            thumbnailCandidates.isNotEmpty ? thumbnailCandidates.first : null;

        final explicitVideoUrls = urls.where(_isLikelyVideoUrl).toList();
        final fallbackVideoUrls =
            urls.where((url) => !_isLikelyImageUrl(url)).toList();
        final effectiveVideoUrls = explicitVideoUrls.isNotEmpty
            ? explicitVideoUrls
            : (fallbackVideoUrls.isNotEmpty ? fallbackVideoUrls : urls);

        for (final videoUrl in effectiveVideoUrls) {
          results.add(
            SharedMediaModel(
              id: messageId,
              type: normalizedType,
              url: videoUrl,
              thumbnailUrl: thumbnailUrl,
              fileName: fileName,
              createdAt: createdAt,
              senderId: senderId,
              senderName: senderName,
            ),
          );
        }
        continue;
      }

      // For images/files - keep one item per URL
      for (final url in urls) {
        results.add(
          SharedMediaModel(
            id: messageId,
            type: normalizedType,
            url: url,
            fileName: fileName,
            createdAt: createdAt,
            senderId: senderId,
            senderName: senderName,
          ),
        );
      }
    }

    return results;
  }

  bool _isLikelyVideoUrl(String url) {
    final lower = _safeUrlPath(url);
    return lower.endsWith('.mp4') ||
        lower.endsWith('.mov') ||
        lower.endsWith('.webm') ||
        lower.endsWith('.avi') ||
        lower.endsWith('.mkv') ||
        lower.endsWith('.m4v');
  }

  bool _isLikelyImageUrl(String url) {
    final lower = _safeUrlPath(url);
    return lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.png') ||
        lower.endsWith('.webp') ||
        lower.endsWith('.gif') ||
        lower.endsWith('.bmp');
  }

  String _safeUrlPath(String url) {
    try {
      return Uri.parse(url).path.toLowerCase();
    } catch (_) {
      return url.toLowerCase();
    }
  }

  String? _extractThumbnailFromMessage(dynamic messageValue) {
    if (messageValue is! String) {
      return null;
    }

    final content = messageValue.trim();
    if (content.isEmpty || !content.startsWith('{')) {
      return null;
    }

    try {
      final decoded = jsonDecode(content);
      if (decoded is! Map<String, dynamic>) {
        return null;
      }

      const candidateKeys = <String>[
        'thumbnail',
        'thumbnailUrl',
        'thumb',
        'thumbUrl',
        'poster',
        'posterUrl',
      ];

      for (final key in candidateKeys) {
        final value = decoded[key];
        if (value is String) {
          final normalized = value.trim();
          if (normalized.isNotEmpty) {
            return normalized;
          }
        }
      }
    } catch (_) {
      return null;
    }

    return null;
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
