import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_chat_app/data/models/chat_message_model.dart';
import 'package:flutter_chat_app/domain/entities/chat_message.dart';
import 'package:flutter_chat_app/proto/chat_message.pb.dart';
import 'package:injectable/injectable.dart';

/// Utility class để chuyển đổi giữa các đối tượng domain với Protocol Buffers
@singleton
class ProtoConverter {
  /// Chuyển đổi từ ChatMessage sang ChatMessageProto
  ChatMessageProto messageToProto(ChatMessage message) {
    final proto = ChatMessageProto();
    
    // Thiết lập các trường cơ bản
    proto.id = message.id;
    proto.localId = message.localId ?? '';
    proto.chatId = message.chatId;
    proto.content = message.content;
    proto.contentType = _contentTypeToProto(message.contentType);
    proto.createdAt = message.createdAt.millisecondsSinceEpoch;
    proto.updatedAt = message.updatedAt?.millisecondsSinceEpoch ?? 0;
    proto.status = _messageStatusToProto(message.status);
    proto.replyToMessageId = message.replyToMessageId ?? '';
    proto.isDeleted = message.isDeleted;
    proto.clientTimestamp = message.clientTimestamp?.toIso8601String() ?? '';
    proto.isEdited = message.isEdited;
    proto.editedAt = message.editedAt?.millisecondsSinceEpoch ?? 0;
    
    // Thiết lập sender
    final sender = SenderProto();
    sender.id = message.sender.id;
    sender.name = message.sender.name;
    sender.avatarUrl = message.sender.avatarUrl ?? '';
    sender.status = message.sender.status ?? '';
    proto.sender = sender;
    
    // Thiết lập attachments
    if (message.attachments != null && message.attachments!.isNotEmpty) {
      for (final attachment in message.attachments!) {
        final attachmentProto = AttachmentProto();
        attachmentProto.id = attachment.id;
        attachmentProto.url = attachment.url;
        attachmentProto.thumbnailUrl = attachment.thumbnailUrl ?? '';
        attachmentProto.mimeType = attachment.mimeType ?? '';
        attachmentProto.size = attachment.size?.toInt() ?? 0;
        attachmentProto.name = attachment.name ?? '';
        attachmentProto.width = attachment.width?.toInt() ?? 0;
        attachmentProto.height = attachment.height?.toInt() ?? 0;
        attachmentProto.duration = attachment.duration?.inMilliseconds ?? 0;
        
        proto.attachments.add(attachmentProto);
      }
    }
    
    // Thiết lập metadata
    if (message.metadata != null && message.metadata!.isNotEmpty) {
      message.metadata!.forEach((key, value) {
        proto.metadata[key] = value.toString();
      });
    }
    
    return proto;
  }
  
  /// Chuyển đổi từ ChatMessageProto sang ChatMessage
  ChatMessage protoToMessage(ChatMessageProto proto) {
    // Tạo sender
    final sender = User(
      id: proto.sender.id,
      name: proto.sender.name,
      avatarUrl: proto.sender.avatarUrl.isEmpty ? null : proto.sender.avatarUrl,
      status: proto.sender.status.isEmpty ? null : proto.sender.status,
    );
    
    // Tạo các attachments
    final attachments = proto.attachments.map((attachmentProto) {
      return MessageAttachment(
        id: attachmentProto.id,
        url: attachmentProto.url,
        thumbnailUrl: attachmentProto.thumbnailUrl.isEmpty ? null : attachmentProto.thumbnailUrl,
        mimeType: attachmentProto.mimeType.isEmpty ? null : attachmentProto.mimeType,
        size: attachmentProto.size == 0 ? null : attachmentProto.size.toDouble(),
        name: attachmentProto.name.isEmpty ? null : attachmentProto.name,
        width: attachmentProto.width == 0 ? null : attachmentProto.width.toDouble(),
        height: attachmentProto.height == 0 ? null : attachmentProto.height.toDouble(),
        duration: attachmentProto.duration == 0 
          ? null 
          : Duration(milliseconds: attachmentProto.duration.toInt()),
      );
    }).toList();
    
    // Tạo metadata
    final metadata = <String, dynamic>{};
    if (proto.metadata.isNotEmpty) {
      proto.metadata.forEach((key, value) {
        metadata[key] = value;
      });
    }
    
    // Tạo đối tượng ChatMessage
    return ChatMessage(
      id: proto.id,
      localId: proto.localId.isEmpty ? null : proto.localId,
      chatId: proto.chatId,
      sender: sender,
      content: proto.content,
      contentType: _protoToContentType(proto.contentType),
      attachments: attachments.isEmpty ? null : attachments,
      createdAt: DateTime.fromMillisecondsSinceEpoch(proto.createdAt),
      updatedAt: proto.updatedAt == 0 
        ? null 
        : DateTime.fromMillisecondsSinceEpoch(proto.updatedAt),
      status: _protoToMessageStatus(proto.status),
      replyToMessageId: proto.replyToMessageId.isEmpty ? null : proto.replyToMessageId,
      isDeleted: proto.isDeleted,
      clientTimestamp: proto.clientTimestamp.isEmpty 
        ? null 
        : DateTime.parse(proto.clientTimestamp),
      metadata: metadata.isEmpty ? null : metadata,
      isEdited: proto.isEdited,
      editedAt: proto.editedAt == 0 
        ? null 
        : DateTime.fromMillisecondsSinceEpoch(proto.editedAt),
    );
  }
  
