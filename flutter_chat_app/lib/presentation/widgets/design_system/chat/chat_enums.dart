/// **CHAT ENUMS**
///
/// Enumerations for chat-specific components.
/// Provides type-safe configuration options for message bubbles, reactions, and status indicators.
///
/// **Architecture**: Clean Architecture + Design System
/// **Pattern**: Enum-based configuration
///
/// **Usage**:
/// ```dart
/// // Message type
/// final type = MessageType.text;
///
/// // Message status (imported from domain)
/// final status = MessageStatus.read;
///
/// // Message alignment
/// final alignment = MessageAlignment.right;
/// ```

// Import MessageStatus from domain
import 'package:flutter_chat_app/shared/domain/entities/chat_message.dart' show MessageStatus;

// Export MessageStatus for convenience
export 'package:flutter_chat_app/shared/domain/entities/chat_message.dart' show MessageStatus;

/// Message content type.
///
/// Determines how the message content is rendered in [AppMessageBubble].
enum MessageType {
  /// Plain text message
  text,

  /// Image message with thumbnail
  image,

  /// Video message with thumbnail and play button
  video,

  /// Audio message with waveform
  audio,

  /// File attachment with icon and name
  file,

  /// Location message with map preview
  location,

  /// Contact card
  contact,

  /// System message (e.g., "User joined the chat")
  system,
}

/// Message bubble alignment.
///
/// Determines the horizontal alignment of the message bubble.
enum MessageAlignment {
  /// Left-aligned (received messages)
  left,

  /// Right-aligned (sent messages)
  right,

  /// Center-aligned (system messages)
  center,
}

/// Reaction type for messages.
///
/// Predefined quick reactions for messages.
enum ReactionType {
  /// 👍 Thumbs up
  thumbsUp,

  /// ❤️ Heart
  heart,

  /// 😂 Laughing face
  laughing,

  /// 😮 Surprised face
  surprised,

  /// 😢 Sad face
  sad,

  /// 😡 Angry face
  angry,

  /// 🎉 Party popper
  party,

  /// 🔥 Fire
  fire,

  /// Custom emoji (use emoji string)
  custom,
}

/// Typing indicator size.
///
/// Determines the size of the typing indicator dots.
enum TypingIndicatorSize {
  /// Small dots (8dp)
  small,

  /// Medium dots (10dp)
  medium,

  /// Large dots (12dp)
  large,
}

/// Audio playback speed.
///
/// Predefined playback speeds for audio messages.
enum AudioPlaybackSpeed {
  /// Normal speed (1.0x)
  normal,

  /// Fast speed (1.5x)
  fast,

  /// Faster speed (2.0x)
  faster,

  /// Slow speed (0.5x)
  slow,
}

/// Read receipt display mode.
///
/// Determines how read receipts are displayed.
enum ReadReceiptMode {
  /// Show checkmarks only
  checkmarks,

  /// Show checkmarks with timestamp
  checkmarksWithTime,

  /// Show avatars of readers
  avatars,

  /// Show avatars with count
  avatarsWithCount,
}

/// Message bubble tail position.
///
/// Determines where the message bubble tail is positioned.
enum MessageTailPosition {
  /// No tail
  none,

  /// Tail at bottom left
  bottomLeft,

  /// Tail at bottom right
  bottomRight,

  /// Tail at top left
  topLeft,

  /// Tail at top right
  topRight,
}

/// Message bubble size variant.
///
/// Determines the size of the message bubble.
enum MessageBubbleSize {
  /// Compact size (smaller padding)
  compact,

  /// Normal size (default padding)
  normal,

  /// Comfortable size (larger padding)
  comfortable,
}

// ============================================================================
// EXTENSION METHODS
// ============================================================================

/// Extension methods for [ReactionType]
extension ReactionTypeExtension on ReactionType {
  /// Get emoji string for reaction type
  String get emoji {
    switch (this) {
      case ReactionType.thumbsUp:
        return '👍';
      case ReactionType.heart:
        return '❤️';
      case ReactionType.laughing:
        return '😂';
      case ReactionType.surprised:
        return '😮';
      case ReactionType.sad:
        return '😢';
      case ReactionType.angry:
        return '😡';
      case ReactionType.party:
        return '🎉';
      case ReactionType.fire:
        return '🔥';
      case ReactionType.custom:
        return '';
    }
  }

  /// Get accessibility label for reaction type
  String get accessibilityLabel {
    switch (this) {
      case ReactionType.thumbsUp:
        return 'Thumbs up';
      case ReactionType.heart:
        return 'Heart';
      case ReactionType.laughing:
        return 'Laughing';
      case ReactionType.surprised:
        return 'Surprised';
      case ReactionType.sad:
        return 'Sad';
      case ReactionType.angry:
        return 'Angry';
      case ReactionType.party:
        return 'Party';
      case ReactionType.fire:
        return 'Fire';
      case ReactionType.custom:
        return 'Custom reaction';
    }
  }
}

/// Extension methods for [AudioPlaybackSpeed]
extension AudioPlaybackSpeedExtension on AudioPlaybackSpeed {
  /// Get speed multiplier value
  double get multiplier {
    switch (this) {
      case AudioPlaybackSpeed.slow:
        return 0.5;
      case AudioPlaybackSpeed.normal:
        return 1.0;
      case AudioPlaybackSpeed.fast:
        return 1.5;
      case AudioPlaybackSpeed.faster:
        return 2.0;
    }
  }

  /// Get display label for speed
  String get label {
    switch (this) {
      case AudioPlaybackSpeed.slow:
        return '0.5x';
      case AudioPlaybackSpeed.normal:
        return '1.0x';
      case AudioPlaybackSpeed.fast:
        return '1.5x';
      case AudioPlaybackSpeed.faster:
        return '2.0x';
    }
  }
}

/// Extension methods for [MessageStatus]
extension MessageStatusExtension on MessageStatus {
  /// Check if message is in a final state (not sending/pending)
  bool get isFinal {
    return this == MessageStatus.sent ||
        this == MessageStatus.delivered ||
        this == MessageStatus.read ||
        this == MessageStatus.failed;
  }

  /// Check if message can be retried
  bool get canRetry {
    return this == MessageStatus.failed;
  }

  /// Check if message is in progress
  bool get isInProgress {
    return this == MessageStatus.sending || this == MessageStatus.pending;
  }
}

/// Waveform visualization style.
///
/// Determines how audio waveforms are rendered.
enum WaveformStyle {
  /// Bars (vertical bars)
  bars,

  /// Rounded bars (bars with rounded corners)
  roundedBars,

  /// Line (continuous line)
  line,

  /// Filled (filled area under line)
  filled,
}

/// Extension methods for [MessageType]
extension MessageTypeExtension on MessageType {
  /// Returns true if the message type is media (image, video, audio)
  bool get isMedia => this == MessageType.image || 
                      this == MessageType.video || 
                      this == MessageType.audio;

  /// Returns true if the message type requires a thumbnail
  bool get requiresThumbnail => this == MessageType.image || 
                                 this == MessageType.video ||
                                 this == MessageType.location;

  /// Returns true if the message type is interactive
  bool get isInteractive => this != MessageType.system;
}
