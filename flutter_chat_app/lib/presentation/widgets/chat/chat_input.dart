import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_chat_app/core/base/base_widget.dart';
import 'package:flutter_chat_app/core/constants/app_constants.dart';
import 'package:flutter_chat_app/core/theme/app_colors.dart';
import 'package:flutter_chat_app/core/theme/app_text_styles.dart';
import 'package:flutter_chat_app/core/utils/logger.dart';
import 'package:flutter_chat_app/core/utils/attachment_type.dart';
import 'package:flutter_chat_app/core/utils/optimized_repaint_boundary.dart';

/// Widget input cho chat
class ChatInput extends BaseStatefulWidget {
  /// Callback khi gửi tin nhắn văn bản
  final Function(String) onSendText;
  
  /// Callback khi bắt đầu nhập
  final VoidCallback? onTypingStarted;
  
  /// Callback khi kết thúc nhập
  final VoidCallback? onTypingEnded;
  
  /// Callback khi chọn kiểu đính kèm
  final Function(AttachmentType)? onAttachmentSelected;
  
  /// Callback khi bắt đầu ghi âm
  final VoidCallback? onVoiceRecordingStarted;
  
  /// Callback khi kết thúc ghi âm và gửi
  final Function(String)? onVoiceRecordingEnded;
  
  /// Callback khi huỷ ghi âm
  final VoidCallback? onVoiceRecordingCancelled;
  
  /// Placeholder hint
  final String hint;
  
  /// Có cho phép đính kèm không
  final bool enableAttachments;
  
  /// Có cho phép ghi âm không
  final bool enableVoiceRecording;
  
  /// Constructor
  const ChatInput({
    Key? key,
    required this.onSendText,
    this.onTypingStarted,
    this.onTypingEnded,
    this.onAttachmentSelected,
    this.onVoiceRecordingStarted,
    this.onVoiceRecordingEnded,
    this.onVoiceRecordingCancelled,
    this.hint = 'Nhập tin nhắn...',
    this.enableAttachments = true,
    this.enableVoiceRecording = true,
  }) : super(key: key);

  @override
  State<ChatInput> createState() => _ChatInputState();
}

class _ChatInputState extends BaseState<ChatInput> {
  /// Controller cho text input
  final TextEditingController _textController = TextEditingController();
  
  /// Focus node
  final FocusNode _focusNode = FocusNode();
  
  /// Đang ghi âm hay không
  bool _isRecording = false;
  
  /// Thời điểm bắt đầu ghi âm
  DateTime? _recordingStartTime;
  
  /// Timer đếm thời gian ghi âm
  Timer? _recordingTimer;
  
  /// Thời lượng đã ghi âm tính bằng giây
  int _recordingDuration = 0;
  
  /// Có đang kéo để huỷ ghi âm không
  bool _isDraggingToCancel = false;
  
  /// Vị trí bắt đầu kéo
  Offset? _dragStartPosition;
  
  /// Trong khoảng thời gian này sau khi gõ sẽ không gửi typing events
  final _typingThrottleDuration = const Duration(milliseconds: 500);
  Timer? _typingThrottleTimer;
  bool _isTyping = false;
  
  @override
  void initState() {
    super.initState();
    
    // Lắng nghe thay đổi văn bản để phát hiện typing
    _textController.addListener(_handleTextChanged);
    
    // Lắng nghe focus thay đổi
    _focusNode.addListener(_handleFocusChanged);
    
    // Khởi tạo
    _recordingStartTime = null;
  }
  
  @override
  void dispose() {
    _textController.removeListener(_handleTextChanged);
    _textController.dispose();
    _focusNode.removeListener(_handleFocusChanged);
    _focusNode.dispose();
    _recordingTimer?.cancel();
    _typingThrottleTimer?.cancel();
    super.dispose();
  }
  
  /// Xử lý khi text thay đổi
  void _handleTextChanged() {
    final text = _textController.text;
    
    // Nếu văn bản thay đổi, báo đang gõ
    if (text.isNotEmpty && !_isTyping) {
      _isTyping = true;
      widget.onTypingStarted?.call();
      
      // Khởi tạo timer để dừng sự kiện typing sau khoảng thời gian
      _typingThrottleTimer?.cancel();
      _typingThrottleTimer = Timer(_typingThrottleDuration, () {
        if (_isTyping) {
          _isTyping = false;
          widget.onTypingEnded?.call();
        }
      });
    } else if (text.isEmpty && _isTyping) {
      // Nếu văn bản rỗng, báo đã ngừng gõ
      _isTyping = false;
      _typingThrottleTimer?.cancel();
      widget.onTypingEnded?.call();
    } else {
      // Reset timer khi vẫn đang gõ
      _typingThrottleTimer?.cancel();
      _typingThrottleTimer = Timer(_typingThrottleDuration, () {
        if (_isTyping) {
          _isTyping = false;
          widget.onTypingEnded?.call();
        }
      });
    }
  }
  
