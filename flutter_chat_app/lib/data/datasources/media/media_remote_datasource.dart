import 'dart:io';

import 'package:flutter_chat_app/core/error/exceptions.dart';
import 'package:flutter_chat_app/data/models/attachment_model.dart';
import 'package:flutter_chat_app/shared/domain/entities/attachment.dart';
import 'package:http/http.dart' as http;
import 'package:injectable/injectable.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as path;

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

      final resolvedPath = _resolveDownloadPath(
        requestUri: uri,
        savePath: savePath,
        headers: streamedResponse.headers,
      );

      final file = File(resolvedPath);
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
      return resolvedPath;
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

  String _resolveDownloadPath({
    required Uri requestUri,
    required String savePath,
    required Map<String, String> headers,
  }) {
    final String? contentDisposition =
        _readHeader(headers, 'content-disposition');
    final String? contentType = _readHeader(headers, 'content-type');
    final String defaultBaseName = path.basename(savePath).trim().isEmpty
        ? 'download_${DateTime.now().millisecondsSinceEpoch}'
        : path.basenameWithoutExtension(savePath);

    final String? headerFileName =
        _filenameFromContentDisposition(contentDisposition);
    final String? urlFileName = _filenameFromUrl(requestUri);

    final String chosenName =
        (headerFileName ?? urlFileName ?? defaultBaseName).trim();
    final String sanitizedBaseName = _sanitizeBaseName(
      path.basenameWithoutExtension(chosenName),
      fallback: defaultBaseName,
    );

    String extension = path.extension(chosenName).toLowerCase();
    if (extension.isEmpty) {
      extension = _extensionFromContentType(contentType);
    }
    if (extension.isEmpty) {
      extension = path.extension(savePath).toLowerCase();
    }

    final String fileName =
        extension.isEmpty ? sanitizedBaseName : '$sanitizedBaseName$extension';
    return path.join(path.dirname(savePath), fileName);
  }

  String? _readHeader(Map<String, String> headers, String key) {
    final String lowerKey = key.toLowerCase();
    for (final entry in headers.entries) {
      if (entry.key.toLowerCase() == lowerKey) {
        return entry.value;
      }
    }
    return null;
  }

  String? _filenameFromContentDisposition(String? value) {
    if (value == null || value.isEmpty) {
      return null;
    }

    final RegExp filenameStarRegExp = RegExp(
      r'filename\*\s*=\s*([^;]+)',
      caseSensitive: false,
    );
    final Match? filenameStarMatch = filenameStarRegExp.firstMatch(value);
    if (filenameStarMatch != null) {
      final String decoded =
          _decodeContentDispositionValue(filenameStarMatch.group(1)!);
      if (decoded.isNotEmpty) {
        return decoded;
      }
    }

    final RegExp filenameRegExp = RegExp(
      r'filename\s*=\s*([^;]+)',
      caseSensitive: false,
    );
    final Match? filenameMatch = filenameRegExp.firstMatch(value);
    if (filenameMatch != null) {
      final String cleaned = _stripQuotedValue(filenameMatch.group(1)!).trim();
      if (cleaned.isNotEmpty) {
        return cleaned;
      }
    }

    return null;
  }

  String _decodeContentDispositionValue(String raw) {
    final String unquoted = _stripQuotedValue(raw).trim();
    final int delimiterIndex = unquoted.indexOf("''");
    final String encodedPart =
        delimiterIndex >= 0 ? unquoted.substring(delimiterIndex + 2) : unquoted;

    try {
      return Uri.decodeComponent(encodedPart);
    } catch (_) {
      return encodedPart;
    }
  }

  String _stripQuotedValue(String value) {
    final String trimmed = value.trim();
    if (trimmed.length >= 2 &&
        trimmed.startsWith('"') &&
        trimmed.endsWith('"')) {
      return trimmed.substring(1, trimmed.length - 1).replaceAll(r'\"', '"');
    }
    return trimmed;
  }

  String? _filenameFromUrl(Uri uri) {
    if (uri.pathSegments.isEmpty) {
      return null;
    }

    final String candidate = uri.pathSegments.last.trim();
    if (candidate.isEmpty) {
      return null;
    }

    return Uri.decodeComponent(candidate);
  }

  String _extensionFromContentType(String? contentType) {
    if (contentType == null || contentType.isEmpty) {
      return '';
    }

    final String mimeType = contentType.split(';').first.trim().toLowerCase();
    if (mimeType.isEmpty) {
      return '';
    }

    final String? ext = extensionFromMime(mimeType);
    if (ext == null || ext.isEmpty) {
      return '';
    }

    return '.${ext.toLowerCase()}';
  }

  String _sanitizeBaseName(String value, {required String fallback}) {
    String sanitized = value
        .replaceAll(RegExp(r'[\\/:*?"<>|]'), '_')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    if (sanitized.isEmpty || sanitized == '.' || sanitized == '..') {
      sanitized = fallback.trim();
    }

    if (sanitized.isEmpty || sanitized == '.' || sanitized == '..') {
      return 'download_${DateTime.now().millisecondsSinceEpoch}';
    }

    return sanitized;
  }
}