  /// Encode list tin nhắn thành binary
  Uint8List encodeMessageList(List<ChatMessage> messages) {
    final proto = ChatMessageListProto();
    
    for (final message in messages) {
      proto.messages.add(messageToProto(message));
    }
    
    return proto.writeToBuffer();
  }
  
  /// Decode binary thành list tin nhắn
  List<ChatMessage> decodeMessageList(Uint8List bytes) {
    final proto = ChatMessageListProto.fromBuffer(bytes);
    
    return proto.messages.map((messageProto) {
      return protoToMessage(messageProto);
    }).toList();
  }

  /// Chuyển ContentType sang ContentTypeProto
  ContentTypeProto _contentTypeToProto(ContentType contentType) {
    switch (contentType) {
      case ContentType.text:
        return ContentTypeProto.TEXT;
      case ContentType.image:
        return ContentTypeProto.IMAGE;
      case ContentType.video:
        return ContentTypeProto.VIDEO;
      case ContentType.audio:
        return ContentTypeProto.AUDIO;
      case ContentType.file:
        return ContentTypeProto.FILE;
      case ContentType.location:
        return ContentTypeProto.LOCATION;
      case ContentType.sticker:
        return ContentTypeProto.STICKER;
      default:
        return ContentTypeProto.TEXT;
    }
  }
  
  /// Chuyển ContentTypeProto sang ContentType
  ContentType _protoToContentType(ContentTypeProto contentType) {
    switch (contentType) {
      case ContentTypeProto.TEXT:
        return ContentType.text;
      case ContentTypeProto.IMAGE:
        return ContentType.image;
      case ContentTypeProto.VIDEO:
        return ContentType.video;
      case ContentTypeProto.AUDIO:
        return ContentType.audio;
      case ContentTypeProto.FILE:
        return ContentType.file;
      case ContentTypeProto.LOCATION:
        return ContentType.location;
      case ContentTypeProto.STICKER:
        return ContentType.sticker;
      default:
        return ContentType.text;
    }
  }
  
  /// Chuyển MessageStatus sang MessageStatusProto
  MessageStatusProto _messageStatusToProto(MessageStatus status) {
    switch (status) {
      case MessageStatus.sending:
        return MessageStatusProto.SENDING;
      case MessageStatus.sent:
        return MessageStatusProto.SENT;
      case MessageStatus.delivered:
        return MessageStatusProto.DELIVERED;
      case MessageStatus.read:
        return MessageStatusProto.READ;
      case MessageStatus.failed:
        return MessageStatusProto.FAILED;
      default:
        return MessageStatusProto.SENDING;
    }
  }
  
  /// Chuyển MessageStatusProto sang MessageStatus
  MessageStatus _protoToMessageStatus(MessageStatusProto status) {
    switch (status) {
      case MessageStatusProto.SENDING:
        return MessageStatus.sending;
      case MessageStatusProto.SENT:
        return MessageStatus.sent;
      case MessageStatusProto.DELIVERED:
        return MessageStatus.delivered;
      case MessageStatusProto.READ:
        return MessageStatus.read;
      case MessageStatusProto.FAILED:
        return MessageStatus.failed;
      default:
        return MessageStatus.sending;
    }
  }
} 