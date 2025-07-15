/// Message Type Enumeration
/// 
/// Defines all possible message types in the chat application.
/// Follows Clean Architecture principles for domain entities.
/// 
/// Author: Senior Flutter/Mobile Architect
library message_type;

/// Enumeration of message types
enum MessageType {
  /// Plain text message
  text,
  
  /// Image message
  image,
  
  /// Video message
  video,
  
  /// Audio message
  audio,
  
  /// Document/file message
  document,
  
  /// Location sharing message
  location,
  
  /// Contact sharing message
  contact,
  
  /// Sticker message
  sticker,
  
  /// GIF message
  gif,
  
  /// Voice note message
  voiceNote,
  
  /// System message (join, leave, etc.)
  system,
  
  /// Reply message
  reply,
  
  /// Forward message
  forward,
  
  /// Event message (meeting, reminder, etc.)
  event,
  
  /// Poll message
  poll,
  
  /// Link preview message
  link,
}

/// Extension methods for MessageType
extension MessageTypeExtension on MessageType {
  /// Get display name for message type
  String get displayName {
    switch (this) {
      case MessageType.text:
        return 'Văn bản';
      case MessageType.image:
        return 'Hình ảnh';
      case MessageType.video:
        return 'Video';
      case MessageType.audio:
        return 'Âm thanh';
      case MessageType.document:
        return 'Tài liệu';
      case MessageType.location:
        return 'Vị trí';
      case MessageType.contact:
        return 'Liên hệ';
      case MessageType.sticker:
        return 'Sticker';
      case MessageType.gif:
        return 'GIF';
      case MessageType.voiceNote:
        return 'Tin nhắn thoại';
      case MessageType.system:
        return 'Hệ thống';
      case MessageType.reply:
        return 'Trả lời';
      case MessageType.forward:
        return 'Chuyển tiếp';
      case MessageType.event:
        return 'Sự kiện';
      case MessageType.poll:
        return 'Bình chọn';
      case MessageType.link:
        return 'Liên kết';
    }
  }

  /// Check if message type requires attachment
  bool get requiresAttachment {
    switch (this) {
      case MessageType.text:
      case MessageType.system:
      case MessageType.event:
      case MessageType.poll:
        return false;
      case MessageType.image:
      case MessageType.video:
      case MessageType.audio:
      case MessageType.document:
      case MessageType.location:
      case MessageType.contact:
      case MessageType.sticker:
      case MessageType.gif:
      case MessageType.voiceNote:
      case MessageType.reply:
      case MessageType.forward:
      case MessageType.link:
        return true;
    }
  }

  /// Check if message type supports text content
  bool get supportsTextContent {
    switch (this) {
      case MessageType.text:
      case MessageType.reply:
      case MessageType.forward:
      case MessageType.system:
      case MessageType.event:
      case MessageType.poll:
      case MessageType.link:
        return true;
      case MessageType.image:
      case MessageType.video:
      case MessageType.audio:
      case MessageType.document:
      case MessageType.location:
      case MessageType.contact:
      case MessageType.sticker:
      case MessageType.gif:
      case MessageType.voiceNote:
        return false;
    }
  }

  /// Get maximum content length for message type
  int get maxContentLength {
    switch (this) {
      case MessageType.text:
      case MessageType.reply:
      case MessageType.forward:
        return 4000;
      case MessageType.system:
      case MessageType.event:
        return 1000;
      case MessageType.poll:
        return 500;
      case MessageType.link:
        return 2000;
      default:
        return 0; // No text content allowed
    }
  }

  /// Check if message type is media
  bool get isMedia {
    switch (this) {
      case MessageType.image:
      case MessageType.video:
      case MessageType.audio:
      case MessageType.voiceNote:
      case MessageType.gif:
        return true;
      default:
        return false;
    }
  }

  /// Check if message type is system generated
  bool get isSystemGenerated {
    switch (this) {
      case MessageType.system:
      case MessageType.event:
        return true;
      default:
        return false;
    }
  }

  /// Get allowed MIME types for message type
  List<String> get allowedMimeTypes {
    switch (this) {
      case MessageType.image:
        return ['image/jpeg', 'image/png', 'image/gif', 'image/webp'];
      case MessageType.video:
        return ['video/mp4', 'video/mov', 'video/avi', 'video/mkv'];
      case MessageType.audio:
      case MessageType.voiceNote:
        return ['audio/mp3', 'audio/wav', 'audio/aac', 'audio/m4a'];
      case MessageType.document:
        return ['application/pdf', 'application/msword', 'application/vnd.openxmlformats-officedocument.wordprocessingml.document'];
      case MessageType.gif:
        return ['image/gif'];
      default:
        return [];
    }
  }

  /// Convert to string for serialization
  String toJson() => name;

  /// Create from string for deserialization
  static MessageType fromJson(String json) {
    return MessageType.values.firstWhere(
      (type) => type.name == json,
      orElse: () => MessageType.text,
    );
  }
}
