import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:flutter_chat_app/core/base/base_widget.dart';
import 'package:flutter_chat_app/core/constants/app_constants.dart';
import 'package:flutter_chat_app/core/theme/app_colors.dart';
import 'package:flutter_chat_app/core/theme/app_text_styles.dart';
import 'package:flutter_chat_app/shared/domain/entities/chat_message.dart';
import 'package:flutter_chat_app/l10n/l10n.dart';
import 'package:flutter_chat_app/features/chat/presentation/widgets/chat/media_preview.dart';

/// Loại nội dung tin nhắn
enum ChatMessageType {
  text,
  image,
  video,
  audio,
  file,
  location,
  sticker,
  contact,
  system,
}

/// Widget hiển thị tin nhắn chat
class ChatBubble extends BaseStatelessWidget {
  /// Nội dung tin nhắn
  final String message;
  
  /// Loại tin nhắn
  final ChatMessageType type;
  
  /// Thời điểm gửi tin nhắn
  final DateTime timestamp;
  
  /// Tin nhắn của người dùng hiện tại hay không
  final bool isMe;
  
  /// Trạng thái tin nhắn
  final MessageStatus status;
  
  /// URL của media (nếu có)
  final String? mediaUrl;
  
  /// Thumbnail URL cho video (nếu có)
  final String? thumbnailUrl;
  
  /// Kích thước file (nếu có)
  final int? fileSize;
  
  /// Tên file (nếu có)
  final String? fileName;
  
  /// Số giây cho audio (nếu là tin nhắn audio)
  final int? audioDuration;
  
  /// Tin nhắn đầu tiên từ người dùng hay không
  final bool isFirstInGroup;
  
  /// Tin nhắn cuối cùng từ người dùng hay không
  final bool isLastInGroup;
  
  /// Callback khi nhấn vào media
  final VoidCallback? onMediaTap;
  
  /// Callback khi nhấn vào tin nhắn
  final VoidCallback? onTap;
  
  /// Callback khi nhấn giữ tin nhắn
  final VoidCallback? onLongPress;
  
  /// Callback khi nhấn vào nút gửi lại
  final VoidCallback? onRetry;
  
  const ChatBubble({
    Key? key,
    required this.message,
    required this.type,
    required this.timestamp,
    required this.isMe,
    this.status = MessageStatus.delivered,
    this.mediaUrl,
    this.thumbnailUrl,
    this.fileSize,
    this.fileName,
    this.audioDuration,
    this.isFirstInGroup = false,
    this.isLastInGroup = false,
    this.onMediaTap,
    this.onTap,
    this.onLongPress,
    this.onRetry,
  }) : super(key: key);

