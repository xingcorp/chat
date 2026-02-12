import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter_chat_app/shared/domain/entities/chat_message.dart';

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
    // System event fields (khớp Angular: ConversationActionType)
    String? actionType,
    String? actorId,
    SenderDto? actor,
    @Default([]) List<String> targetUserIds,
    @Default([]) List<SenderDto> targetUsers,
    String? newValue,
    String? oldValue,
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
    @Default([]) List<String> imageUrls,
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
    String? type,
    @Default([]) List<String> urls,
    String? fileName,
    @Default([]) List<MentionDto> mentionTo,
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
    @Default([]) List<String> reactorIds,
    @Default([]) List<UserReactionDto> reactors,
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
    @JsonKey(name: 'fullname') required String fullName,
    @Default([]) List<String> imageUrls,
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

/// **Mapper Extensions**
///
/// Convert DTOs to domain entities

extension MessageDtoMapper on MessageDto {
  /// Convert MessageDto to ChatMessage domain entity
  ChatMessage toDomain() {
    // Parse content type from string (backend uses ChatMessageType enum: TEXT/IMAGE/VIDEO/DOC/...)
    final typeStr = type.toLowerCase();
    ContentType contentType;
    switch (typeStr) {
      case 'text':
        contentType = ContentType.text;
        break;
      case 'image':
        contentType = ContentType.image;
        break;
      case 'video':
        contentType = ContentType.video;
        break;
      case 'audio':
        contentType = ContentType.audio;
        break;
      case 'voice_note':
        contentType = ContentType.audio;
        break;
      case 'doc':
      case 'file':
        contentType = ContentType.file;
        break;
      case 'location':
        contentType = ContentType.location;
        break;
      case 'link':
        contentType = ContentType.link;
        break;
      case 'log':
      case 'event':
        contentType = ContentType.event;
        break;
      default:
        contentType = ContentType.text;
        break;
    }

    // Convert sender
    final messageSender = sender != null
        ? MessageSender(
            id: sender!.id,
            name: sender!.fullName,
            avatar: sender!.imageUrls.isNotEmpty ? sender!.imageUrls.first : null,
          )
        : MessageSender(
            id: senderId,
            name: 'Unknown',
            avatar: null,
          );

    // Convert reactions - map userName from reactors
    final messageReactions = <MessageReaction>[];
    for (final r in reactions) {
      // Create map userId -> userName
      final reactorNameMap = <String, String>{};
      for (var i = 0; i < r.reactorIds.length && i < r.reactors.length; i++) {
        reactorNameMap[r.reactorIds[i]] = r.reactors[i].fullName;
      }

      for (final reactorId in r.reactorIds) {
        messageReactions.add(
          MessageReaction(
            code: r.code,
            userId: reactorId,
            userName: reactorNameMap[reactorId],
            createdAt: DateTime.now(), // Backend doesn't provide timestamp
          ),
        );
      }
    }

    // Convert attachments from URLs
    final messageAttachments = urls.map((url) {
      return MessageAttachment(
        id: url.hashCode.toString(),
        url: url,
        type: type,
        size: 0, // Backend doesn't provide size
        name: fileName ?? url.split('/').last,
      );
    }).toList();

    final mentions = mentionTo
        .map(
          (m) => MessageSender(
            id: m.id,
            name: m.fullName,
            avatar: null,
          ),
        )
        .toList();

    // Convert reply message
    ChatMessage? replyMsg;
    if (replyMessage != null) {
      final replySender = replyMessage!.sender;

      // Convert reply content type (fallback to text if missing)
      final replyTypeStr = replyMessage!.type?.toLowerCase();
      ContentType replyContentType = ContentType.text;
      switch (replyTypeStr) {
        case 'image':
          replyContentType = ContentType.image;
          break;
        case 'video':
          replyContentType = ContentType.video;
          break;
        case 'audio':
        case 'voice_note':
          replyContentType = ContentType.audio;
          break;
        case 'doc':
        case 'file':
          replyContentType = ContentType.file;
          break;
        case 'location':
          replyContentType = ContentType.location;
          break;
        case 'link':
          replyContentType = ContentType.link;
          break;
        case 'log':
        case 'event':
          replyContentType = ContentType.event;
          break;
      }

      final replyMentions = replyMessage!.mentionTo
          .map(
            (m) => MessageSender(
              id: m.id,
              name: m.fullName,
              avatar: null,
            ),
          )
          .toList();

      replyMsg = ChatMessage(
        id: replyMessage!.id,
        chatId: chatId,
        content: replyMessage!.content,
        contentType: replyContentType,
        sender: replySender != null
            ? MessageSender(
                id: replySender.id,
                name: replySender.fullName,
                avatar: replySender.imageUrls.isNotEmpty
                    ? replySender.imageUrls.first
                    : null,
              )
            : MessageSender(id: '', name: 'Unknown'),
        createdAt: DateTime.fromMillisecondsSinceEpoch(createdAt),
        updatedAt: DateTime.fromMillisecondsSinceEpoch(createdAt),
        urls: replyMessage!.urls,
        fileName: replyMessage!.fileName,
        mentionTo: replyMentions,
      );
    }

    // Convert actor (system events)
    MessageSender? actorSender;
    if (actor != null) {
      actorSender = MessageSender(
        id: actor!.id,
        name: actor!.fullName,
        avatar: actor!.imageUrls.isNotEmpty ? actor!.imageUrls.first : null,
      );
    } else if (actorId != null) {
      actorSender = MessageSender(id: actorId!, name: 'Unknown');
    }

    // Convert target users (system events)
    final targetUserSenders = targetUsers
        .map((u) => MessageSender(
              id: u.id,
              name: u.fullName,
              avatar: u.imageUrls.isNotEmpty ? u.imageUrls.first : null,
            ))
        .toList();

    return ChatMessage(
      id: id,
      chatId: chatId,
      content: content,
      contentType: contentType,
      sender: messageSender,
      createdAt: DateTime.fromMillisecondsSinceEpoch(createdAt),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(editAt ?? createdAt),
      editedAt: editAt != null ? DateTime.fromMillisecondsSinceEpoch(editAt!) : null,
      deletedAt: deletedAt != null ? DateTime.fromMillisecondsSinceEpoch(deletedAt!) : null,
      readBy: readerIds,
      deliveredTo: const [], // Backend doesn't track delivery separately
      attachments: messageAttachments,
      reactions: messageReactions,
      mentionTo: mentions,
      urls: urls,
      fileName: fileName,
      forwardedFromMessageId: forwardedFromMessageId,
      replyMessageId: replyMessageId,
      replyMessage: replyMsg,
      actionType: actionType,
      actor: actorSender,
      targetUsers: targetUserSenders,
      newValue: newValue,
      oldValue: oldValue,
    );
  }
}

extension MessageListResponseDtoMapper on MessageListResponseDto {
  /// Convert message list to domain entities
  List<ChatMessage> toDomainList() {
    return messages.map((dto) => dto.toDomain()).toList();
  }
}
