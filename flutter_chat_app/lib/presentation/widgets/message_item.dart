import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_app/core/services/date_formatter_service.dart';
import 'package:flutter_chat_app/domain/entities/chat_message.dart';

/// Widget hiển thị một tin nhắn trong đoạn chat
class MessageItem extends StatelessWidget {
  /// Tin nhắn cần hiển thị
  final ChatMessage message;
  
  /// Người gửi tin nhắn
  final MessageSender sender;
  
  /// Có phải tin nhắn của người dùng hiện tại
  final bool isCurrentUser;
  
  /// Có hiển thị tin nhắn đầy đủ
  final bool showFull;
  
  /// Xử lý khi nhấn vào tin nhắn
  final VoidCallback? onTap;
  
  /// Callback khi nhấn giữ tin nhắn
  final VoidCallback? onLongPress;
  
  /// Đánh dấu tin nhắn đang được highlight (VD: khi tìm kiếm)
  final bool isHighlighted;
  
  /// Constructor
  const MessageItem({
    Key? key,
    required this.message,
    required this.sender,
    required this.isCurrentUser,
    this.showFull = true,
    this.onTap,
    this.onLongPress,
    this.isHighlighted = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2.0, horizontal: 8.0),
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(16.0),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 4.0),
          decoration: BoxDecoration(
            color: isHighlighted 
                ? Colors.amber.withOpacity(0.2)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(16.0),
          ),
          child: Row(
            mainAxisAlignment: isCurrentUser 
                ? MainAxisAlignment.end
                : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!isCurrentUser) _buildAvatar(context),
              
