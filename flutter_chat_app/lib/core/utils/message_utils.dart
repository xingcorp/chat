import 'package:flutter_chat_app/shared/domain/entities/chat_message.dart';

/// Tiện ích xử lý tin nhắn
class MessageUtils {
  /// Kiểm tra xem tin nhắn có phải là tin nhắn phương tiện (ảnh, video, âm thanh)
  static bool isMediaMessage(ChatMessage message) {
    final contentType = message.contentType.toString().toLowerCase();
    return contentType == 'image' || contentType == 'video' || contentType == 'audio';
  }
  
  /// Kiểm tra xem tin nhắn có phải là tin nhắn văn bản
  static bool isTextMessage(ChatMessage message) {
    return message.contentType.toString().toLowerCase() == 'text';
  }
  
  /// Kiểm tra xem tin nhắn có phải là tin nhắn file
  static bool isFileMessage(ChatMessage message) {
    return message.contentType.toString().toLowerCase() == 'file';
  }
  
  /// Kiểm tra xem tin nhắn có phải là tin nhắn hệ thống
  static bool isSystemMessage(ChatMessage message) {
    return message.contentType.toString().toLowerCase() == 'system';
  }
  
  /// Kiểm tra xem tin nhắn có đính kèm không
  static bool hasAttachments(ChatMessage message) {
    return message.attachments.isNotEmpty;
  }
  
  /// Lấy phần mở rộng của tệp từ tên tệp
  static String getFileExtension(String fileName) {
    final parts = fileName.split('.');
    return parts.length > 1 ? parts.last.toLowerCase() : '';
  }
  
  /// Kiểm tra xem tệp có phải là hình ảnh không dựa trên phần mở rộng
  static bool isImageFile(String fileName) {
    final extension = getFileExtension(fileName);
    return ['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp'].contains(extension);
  }
  
  /// Kiểm tra xem tệp có phải là video không dựa trên phần mở rộng
  static bool isVideoFile(String fileName) {
    final extension = getFileExtension(fileName);
    return ['mp4', 'mov', 'avi', 'mkv', 'webm', '3gp'].contains(extension);
  }
  
  /// Kiểm tra xem tệp có phải là âm thanh không dựa trên phần mở rộng
  static bool isAudioFile(String fileName) {
    final extension = getFileExtension(fileName);
    return ['mp3', 'wav', 'ogg', 'm4a', 'aac'].contains(extension);
  }
  
  /// Lấy icon cho tệp dựa trên loại tệp
  static String getFileIcon(String fileName) {
    final extension = getFileExtension(fileName);
    
    // Document files
    if (['pdf', 'doc', 'docx', 'txt', 'rtf'].contains(extension)) {
      return 'document';
    }
    // Spreadsheet files
    else if (['xls', 'xlsx', 'csv'].contains(extension)) {
      return 'spreadsheet';
    }
    // Presentation files
    else if (['ppt', 'pptx'].contains(extension)) {
      return 'presentation';
    }
    // Compressed files
    else if (['zip', 'rar', '7z', 'tar', 'gz'].contains(extension)) {
      return 'archive';
    }
    // Image files
    else if (isImageFile(fileName)) {
      return 'image';
    }
    // Video files
    else if (isVideoFile(fileName)) {
      return 'video';
    }
    // Audio files
    else if (isAudioFile(fileName)) {
      return 'audio';
    }
    // Default
    else {
      return 'file';
    }
  }
  
  /// Lấy tiêu đề hiển thị dựa trên loại nội dung
  static String getContentTypeDisplay(String contentType) {
    switch (contentType.toLowerCase()) {
      case 'text':
        return 'Tin nhắn';
      case 'image':
        return 'Hình ảnh';
      case 'video':
        return 'Video';
      case 'audio':
        return 'Ghi âm';
      case 'file':
        return 'Tệp đính kèm';
      case 'location':
        return 'Vị trí';
      case 'contact':
        return 'Danh thiếp';
      case 'sticker':
        return 'Nhãn dán';
      case 'system':
        return 'Thông báo hệ thống';
      default:
        return 'Tin nhắn';
    }
  }
  
