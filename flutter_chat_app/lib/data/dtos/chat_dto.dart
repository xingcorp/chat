import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter_chat_app/shared/domain/entities/chat.dart';

part 'chat_dto.freezed.dart';
part 'chat_dto.g.dart';

LastMessageDto? _lastMessageFromJson(dynamic value) {
  if (value == null) return null;
  if (value is Map<String, dynamic>) return LastMessageDto.fromJson(value);
  if (value is List && value.isNotEmpty) {
    final first = value.first;
    if (first is Map<String, dynamic>) return LastMessageDto.fromJson(first);
  }
  return null;
}

UserBriefDto? _userBriefFromJson(dynamic value) {
  if (value == null) return null;
  if (value is Map<String, dynamic>) return UserBriefDto.fromJson(value);
  if (value is List && value.isNotEmpty) {
    final first = value.first;
    if (first is Map<String, dynamic>) return UserBriefDto.fromJson(first);
  }
  return null;
}

MentionToDto? _mentionToFromJson(dynamic value) {
  if (value == null) return null;
  if (value is Map<String, dynamic>) return MentionToDto.fromJson(value);
  if (value is List && value.isNotEmpty) {
    final first = value.first;
    if (first is Map<String, dynamic>) return MentionToDto.fromJson(first);
  }
  return null;
}

PersonalConversationDto? _personalConversationFromJson(dynamic value) {
  if (value == null) return null;
  if (value is Map<String, dynamic>) {
    return PersonalConversationDto.fromJson(value);
  }
  if (value is List && value.isNotEmpty) {
    final first = value.first;
    if (first is Map<String, dynamic>) {
      return PersonalConversationDto.fromJson(first);
    }
  }
  return null;
}

/// **Chat DTO (Data Transfer Object)**
///
/// Freezed model for backend API responses/requests.
/// Maps directly to backend conversation schema.
///
/// **Benefits:**
/// - Immutable by default
/// - Auto-generated copyWith, ==, hashCode
/// - Type-safe JSON serialization
/// - Less boilerplate code
///
/// **Backend Schema:**
/// - Uses `imgUrl` not `avatarUrl`
/// - Uses `conversationId` in some contexts
/// - Has nested `creator` and `members` objects
@freezed
class ChatDto with _$ChatDto {
  const factory ChatDto({
    required String id,
    String? name,
    required String type,
    String? description,
    @JsonKey(name: 'imgUrl') String? imageUrl,
    String? groupType,
    required int createdAt,
    int? lastMessageAt,
    String? lastMessageId,
    @JsonKey(fromJson: _lastMessageFromJson) LastMessageDto? lastMessage,
    @JsonKey(fromJson: _personalConversationFromJson)
    PersonalConversationDto? personalConversation,
    CreatorDto? creator,
    @Default([]) List<MemberDto> members,
  }) = _ChatDto;

  factory ChatDto.fromJson(Map<String, dynamic> json) =>
      _$ChatDtoFromJson(json);
}

@freezed
class LastMessageDto with _$LastMessageDto {
  const factory LastMessageDto({
    required String id,
    String? message,
    String? fileName,
    String? type,
    @JsonKey(fromJson: _userBriefFromJson) UserBriefDto? sender,
    @JsonKey(fromJson: _mentionToFromJson) MentionToDto? mentionTo,
  }) = _LastMessageDto;

  factory LastMessageDto.fromJson(Map<String, dynamic> json) =>
      _$LastMessageDtoFromJson(json);
}

@freezed
class UserBriefDto with _$UserBriefDto {
  const factory UserBriefDto({
    required String id,
    @JsonKey(name: 'fullname') required String fullName,
  }) = _UserBriefDto;

  factory UserBriefDto.fromJson(Map<String, dynamic> json) =>
      _$UserBriefDtoFromJson(json);
}

@freezed
class MentionToDto with _$MentionToDto {
  const factory MentionToDto({
    required String id,
    @JsonKey(name: 'fullname') required String fullName,
  }) = _MentionToDto;

  factory MentionToDto.fromJson(Map<String, dynamic> json) =>
      _$MentionToDtoFromJson(json);
}

@freezed
class PersonalConversationDto with _$PersonalConversationDto {
  const factory PersonalConversationDto({
    String? lastMessageReadId,
    @Default(0) int unreadCount,
  }) = _PersonalConversationDto;

  factory PersonalConversationDto.fromJson(Map<String, dynamic> json) =>
      _$PersonalConversationDtoFromJson(json);
}

/// **Creator DTO**
///
/// Nested object in conversation response
@freezed
class CreatorDto with _$CreatorDto {
  const factory CreatorDto({
    required String id,
    @JsonKey(name: 'fullname') required String fullName,
    @Default([]) List<String> imageUrls,
  }) = _CreatorDto;

  factory CreatorDto.fromJson(Map<String, dynamic> json) =>
      _$CreatorDtoFromJson(json);
}

/// **Member DTO**
///
/// Nested object in conversation response
@freezed
class MemberDto with _$MemberDto {
  const factory MemberDto({
    required String id,
    required String userId,
    @Default(false) bool admin,
    @Default(false) bool connected,
    @Default(false) bool hide,
    @Default(0) int unreadCount,
    String? lastMessageReadId,
    UserDto? user,
  }) = _MemberDto;

  factory MemberDto.fromJson(Map<String, dynamic> json) =>
      _$MemberDtoFromJson(json);
}

/// **User DTO**
///
/// Nested object in member response
@freezed
class UserDto with _$UserDto {
  const factory UserDto({
    required String id,
    @JsonKey(name: 'fullname') required String fullName,
    @Default([]) List<String> imageUrls,
    String? email,
  }) = _UserDto;

  factory UserDto.fromJson(Map<String, dynamic> json) =>
      _$UserDtoFromJson(json);
}

/// **Chat List Response DTO**
///
/// Wrapper for conversation list response
@freezed
class ChatListResponseDto with _$ChatListResponseDto {
  const factory ChatListResponseDto({
    required int total,
    @Default([]) List<ChatDto> conversations,
  }) = _ChatListResponseDto;

  factory ChatListResponseDto.fromJson(Map<String, dynamic> json) =>
      _$ChatListResponseDtoFromJson(json);
}

/// **Mapper Extensions**
///
/// Convert DTOs to Domain Entities

extension ChatDtoMapper on ChatDto {
  /// Convert ChatDto to Chat entity
  Chat toDomain() {
    return Chat(
      id: id,
      name: name,
      avatarUrl: imageUrl,
      lastMessageTime: lastMessageAt != null 
          ? DateTime.fromMillisecondsSinceEpoch(lastMessageAt!)
          : null,
      lastMessagePreview: lastMessage?.message,
      unreadCount: personalConversation?.unreadCount ?? members.firstOrNull?.unreadCount ?? 0,
      type: _mapChatType(type),
      participantIds: members.map((m) => m.userId).toList(),
    );
  }
  
  /// Map string type to ChatType enum
  ChatType _mapChatType(String type) {
    switch (type.toLowerCase()) {
      case 'direct':
      case 'private':
        return ChatType.direct;
      case 'group':
        return ChatType.group;
      case 'channel':
        return ChatType.channel;
      default:
        return ChatType.direct;
    }
  }
}

extension ChatListResponseDtoMapper on ChatListResponseDto {
  /// Convert list of ChatDto to list of Chat entities
  List<Chat> toDomainList() {
    return conversations.map((dto) => dto.toDomain()).toList();
  }
}
