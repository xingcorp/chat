import 'package:freezed_annotation/freezed_annotation.dart';

part 'chat_object_dto.freezed.dart';
part 'chat_object_dto.g.dart';

/// **Storage Upload DTOs**
///
/// Freezed models for file upload operations.
/// Maps to backend storageGeneratePresignedUrls GraphQL mutation.
///
/// **Matching Angular:** storage-query.ts, types.ts
///
/// **Backend API:**
/// - storageGeneratePresignedUrls: Generate pre-signed upload URLs
/// - chatObjectGetUrl: Get download URL for uploaded files
///
/// **Upload Flow:**
/// 1. Call storageGeneratePresignedUrls → get presignedUrl, path, url
/// 2. PUT file binary to presignedUrl with Content-Type header
/// 3. Use url in chatMessageAdd (urls field)

/// **Generate Presigned URL Response Item**
///
/// Single file upload data from storageGeneratePresignedUrls response.
///
/// **Matching Angular:** GeneratePresignedUrlResponse in types.ts
@freezed
class PresignedUrlDataDto with _$PresignedUrlDataDto {
  const factory PresignedUrlDataDto({
    /// Unique file ID from storage service
    required String id,

    /// Pre-signed URL for direct upload (PUT request)
    required String presignedUrl,

    /// Storage path for referencing uploaded file
    required String path,

    /// CDN URL for accessing uploaded file (use this in chatMessageAdd urls)
    String? url,
  }) = _PresignedUrlDataDto;

  factory PresignedUrlDataDto.fromJson(Map<String, dynamic> json) =>
      _$PresignedUrlDataDtoFromJson(json);
}

/// **Storage Generate Presigned URLs Response**
///
/// Response from storageGeneratePresignedUrls mutation.
/// Contains array of presigned upload data.
///
/// **Matching Angular:** GeneratePresignedUrlsResponse in types.ts
@freezed
class StorageUploadResponseDto with _$StorageUploadResponseDto {
  const factory StorageUploadResponseDto({
    /// Array of presigned URL data for each file
    required List<PresignedUrlDataDto> data,
  }) = _StorageUploadResponseDto;

  factory StorageUploadResponseDto.fromJson(Map<String, dynamic> json) =>
      _$StorageUploadResponseDtoFromJson(json);
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

/// **Generate Presigned URL Params**
///
/// Input parameters for a single file upload request.
///
/// **Matching Angular:** GeneratePresignedUrlParams in storage.args.ts
class GeneratePresignedUrlParams {
  /// Original filename with extension
  final String fileName;

  /// File MIME type (e.g., "image/jpeg", "application/pdf")
  final String fileType;

  const GeneratePresignedUrlParams({
    required this.fileName,
    required this.fileType,
  });

  Map<String, dynamic> toJson() => {
        'fileName': fileName,
        'fileType': fileType,
      };
}

/// **Upload File Args**
///
/// Input for storageGeneratePresignedUrls mutation.
///
/// **Matching Angular:** UploadFileArgs in storage.args.ts
class UploadFileArgs {
  /// List of files to generate presigned URLs for
  final List<GeneratePresignedUrlParams> files;

  const UploadFileArgs({required this.files});

  Map<String, dynamic> toJson() => {
        'files': files.map((f) => f.toJson()).toList(),
      };
}

// ============================================================================
// LEGACY TYPES (kept for backward compatibility, will be removed)
// ============================================================================

/// @deprecated Use StorageUploadResponseDto instead
@freezed
class ChatObjectUploadResponseDto with _$ChatObjectUploadResponseDto {
  const factory ChatObjectUploadResponseDto({
    /// Pre-signed GCP Cloud Storage URL for direct upload (PUT request)
    required String uploadUrl,

    /// Storage path for referencing uploaded file
    required String path,
  }) = _ChatObjectUploadResponseDto;

  factory ChatObjectUploadResponseDto.fromJson(Map<String, dynamic> json) =>
      _$ChatObjectUploadResponseDtoFromJson(json);
}

/// @deprecated Use GeneratePresignedUrlParams instead
enum ChatObjectType {
  @JsonValue('MESSAGE')
  message,

  @JsonValue('GROUP')
  group,

  @JsonValue('STORY')
  story,
}
