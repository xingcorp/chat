import 'dart:convert';
import 'package:flutter_chat_app/data/dtos/message_dto.dart';
import 'package:flutter_chat_app/data/models/message_model.dart';
import 'package:uuid/uuid.dart';

/// **Message Mapper**
///
/// Converts between MessageDto (API) and MessageModel (Isar DB).
///
/// **Responsibilities:**
/// - Map DTO fields to Model fields
/// - Convert timestamps
/// - Parse message type
/// - Store additional data in metadata
class MessageMapper {
  static const _uuid = Uuid();

  /// **Convert MessageDto to MessageModel**
  ///
  /// Maps backend DTO to Isar model for local storage.
  ///
  /// **Parameters:**
  /// - dto: MessageDto from backend API
  ///
  /// **Returns:** MessageModel ready for Isar storage
  static MessageModel toModel(MessageDto dto) {
    // Generate local ID from server ID or create new
    final localId = dto.id.isNotEmpty ? dto.id : _uuid.v4();
    
    // Parse type
    final typeStr = dto.type.toLowerCase();
    final type = MessageType.values.firstWhere(
      (e) => e.name == typeStr,
      orElse: () => MessageType.text,
    );
    
    // Convert timestamps
    final createdAt = DateTime.fromMillisecondsSinceEpoch(dto.createdAt);
    final updatedAt = dto.editAt != null
        ? DateTime.fromMillisecondsSinceEpoch(dto.editAt!)
        : null;
    
    // Check if deleted
    final isDeleted = dto.deletedAt != null;
    
    // Build metadata with backend-specific fields
    final metadata = jsonEncode({
      'urls': dto.urls,
      'fileName': dto.fileName,
      'reactions': dto.reactions.map((r) => r.toJson()).toList(),
      'mentionTo': dto.mentionTo.map((m) => m.toJson()).toList(),
      'replyMessage': dto.replyMessage?.toJson(),
      'forwardedFromMessageId': dto.forwardedFromMessageId,
      'sender': dto.sender?.toJson(),
    });
    
    return MessageModel(
      serverId: dto.id,
      localId: localId,
      chatId: dto.chatId,
      senderId: dto.senderId,
      readBy: dto.readerIds,
      content: dto.content, // DTO uses content (mapped from 'message')
      type: type,
      status: MessageStatus.sent, // Backend messages are already sent
      createdAt: createdAt,
      updatedAt: updatedAt,
      replyToMessageId: dto.replyMessageId,
      metadata: metadata,
      isDeleted: isDeleted,
      isPinned: false, // Backend doesn't provide this
      retryCount: 0,
      errorMessage: null,
    );
  }

  /// **Convert MessageModel to MessageDto**
  ///
  /// Maps Isar model to DTO for backend API requests.
  /// Used for sending messages.
  ///
  /// **Parameters:**
  /// - model: MessageModel from Isar storage
  /// - receiverId: Optional receiver ID for direct chat
  ///
  /// **Returns:** MessageDto ready for backend API
  static MessageDto toDto(MessageModel model, {String? receiverId}) {
    // Parse metadata
    final metadataMap = model.metadataMap ?? {};
    
    // Convert type to uppercase
    final type = model.type.name.toUpperCase();
    
    // Convert timestamps
    final createdAt = model.createdAt.millisecondsSinceEpoch;
    final editAt = model.updatedAt?.millisecondsSinceEpoch;
    final deletedAt = model.isDeleted ? DateTime.now().millisecondsSinceEpoch : null;
    
    // Extract fields from metadata
    final urls = (metadataMap['urls'] as List?)?.cast<String>() ?? <String>[];
    final fileName = metadataMap['fileName'] as String?;
    final forwardedFromMessageId = metadataMap['forwardedFromMessageId'] as String?;
    
    // Parse reactions from metadata
    final reactions = <ReactionDto>[];
    if (metadataMap['reactions'] != null) {
      final reactionsList = metadataMap['reactions'] as List;
      reactions.addAll(
        reactionsList.map((r) => ReactionDto.fromJson(r as Map<String, dynamic>)),
      );
    }
    
    // Parse mentions from metadata
    final mentions = <MentionDto>[];
    if (metadataMap['mentionTo'] != null) {
      final mentionsList = metadataMap['mentionTo'] as List;
      mentions.addAll(
        mentionsList.map((m) => MentionDto.fromJson(m as Map<String, dynamic>)),
      );
    }
    
    // Parse reply message from metadata
    ReplyMessageDto? replyMessage;
    if (metadataMap['replyMessage'] != null) {
      replyMessage = ReplyMessageDto.fromJson(
        metadataMap['replyMessage'] as Map<String, dynamic>,
      );
    }
    
    // Parse sender from metadata
    SenderDto? sender;
    if (metadataMap['sender'] != null) {
      sender = SenderDto.fromJson(
        metadataMap['sender'] as Map<String, dynamic>,
      );
    }
    
    return MessageDto(
      id: model.serverId ?? model.localId,
      content: model.content, // Model uses content, DTO maps to 'message'
      urls: urls,
      type: type,
      createdAt: createdAt,
      editAt: editAt,
      deletedAt: deletedAt,
      replyMessageId: model.replyToMessageId,
      replyMessage: replyMessage,
      forwardedFromMessageId: forwardedFromMessageId,
      fileName: fileName,
      senderId: model.senderId,
      sender: sender,
      chatId: model.chatId,
      readerIds: model.readBy,
      reactions: reactions,
      mentionTo: mentions,
    );
  }

  /// **Convert list of MessageDto to list of MessageModel**
  static List<MessageModel> toModelList(List<MessageDto> dtos) {
    return dtos.map((dto) => toModel(dto)).toList();
  }

  /// **Convert list of MessageModel to list of MessageDto**
  static List<MessageDto> toDtoList(List<MessageModel> models) {
    return models.map((model) => toDto(model)).toList();
  }
}
