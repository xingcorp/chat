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