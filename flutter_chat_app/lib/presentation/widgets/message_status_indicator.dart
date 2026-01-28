import 'package:flutter/material.dart';
import 'package:flutter_chat_app/core/services/message_queue_service.dart';
import 'package:flutter_chat_app/domain/entities/message_queue_status.dart';

/// Widget hiển thị trạng thái của tin nhắn
class MessageStatusIndicator extends StatelessWidget {
  /// ID của tin nhắn (local ID)
  final String messageId;
  
  /// Trạng thái hiện tại, nếu null sẽ tự lấy từ dịch vụ
  final MessageQueueStatus? status;
  
  /// Kích thước của icon
  final double size;
  
  /// Màu sắc khi tin nhắn gặp lỗi
  final Color errorColor;
  
  /// Màu sắc khi tin nhắn đang chờ hoặc đang gửi
  final Color pendingColor;
  
  /// Màu sắc khi tin nhắn đã gửi thành công
  final Color sentColor;
  
  /// Màu sắc khi tin nhắn đã được nhận
  final Color deliveredColor;
  
  /// Màu sắc khi tin nhắn đã được đọc
  final Color readColor;
  
  /// Dịch vụ quản lý hàng đợi tin nhắn
  final MessageQueueService messageQueueService;
  
  /// Callback khi nhấn vào indicator
  final VoidCallback? onPressed;

  /// Constructor
  const MessageStatusIndicator({
    Key? key,
    required this.messageId,
    required this.messageQueueService,
    this.status,
    this.size = 16.0,
    this.errorColor = Colors.red,
    this.pendingColor = Colors.grey,
    this.sentColor = Colors.blue,
    this.deliveredColor = Colors.green,
    this.readColor = Colors.green,
    this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Nếu đã có trạng thái, hiển thị luôn
    if (status != null) {
      return _buildIndicator(status!);
    }
    
    // TODO: Refactor to use MessageBloc instead of MessageQueueService
    // MessageQueueService no longer has getMessageById() and messageStatusStream
    // This widget needs to be refactored to use BLoC pattern
    // For now, show default sent status
    return _buildIndicator(MessageQueueStatus.sent);
    
    // // Ngược lại, lấy trạng thái từ service
    // final queuedMessage = messageQueueService.getMessageById(messageId);
    // 
    // if (queuedMessage == null) {
    //   // Nếu không tìm thấy tin nhắn, hiển thị đã gửi
    //   return _buildIndicator(MessageQueueStatus.sent);
    // }
    // 
    // // Lắng nghe cập nhật trạng thái
    // return StreamBuilder<QueuedMessage>(
    //   stream: messageQueueService.messageStatusStream,
    //   initialData: queuedMessage,
    //   builder: (context, snapshot) {
    //     // Filter chỉ lấy cập nhật cho tin nhắn này
    //     if (snapshot.hasData && snapshot.data!.localId == messageId) {
    //       return _buildIndicator(snapshot.data!.status);
    //     }
    //     return _buildIndicator(queuedMessage.status);
    //   },
    // );
  }
  
  /// Xây dựng chỉ báo trạng thái dựa trên status
  Widget _buildIndicator(MessageQueueStatus status) {
    IconData iconData;
    Color color;
    bool showProgress = false;
    
    switch (status) {
      case MessageQueueStatus.draft:
        iconData = Icons.edit;
        color = pendingColor;
        break;
      case MessageQueueStatus.pending:
        iconData = Icons.access_time;
        color = pendingColor;
        break;
      case MessageQueueStatus.sending:
        iconData = Icons.send;
        color = pendingColor;
        showProgress = true;
        break;
      case MessageQueueStatus.sent:
        iconData = Icons.check;
        color = sentColor;
        break;
      case MessageQueueStatus.delivered:
        iconData = Icons.done_all;
        color = deliveredColor;
        break;
      case MessageQueueStatus.read:
        iconData = Icons.done_all;
        color = readColor;
        break;
      case MessageQueueStatus.failed:
        iconData = Icons.error_outline;
        color = errorColor;
        break;
      case MessageQueueStatus.cancelled:
        iconData = Icons.cancel;
        color = errorColor;
        break;
      case MessageQueueStatus.conflicted:
        iconData = Icons.warning;
        color = errorColor;
        break;
    }
    
    // Nếu có lỗi hoặc thất bại, cho phép nhấp để thử lại
    final canRetry = status == MessageQueueStatus.failed;
    
    if (showProgress) {
      // Hiển thị indicator quay tròn khi đang gửi
      return SizedBox(
        width: size,
        height: size,
        child: CircularProgressIndicator(
          strokeWidth: 2.0,
          valueColor: AlwaysStoppedAnimation<Color>(color),
        ),
      );
    } else if (canRetry && onPressed != null) {
      // Cho phép nhấn để thử lại nếu gặp lỗi
      return InkWell(
        onTap: onPressed,
        child: Icon(
          iconData,
          size: size,
          color: color,
        ),
      );
    } else {
      // Trạng thái thông thường
      return Icon(
        iconData,
        size: size,
        color: color,
      );
    }
  }
} 