  /// Xử lý khi focus thay đổi
  void _handleFocusChanged() {
    if (!_focusNode.hasFocus && _isTyping) {
      // Khi mất focus mà đang gõ, báo đã ngừng gõ
      _isTyping = false;
      _typingThrottleTimer?.cancel();
      widget.onTypingEnded?.call();
    }
  }
  
  /// Gửi tin nhắn
  void _handleSendMessage() {
    final text = _textController.text.trim();
    if (text.isNotEmpty) {
      // Gửi tin nhắn
      widget.onSendText(text);
      
      // Xóa văn bản
      _textController.clear();
      
      // Đặt lại trạng thái typing
      _isTyping = false;
      _typingThrottleTimer?.cancel();
      widget.onTypingEnded?.call();
      
      // Giữ focus cho input
      _focusNode.requestFocus();
    }
  }
  
  /// Hiển thị menu đính kèm
  void _showAttachmentMenu() {
    // Ẩn keyboard
    FocusScope.of(context).unfocus();
    
    // Hiển thị bottom sheet
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(AppConstants.kLargeBorderRadius),
          topRight: Radius.circular(AppConstants.kLargeBorderRadius),
        ),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Title
              Padding(
                padding: EdgeInsets.all(AppConstants.kDefaultPadding),
                child: Text(
                  'Đính kèm',
                  style: AppTextStyles.heading5(),
                ),
              ),
              
              // Divider
              const Divider(height: 1),
              
