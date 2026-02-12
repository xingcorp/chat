import 'package:freezed_annotation/freezed_annotation.dart';

part 'chat_object_dto.freezed.dart';
part 'chat_object_dto.g.dart';

/// **Chat Object DTO (Data Transfer Object)**
///
/// Freezed model for file upload/download operations.
/// Maps to backend chatObject GraphQL schema.
///
/// **Backend API:**
/// - chatObjectGenLinkUpload: Generate pre-signed upload URL
/// - chatObjectGetUrl: Get download URL for uploaded files
///
/// **Upload Flow:**
/// 1. Call chatObjectGenLinkUpload → get uploadUrl & path
/// 2. PUT file to uploadUrl (GCP Cloud Storage)
/// 3. Use path in chatMessageAdd (urls field)
@freezed
class ChatObjectUploadResponseDto with _$ChatObjectUploadResponseDto {
  const factory ChatObjectUploadResponseDto({
    /// Pre-signed GCP Cloud Storage URL for direct upload (PUT request)
    required String uploadUrl,

    /// Storage path for referencing uploaded file
    /// Format: MESSAGE/{conversationId}/{timestamp}/{filename}
    required String path,
  }) = _ChatObjectUploadResponseDto;

  factory ChatObjectUploadResponseDto.fromJson(Map<String, dynamic> json) =>
      _$ChatObjectUploadResponseDtoFromJson(json);
}

/// **Chat Object Get URL Response DTO**
///
/// Response when retrieving download URL for uploaded files.
@freezed
class ChatObjectGetUrlResponseDto with _$ChatObjectGetUrlResponseDto {
  const factory ChatObjectGetUrlResponseDto({
    /// Original storage path
    required String path,

    /// Firebase CDN download URL
    required String url,
  }) = _ChatObjectGetUrlResponseDto;

  factory ChatObjectGetUrlResponseDto.fromJson(Map<String, dynamic> json) =>
      _$ChatObjectGetUrlResponseDtoFromJson(json);
}

/// **Chat Object Type**
///
/// Type of object being uploaded.
enum ChatObjectType {
  /// Message attachment (requires conversationId)
  @JsonValue('MESSAGE')
  message,

  /// Group avatar
  @JsonValue('GROUP')
  group,

  /// Story media
  @JsonValue('STORY')
  story,
}

/// **Chat Object Upload Input**
///
/// Input for generating upload link.
class ChatObjectUploadInput {
  /// Original filename with extension
  final String filename;

  /// Conversation ID (required for MESSAGE type)
  final String? conversationId;

  /// Upload type
  final ChatObjectType type;

  /// File MIME type (e.g., "image/jpeg", "application/pdf")
  final String mimetype;

  const ChatObjectUploadInput({
    required this.filename,
    this.conversationId,
    required this.type,
    required this.mimetype,
  });

  Map<String, dynamic> toJson() {
    return {
      'filename': filename,
      if (conversationId != null) 'conversationId': conversationId,
      'type': type.name.toUpperCase(),
      'mimetype': mimetype,
    };
  }
}
