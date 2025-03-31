import 'package:flutter/material.dart';

/// Widget hiển thị xem trước tệp đính kèm
class AttachmentPreview extends StatelessWidget {
  /// ID của tệp đính kèm
  final String attachmentId;
  
  /// Callback khi người dùng xóa tệp đính kèm
  final VoidCallback? onRemove;
  
  /// Kích thước tối đa
  final double maxSize;
  
  /// Constructor
  const AttachmentPreview({
    Key? key,
    required this.attachmentId,
    this.onRemove,
    this.maxSize = 80.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Trong ứng dụng thực, sẽ hiển thị hình ảnh, video, hoặc tệp tin
    // dựa trên attachmentId bằng cách tải từ service
    
    return Stack(
      children: [
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 4.0),
          width: maxSize,
          height: maxSize,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: Center(
            // Hiển thị placeholder, trong ứng dụng thực sẽ là ảnh hoặc icon phù hợp
            child: Icon(
              _getIconForAttachment(),
              size: maxSize / 2,
              color: Colors.grey[600],
            ),
          ),
        ),
        if (onRemove != null)
          Positioned(
            top: 0,
            right: 0,
            child: GestureDetector(
              onTap: onRemove,
              child: Container(
                padding: const EdgeInsets.all(2.0),
                decoration: BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.close,
                  size: 16.0,
                  color: Colors.white,
                ),
              ),
            ),
          ),
      ],
    );
  }
  
  /// Trả về icon tương ứng với loại tệp đính kèm
  IconData _getIconForAttachment() {
    // Trong ứng dụng thực, sẽ xác định loại tệp dựa trên ID
    // và hiển thị icon phù hợp
    
    // Ví dụ đơn giản
    if (attachmentId.contains('image')) {
      return Icons.image;
    } else if (attachmentId.contains('video')) {
      return Icons.videocam;
    } else if (attachmentId.contains('audio')) {
      return Icons.audiotrack;
    } else if (attachmentId.contains('doc')) {
      return Icons.insert_drive_file;
    } else {
      return Icons.attach_file;
    }
  }
} 