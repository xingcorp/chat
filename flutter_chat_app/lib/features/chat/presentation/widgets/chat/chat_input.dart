import 'dart:async';
import 'dart:io';

import 'package:app_settings/app_settings.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_chat_app/core/base/base_widget.dart';
import 'package:flutter_chat_app/core/constants/app_constants.dart';
import 'package:flutter_chat_app/core/constants/app_dimens.dart';
import 'package:flutter_chat_app/core/theme/app_colors.dart';
import 'package:flutter_chat_app/core/di/injection.dart';
import 'package:flutter_chat_app/core/services/emoji_shortcode_service.dart';
import 'package:flutter_chat_app/core/services/emoticon_parser_service.dart';
import 'package:flutter_chat_app/core/services/voice_recorder_service.dart';
import 'package:flutter_chat_app/core/theme/app_text_styles.dart';
import 'package:flutter_chat_app/core/utils/attachment_type.dart';
import 'package:flutter_chat_app/core/utils/logger.dart';
import 'package:flutter_chat_app/core/utils/optimized_repaint_boundary.dart';
import 'package:flutter_chat_app/l10n/l10n.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/buttons/app_button.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/dialogs/app_alert_dialog.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/feedback/app_snack_bar.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/feedback/app_toast.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/feedback/feedback_type.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/menus/app_tooltip.dart';
import 'package:flutter_chat_app/features/chat/presentation/widgets/chat/shortcode_autocomplete_overlay.dart';

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
    super.key,
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
  });

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

  // ── Shortcode autocomplete state ──
  /// Query hiện tại cho shortcode autocomplete (phần sau `:`)
  String? _shortcodeQuery;

  /// Vị trí của dấu `:` bắt đầu shortcode trong text
  int _shortcodeStartIndex = -1;

  /// LayerLink để anchor overlay vào input
  final LayerLink _shortcodeLayerLink = LayerLink();

  /// OverlayEntry cho shortcode popup
  OverlayEntry? _shortcodeOverlayEntry;

  bool get _usesDesktopVoiceRecordingUx {
    if (kIsWeb) return true;
    return Platform.isMacOS || Platform.isWindows || Platform.isLinux;
  }

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
    _dismissShortcodeOverlay();
    if (_isRecording) {
      unawaited(_voiceRecorderService.cancelRecording());
    }
    super.dispose();
  }

  /// Xử lý khi text thay đổi
  void _handleTextChanged() {
    final text = _textController.text;

    // Detect shortcode autocomplete (:smile, :heart, ...)
    _detectShortcodeQuery();

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
    // Dismiss shortcode overlay khi mất focus
    if (!_focusNode.hasFocus) {
      _dismissShortcodeOverlay();
    }
  }

  // ══════════════════════════════════════════
  // Shortcode Autocomplete
  // ══════════════════════════════════════════

  /// Detect shortcode typing pattern `:query` trong text tại vị trí cursor
  ///
  /// Pattern: Discord/Telegram/Slack
  /// - User gõ `:` → bắt đầu track
  /// - Tiếp tục gõ 2+ ký tự → show overlay
  /// - Space, Enter, hoặc xóa `:` → dismiss
  void _detectShortcodeQuery() {
    final text = _textController.text;
    final selection = _textController.selection;

    // Cần có cursor position hợp lệ
    if (!selection.isValid || selection.baseOffset != selection.extentOffset) {
      _dismissShortcodeOverlay();
      return;
    }

    final cursorPos = selection.baseOffset;
    if (cursorPos <= 0) {
      _dismissShortcodeOverlay();
      return;
    }

    // Tìm dấu `:` gần nhất phía trước cursor
    final textBeforeCursor = text.substring(0, cursorPos);
    final lastColonIndex = textBeforeCursor.lastIndexOf(':');

    if (lastColonIndex < 0) {
      _dismissShortcodeOverlay();
      return;
    }

    // Kiểm tra `:` phải ở đầu text hoặc sau whitespace
    if (lastColonIndex > 0 && textBeforeCursor[lastColonIndex - 1] != ' ') {
      _dismissShortcodeOverlay();
      return;
    }

    // Lấy query (phần giữa `:` và cursor)
    final query = textBeforeCursor.substring(lastColonIndex + 1);

    // Query không được chứa space (nếu có space → không phải shortcode)
    if (query.contains(' ') || query.contains('\n')) {
      _dismissShortcodeOverlay();
      return;
    }

    // Cần ít nhất 2 ký tự để bắt đầu search (Discord/Slack standard)
    if (query.length < 2) {
      _dismissShortcodeOverlay();
      return;
    }

    // Kiểm tra có kết quả không
    final results = EmojiShortcodeService.search(query, limit: 6);
    if (results.isEmpty) {
      _dismissShortcodeOverlay();
      return;
    }

    // Update state và show overlay
    _shortcodeQuery = query;
    _shortcodeStartIndex = lastColonIndex;
    _showShortcodeOverlay();
  }

  /// Hiển thị shortcode autocomplete overlay phía trên input
  void _showShortcodeOverlay() {
    // Remove existing overlay trước
    _shortcodeOverlayEntry?.remove();

    final overlay = Overlay.of(context);

    _shortcodeOverlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        width: 260,
        child: CompositedTransformFollower(
          link: _shortcodeLayerLink,
          showWhenUnlinked: false,
          offset: const Offset(0, -8),
          followerAnchor: Alignment.bottomLeft,
          targetAnchor: Alignment.topLeft,
          child: ShortcodeAutocompleteOverlay(
            query: _shortcodeQuery ?? '',
            onSelect: _onShortcodeSelected,
            onDismiss: _dismissShortcodeOverlay,
          ),
        ),
      ),
    );

    overlay.insert(_shortcodeOverlayEntry!);
  }

  /// User chọn emoji từ shortcode autocomplete
  void _onShortcodeSelected(String emoji, String shortcode) {
    final text = _textController.text;
    final startIndex = _shortcodeStartIndex;

    if (startIndex < 0 || startIndex >= text.length) {
      _dismissShortcodeOverlay();
      return;
    }

    // Replace `:query` bằng emoji character
    final cursorPos = _textController.selection.baseOffset;
    final before = text.substring(0, startIndex);
    final after = cursorPos < text.length ? text.substring(cursorPos) : '';
    final newText = '$before$emoji $after';

    _textController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(
        offset: startIndex + emoji.length + 1,
      ),
    );

    _dismissShortcodeOverlay();
  }

  /// Dismiss và cleanup shortcode overlay
  void _dismissShortcodeOverlay() {
    _shortcodeOverlayEntry?.remove();
    _shortcodeOverlayEntry = null;
    _shortcodeQuery = null;
    _shortcodeStartIndex = -1;
  }

  /// Gửi tin nhắn
  void _handleSendMessage() {
    final rawText = _textController.text.trim();
    if (rawText.isNotEmpty) {
      // Convert emoticons thành emoji trước khi gửi
      // Pattern: Zalo/Messenger/WhatsApp — convert on send
      // 1. Shortcodes: :smile: → 😊, :heart: → ❤️
      // 2. Emoticons: :) → 😊, :v → ✌️
      final withShortcodes = EmojiShortcodeService.convert(rawText);
      final text = EmoticonParserService.convert(withShortcodes);

      // Gửi tin nhắn
      widget.onSendText(text);

      // Xóa văn bản
      _textController.clear();

      // Dismiss shortcode overlay nếu đang hiện
      _dismissShortcodeOverlay();

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
      final startResult = await _voiceRecorderService.startRecordingWithResult();
      if (!mounted) return;

      if (startResult == VoiceRecordingStartResult.permissionDenied ||
          startResult ==
              VoiceRecordingStartResult.permissionPermanentlyDenied) {
        await _showMicrophonePermissionDialog(
          isPermanentlyDenied:
              startResult ==
              VoiceRecordingStartResult.permissionPermanentlyDenied,
        );
        return;
      }

      if (startResult != VoiceRecordingStartResult.started) {
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

  Future<void> _onVoiceRecordingTap() async {
    debugPrint('[ChatInput] _onVoiceRecordingTap called!');
    debugPrint('[ChatInput] _isRecording=$_isRecording, mounted=$mounted');
    debugPrint('[ChatInput] _usesDesktopVoiceRecordingUx=$_usesDesktopVoiceRecordingUx');
    if (_isRecording || !mounted) {
      debugPrint('[ChatInput] BLOCKED: _isRecording=$_isRecording, mounted=$mounted');
      return;
    }

    if (_usesDesktopVoiceRecordingUx) {
      debugPrint('[ChatInput] Desktop mode -> _startRecording()');
      await _startRecording();
    } else {
      debugPrint('[ChatInput] Mobile mode -> showing AppToast.info');
      // Mobile: show toast hint
      AppToast.info(
        context: context,
        message: context.l10n.longPressToRecord,
        duration: const Duration(seconds: 2),
      );
      debugPrint('[ChatInput] AppToast.info called successfully');
    }
  }

  Widget _buildVoiceRecordingButton(BuildContext context) {
    debugPrint('[ChatInput] _buildVoiceRecordingButton: _usesDesktopVoiceRecordingUx=$_usesDesktopVoiceRecordingUx');
    final micButton = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        debugPrint('[ChatInput] GestureDetector.onTap FIRED!');
        _onVoiceRecordingTap();
      },
      onLongPress: _usesDesktopVoiceRecordingUx
          ? null
          : () {
              unawaited(_startRecording());
            },
      onLongPressEnd:
          _usesDesktopVoiceRecordingUx ? null : _stopRecording,
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
    );

    // Desktop: wrap with AppTooltip for hover hint
    if (_usesDesktopVoiceRecordingUx) {
      return AppTooltip(
        message: context.l10n.recordVoiceMessage,
        child: micButton,
      );
    }

    // Mobile: no tooltip wrapper, toast is shown on tap
    return micButton;
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
            await AppSettings.openAppSettings();
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isTextEmpty = _textController.text.isEmpty;
    debugPrint('[ChatInput] build: isTextEmpty=$isTextEmpty, enableVoiceRecording=${widget.enableVoiceRecording}, _isRecording=$_isRecording');

    // Kiểm tra nếu đang ghi âm
    if (_isRecording) {
      return _buildRecordingUI();
    }

    return OptimizedRepaintBoundary(
      perfTag: 'chat_input',
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimens.inputBarMargin,
          vertical: AppDimens.inputBarMargin,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(AppDimens.inputBarRadius),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadow,
                blurRadius: AppDimens.inputBarElevation,
                offset: const Offset(0, -1),
              ),
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
                child: CompositedTransformTarget(
                  link: _shortcodeLayerLink,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? AppColors.inputBackgroundDarkMode
                          : AppColors.inputBackground,
                      borderRadius:
                          BorderRadius.circular(AppDimens.inputBarRadius),
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
                                color: Theme.of(context).brightness == Brightness.dark
                                    ? AppColors.textHintDarkMode
                                    : AppColors.textHint,
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
              ),
              // Morphing send/mic button with rotation animation
              AnimatedSwitcher(
                duration: const Duration(milliseconds: AppDimens.durationFast),
                transitionBuilder: (child, animation) {
                  return ScaleTransition(
                    scale: animation,
                    child: child,
                  );
                },
                child: isTextEmpty && widget.enableVoiceRecording
                    ? KeyedSubtree(
                        key: const ValueKey('mic_button'),
                        child: _buildVoiceRecordingButton(context),
                      )
                    : IconButton(
                        key: const ValueKey('send_button'),
                        icon: Icon(
                          Icons.send_rounded,
                          color: AppColors.primary,
                        ),
                        onPressed: _handleSendMessage,
                      ),
              ),
            ],
          ),
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
