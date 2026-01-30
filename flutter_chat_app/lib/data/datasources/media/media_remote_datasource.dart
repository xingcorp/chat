import 'dart:io';
import 'package:injectable/injectable.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_chat_app/core/error/exceptions.dart';
import 'package:flutter_chat_app/data/models/attachment_model.dart';
import 'package:flutter_chat_app/domain/entities/attachment.dart';

/// Interface for remote media data source
abstract class IMediaRemoteDataSource {
  /// Upload media file to server
  Future<AttachmentModel> uploadMedia({
    required String filePath,
    required AttachmentType type,
    required String chatId,
    String? messageId,
    void Function(double progress)? onProgress,
  });
  
  /// Download media file from server
  Future<String> downloadMedia({
    required String url,
    required String savePath,
    void Function(double progress)? onProgress,
  });
  
  /// Get attachment metadata from server
  Future<AttachmentModel> getAttachment(String attachmentId);
  
  /// Get attachments for a message
  Future<List<AttachmentModel>> getMessageAttachments(String messageId);
  
  /// Get attachments for a chat
  Future<List<AttachmentModel>> getChatAttachments({
    required String chatId,
    AttachmentType? type,
  });
}

/// Implementation of remote media data source
@lazySingleton
class MediaRemoteDataSourceImpl implements IMediaRemoteDataSource {
  final http.Client _httpClient;
  final String _baseUrl;
  
  MediaRemoteDataSourceImpl({
    required http.Client httpClient,
    @Named('baseUrl') required String baseUrl,
  })  : _httpClient = httpClient,
        _baseUrl = baseUrl;
  
  @override
  Future<AttachmentModel> uploadMedia({
    required String filePath,
    required AttachmentType type,
    required String chatId,
    String? messageId,
    void Function(double progress)? onProgress,
  }) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        throw FileException(message: 'File not found');
      }
      
      final uri = Uri.parse('$_baseUrl/api/media/upload');
      final request = http.MultipartRequest('POST', uri);
      
      // Add file
      final fileStream = http.ByteStream(file.openRead());
      final fileLength = await file.length();
      final multipartFile = http.MultipartFile(
        'file',
        fileStream,
        fileLength,
        filename: file.path.split('/').last,
      );
      request.files.add(multipartFile);
      
      // Add metadata
      request.fields['type'] = type.toString().split('.').last;
      request.fields['chatId'] = chatId;
      if (messageId != null) {
        request.fields['messageId'] = messageId;
      }
      
      // Send request
      final streamedResponse = await _httpClient.send(request);
      
      // Track progress
      if (onProgress != null) {
        int bytesReceived = 0;
        streamedResponse.stream.listen(
          (chunk) {
            bytesReceived += chunk.length;
            onProgress(bytesReceived / fileLength);
          },
        );
      }
      
      final response = await http.Response.fromStream(streamedResponse);
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        return AttachmentModel.fromJson(response.body);
      } else {
        throw ServerException(
          message: 'Upload failed: ${response.body}',
          statusCode: response.statusCode,
        );
      }
    } on SocketException {
      throw NetworkException();
    } catch (e) {
      if (e is ServerException || e is NetworkException || e is FileException) {
        rethrow;
      }
      throw ServerException(message: 'Upload error: $e');
    }
  }
  
  @override
  Future<String> downloadMedia({
    required String url,
    required String savePath,
    void Function(double progress)? onProgress,
  }) async {
    try {
      final uri = Uri.parse(url);
      final request = http.Request('GET', uri);
      final streamedResponse = await _httpClient.send(request);
      
      if (streamedResponse.statusCode != 200) {
        throw ServerException(
          message: 'Download failed',
          statusCode: streamedResponse.statusCode,
        );
      }
      
      final file = File(savePath);
      await file.create(recursive: true);
      
      final sink = file.openWrite();
      int bytesReceived = 0;
      final contentLength = streamedResponse.contentLength ?? 0;
      
      await for (final chunk in streamedResponse.stream) {
        sink.add(chunk);
        bytesReceived += chunk.length;
        
        if (onProgress != null && contentLength > 0) {
          onProgress(bytesReceived / contentLength);
        }
      }
      
      await sink.close();
      return savePath;
    } on SocketException {
      throw NetworkException();
    } catch (e) {
      if (e is ServerException || e is NetworkException) {
        rethrow;
      }
      throw ServerException(message: 'Download error: $e');
    }
  }
  
  @override
  Future<AttachmentModel> getAttachment(String attachmentId) async {
    try {
      final uri = Uri.parse('$_baseUrl/api/media/$attachmentId');
      final response = await _httpClient.get(uri);
      
      if (response.statusCode == 200) {
        return AttachmentModel.fromJson(response.body);
      } else if (response.statusCode == 404) {
        throw ServerException(message: 'Attachment not found');
      } else {
        throw ServerException(
          message: 'Failed to get attachment',
          statusCode: response.statusCode,
        );
      }
    } on SocketException {
      throw NetworkException();
    } catch (e) {
      if (e is ServerException || e is NetworkException) {
        rethrow;
      }
      throw ServerException(message: 'Get attachment error: $e');
    }
  }
  
  @override
  Future<List<AttachmentModel>> getMessageAttachments(String messageId) async {
    try {
      final uri = Uri.parse('$_baseUrl/api/media/message/$messageId');
      final response = await _httpClient.get(uri);
      
      if (response.statusCode == 200) {
        return AttachmentModel.fromJsonList(response.body);
      } else {
        throw ServerException(
          message: 'Failed to get message attachments',
          statusCode: response.statusCode,
        );
      }
    } on SocketException {
      throw NetworkException();
    } catch (e) {
      if (e is ServerException || e is NetworkException) {
        rethrow;
      }
      throw ServerException(message: 'Get message attachments error: $e');
    }
  }
  
  @override
  Future<List<AttachmentModel>> getChatAttachments({
    required String chatId,
    AttachmentType? type,
  }) async {
    try {
      final queryParams = <String, String>{'chatId': chatId};
      if (type != null) {
        queryParams['type'] = type.toString().split('.').last;
      }
      
      final uri = Uri.parse('$_baseUrl/api/media/chat/$chatId')
          .replace(queryParameters: queryParams);
      final response = await _httpClient.get(uri);
      
      if (response.statusCode == 200) {
        return AttachmentModel.fromJsonList(response.body);
      } else {
        throw ServerException(
          message: 'Failed to get chat attachments',
          statusCode: response.statusCode,
        );
      }
    } on SocketException {
      throw NetworkException();
    } catch (e) {
      if (e is ServerException || e is NetworkException) {
        rethrow;
      }
      throw ServerException(message: 'Get chat attachments error: $e');
    }
  }
}
