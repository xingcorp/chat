/// Format of message content.
///
/// Used to determine how to render and store message content:
/// - [plainText]: Standard text with optional mention/link parsing
/// - [deltaJson]: Quill Delta JSON format containing rich text formatting
///
/// This enum lives in the domain layer and has no dependency on
/// flutter_quill or any infrastructure package.
enum ContentFormat {
  /// Plain text content (default, backward compatible).
  ///
  /// Messages received from the server without local rich text data
  /// will always have this format.
  plainText,

  /// Quill Delta JSON format (rich text).
  ///
  /// Only available for messages composed locally with the rich text
  /// composer. The Delta JSON is stored in [ChatMessage.contentDelta]
  /// and persisted to Isar. The server only receives the plain text
  /// extraction via the existing `message` field.
  deltaJson,
}