  // ══════════════════════════════════════════
  // Clipboard / Copy Utilities
  // ══════════════════════════════════════════

  /// Regex patterns (reuse from TextSpanBuilder)
  static final RegExp _mentionBracketRegex = RegExp(r'\[@([^\]]+)\]');
  static final RegExp _uuidMentionRegex = RegExp(
    r'@([0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12})',
  );
  static final RegExp _brRegex = RegExp(r'<br\s*/?>', caseSensitive: false);
  static final RegExp _anchorRegex = RegExp(
    r'<a\s+[^>]*href=["\x27]([^"\x27]+)["\x27][^>]*>([^<]*)</a>',
    caseSensitive: false,
  );
  static final RegExp _boldRegex =
      RegExp(r'<b>([^<]*)</b>', caseSensitive: false);
  static final RegExp _italicRegex =
      RegExp(r'<i>([^<]*)</i>', caseSensitive: false);
  static final RegExp _underlineRegex =
      RegExp(r'<u>([^<]*)</u>', caseSensitive: false);

  /// Trích xuất plain text từ raw message content cho clipboard.
  ///
  /// Tương đương Stream Chat Flutter `Message.replaceMentions(linkify: false)`:
  /// - `[@userId]` -> `@DisplayName` (hoặc `@userId` nếu không tìm thấy)
  /// - `@<uuid>` -> `@DisplayName`
  /// - `<br>`, `<br/>` -> newline
  /// - `<a href="url">text</a>` -> `text`
  /// - `<b>text</b>` -> `text`
  /// - `<i>text</i>` -> `text`
  /// - `<u>text</u>` -> `text`
  /// - URLs, phone numbers, emails giữ nguyên
  ///
  /// [rawContent] nội dung gốc từ message (chứa markup)
  /// [mentionNameById] map userId -> displayName cho mentions
  static String extractCopyableText(
    String rawContent, {
    Map<String, String> mentionNameById = const {},
  }) {
    var result = rawContent;

    // 1. Replace HTML <br> -> newline
    result = result.replaceAll(_brRegex, '\n');

    // 2. Replace HTML <a> -> display text only
    result = result.replaceAllMapped(
      _anchorRegex,
      (match) => match.group(2) ?? match.group(1) ?? '',
    );

    // 3. Strip HTML formatting tags, keep text content
    result = result.replaceAllMapped(
      _boldRegex,
      (match) => match.group(1) ?? '',
    );
    result = result.replaceAllMapped(
      _italicRegex,
      (match) => match.group(1) ?? '',
    );
    result = result.replaceAllMapped(
      _underlineRegex,
      (match) => match.group(1) ?? '',
    );

    // 4. Replace [@id] mentions -> @DisplayName
    result = result.replaceAllMapped(_mentionBracketRegex, (match) {
      final id = match.group(1) ?? '';
      if (id.isEmpty) return '@';
      final name = mentionNameById[id];
      if (name != null && name.trim().isNotEmpty) {
        return '@${name.trim()}';
      }
      return '@$id';
    });

    // 5. Replace @uuid mentions -> @DisplayName
    result = result.replaceAllMapped(_uuidMentionRegex, (match) {
      final id = match.group(1) ?? '';
      final name = mentionNameById[id];
      if (name != null && name.trim().isNotEmpty) {
        return '@${name.trim()}';
      }
      // Giữ nguyên nếu không resolve được
      return match.group(0) ?? '@$id';
    });

    return result;
  }

  /// Trả về tin nhắn ngắn gọn cho thông báo
  static String getNotificationPreview(ChatMessage message) {
    final contentType = message.contentType.toString().toLowerCase();
    
    if (contentType == 'text') {
      // Lấy nội dung ngắn gọn cho thông báo
      final content = message.content.length > 50 
          ? '${message.content.substring(0, 47)}...'
          : message.content;
      
      return content;
    } else {
      // Với các loại tin nhắn khác, trả về mô tả loại
      return getContentTypeDisplay(contentType);
    }
  }
} 