  @override
  Widget buildContent(BuildContext context) {
    // Sử dụng RepaintBoundary để tối ưu việc render
    return RepaintBoundary(
      child: GestureDetector(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Align(
          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: _getBubbleMargin(),
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.75,
            ),
            decoration: BoxDecoration(
              color: _getBubbleColor(context),
              borderRadius: _getBubbleRadius(),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildContent(context),
                _buildTimestampAndStatus(context),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  /// Lấy bán kính bo góc cho bubble dựa trên vị trí trong nhóm
  BorderRadius _getBubbleRadius() {
    final radius = AppConstants.kDefaultBorderRadius;
    
    if (isMe) {
      return BorderRadius.only(
        topLeft: Radius.circular(radius),
        bottomLeft: Radius.circular(radius),
        topRight: isFirstInGroup 
            ? Radius.circular(radius) 
            : Radius.circular(radius / 3),
        bottomRight: isLastInGroup 
            ? Radius.circular(radius) 
            : Radius.circular(radius / 3),
      );
    } else {
      return BorderRadius.only(
        topRight: Radius.circular(radius),
        bottomRight: Radius.circular(radius),
        topLeft: isFirstInGroup 
            ? Radius.circular(radius) 
            : Radius.circular(radius / 3),
        bottomLeft: isLastInGroup 
            ? Radius.circular(radius) 
            : Radius.circular(radius / 3),
      );
    }
  }
  
  /// Lấy margin cho bubble dựa trên vị trí trong nhóm
  EdgeInsets _getBubbleMargin() {
    final defaultPadding = AppConstants.kDefaultPadding;
    final smallPadding = AppConstants.kSmallPadding;
    
    return EdgeInsets.only(
      left: isMe ? defaultPadding : smallPadding,
      right: isMe ? smallPadding : defaultPadding,
      top: isFirstInGroup ? smallPadding : 2,
      bottom: isLastInGroup ? smallPadding : 2,
    );
  }
  
  /// Lấy màu cho bubble dựa trên người gửi và theme
  Color _getBubbleColor(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    if (isMe) {
      return AppColors.getSentMessageBackgroundColor(isDarkMode);
    } else {
      return AppColors.getReceivedMessageBackgroundColor(isDarkMode);
    }
  }
  
  /// Build nội dung tin nhắn dựa trên loại tin nhắn
  Widget _buildContent(BuildContext context) {
    final padding = AppConstants.kDefaultPadding;
    
    switch (type) {
      case ChatMessageType.text:
        return Padding(
          padding: EdgeInsets.all(padding),
          child: Text(
            message,
            style: AppTextStyles.chatMessage(
              color: isMe 
                  ? AppColors.sentMessageText 
                  : AppColors.receivedMessageText,
            ),
          ),
        );
      case ChatMessageType.image:
        return GestureDetector(
          onTap: onMediaTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              MediaPreview(
                mediaUrl: mediaUrl!,
                isImage: true,
                onTap: onMediaTap,
              ),
              if (message.isNotEmpty)
                Padding(
                  padding: EdgeInsets.all(padding),
                  child: Text(
                    message,
                    style: AppTextStyles.chatMessage(
                      color: isMe 
                          ? AppColors.sentMessageText 
                          : AppColors.receivedMessageText,
                    ),
                  ),
                ),
            ],
          ),
        );
      case ChatMessageType.video:
        return GestureDetector(
          onTap: onMediaTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              MediaPreview(
                mediaUrl: mediaUrl!,
                thumbnailUrl: thumbnailUrl,
                isImage: false,
                onTap: onMediaTap,
              ),
              if (message.isNotEmpty)
                Padding(
                  padding: EdgeInsets.all(padding),
                  child: Text(
                    message,
                    style: AppTextStyles.chatMessage(
                      color: isMe 
                          ? AppColors.sentMessageText 
                          : AppColors.receivedMessageText,
                    ),
                  ),
                ),
            ],
          ),
        );
      case ChatMessageType.audio:
        return Padding(
          padding: EdgeInsets.all(padding),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.play_circle_fill,
                color: Colors.grey[600],
                size: 36,
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ghi âm',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isMe 
                          ? AppColors.sentMessageText 
                          : AppColors.receivedMessageText,
                    ),
                  ),
                  Text(
                    '${audioDuration ?? 0} giây',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      case ChatMessageType.file:
        return Padding(
          padding: EdgeInsets.all(padding),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.insert_drive_file,
                color: Colors.grey[600],
                size: 36,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fileName ?? 'File',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isMe 
                            ? AppColors.sentMessageText 
                            : AppColors.receivedMessageText,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (fileSize != null)
                      Text(
                        _formatFileSize(fileSize!),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      case ChatMessageType.location:
        return Padding(
          padding: EdgeInsets.all(padding),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.location_on,
                color: Colors.grey[600],
                size: 36,
              ),
              const SizedBox(width: 8),
              Text(
                'Vị trí',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isMe 
                      ? AppColors.sentMessageText 
                      : AppColors.receivedMessageText,
                ),
              ),
            ],
          ),
        );
      case ChatMessageType.sticker:
        return Image.network(
          mediaUrl!,
          width: 128,
          height: 128,
          fit: BoxFit.contain,
        );
      case ChatMessageType.contact:
        return Padding(
          padding: EdgeInsets.all(padding),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.person,
                color: Colors.grey[600],
                size: 36,
              ),
              const SizedBox(width: 8),
              Text(
                message,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isMe 
                      ? AppColors.sentMessageText 
                      : AppColors.receivedMessageText,
                ),
              ),
            ],
          ),
        );
      case ChatMessageType.system:
        return Padding(
          padding: EdgeInsets.all(padding),
          child: Text(
            message,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
        );
      default:
        return Padding(
          padding: EdgeInsets.all(padding),
          child: Text(
            message,
            style: AppTextStyles.chatMessage(
              color: isMe 
                  ? AppColors.sentMessageText 
                  : AppColors.receivedMessageText,
            ),
          ),
        );
    }
  }
  
  /// Build widget hiển thị thời gian và trạng thái tin nhắn
  Widget _buildTimestampAndStatus(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8, bottom: 4, left: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _formatTime(timestamp),
            style: const TextStyle(
              fontSize: 10,
              color: Colors.grey,
            ),
          ),
          const SizedBox(width: 4),
          if (isMe) _buildStatusIcon(),
        ],
      ),
    );
  }
  
  /// Build icon trạng thái tin nhắn
  Widget _buildStatusIcon() {
    switch (status) {
      case MessageStatus.sending:
        return const Icon(
          Icons.access_time,
          size: 12,
          color: Colors.grey,
        );
      case MessageStatus.sent:
        return const Icon(
          Icons.check,
          size: 12,
          color: Colors.grey,
        );
      case MessageStatus.delivered:
        return const Icon(
          Icons.done_all,
          size: 12,
          color: Colors.grey,
        );
      case MessageStatus.read:
        return const Icon(
          Icons.done_all,
          size: 12,
          color: Colors.blue,
        );
      case MessageStatus.failed:
        return GestureDetector(
          onTap: onRetry,
          child: const Icon(
            Icons.error_outline,
            size: 12,
            color: Colors.red,
          ),
        );
      default:
        return const SizedBox.shrink();
    }
  }
  
  /// Format thời gian theo ngày hoặc giờ
  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);
    
    if (difference.inDays > 0) {
      return '${time.day}/${time.month}/${time.year}';
    } else {
      return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    }
  }
  
  /// Format kích thước file thành chuỗi đọc được
  String _formatFileSize(int size) {
    if (size < 1024) {
      return '$size B';
    } else if (size < 1024 * 1024) {
      return '${(size / 1024).toStringAsFixed(1)} KB';
    } else if (size < 1024 * 1024 * 1024) {
      return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(size / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
  }
} 