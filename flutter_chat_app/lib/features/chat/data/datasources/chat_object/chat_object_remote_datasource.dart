import 'package:dio/dio.dart';
import 'package:flutter_chat_app/core/network/graphql_client.dart';
import 'package:flutter_chat_app/data/dtos/chat_object_dto.dart';
import 'package:flutter_chat_app/data/graphql/chat_operations.dart';
import 'package:injectable/injectable.dart';

/// **Chat Object Remote Data Source Interface**
///
/// Handles file upload/download operations for chat attachments.
/// Implements 2-step upload process:
/// 1. Get pre-signed upload URL from backend
/// 2. Upload file directly to GCP Cloud Storage
abstract class IChatObjectRemoteDataSource {
  /// Generate pre-signed upload URL (Step 1 of upload process)
  Future<ChatObjectUploadResponseDto> generateUploadLink({
    required String filename,
    String? conversationId,
    required ChatObjectType type,
    required String mimetype,
  });

  /// Upload file to GCP Cloud Storage (Step 2 of upload process)
  Future<void> uploadFile({
    required String uploadUrl,
    required String filePath,
    ProgressCallback? onProgress,
  });

  /// Get download URL for uploaded file
  Future<ChatObjectGetUrlResponseDto> getObjectUrl(String path);
}

/// **Chat Object Remote Data Source Implementation**
///
/// Uses GraphQL for API calls and Dio for file uploads.
@LazySingleton(as: IChatObjectRemoteDataSource)
class ChatObjectRemoteDataSource implements IChatObjectRemoteDataSource {
  final GraphQLClientWrapper _client;
  final Dio _dio;

  ChatObjectRemoteDataSource(
    this._client,
    @Named('uploadClient') this._dio,
  );

  @override
  Future<ChatObjectUploadResponseDto> generateUploadLink({
    required String filename,
    String? conversationId,
    required ChatObjectType type,
    required String mimetype,
  }) async {
    final input = ChatObjectUploadInput(
      filename: filename,
      conversationId: conversationId,
      type: type,
      mimetype: mimetype,
    );

    final result = await _client.mutate(
      ChatMutations.generateUploadLink,
      variables: {'arguments': input.toJson()},
    );

    final data = result['chatObjectGenLinkUpload'];
    if (data == null) {
      throw Exception('No upload link returned from server');
    }

    return ChatObjectUploadResponseDto.fromJson(data);
  }

  @override
  Future<void> uploadFile({
    required String uploadUrl,
    required String filePath,
    ProgressCallback? onProgress,
  }) async {
    try {
      // Upload file directly to GCP Cloud Storage
      await _dio.putUri(
        Uri.parse(uploadUrl),
        data: FormData.fromMap({
          'file': await MultipartFile.fromFile(filePath),
        }),
        options: Options(
          sendTimeout: const Duration(minutes: 5),
          receiveTimeout: const Duration(minutes: 5),
        ),
        onSendProgress: onProgress,
      );
    } catch (e) {
      throw Exception('Failed to upload file: $e');
    }
  }

  @override
  Future<ChatObjectGetUrlResponseDto> getObjectUrl(String path) async {
    final result = await _client.query(
      ChatMutations.getObjectUrl,
      variables: {'path': path},
    );

    final data = result['chatObjectGetUrl'];
    if (data == null) {
      throw Exception('No URL returned from server');
    }

    return ChatObjectGetUrlResponseDto.fromJson(data);
  }
}