              // Grid các loại đính kèm
              GridView.count(
                shrinkWrap: true,
                crossAxisCount: 4,
                padding: EdgeInsets.all(AppConstants.kDefaultPadding),
                children: [
                  _buildAttachmentButton(
                    icon: Icons.photo,
                    label: 'Ảnh',
                    onTap: () {
                      Navigator.pop(context);
                      widget.onAttachmentSelected?.call(AttachmentType.photo);
                    },
                  ),
                  _buildAttachmentButton(
                    icon: Icons.videocam,
                    label: 'Video',
                    onTap: () {
                      Navigator.pop(context);
                      widget.onAttachmentSelected?.call(AttachmentType.video);
                    },
                  ),
                  _buildAttachmentButton(
                    icon: Icons.insert_drive_file,
                    label: 'File',
                    onTap: () {
                      Navigator.pop(context);
                      widget.onAttachmentSelected?.call(AttachmentType.file);
                    },
                  ),
                  _buildAttachmentButton(
                    icon: Icons.location_on,
                    label: 'Vị trí',
                    onTap: () {
                      Navigator.pop(context);
                      widget.onAttachmentSelected?.call(AttachmentType.location);
                    },
                  ),
                  _buildAttachmentButton(
                    icon: Icons.person,
                    label: 'Liên hệ',
                    onTap: () {
                      Navigator.pop(context);
                      widget.onAttachmentSelected?.call(AttachmentType.contact);
                    },
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
  
  /// Widget button cho attachment
  Widget _buildAttachmentButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: Theme.of(context).primaryColor,
              size: 28,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
        ],
      ),
    );
  }
  
  /// Bắt đầu ghi âm
  void _startRecording() {
    if (!widget.enableVoiceRecording) return;
    
    try {
      setState(() {
        _isRecording = true;
        _recordingStartTime = DateTime.now();
        _recordingDuration = 0;
        _isDraggingToCancel = false;
        _dragStartPosition = null;
      });
      
      // Thông báo bắt đầu ghi âm
      widget.onVoiceRecordingStarted?.call();
      
      // Bắt đầu timer đếm thời gian
      _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() {
          _recordingDuration++;
        });
      });
    } catch (e) {
      LogUtils.e('ChatInput', 'Lỗi khi bắt đầu ghi âm: $e');
      setState(() {
        _isRecording = false;
      });
      
      // Thông báo lỗi nếu cần
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Không thể ghi âm: $e'),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }
  
  /// Dừng ghi âm
  void _stopRecording(LongPressEndDetails details) {
    if (!_isRecording) return;
    
    try {
      final bool isCancelled = _isDraggingToCancel;
      
      setState(() {
        _isRecording = false;
        _recordingTimer?.cancel();
        _recordingTimer = null;
      });
      
      // Thông báo kết quả ghi âm
      if (isCancelled) {
        widget.onVoiceRecordingCancelled?.call();
      } else {
        // Giả lập gửi âm thanh, trong thực tế sẽ lưu file và trả về path
        final String fakePath = 'recording_${DateTime.now().millisecondsSinceEpoch}.mp3';
        widget.onVoiceRecordingEnded?.call(fakePath);
      }
    } catch (e) {
      LogUtils.e('ChatInput', 'Lỗi khi dừng ghi âm: $e');
      // Thông báo lỗi nếu cần
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Có lỗi xảy ra: $e'),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final bool isTextEmpty = _textController.text.isEmpty;
    
    // Kiểm tra nếu đang ghi âm
    if (_isRecording) {
      return _buildRecordingUI();
    }
    
    return OptimizedRepaintBoundary(
      perfTag: 'chat_input',
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -1),
            )
          ],
        ),
        padding: EdgeInsets.symmetric(
          horizontal: AppConstants.kSmallPadding,
          vertical: AppConstants.kSmallPadding,
        ),
        child: Row(
          children: [
            if (widget.enableAttachments)
              IconButton(
                icon: const Icon(Icons.attach_file),
                onPressed: _showAttachmentMenu,
              ),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.grey[800]
                      : Colors.grey[200],
                  borderRadius: BorderRadius.circular(AppConstants.kDefaultBorderRadius),
                ),
                padding: EdgeInsets.symmetric(
                  horizontal: AppConstants.kSmallPadding,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _textController,
                        focusNode: _focusNode,
                        minLines: 1,
                        maxLines: 5,
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: widget.hint,
                          hintStyle: TextStyle(
                            color: Colors.grey[500],
                          ),
                        ),
                        onSubmitted: (_) {
                          _handleSendMessage();
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            isTextEmpty && widget.enableVoiceRecording
                ? GestureDetector(
                    onLongPress: _startRecording,
                    onLongPressEnd: _stopRecording,
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.mic,
                        color: Colors.white,
                      ),
                    ),
                  )
                : IconButton(
                    icon: Icon(
                      Icons.send,
                      color: Theme.of(context).primaryColor,
                    ),
                    onPressed: _handleSendMessage,
                  ),
          ],
        ),
      ),
    );
  }
  
  /// Widget hiển thị khi đang ghi âm
  Widget _buildRecordingUI() {
    return RepaintBoundary(
      child: GestureDetector(
        onLongPressEnd: _stopRecording,
        onPanUpdate: (details) {
          if (_dragStartPosition == null) {
            _dragStartPosition = details.localPosition;
            return;
          }
          
          // Tính khoảng cách kéo theo chiều ngang (phải sang trái để huỷ)
          final double dragDistance = _dragStartPosition!.dx - details.localPosition.dx;
          
          // Nếu kéo quá ngưỡng, đánh dấu là huỷ
          if (dragDistance > 50) {
            if (!_isDraggingToCancel) {
              setState(() {
                _isDraggingToCancel = true;
              });
            }
          } else if (_isDraggingToCancel) {
            setState(() {
              _isDraggingToCancel = false;
            });
          }
        },
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: AppConstants.kDefaultPadding,
            vertical: AppConstants.kSmallPadding,
          ),
          color: Theme.of(context).cardColor,
          child: Row(
            children: [
              if (_isDraggingToCancel)
                const Icon(
                  Icons.delete,
                  color: Colors.red,
                )
              else
                const Icon(
                  Icons.mic,
                  color: Colors.red,
                ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  _isDraggingToCancel
                      ? 'Thả để huỷ ghi âm'
                      : 'Đang ghi âm... ${_formatRecordingDuration()}',
                  style: TextStyle(
                    color: _isDraggingToCancel ? Colors.red : Colors.grey[600],
                  ),
                ),
              ),
              Text(
                'Thả để gửi',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  /// Format thời gian ghi âm
  String _formatRecordingDuration() {
    final minutes = (_recordingDuration ~/ 60).toString().padLeft(2, '0');
    final seconds = (_recordingDuration % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
} 