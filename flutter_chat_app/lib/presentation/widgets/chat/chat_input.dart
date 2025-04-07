import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_chat_app/core/base/base_widget.dart';
import 'package:flutter_chat_app/core/constants/app_constants.dart';
import 'package:flutter_chat_app/core/theme/app_colors.dart';
import 'package:flutter_chat_app/core/theme/app_text_styles.dart';
import 'package:flutter_chat_app/core/utils/logger.dart';

/// Các loại hành động đính kèm
enum AttachmentType {
  photo,
  video,
  file,
  location,
  contact,
}

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
  final Function(Duration)? onVoiceRecordingEnded;
  
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
  _ChatInputState createState() => _ChatInputState();
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
          topLeft: Radius.circular(AppConstants.kLargeBorderRadius.r),
          topRight: Radius.circular(AppConstants.kLargeBorderRadius.r),
        ),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Title
              Padding(
                padding: EdgeInsets.all(AppConstants.kDefaultPadding.r),
                child: Text(
                  'Đính kèm',
                  style: AppTextStyles.heading5(),
                ),
              ),
              
              // Divider
              Divider(height: 1.r),
              
              // Grid các loại đính kèm
              GridView.count(
                shrinkWrap: true,
                crossAxisCount: 4,
                padding: EdgeInsets.all(AppConstants.kDefaultPadding.r),
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
              
              // Bottom padding
              SizedBox(height: 16.h),
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(
        AppConstants.kDefaultBorderRadius.r,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 50.r,
            height: 50.r,
            decoration: BoxDecoration(
              color: AppColors.primaryBackground,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: AppColors.primary,
              size: 24.r,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            label,
            style: AppTextStyles.bodySmall(),
          ),
        ],
      ),
    );
  }
  
  /// Bắt đầu ghi âm
  void _startRecording() {
    if (!widget.enableVoiceRecording) return;
    
    safeSetState(() {
      _isRecording = true;
      _recordingStartTime = DateTime.now();
      _recordingDuration = 0;
      _isDraggingToCancel = false;
      _dragStartPosition = null;
    });
    
    // Thông báo bắt đầu
    widget.onVoiceRecordingStarted?.call();
    
    // Phản hồi haptic
    HapticFeedback.mediumImpact();
    
    // Bắt đầu timer đếm thời gian
    _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      safeSetState(() {
        _recordingDuration += 1;
      });
    });
    
    LogUtils.d('ChatInput', 'Started voice recording');
  }
  
  /// Kết thúc ghi âm và gửi
  void _stopAndSendRecording() {
    if (!_isRecording) return;
    
    final duration = Duration(seconds: _recordingDuration);
    
    safeSetState(() {
      _isRecording = false;
      _recordingTimer?.cancel();
      _recordingTimer = null;
    });
    
    // Phản hồi haptic
    HapticFeedback.mediumImpact();
    
    // Kiểm tra nếu kéo để huỷ
    if (_isDraggingToCancel) {
      widget.onVoiceRecordingCancelled?.call();
      LogUtils.d('ChatInput', 'Cancelled voice recording');
    } else {
      // Gửi recording nếu thời lượng đủ
      if (_recordingDuration >= 1) {
        widget.onVoiceRecordingEnded?.call(duration);
        LogUtils.d('ChatInput', 'Sent voice recording: ${duration.inSeconds}s');
      } else {
        // Huỷ nếu thời lượng quá ngắn
        widget.onVoiceRecordingCancelled?.call();
        LogUtils.d('ChatInput', 'Recording too short, cancelled');
      }
    }
  }
  
  /// Format thời gian ghi âm
  String _formatRecordingDuration() {
    final minutes = (_recordingDuration ~/ 60).toString().padLeft(2, '0');
    final seconds = (_recordingDuration % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
  
  @override
  Widget buildContent(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowColor.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: SafeArea(
        child: _isRecording ? _buildRecordingUI() : _buildNormalInputUI(),
      ),
    );
  }
  
  /// UI nhập tin nhắn bình thường
  Widget _buildNormalInputUI() {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: AppConstants.kDefaultPadding.r,
        vertical: AppConstants.kSmallPadding.r,
      ),
      child: Row(
        children: [
          // Nút đính kèm
          if (widget.enableAttachments)
            IconButton(
              icon: Icon(
                Icons.add_circle_outline,
                color: AppColors.primary,
                size: 24.r,
              ),
              onPressed: _showAttachmentMenu,
              splashRadius: 20.r,
            ),
          
          // Text input
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.chatInputBackground,
                borderRadius: BorderRadius.circular(
                  AppConstants.kCircularBorderRadius.r,
                ),
                border: Border.all(
                  color: AppColors.greyLight,
                  width: 1.r,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      focusNode: _focusNode,
                      decoration: InputDecoration(
                        hintText: widget.hint,
                        hintStyle: AppTextStyles.inputHint(),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12.r,
                          vertical: 8.r,
                        ),
                      ),
                      textCapitalization: TextCapitalization.sentences,
                      keyboardType: TextInputType.multiline,
                      maxLines: 5,
                      minLines: 1,
                      onSubmitted: (_) => _handleSendMessage(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Nút gửi hoặc ghi âm
          _textController.text.trim().isNotEmpty
              ? IconButton(
                  icon: Icon(
                    Icons.send,
                    color: AppColors.primary,
                    size: 24.r,
                  ),
                  onPressed: _handleSendMessage,
                  splashRadius: 20.r,
                )
              : widget.enableVoiceRecording
                  ? GestureDetector(
                      onLongPress: _startRecording,
                      child: Padding(
                        padding: EdgeInsets.all(8.r),
                        child: Icon(
                          Icons.mic,
                          color: AppColors.primary,
                          size: 24.r,
                        ),
                      ),
                    )
                  : IconButton(
                      icon: Icon(
                        Icons.send,
                        color: AppColors.textDisabled,
                        size: 24.r,
                      ),
                      onPressed: null,
                      splashRadius: 20.r,
                    ),
        ],
      ),
    );
  }
  
  /// UI ghi âm
  Widget _buildRecordingUI() {
    return GestureDetector(
      onLongPressEnd: (_) => _stopAndSendRecording(),
      onPanUpdate: (details) {
        if (_dragStartPosition == null) {
          _dragStartPosition = details.globalPosition;
        }
        
        // Tính khoảng cách kéo
        final dragDistance = (_dragStartPosition! - details.globalPosition).dy;
        
        // Nếu kéo lên trên một khoảng đủ lớn, đánh dấu là huỷ
        if (dragDistance > 50) {
          if (!_isDraggingToCancel) {
            safeSetState(() {
              _isDraggingToCancel = true;
            });
            HapticFeedback.lightImpact();
          }
        } else if (_isDraggingToCancel) {
          safeSetState(() {
            _isDraggingToCancel = false;
          });
        }
      },
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: AppConstants.kDefaultPadding.r,
          vertical: AppConstants.kDefaultPadding.r,
        ),
        color: _isDraggingToCancel
            ? Colors.red.withOpacity(0.1)
            : AppColors.primary.withOpacity(0.1),
        child: Row(
          children: [
            // Icon microphone
            Container(
              width: 40.r,
              height: 40.r,
              decoration: BoxDecoration(
                color: _isDraggingToCancel
                    ? Colors.red
                    : AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: Icon(
                _isDraggingToCancel ? Icons.close : Icons.mic,
                color: Colors.white,
                size: 24.r,
              ),
            ),
            
            SizedBox(width: 16.w),
            
            // Recording indicator and timer
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _isDraggingToCancel
                        ? 'Thả để huỷ'
                        : 'Đang ghi âm...',
                    style: AppTextStyles.bodyMedium(
                      color: _isDraggingToCancel
                          ? Colors.red
                          : AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Row(
                    children: [
                      Container(
                        width: 8.r,
                        height: 8.r,
                        decoration: BoxDecoration(
                          color: _isDraggingToCancel
                              ? Colors.red
                              : Colors.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        _formatRecordingDuration(),
                        style: AppTextStyles.bodySmall(),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Swipe instruction
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.keyboard_arrow_up,
                  color: AppColors.textSecondary,
                  size: 24.r,
                ),
                SizedBox(height: 4.h),
                Text(
                  'Kéo lên\nđể huỷ',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.caption(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
} 