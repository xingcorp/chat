import 'dart:io';
import 'package:injectable/injectable.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:flutter_chat_app/core/error/exceptions.dart';
import 'package:flutter_chat_app/data/models/attachment_model.dart';
import 'package:flutter_chat_app/domain/entities/attachment.dart';

/// Interface for local media data source
abstract class IMediaLocalDataSource {
  /// Cache media file locally
  Future<String> cacheMedia({
    required String sourceFilePath,
    required String attachmentId,
    required AttachmentType type,
  });
  
  /// Get cached media file path
  Future<String?> getCachedMediaPath(String attachmentId);
  
  /// Delete cached media file
  Future<void> deleteCachedMedia(String attachmentId);
  
  /// Clear all cached media
  Future<void> clearMediaCache();
  
  /// Get cache size in bytes
  Future<int> getCacheSize();
  
  /// Check if media is cached
  Future<bool> isMediaCached(String attachmentId);
  
  /// Save attachment metadata
  Future<void> saveAttachmentMetadata(AttachmentModel attachment);
  
  /// Get attachment metadata
  Future<AttachmentModel?> getAttachmentMetadata(String attachmentId);
  
  /// Get all cached attachments metadata
  Future<List<AttachmentModel>> getAllCachedAttachments();
}

/// Implementation of local media data source
@lazySingleton
class MediaLocalDataSourceImpl implements IMediaLocalDataSource {
  static const String _cacheDir = 'media_cache';
  static const String _metadataFile = 'attachments_metadata.json';
  
  final Map<String, AttachmentModel> _metadataCache = {};
  bool _metadataLoaded = false;
  
  /// Get media cache directory
  Future<Directory> _getCacheDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final cacheDir = Directory(path.join(appDir.path, _cacheDir));
    
    if (!await cacheDir.exists()) {
      await cacheDir.create(recursive: true);
    }
    
    return cacheDir;
  }
  
  /// Get metadata file
  Future<File> _getMetadataFile() async {
    final cacheDir = await _getCacheDirectory();
    return File(path.join(cacheDir.path, _metadataFile));
  }
  
  /// Load metadata from file
  Future<void> _loadMetadata() async {
    if (_metadataLoaded) return;
    
    try {
      final file = await _getMetadataFile();
      if (await file.exists()) {
        final content = await file.readAsString();
        final attachments = AttachmentModel.fromJsonList(content);
        
        for (final attachment in attachments) {
          _metadataCache[attachment.id] = attachment;
        }
      }
      _metadataLoaded = true;
    } catch (e) {
      throw CacheException(message: 'Failed to load metadata: $e');
    }
  }
  
  /// Save metadata to file
  Future<void> _saveMetadata() async {
    try {
      final file = await _getMetadataFile();
      final attachments = _metadataCache.values.toList();
      final json = AttachmentModel.toJsonList(attachments);
      await file.writeAsString(json);
    } catch (e) {
      throw CacheException(message: 'Failed to save metadata: $e');
    }
  }
  
  /// Get file path for attachment
  String _getFilePath(String attachmentId, AttachmentType type) {
    final extension = _getExtensionForType(type);
    return '$attachmentId$extension';
  }
  
  /// Get file extension for attachment type
  String _getExtensionForType(AttachmentType type) {
    switch (type) {
      case AttachmentType.image:
        return '.jpg';
      case AttachmentType.video:
        return '.mp4';
      case AttachmentType.audio:
        return '.mp3';
      case AttachmentType.document:
        return '.pdf';
      case AttachmentType.location:
        return '.json';
      case AttachmentType.contact:
        return '.vcf';
      case AttachmentType.other:
        return '.bin';
    }
  }
  
  @override
  Future<String> cacheMedia({
    required String sourceFilePath,
    required String attachmentId,
    required AttachmentType type,
  }) async {
    try {
      final sourceFile = File(sourceFilePath);
      if (!await sourceFile.exists()) {
        throw CacheException(message: 'Source file not found');
      }
      
      final cacheDir = await _getCacheDirectory();
      final fileName = _getFilePath(attachmentId, type);
      final targetPath = path.join(cacheDir.path, fileName);
      final targetFile = File(targetPath);
      
      // Copy file to cache
      await sourceFile.copy(targetPath);
      
      return targetPath;
    } catch (e) {
      if (e is CacheException) rethrow;
      throw CacheException(message: 'Failed to cache media: $e');
    }
  }
  
  @override
  Future<String?> getCachedMediaPath(String attachmentId) async {
    try {
      await _loadMetadata();
      
      final metadata = _metadataCache[attachmentId];
      if (metadata == null) return null;
      
      final cacheDir = await _getCacheDirectory();
      final fileName = _getFilePath(attachmentId, metadata.type);
      final filePath = path.join(cacheDir.path, fileName);
      final file = File(filePath);
      
      if (await file.exists()) {
        return filePath;
      }
      
      return null;
    } catch (e) {
      throw CacheException(message: 'Failed to get cached media path: $e');
    }
  }
  
  @override
  Future<void> deleteCachedMedia(String attachmentId) async {
    try {
      await _loadMetadata();
      
      final metadata = _metadataCache[attachmentId];
      if (metadata == null) return;
      
      final cacheDir = await _getCacheDirectory();
      final fileName = _getFilePath(attachmentId, metadata.type);
      final filePath = path.join(cacheDir.path, fileName);
      final file = File(filePath);
      
      if (await file.exists()) {
        await file.delete();
      }
      
      _metadataCache.remove(attachmentId);
      await _saveMetadata();
    } catch (e) {
      throw CacheException(message: 'Failed to delete cached media: $e');
    }
  }
  
  @override
  Future<void> clearMediaCache() async {
    try {
      final cacheDir = await _getCacheDirectory();
      
      if (await cacheDir.exists()) {
        await cacheDir.delete(recursive: true);
        await cacheDir.create();
      }
      
      _metadataCache.clear();
      await _saveMetadata();
    } catch (e) {
      throw CacheException(message: 'Failed to clear media cache: $e');
    }
  }
  
  @override
  Future<int> getCacheSize() async {
    try {
      final cacheDir = await _getCacheDirectory();
      
      if (!await cacheDir.exists()) {
        return 0;
      }
      
      int totalSize = 0;
      await for (final entity in cacheDir.list(recursive: true)) {
        if (entity is File) {
          totalSize += await entity.length();
        }
      }
      
      return totalSize;
    } catch (e) {
      throw CacheException(message: 'Failed to get cache size: $e');
    }
  }
  
  @override
  Future<bool> isMediaCached(String attachmentId) async {
    final cachedPath = await getCachedMediaPath(attachmentId);
    return cachedPath != null;
  }
  
  @override
  Future<void> saveAttachmentMetadata(AttachmentModel attachment) async {
    try {
      await _loadMetadata();
      _metadataCache[attachment.id] = attachment;
      await _saveMetadata();
    } catch (e) {
      throw CacheException(message: 'Failed to save attachment metadata: $e');
    }
  }
  
  @override
  Future<AttachmentModel?> getAttachmentMetadata(String attachmentId) async {
    try {
      await _loadMetadata();
      return _metadataCache[attachmentId];
    } catch (e) {
      throw CacheException(message: 'Failed to get attachment metadata: $e');
    }
  }
  
  @override
  Future<List<AttachmentModel>> getAllCachedAttachments() async {
    try {
      await _loadMetadata();
      return _metadataCache.values.toList();
    } catch (e) {
      throw CacheException(message: 'Failed to get all cached attachments: $e');
    }
  }
}
