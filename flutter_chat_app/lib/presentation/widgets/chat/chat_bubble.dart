import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_chat_app/core/base/base_widget.dart';
import 'package:flutter_chat_app/core/constants/app_constants.dart';
import 'package:flutter_chat_app/core/theme/app_colors.dart';
import 'package:flutter_chat_app/core/theme/app_text_styles.dart';
import 'package:flutter_chat_app/presentation/widgets/chat/media_preview.dart';

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

/// Trạng thái gửi tin nhắn
enum MessageStatus {
  sending, // Đang gửi
  sent, // Đã gửi nhưng chưa đến máy chủ
  delivered, // Đã gửi đến máy chủ
  read, // Đã đọc
  failed, // Gửi thất bại
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
    final radius = AppConstants.kDefaultBorderRadius.r;
    
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
    final defaultPadding = AppConstants.kDefaultPadding.r;
    final smallPadding = AppConstants.kSmallPadding.r;
    
    return EdgeInsets.only(
      left: isMe ? defaultPadding : smallPadding,
      right: isMe ? smallPadding : defaultPadding,
      top: isFirstInGroup ? smallPadding : 2.r,
      bottom: isLastInGroup ? smallPadding : 2.r,
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
    final padding = AppConstants.kDefaultPadding.r;
    
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
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(_getBubbleRadius().topLeft.x),
                topRight: Radius.circular(_getBubbleRadius().topRight.x),
              ),
              child: MediaPreview(
                mediaUrl: mediaUrl!,
                isImage: true,
                onTap: onMediaTap,
              ),
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
        );
        
      case ChatMessageType.video:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(_getBubbleRadius().topLeft.x),
                topRight: Radius.circular(_getBubbleRadius().topRight.x),
              ),
              child: MediaPreview(
                mediaUrl: mediaUrl!,
                thumbnailUrl: thumbnailUrl,
                isImage: false,
                onTap: onMediaTap,
              ),
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
        );
        
      case ChatMessageType.file:
        return Padding(
          padding: EdgeInsets.all(padding),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.insert_drive_file, size: 24.r),
              SizedBox(width: 8.w),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fileName ?? 'File',
                      style: AppTextStyles.chatMessage(
                        fontWeight: FontWeight.w500,
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
                        style: AppTextStyles.chatTime(
                          color: AppColors.textSecondary,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
        
      // Các case khác có thể được thêm vào sau
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
  
  /// Build timestamp và trạng thái tin nhắn
  Widget _buildTimestampAndStatus(BuildContext context) {
    if (!isLastInGroup) return const SizedBox.shrink();
    
    return Padding(
      padding: EdgeInsets.only(
        right: 8.r,
        bottom: 4.r,
        left: 8.r,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _formatTime(timestamp),
            style: AppTextStyles.chatTime(),
          ),
          SizedBox(width: 4.w),
          if (isMe) _buildStatusIcon(),
          if (status == MessageStatus.failed)
            GestureDetector(
              onTap: onRetry,
              child: Padding(
                padding: EdgeInsets.all(4.r),
                child: Icon(
                  Icons.refresh,
                  size: 12.r,
                  color: AppColors.error,
                ),
              ),
            ),
        ],
      ),
    );
  }
  
  /// Build icon trạng thái tin nhắn
  Widget _buildStatusIcon() {
    switch (status) {
      case MessageStatus.sending:
        return Icon(
          Icons.access_time,
          size: 12.r,
          color: AppColors.grey,
        );
      case MessageStatus.sent:
        return Icon(
          Icons.check,
          size: 12.r,
          color: AppColors.grey,
        );
      case MessageStatus.delivered:
        return Icon(
          Icons.done_all,
          size: 12.r,
          color: AppColors.grey,
        );
      case MessageStatus.read:
        return Icon(
          Icons.done_all,
          size: 12.r,
          color: AppColors.primary,
        );
      case MessageStatus.failed:
        return Icon(
          Icons.error_outline,
          size: 12.r,
          color: AppColors.error,
        );
    }
  }
  
  /// Format thời gian hiển thị
  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    final messageDate = DateTime(dateTime.year, dateTime.month, dateTime.day);
    
    final hours = dateTime.hour.toString().padLeft(2, '0');
    final minutes = dateTime.minute.toString().padLeft(2, '0');
    final time = '$hours:$minutes';
    
    if (messageDate == today) {
      return time;
    } else if (messageDate == yesterday) {
      return 'Hôm qua';
    } else {
      final day = dateTime.day.toString().padLeft(2, '0');
      final month = dateTime.month.toString().padLeft(2, '0');
      return '$day/$month';
    }
  }
  
  /// Format kích thước file
  String _formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      final kb = bytes / 1024;
      return '${kb.toStringAsFixed(1)} KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      final mb = bytes / (1024 * 1024);
      return '${mb.toStringAsFixed(1)} MB';
    } else {
      final gb = bytes / (1024 * 1024 * 1024);
      return '${gb.toStringAsFixed(1)} GB';
    }
  }
} 