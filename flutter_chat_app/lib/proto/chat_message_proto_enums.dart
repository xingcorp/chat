/// Protocol Buffer enum definitions for chat messages
/// 
/// This file provides manual implementations of proto enums
/// to avoid dependency on protobuf code generation.

/// Content type enumeration for protocol buffers
enum ContentTypeProto {
  TEXT,
  IMAGE,
  VIDEO,
  AUDIO,
  FILE,
  LOCATION,
  STICKER,
}

/// Message status enumeration for protocol buffers
enum MessageStatusProto {
  SENDING,
  SENT,
  DELIVERED,
  READ,
  FAILED,
}

/// Extension methods for ContentTypeProto
extension ContentTypeProtoExtension on ContentTypeProto {
  /// Convert to integer value for proto serialization
  int get value {
    switch (this) {
      case ContentTypeProto.TEXT:
        return 0;
      case ContentTypeProto.IMAGE:
        return 1;
      case ContentTypeProto.VIDEO:
        return 2;
      case ContentTypeProto.AUDIO:
        return 3;
      case ContentTypeProto.FILE:
        return 4;
      case ContentTypeProto.LOCATION:
        return 5;
      case ContentTypeProto.STICKER:
        return 6;
    }
  }
  
  /// Create from integer value
  static ContentTypeProto fromValue(int value) {
    switch (value) {
      case 0:
        return ContentTypeProto.TEXT;
      case 1:
        return ContentTypeProto.IMAGE;
      case 2:
        return ContentTypeProto.VIDEO;
      case 3:
        return ContentTypeProto.AUDIO;
      case 4:
        return ContentTypeProto.FILE;
      case 5:
        return ContentTypeProto.LOCATION;
      case 6:
        return ContentTypeProto.STICKER;
      default:
        return ContentTypeProto.TEXT;
    }
  }
  
  /// Convert to string representation
  String get name {
    switch (this) {
      case ContentTypeProto.TEXT:
        return 'TEXT';
      case ContentTypeProto.IMAGE:
        return 'IMAGE';
      case ContentTypeProto.VIDEO:
        return 'VIDEO';
      case ContentTypeProto.AUDIO:
        return 'AUDIO';
      case ContentTypeProto.FILE:
        return 'FILE';
      case ContentTypeProto.LOCATION:
        return 'LOCATION';
      case ContentTypeProto.STICKER:
        return 'STICKER';
    }
  }
}

/// Extension methods for MessageStatusProto
extension MessageStatusProtoExtension on MessageStatusProto {
  /// Convert to integer value for proto serialization
  int get value {
    switch (this) {
      case MessageStatusProto.SENDING:
        return 0;
      case MessageStatusProto.SENT:
        return 1;
      case MessageStatusProto.DELIVERED:
        return 2;
      case MessageStatusProto.READ:
        return 3;
      case MessageStatusProto.FAILED:
        return 4;
    }
  }
  
  /// Create from integer value
  static MessageStatusProto fromValue(int value) {
    switch (value) {
      case 0:
        return MessageStatusProto.SENDING;
      case 1:
        return MessageStatusProto.SENT;
      case 2:
        return MessageStatusProto.DELIVERED;
      case 3:
        return MessageStatusProto.READ;
      case 4:
        return MessageStatusProto.FAILED;
      default:
        return MessageStatusProto.SENDING;
    }
  }
  
  /// Convert to string representation
  String get name {
    switch (this) {
      case MessageStatusProto.SENDING:
        return 'SENDING';
      case MessageStatusProto.SENT:
        return 'SENT';
      case MessageStatusProto.DELIVERED:
        return 'DELIVERED';
      case MessageStatusProto.READ:
        return 'READ';
      case MessageStatusProto.FAILED:
        return 'FAILED';
    }
  }
}

/// Utility class for proto enum conversions
class ProtoEnumConverter {
  /// Convert ContentType to ContentTypeProto
  static ContentTypeProto contentTypeToProto(dynamic contentType) {
    final typeStr = contentType.toString().split('.').last;
    switch (typeStr.toLowerCase()) {
      case 'text':
        return ContentTypeProto.TEXT;
      case 'image':
        return ContentTypeProto.IMAGE;
      case 'video':
        return ContentTypeProto.VIDEO;
      case 'audio':
        return ContentTypeProto.AUDIO;
      case 'file':
        return ContentTypeProto.FILE;
      case 'location':
        return ContentTypeProto.LOCATION;
      case 'sticker':
        return ContentTypeProto.STICKER;
      default:
        return ContentTypeProto.TEXT;
    }
  }
  
  /// Convert MessageStatus to MessageStatusProto
  static MessageStatusProto messageStatusToProto(dynamic messageStatus) {
    final statusStr = messageStatus.toString().split('.').last;
    switch (statusStr.toLowerCase()) {
      case 'sending':
        return MessageStatusProto.SENDING;
      case 'sent':
        return MessageStatusProto.SENT;
      case 'delivered':
        return MessageStatusProto.DELIVERED;
      case 'read':
        return MessageStatusProto.READ;
      case 'failed':
        return MessageStatusProto.FAILED;
      default:
        return MessageStatusProto.SENDING;
    }
  }
}
