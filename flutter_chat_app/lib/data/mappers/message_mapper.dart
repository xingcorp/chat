import 'dart:convert';
import 'package:flutter_chat_app/data/dtos/message_dto.dart';
import 'package:flutter_chat_app/data/models/message_model.dart';
import 'package:flutter_chat_app/shared/domain/entities/chat_message.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/foundation.dart';

/// **Message Mapper**
///
/// Converts between MessageDto (API), MessageModel (Isar DB), and ChatMessage (Domain Entity).
///
/// **Responsibilities:**
/// - Map DTO fields to Model fields
/// - Map DTO fields to Domain Entity fields
/// - Convert timestamps
/// - Parse message type
/// - Store additional data in metadata
class MessageMapper {
  static const _uuid = Uuid();

  /// **Convert MessageDto to ChatMessage Domain Entity**
  ///
  /// Maps backend DTO directly to domain entity for real-time events.
  /// Bypasses MessageModel layer since real-time messages are stored by repository.
  ///
  /// **Parameters:**
  /// - dto: MessageDto from backend API or Socket.IO event
  ///
  /// **Returns:** ChatMessage domain entity
  static ChatMessage toEntity(MessageDto dto) {
    // Parse content type
    final typeStr = dto.type.toLowerCase();
    final contentType = _parseContentType(typeStr);
    
    // Convert timestamps
    final createdAt = DateTime.fromMillisecondsSinceEpoch(dto.createdAt);
    final updatedAt = dto.editAt != null
        ? DateTime.fromMillisecondsSinceEpoch(dto.editAt!)
        : createdAt;
    
    // Create sender
    final sender = MessageSender(
      id: dto.senderId,
      name: dto.sender?.fullName ?? 'Unknown',
      avatar: (dto.sender?.imageUrls.isNotEmpty ?? false)
          ? dto.sender!.imageUrls.first
          : null,
    );
    
    // Parse attachments from URLs
    final attachments = dto.urls.map((url) {
      return MessageAttachment(
        id: _uuid.v4(),
        url: url,
        type: _getAttachmentType(url),
        name: dto.fileName ?? _getFileNameFromUrl(url),
        size: 0, // Not provided by backend
      );
    }).toList();

    final mentions = dto.mentionTo
        .map(
          (m) => MessageSender(
            id: m.id,
            name: m.fullName,
            avatar: null,
          ),
        )
        .toList();

    final reactions = <MessageReaction>[];
    for (final r in dto.reactions) {
      final reactorNameMap = <String, String>{};
      for (var i = 0; i < r.reactorIds.length && i < r.reactors.length; i++) {
        reactorNameMap[r.reactorIds[i]] = r.reactors[i].fullName;
      }

      for (final reactorId in r.reactorIds) {
        reactions.add(
          MessageReaction(
            code: r.code,
            userId: reactorId,
            userName: reactorNameMap[reactorId],
            createdAt: createdAt,
          ),
        );
      }
    }
    
    // Convert nested reply message (if backend provides it)
    ChatMessage? replyMessage;
    if (dto.replyMessage != null) {
      final r = dto.replyMessage!;

      if (kDebugMode) {
        debugPrint(
          '[dto.replyMessage] parentId=${dto.id} replyId=${r.id} '
          'type=${r.type} urls=${r.urls.length} fileName=${r.fileName}',
        );
      }

      final replyTypeStr = (r.type ?? 'text').toLowerCase();
      final replyContentType = _parseContentType(replyTypeStr);

      final replySender = r.sender;
      final replySenderEntity = replySender != null
          ? MessageSender(
              id: replySender.id,
              name: replySender.fullName,
              avatar: replySender.imageUrls.isNotEmpty
                  ? replySender.imageUrls.first
                  : null,
            )
          : MessageSender(id: '', name: 'Unknown');

      final replyAttachments = r.urls.map((url) {
        return MessageAttachment(
          id: _uuid.v4(),
          url: url,
          type: _getAttachmentType(url),
          name: r.fileName ?? _getFileNameFromUrl(url),
          size: 0,
        );
      }).toList();

      final replyMentions = r.mentionTo
          .map(
            (m) => MessageSender(
              id: m.id,
              name: m.fullName,
              avatar: null,
            ),
          )
          .toList();

      replyMessage = ChatMessage(
        id: r.id,
        chatId: dto.chatId,
        content: r.content,
        contentType: replyContentType,
        sender: replySenderEntity,
        createdAt: createdAt,
        updatedAt: createdAt,
        urls: r.urls,
        fileName: r.fileName,
        attachments: replyAttachments,
        mentionTo: replyMentions,
      );
    }

    return ChatMessage(
      id: dto.id,
      chatId: dto.chatId,
      content: dto.content,
      contentType: contentType,
      sender: sender,
      createdAt: createdAt,
      updatedAt: updatedAt,
      readBy: dto.readerIds,
      deliveredTo: const [], // Not provided by backend
      attachments: attachments,
      mentionTo: mentions,
      replyMessageId: dto.replyMessageId,
      replyMessage: replyMessage,
      reactions: reactions,
    );
  }

  /// **Parse ContentType from string**
  static ContentType _parseContentType(String typeStr) {
    switch (typeStr) {
      case 'text':
        return ContentType.text;
      case 'image':
        return ContentType.image;
      case 'video':
        return ContentType.video;
      case 'audio':
        return ContentType.audio;
      case 'doc':
      case 'file':
        return ContentType.file;
      case 'location':
        return ContentType.location;
      case 'link':
        return ContentType.link;
      case 'event':
        return ContentType.event;
      case 'voice_note':
        return ContentType.audio;
      default:
        return ContentType.text;
    }
  }

  /// **Get attachment type from URL**
  static String _getAttachmentType(String url) {
    final extension = url.split('.').last.toLowerCase();
    if (['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(extension)) {
      return 'image';
    } else if (['mp4', 'mov', 'avi', 'mkv'].contains(extension)) {
      return 'video';
    } else if (['mp3', 'wav', 'ogg', 'm4a'].contains(extension)) {
      return 'audio';
    } else {
      return 'file';
    }
  }

  /// **Get file name from URL**
  static String _getFileNameFromUrl(String url) {
    try {
      return Uri.parse(url).pathSegments.last;
    } catch (_) {
      return 'file';
    }
  }

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
    final MessageType type;
    switch (typeStr) {
      case 'text':
        type = MessageType.text;
        break;
      case 'image':
        type = MessageType.image;
        break;
      case 'video':
        type = MessageType.video;
        break;
      case 'audio':
        type = MessageType.audio;
        break;
      case 'voice_note':
        type = MessageType.audio;
        break;
      case 'doc':
      case 'file':
        type = MessageType.file;
        break;
      case 'location':
        type = MessageType.location;
        break;
      default:
        type = MessageType.text;
        break;
    }
    
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

    final mentionToJson = dto.mentionTo
        .map(
          (m) => {
            'id': m.id,
            'name': m.fullName,
          },
        )
        .toList();
    
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
      urls: dto.urls,
      fileName: dto.fileName,
      forwardedFromMessageId: dto.forwardedFromMessageId,
      metadata: metadata,
      mentionToJson: jsonEncode(mentionToJson),
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
