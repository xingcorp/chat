import 'package:flutter/widgets.dart';
import 'package:flutter_chat_app/shared/domain/entities/attachment.dart';
import 'package:flutter_chat_app/l10n/l10n.dart';

/// Service for formatting message previews with attachment type indicators.
///
/// Follows industry standards (Facebook Messenger, WhatsApp, Zalo) for
/// displaying message previews with appropriate icons and text.
///
/// ## Features
/// - Attachment type icons (📷, 📹, 🎧, 📄, 🎤)
/// - Fallback to message text if no attachments
/// - Full internationalization through l10n
/// - Null-safe with graceful defaults
///
/// ## Usage
/// ```dart
/// final preview = MessagePreviewFormatter.format(
///   context: context,
///   text: message.content,
///   attachments: message.attachments,
/// );
/// ```
class MessagePreviewFormatter {
  const MessagePreviewFormatter._();

  /// Formats a message preview with attachment indicators.
  ///
  /// Returns formatted text with emoji icons for attachments:
  /// - 📷 Photo
  /// - 📹 Video
  /// - 🎧 Audio
  /// - 📄 Document/File
  /// - 🎤 Voice message
  ///
  /// Priority:
  /// 1. If has attachments → Icon + Title
  /// 2. If has text → Text
  /// 3. Otherwise → Empty message placeholder
  ///
  /// Examples:
  /// - Image + text → "📷 Beautiful sunset"
  /// - Image no text → "📷 Photo"
  /// - File with name → "📄 report.pdf"
  /// - Text only → "Hello world"
  /// - Empty → "No message"
  static String format({
    required BuildContext context,
    String? text,
    List<Attachment>? attachments,
  }) {
    // Priority 1: Show attachment if present
    if (attachments != null && attachments.isNotEmpty) {
      return _formatWithAttachment(context, text, attachments.first);
    }

    // Priority 2: Show text if present
    if (text != null && text.trim().isNotEmpty) {
      return text.trim();
    }

    // Priority 3: Empty message placeholder
    return context.l10n.emptyMessage;
  }

  /// Formats attachment with icon and title.
  static String _formatWithAttachment(
    BuildContext context,
    String? text,
    Attachment attachment,
  ) {
    final icon = _getAttachmentIcon(attachment.type);
    final title = _getAttachmentTitle(context, attachment, text);

    // If no icon (unknown type), just return title
    if (icon.isEmpty) {
      return title;
    }

    return '$icon $title';
  }

  /// Returns emoji icon for attachment type.
  static String _getAttachmentIcon(AttachmentType type) {
    return switch (type) {
      AttachmentType.image => '📷',
      AttachmentType.video => '📹',
      AttachmentType.audio => '🎧',
      AttachmentType.document => '📄',
      AttachmentType.location => '📍',
      AttachmentType.contact => '👤',
      AttachmentType.other => '',
    };
  }

  /// Returns localized title for attachment.
  ///
  /// Priority:
  /// 1. Message text (if present)
  /// 2. File name (for document attachments)
  /// 3. Localized type name
  static String _getAttachmentTitle(
    BuildContext context,
    Attachment attachment,
    String? text,
  ) {
    final l10n = context.l10n;

    // If message has text, prefer it
    if (text != null && text.trim().isNotEmpty) {
      return text.trim();
    }

    // Otherwise use localized attachment type name
    return switch (attachment.type) {
      AttachmentType.image => l10n.photo,
      AttachmentType.video => l10n.video,
      AttachmentType.audio => l10n.audio,
      AttachmentType.document => attachment.name ?? l10n.file,
      AttachmentType.location => l10n.attachment,
      AttachmentType.contact => l10n.attachment,
      AttachmentType.other => l10n.attachment,
    };
  }
}
