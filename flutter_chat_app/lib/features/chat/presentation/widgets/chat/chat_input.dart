import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_chat_app/core/base/base_widget.dart';
import 'package:flutter_chat_app/core/constants/app_constants.dart';
import 'package:flutter_chat_app/core/di/injection.dart';
import 'package:flutter_chat_app/core/services/voice_recorder_service.dart';
import 'package:flutter_chat_app/core/theme/app_text_styles.dart';
import 'package:flutter_chat_app/core/utils/logger.dart';
import 'package:flutter_chat_app/core/utils/attachment_type.dart';
import 'package:flutter_chat_app/core/utils/optimized_repaint_boundary.dart';
import 'package:flutter_chat_app/l10n/l10n.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/buttons/app_button.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/dialogs/app_alert_dialog.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/feedback/app_snack_bar.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/feedback/feedback_type.dart';
import 'package:permission_handler/permission_handler.dart';

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
  ChatInput({
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

  late final VoiceRecorderService _voiceRecorderService;

  /// Đang ghi âm hay không
  bool _isRecording = false;

  /// Timer đếm thời gian ghi âm
  Timer? _recordingTimer;

  /// Thời lượng đã ghi âm tính bằng giây
  int _recordingDuration = 0;

  /// Có đang kéo để huỷ ghi âm không
  bool _isDraggingToCancel = false;

  /// Vị trí bắt đầu kéo
  Offset? _dragStartPosition;

  /// Mức amplitude realtime của âm thanh
  double _recordingAmplitude = 0.0;

  /// Trong khoảng thời gian này sau khi gõ sẽ không gửi typing events
  final _typingThrottleDuration = const Duration(milliseconds: 500);
  Timer? _typingThrottleTimer;
  bool _isTyping = false;
  StreamSubscription<double>? _recordingAmplitudeSubscription;
  StreamSubscription<String>? _recordingLimitReachedSubscription;
  DateTime? _lastVoiceRecordingHintAt;

  @override
  void initState() {
    super.initState();
    _voiceRecorderService = getIt<VoiceRecorderService>();
    _recordingAmplitudeSubscription =
        _voiceRecorderService.amplitudeStream.listen((amplitude) {
      if (!mounted) return;
      safeSetState(() {
        _recordingAmplitude = amplitude.clamp(0.0, 1.0);
      });
    });
    _recordingLimitReachedSubscription =
        _voiceRecorderService.recordingLimitReachedStream.listen(
      _handleRecordingLimitReached,
    );

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
    _recordingAmplitudeSubscription?.cancel();
    _recordingLimitReachedSubscription?.cancel();
    if (_isRecording) {
      unawaited(_voiceRecorderService.cancelRecording());
    }
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
                      widget.onAttachmentSelected
                          ?.call(AttachmentType.location);
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
  Future<void> _startRecording() async {
    if (!widget.enableVoiceRecording || _isRecording) return;

    try {
      final permissionResult = await _voiceRecorderService.ensurePermission();
      if (!mounted) return;

      if (permissionResult != VoiceRecorderPermissionResult.granted) {
        await _showMicrophonePermissionDialog(
          isPermanentlyDenied: permissionResult ==
              VoiceRecorderPermissionResult.permanentlyDenied,
        );
        return;
      }

      final started = await _voiceRecorderService.startRecording();
      if (!mounted) return;
      if (!started) {
        AppSnackBar.show(
          context: context,
          message: context.l10n.errorOccurred,
          type: FeedbackType.error,
        );
        return;
      }

      safeSetState(() {
        _isRecording = true;
        _recordingDuration = 0;
        _isDraggingToCancel = false;
        _dragStartPosition = null;
        _recordingAmplitude = 0.0;
      });

      // Thông báo bắt đầu ghi âm
      widget.onVoiceRecordingStarted?.call();

      // Bắt đầu timer đếm thời gian
      _recordingTimer?.cancel();
      _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted) return;
        safeSetState(() {
          final nextDuration = _recordingDuration + 1;
          _recordingDuration = nextDuration > 300 ? 300 : nextDuration;
        });
      });
    } catch (e) {
      LogUtils.e('ChatInput', 'Lỗi khi bắt đầu ghi âm: $e');
      safeSetState(() {
        _isRecording = false;
      });

      if (mounted) {
        AppSnackBar.show(
          context: context,
          message: context.l10n.errorOccurred,
          type: FeedbackType.error,
        );
      }
    }
  }

  void _onVoiceRecordingTap() {
    if (_isRecording || !mounted) return;

    final now = DateTime.now();
    final lastHintAt = _lastVoiceRecordingHintAt;
    if (lastHintAt != null &&
        now.difference(lastHintAt) < const Duration(seconds: 2)) {
      return;
    }

    _lastVoiceRecordingHintAt = now;
    AppSnackBar.show(
      context: context,
      message: context.l10n.longPressToRecord,
      type: FeedbackType.info,
    );
  }

  /// Dừng ghi âm
  Future<void> _stopRecording(LongPressEndDetails details) async {
    if (!_isRecording) return;

    try {
      final bool isCancelled = _isDraggingToCancel;
      String? filePath;

      if (isCancelled) {
        await _voiceRecorderService.cancelRecording();
      } else {
        filePath = await _voiceRecorderService.stopRecording();
      }

      safeSetState(() {
        _isRecording = false;
        _recordingDuration = 0;
        _isDraggingToCancel = false;
        _dragStartPosition = null;
        _recordingAmplitude = 0.0;
      });
      _recordingTimer?.cancel();
      _recordingTimer = null;

      // Thông báo kết quả ghi âm
      if (isCancelled) {
        widget.onVoiceRecordingCancelled?.call();
      } else {
        final resolvedPath = filePath?.trim() ?? '';
        if (resolvedPath.isEmpty) {
          if (mounted) {
            AppSnackBar.show(
              context: context,
              message: context.l10n.errorOccurred,
              type: FeedbackType.error,
            );
          }
          return;
        }
        widget.onVoiceRecordingEnded?.call(resolvedPath);
      }
    } catch (e) {
      LogUtils.e('ChatInput', 'Lỗi khi dừng ghi âm: $e');
      if (mounted) {
        AppSnackBar.show(
          context: context,
          message: context.l10n.errorOccurred,
          type: FeedbackType.error,
        );
      }
    }
  }

  void _handleRecordingLimitReached(String filePath) {
    if (!_isRecording || !mounted) return;

    _recordingTimer?.cancel();
    safeSetState(() {
      _isRecording = false;
      _recordingDuration = 0;
      _isDraggingToCancel = false;
      _dragStartPosition = null;
      _recordingAmplitude = 0.0;
    });

    widget.onVoiceRecordingEnded?.call(filePath);
    AppSnackBar.show(
      context: context,
      message: context.l10n.recordingLimitReached,
      type: FeedbackType.info,
    );
  }

  Future<void> _showMicrophonePermissionDialog({
    required bool isPermanentlyDenied,
  }) async {
    await AppAlertDialog.show<void>(
      context: context,
      title: context.l10n.microphonePermissionTitle,
      content: isPermanentlyDenied
          ? context.l10n.microphonePermissionPermanentlyDeniedMessage
          : context.l10n.microphonePermissionMessage,
      actions: [
        AppButton.text(
          text: context.l10n.cancel,
          onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
        ),
        AppButton.primary(
          text: context.l10n.openSettings,
          onPressed: () async {
            Navigator.of(context, rootNavigator: true).pop();
            await openAppSettings();
          },
        ),
      ],
    );
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
                  borderRadius:
                      BorderRadius.circular(AppConstants.kDefaultBorderRadius),
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
                    onTap: _onVoiceRecordingTap,
                    onLongPress: () {
                      unawaited(_startRecording());
                    },
                    onLongPressEnd: _stopRecording,
                    child: Tooltip(
                      message: context.l10n.longPressToRecord,
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.mic,
                          color: Colors.white,
                        ),
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
          final double dragDistance =
              _dragStartPosition!.dx - details.localPosition.dx;

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
                Icon(
                  Icons.delete,
                  color: Colors.red,
                )
              else
                Icon(
                  Icons.mic,
                  color: Colors.red,
                ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _isDraggingToCancel
                          ? context.l10n.cancelRecording
                          : '${context.l10n.recording} ${_formatRecordingDuration()}',
                      style: TextStyle(
                        color:
                            _isDraggingToCancel ? Colors.red : Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: AppConstants.kSmallPadding / 2),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(
                          AppConstants.kSmallBorderRadius),
                      child: LinearProgressIndicator(
                        minHeight: 4,
                        value: _recordingAmplitude > 0
                            ? _recordingAmplitude
                            : 0.04,
                        backgroundColor: Colors.grey[300],
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _isDraggingToCancel
                              ? Colors.red
                              : Theme.of(context).primaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                _isDraggingToCancel
                    ? context.l10n.cancelRecording
                    : '${context.l10n.releaseToSend}\n${context.l10n.slideToCancel}',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
                textAlign: TextAlign.right,
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
