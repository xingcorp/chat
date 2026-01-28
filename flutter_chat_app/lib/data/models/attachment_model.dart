import 'dart:convert';
import 'package:flutter_chat_app/domain/entities/attachment.dart';

/// Data model for Attachment with JSON serialization
class AttachmentModel extends Attachment {
  AttachmentModel({
    required super.id,
    required super.name,
    super.localPath,
    super.url,
    required super.type,
    required super.mimeType,
    required super.size,
    super.width,
    super.height,
    super.duration,
    super.thumbnailUrl,
    super.metadata,
    super.status,
    super.uploadProgress,
    super.errorMessage,
  });
  
  /// Create from domain entity
  factory AttachmentModel.fromDomain(Attachment attachment) {
    return AttachmentModel(
      id: attachment.id,
      name: attachment.name,
      localPath: attachment.localPath,
      url: attachment.url,
      type: attachment.type,
      mimeType: attachment.mimeType,
      size: attachment.size,
      width: attachment.width,
      height: attachment.height,
      duration: attachment.duration,
      thumbnailUrl: attachment.thumbnailUrl,
      metadata: attachment.metadata,
      status: attachment.status,
      uploadProgress: attachment.uploadProgress,
      errorMessage: attachment.errorMessage,
    );
  }
  
  /// Convert to domain entity
  Attachment toDomain() {
    return Attachment(
      id: id,
      name: name,
      localPath: localPath,
      url: url,
      type: type,
      mimeType: mimeType,
      size: size,
      width: width,
      height: height,
      duration: duration,
      thumbnailUrl: thumbnailUrl,
      metadata: metadata,
      status: status,
      uploadProgress: uploadProgress,
      errorMessage: errorMessage,
    );
  }
  
  /// Create from JSON
  factory AttachmentModel.fromJson(String jsonString) {
    final json = jsonDecode(jsonString) as Map<String, dynamic>;
    final attachment = Attachment.fromJson(json);
    return AttachmentModel.fromDomain(attachment);
  }
  
  /// Create from Map
  factory AttachmentModel.fromMap(Map<String, dynamic> json) {
    final attachment = Attachment.fromJson(json);
    return AttachmentModel.fromDomain(attachment);
  }
  
  /// Convert to JSON string
  String toJsonString() {
    return jsonEncode(toJson());
  }
  
  /// Create list from JSON array string
  static List<AttachmentModel> fromJsonList(String jsonString) {
    final List<dynamic> jsonList = jsonDecode(jsonString);
    return jsonList
        .map((json) => AttachmentModel.fromMap(json as Map<String, dynamic>))
        .toList();
  }
  
  /// Convert list to JSON array string
  static String toJsonList(List<AttachmentModel> attachments) {
    final jsonList = attachments.map((a) => a.toJson()).toList();
    return jsonEncode(jsonList);
  }
  
  @override
  AttachmentModel copyWith({
    String? id,
    String? name,
    String? localPath,
    String? url,
    AttachmentType? type,
    String? mimeType,
    int? size,
    int? width,
    int? height,
    int? duration,
    String? thumbnailUrl,
    Map<String, dynamic>? metadata,
    AttachmentStatus? status,
    int? uploadProgress,
    String? errorMessage,
  }) {
    return AttachmentModel(
      id: id ?? this.id,
      name: name ?? this.name,
      localPath: localPath ?? this.localPath,
      url: url ?? this.url,
      type: type ?? this.type,
      mimeType: mimeType ?? this.mimeType,
      size: size ?? this.size,
      width: width ?? this.width,
      height: height ?? this.height,
      duration: duration ?? this.duration,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      metadata: metadata ?? this.metadata,
      status: status ?? this.status,
      uploadProgress: uploadProgress ?? this.uploadProgress,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