              Flexible(
                child: Column(
                  crossAxisAlignment: isCurrentUser 
                      ? CrossAxisAlignment.end
                      : CrossAxisAlignment.start,
                  children: [
                    // Tên người gửi (chỉ hiển thị khi không phải người dùng hiện tại)
                    if (!isCurrentUser && message.sender.name.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(left: 12.0, bottom: 2.0),
                        child: Text(
                          message.sender.name,
                          style: TextStyle(
                            fontSize: 12.0,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                    
                    // Nội dung tin nhắn chính
                    _buildMessageContent(context),
                  ],
                ),
              ),
              
              if (isCurrentUser) 
                SizedBox(width: 8.0),
              
              if (isCurrentUser) _buildMessageStatus(),
            ],
          ),
        ),
      ),
    );
  }
  
  /// Xây dựng avatar của người gửi
  Widget _buildAvatar(BuildContext context) {
    return CircleAvatar(
      radius: 16.0,
      backgroundColor: Theme.of(context).colorScheme.primary,
      child: message.sender.avatar != null && message.sender.avatar!.isNotEmpty
          ? ClipRRect(
              borderRadius: BorderRadius.circular(16.0),
              child: CachedNetworkImage(
                imageUrl: message.sender.avatar!,
                width: 32.0,
                height: 32.0,
                fit: BoxFit.cover,
                placeholder: (context, url) => Text(
                  message.sender.name.isNotEmpty ? message.sender.name[0].toUpperCase() : '?',
                  style: const TextStyle(color: Colors.white),
                ),
                errorWidget: (context, url, error) => Text(
                  message.sender.name.isNotEmpty ? message.sender.name[0].toUpperCase() : '?',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            )
          : Text(
              message.sender.name.isNotEmpty ? message.sender.name[0].toUpperCase() : '?',
              style: const TextStyle(color: Colors.white),
            ),
    );
  }
  
  /// Xây dựng nội dung tin nhắn
  Widget _buildMessageContent(BuildContext context) {
    final contentType = message.contentType.toString().toLowerCase();
    
    // Bong bóng chat
    return Container(
      margin: EdgeInsets.only(
        left: isCurrentUser ? 64.0 : 0.0,
        right: isCurrentUser ? 0.0 : 64.0,
      ),
      decoration: BoxDecoration(
        color: isCurrentUser 
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).cardColor,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16.0),
          topRight: Radius.circular(16.0),
          bottomLeft: Radius.circular(isCurrentUser ? 16.0 : 4.0),
          bottomRight: Radius.circular(isCurrentUser ? 4.0 : 16.0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16.0),
          topRight: Radius.circular(16.0),
          bottomLeft: Radius.circular(isCurrentUser ? 16.0 : 4.0),
          bottomRight: Radius.circular(isCurrentUser ? 4.0 : 16.0),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Nội dung tin nhắn dựa trên loại
            if (contentType == 'text')
              _buildTextMessage(context)
            else if (contentType == 'image')
              _buildImageMessage()
            else if (contentType == 'video')
              _buildVideoMessage()
            else if (contentType == 'audio')
              _buildAudioMessage()
            else if (contentType == 'file')
              _buildFileMessage(context)
            else
              _buildUnknownMessage(context),
            
            // Thời gian gửi tin nhắn
            _buildTimestamp(context),
            
            // Reactions (if any)
            if (message.reactions.isNotEmpty)
              _buildReactions(context),
          ],
        ),
      ),
    );
  }
  
  /// Xây dựng hiển thị reactions
  Widget _buildReactions(BuildContext context) {
    // Group reactions by emoji code
    final reactionCounts = <String, int>{};
    for (final reaction in message.reactions) {
      reactionCounts[reaction.code] = (reactionCounts[reaction.code] ?? 0) + 1;
    }
    
    return Padding(
      padding: const EdgeInsets.only(left: 8.0, right: 8.0, bottom: 4.0),
      child: Wrap(
        spacing: 4.0,
        runSpacing: 4.0,
        children: reactionCounts.entries.map((entry) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0),
            decoration: BoxDecoration(
              color: isCurrentUser 
                  ? Colors.white.withOpacity(0.2)
                  : Theme.of(context).colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12.0),
              border: Border.all(
                color: isCurrentUser 
                    ? Colors.white.withOpacity(0.3)
                    : Theme.of(context).colorScheme.primary.withOpacity(0.3),
                width: 1.0,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  entry.key,
                  style: const TextStyle(fontSize: 12.0),
                ),
                const SizedBox(width: 2.0),
                Text(
                  entry.value.toString(),
                  style: TextStyle(
                    fontSize: 10.0,
                    fontWeight: FontWeight.bold,
                    color: isCurrentUser 
                        ? Colors.white
                        : Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
  
  /// Xây dựng tin nhắn văn bản
  Widget _buildTextMessage(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      child: Text(
        message.content,
        style: TextStyle(
          fontSize: 15.0,
          color: isCurrentUser 
              ? Colors.white
              : Theme.of(context).colorScheme.onSurface,
        ),
      ),
    );
  }
  
  /// Xây dựng tin nhắn hình ảnh
  Widget _buildImageMessage() {
    if (message.attachments.isEmpty) {
      return _buildErrorMessage('Không tìm thấy hình ảnh');
    }
    
    final attachment = message.attachments.first;
    final imageUrl = attachment.url;
    
    return Container(
      constraints: BoxConstraints(
        maxWidth: 240.0,
        maxHeight: 320.0,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16.0),
          topRight: Radius.circular(16.0),
        ),
        child: CachedNetworkImage(
          imageUrl: imageUrl,
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(
            height: 200.0,
            color: Colors.grey[300],
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          ),
          errorWidget: (context, url, error) => Container(
            height: 200.0,
            color: Colors.grey[300],
            child: const Center(
              child: Icon(Icons.error),
            ),
          ),
        ),
      ),
    );
  }
  
  /// Xây dựng tin nhắn video
  Widget _buildVideoMessage() {
    if (message.attachments.isEmpty) {
      return _buildErrorMessage('Không tìm thấy video');
    }
    
    final attachment = message.attachments.first;
    
    // Hiển thị thumbnail của video với nút play
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          constraints: BoxConstraints(
            maxWidth: 240.0,
            maxHeight: 320.0,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(16.0),
              topRight: Radius.circular(16.0),
            ),
            child: Container(
              color: Colors.black,
              child: attachment.url.isNotEmpty 
                  ? CachedNetworkImage(
                      imageUrl: attachment.url,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        height: 200.0,
                        color: Colors.grey[800],
                      ),
                      errorWidget: (context, url, error) => Container(
                        height: 200.0,
                        color: Colors.grey[800],
                        child: const Center(
                          child: Icon(Icons.movie, color: Colors.white54, size: 48.0),
                        ),
                      ),
                    )
                  : Container(
                      height: 200.0,
                      color: Colors.grey[800],
                      child: const Center(
                        child: Icon(Icons.movie, color: Colors.white54, size: 48.0),
                      ),
                    ),
            ),
          ),
        ),
        Icon(
          Icons.play_circle_fill,
          color: Colors.white.withOpacity(0.8),
          size: 48.0,
        ),
      ],
    );
  }
  
  /// Xây dựng tin nhắn âm thanh
  Widget _buildAudioMessage() {
    return Container(
      width: 200.0,
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      child: Row(
        children: [
          Icon(
            Icons.play_arrow,
            color: isCurrentUser ? Colors.white : Colors.grey[700],
          ),
          const SizedBox(width: 8.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 3.0,
                  decoration: BoxDecoration(
                    color: isCurrentUser ? Colors.white70 : Colors.grey[400],
                    borderRadius: BorderRadius.circular(1.5),
                  ),
                ),
                const SizedBox(height: 4.0),
                Text(
                  '0:00 / 0:30',
                  style: TextStyle(
                    fontSize: 10.0,
                    color: isCurrentUser ? Colors.white70 : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  /// Xây dựng tin nhắn file
  Widget _buildFileMessage(BuildContext context) {
    if (message.attachments.isEmpty) {
      return _buildErrorMessage('Không tìm thấy file');
    }
    
    final attachment = message.attachments.first;
    
    return Container(
      constraints: const BoxConstraints(
        maxWidth: 250.0,
      ),
      child: Card(
        margin: EdgeInsets.zero,
        color: isCurrentUser
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).cardColor,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(0)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Container(
                width: 40.0,
                height: 40.0,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(4.0),
                ),
                child: Icon(
                  Icons.insert_drive_file,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(width: 8.0),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      attachment.name,
                      style: TextStyle(
                        fontSize: 14.0,
                        fontWeight: FontWeight.bold,
                        color: isCurrentUser ? Colors.white : Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4.0),
                    Text(
                      '${(attachment.size / 1024).toStringAsFixed(1)} KB',
                      style: TextStyle(
                        fontSize: 12.0,
                        color: isCurrentUser ? Colors.white70 : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.download,
                color: isCurrentUser ? Colors.white70 : Colors.grey[700],
                size: 20.0,
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  /// Xây dựng tin nhắn không xác định loại
  Widget _buildUnknownMessage(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.help_outline,
            size: 16.0,
            color: isCurrentUser 
                ? Colors.white70
                : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          ),
          const SizedBox(width: 4.0),
          Flexible(
            child: Text(
              message.content.isNotEmpty 
                  ? message.content
                  : 'Không thể hiển thị tin nhắn này',
              style: TextStyle(
                fontSize: 14.0,
                fontStyle: FontStyle.italic,
                color: isCurrentUser 
                    ? Colors.white
                    : Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  /// Xây dựng thông báo lỗi
  Widget _buildErrorMessage(String errorText) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.error_outline,
            size: 16.0,
            color: isCurrentUser ? Colors.white70 : Colors.red[300],
          ),
          const SizedBox(width: 4.0),
          Text(
            errorText,
            style: TextStyle(
              fontSize: 14.0,
              fontStyle: FontStyle.italic,
              color: isCurrentUser ? Colors.white70 : Colors.red[300],
            ),
          ),
        ],
      ),
    );
  }
  
  /// Xây dựng hiển thị thời gian gửi tin nhắn
  Widget _buildTimestamp(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0, bottom: 4.0, left: 8.0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Show "Edited" label if message was edited
          if (message.editedAt != null) ...[
            Text(
              'Edited', // TODO: Use context.l10n.edited when available
              style: TextStyle(
                fontSize: 10.0,
                fontStyle: FontStyle.italic,
                color: isCurrentUser 
                    ? Colors.white60
                    : Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
              ),
            ),
            const SizedBox(width: 4.0),
          ],
          Text(
            DateFormatterService.formatTimeForMessage(message.createdAt),
            style: TextStyle(
              fontSize: 10.0,
              color: isCurrentUser 
                  ? Colors.white70
                  : Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }
  
  /// Xây dựng hiển thị trạng thái tin nhắn (đã gửi, đã nhận, đã đọc)
  Widget _buildMessageStatus() {
    // Kiểm tra tin nhắn đã được đọc bởi ai
    final hasRead = message.readBy.isNotEmpty;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Icon(
        hasRead ? Icons.done_all : Icons.done,
        size: 16.0,
        color: hasRead ? Colors.blue : Colors.grey[400],
      ),
    );
  }
} 