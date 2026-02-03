import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter_chat_app/shared/domain/entities/chat.dart';

part 'chat_dto.freezed.dart';
part 'chat_dto.g.dart';

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
    CreatorDto? creator,
    @Default([]) List<MemberDto> members,
  }) = _ChatDto;

  factory ChatDto.fromJson(Map<String, dynamic> json) =>
      _$ChatDtoFromJson(json);
}

/// **Creator DTO**
///
/// Nested object in conversation response
@freezed
class CreatorDto with _$CreatorDto {
  const factory CreatorDto({
    required String id,
    @JsonKey(name: 'fullname') required String fullName,
    String? avatarUrl,
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
    String? avatarUrl,
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
      lastMessagePreview: null, // Not available in DTO
      unreadCount: members.firstOrNull?.unreadCount ?? 0,
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
