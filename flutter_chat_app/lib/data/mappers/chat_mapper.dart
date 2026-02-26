import 'dart:convert';

import 'package:flutter_chat_app/data/dtos/chat_dto.dart';
import 'package:flutter_chat_app/data/models/chat_model.dart';
import 'package:flutter_chat_app/shared/domain/entities/chat.dart';

/// **Chat Mapper**
///
/// Converts between ChatDto (API) and ChatModel (Isar DB).
///
/// **Responsibilities:**
/// - Map DTO fields to Model fields
/// - Extract current user's unreadCount from members
/// - Find admin from members list
/// - Convert timestamps
/// - Store additional data in metadata
class ChatMapper {
  /// **Convert ChatDto to ChatModel**
  ///
  /// Maps backend DTO to Isar model for local storage.
  ///
  /// **Parameters:**
  /// - dto: ChatDto from backend API
  /// - currentUserId: Current user's ID to extract unreadCount
  ///
  /// **Returns:** ChatModel ready for Isar storage
  static ChatModel toModel(ChatDto dto, String currentUserId) {
    // Extract participant IDs from members (filter out nulls)
    final participantIds = dto.members
        .map((m) => m.userId)
        .whereType<String>()
        .toList();

    // Find admin (first member with admin=true)
    final adminMember = dto.members.firstWhere(
      (m) => m.admin,
      orElse: () => const MemberDto(id: '', userId: ''),
    );
    final adminId = (adminMember.userId?.isNotEmpty ?? false) ? adminMember.userId : null;
    
    // Find current user's member to get unreadCount
    final currentUserMember = dto.members.firstWhere(
      (m) => m.userId == currentUserId,
      orElse: () => const MemberDto(id: '', userId: ''),
    );
    final unreadCount = currentUserMember.unreadCount;
    
    // Parse type
    final typeStr = dto.type.toLowerCase();
    final type = ChatType.values.firstWhere(
      (e) => e.name == typeStr,
      orElse: () => ChatType.direct,
    );
    
    // Convert timestamps
    final createdAt = DateTime.fromMillisecondsSinceEpoch(dto.createdAt);
    final lastMessageTime = dto.lastMessageAt != null
        ? DateTime.fromMillisecondsSinceEpoch(dto.lastMessageAt!)
        : null;
    
    // Store additional backend data in metadata
    final metadata = jsonEncode({
      'description': dto.description,
      'groupType': dto.groupType,
      'creator': dto.creator?.toJson(),
      'members': dto.members.map((m) => m.toJson()).toList(),
    });
    
    return ChatModel(
      serverId: dto.id,
      name: dto.name,
      type: type,
      lastMessageId: dto.lastMessageId,
      lastMessagePreview: null, // Backend doesn't provide preview
      lastMessageTime: lastMessageTime,
      unreadCount: unreadCount,
      participantIds: participantIds,
      adminId: adminId,
      avatarUrl: dto.imageUrl, // DTO uses imageUrl, Model uses avatarUrl
      isMuted: false, // Backend doesn't provide this
      isPinned: false, // Backend doesn't provide this
      createdAt: createdAt,
      updatedAt: lastMessageTime,
      metadata: metadata,
    );
  }

  /// **Convert ChatModel to ChatDto**
  ///
  /// Maps Isar model to DTO for backend API requests.
  /// Used for creating/updating groups.
  ///
  /// **Parameters:**
  /// - model: ChatModel from Isar storage
  ///
  /// **Returns:** ChatDto ready for backend API
  static ChatDto toDto(ChatModel model) {
    // Parse metadata
    final metadataMap = model.metadataMap ?? {};
    
    // Convert type
    final type = model.type.name.substring(0, 1).toUpperCase() + 
                 model.type.name.substring(1);
    
    // Convert timestamps
    final createdAt = model.createdAt.millisecondsSinceEpoch;
    final lastMessageAt = model.lastMessageTime?.millisecondsSinceEpoch;
    
    // Parse creator from metadata
    CreatorDto? creator;
    if (metadataMap['creator'] != null) {
      creator = CreatorDto.fromJson(metadataMap['creator'] as Map<String, dynamic>);
    }
    
    // Parse members from metadata
    final members = <MemberDto>[];
    if (metadataMap['members'] != null) {
      final membersList = metadataMap['members'] as List;
      members.addAll(
        membersList.map((m) => MemberDto.fromJson(m as Map<String, dynamic>)),
      );
    }
    
    return ChatDto(
      id: model.serverId,
      name: model.name,
      type: type,
      description: metadataMap['description'] as String?,
      imageUrl: model.avatarUrl,
      groupType: metadataMap['groupType'] as String?,
      createdAt: createdAt,
      lastMessageAt: lastMessageAt,
      lastMessageId: model.lastMessageId,
      creator: creator,
      members: members,
    );
  }

  /// **Convert list of ChatDto to list of ChatModel**
  static List<ChatModel> toModelList(List<ChatDto> dtos, String currentUserId) {
    return dtos.map((dto) => toModel(dto, currentUserId)).toList();
  }

  /// **Convert list of ChatModel to list of ChatDto**
  static List<ChatDto> toDtoList(List<ChatModel> models) {
    return models.map((model) => toDto(model)).toList();
  }
}
