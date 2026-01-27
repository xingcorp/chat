import 'package:freezed_annotation/freezed_annotation.dart';

part 'message_dto.freezed.dart';
part 'message_dto.g.dart';

/// **Message DTO (Data Transfer Object)**
///
/// Freezed model for backend API responses/requests.
/// Maps directly to backend message schema.
///
/// **Backend Schema:**
/// - Uses `message` not `content`
/// - Uses `urls` array not single `url`
/// - Uses `readerIds` not `readBy`
/// - Uses `conversationId` not `chatId`
@freezed
class MessageDto with _$MessageDto {
  const factory MessageDto({
    required String id,
    @JsonKey(name: 'message') required String content,
    @Default([]) List<String> urls,
    required String type,
    required int createdAt,
    int? editAt,
    int? deletedAt,
    String? replyMessageId,
    ReplyMessageDto? replyMessage,
    String? forwardedFromMessageId,
    String? fileName,
    required String senderId,
    SenderDto? sender,
    @JsonKey(name: 'conversationId') required String chatId,
    @Default([]) List<String> readerIds,
    @Default([]) List<ReactionDto> reactions,
    @Default([]) List<MentionDto> mentionTo,
  }) = _MessageDto;

  factory MessageDto.fromJson(Map<String, dynamic> json) =>
      _$MessageDtoFromJson(json);
}

/// **Sender DTO**
///
/// Nested object in message response
@freezed
class SenderDto with _$SenderDto {
  const factory SenderDto({
    required String id,
    @JsonKey(name: 'fullname') required String fullName,
    String? avatarUrl,
  }) = _SenderDto;

  factory SenderDto.fromJson(Map<String, dynamic> json) =>
      _$SenderDtoFromJson(json);
}

/// **Reply Message DTO**
///
/// Nested object for replied message
@freezed
class ReplyMessageDto with _$ReplyMessageDto {
  const factory ReplyMessageDto({
    required String id,
    @JsonKey(name: 'message') required String content,
    SenderDto? sender,
  }) = _ReplyMessageDto;

  factory ReplyMessageDto.fromJson(Map<String, dynamic> json) =>
      _$ReplyMessageDtoFromJson(json);
}

/// **Reaction DTO**
///
/// Nested object for message reactions
@freezed
class ReactionDto with _$ReactionDto {
  const factory ReactionDto({
    required String code,
    required String userId,
    UserReactionDto? user,
  }) = _ReactionDto;

  factory ReactionDto.fromJson(Map<String, dynamic> json) =>
      _$ReactionDtoFromJson(json);
}

/// **User Reaction DTO**
///
/// Nested object in reaction
@freezed
class UserReactionDto with _$UserReactionDto {
  const factory UserReactionDto({
    required String id,
    @JsonKey(name: 'fullname') required String fullName,
  }) = _UserReactionDto;

  factory UserReactionDto.fromJson(Map<String, dynamic> json) =>
      _$UserReactionDtoFromJson(json);
}

/// **Mention DTO**
///
/// Nested object for mentioned users
@freezed
class MentionDto with _$MentionDto {
  const factory MentionDto({
    required String id,
    @JsonKey(name: 'fullname') required String fullName,
  }) = _MentionDto;

  factory MentionDto.fromJson(Map<String, dynamic> json) =>
      _$MentionDtoFromJson(json);
}

/// **Message List Response DTO**
///
/// Wrapper for message list response with pagination
@freezed
class MessageListResponseDto with _$MessageListResponseDto {
  const factory MessageListResponseDto({
    LastKeyDto? lastKey,
    @Default([]) List<MessageDto> messages,
  }) = _MessageListResponseDto;

  factory MessageListResponseDto.fromJson(Map<String, dynamic> json) =>
      _$MessageListResponseDtoFromJson(json);
}

/// **Last Key DTO**
///
/// Pagination cursor for message list
@freezed
class LastKeyDto with _$LastKeyDto {
  const factory LastKeyDto({
    @JsonKey(name: 'conversationId') required String chatId,
    required int createdAt,
  }) = _LastKeyDto;

  factory LastKeyDto.fromJson(Map<String, dynamic> json) =>
      _$LastKeyDtoFromJson(json);
}
