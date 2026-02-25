import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter_chat_app/domain/entities/chat_info/shared_media.dart';

part 'shared_media_model.freezed.dart';
part 'shared_media_model.g.dart';

/// Model cho shared media (Data layer)
/// Sử dụng Freezed cho immutability và JSON serialization
@freezed
class SharedMediaModel with _$SharedMediaModel {
  const factory SharedMediaModel({
    required String id,
    required String type,
    required String url,
    String? thumbnailUrl,
    String? fileName,
    int? fileSize,
    required DateTime createdAt,
    required String senderId,
    required String senderName,
  }) = _SharedMediaModel;

  factory SharedMediaModel.fromJson(Map<String, dynamic> json) =>
      _$SharedMediaModelFromJson(json);

  const SharedMediaModel._();

  /// Convert model sang domain entity
  SharedMedia toEntity() {
    return SharedMedia(
      id: id,
      type: _parseMediaType(type),
      url: url,
      thumbnailUrl: thumbnailUrl,
      fileName: fileName,
      fileSize: fileSize,
      createdAt: createdAt,
      senderId: senderId,
      senderName: senderName,
    );
  }

  /// Convert từ entity sang model
  static SharedMediaModel fromEntity(SharedMedia entity) {
    return SharedMediaModel(
      id: entity.id,
      type: entity.type.name,
      url: entity.url,
      thumbnailUrl: entity.thumbnailUrl,
      fileName: entity.fileName,
      fileSize: entity.fileSize,
      createdAt: entity.createdAt,
      senderId: entity.senderId,
      senderName: entity.senderName,
    );
  }

  /// Parse string sang SharedMediaType enum
  static SharedMediaType _parseMediaType(String type) {
    switch (type.toLowerCase()) {
      case 'photo':
      case 'image':
        return SharedMediaType.photo;
      case 'video':
        return SharedMediaType.video;
      case 'file':
      case 'document':
        return SharedMediaType.file;
      case 'link':
      case 'url':
        return SharedMediaType.link;
      default:
        return SharedMediaType.file;
    }
  }
}
