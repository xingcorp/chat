import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_chat_app/core/services/message_queue_service.dart';
import 'package:flutter_chat_app/shared/domain/entities/chat_message.dart';
import 'package:flutter_chat_app/presentation/blocs/message_queue/message_queue_bloc.dart';
import 'package:flutter_chat_app/presentation/widgets/attachment_preview.dart';

/// Widget nhập tin nhắn có hỗ trợ hàng đợi tin nhắn
class ChatMessageInput extends StatefulWidget {
  /// ID của cuộc trò chuyện
  final String chatId;
  
  /// Callback khi gửi tin nhắn
  final Function(String messageId)? onMessageSent;
  
  /// Gợi ý hiển thị trong ô nhập
  final String hintText;
  
  /// Có cho phép gửi tin nhắn media không
  final bool allowMedia;
  
  /// Constructor
  const ChatMessageInput({
    Key? key,
    required this.chatId,
    this.onMessageSent,
    this.hintText = 'Type a message...',
    this.allowMedia = true,
  }) : super(key: key);

  @override
  State<ChatMessageInput> createState() => _ChatMessageInputState();
}

class _ChatMessageInputState extends State<ChatMessageInput> {
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final List<String> _attachmentIds = [];
  bool _isComposing = false;
  
  // Bản nháp của ô nhập
  String? _draftKey;
  
  @override
  void initState() {
    super.initState();
    
    // Tạo key cho bản nháp
    _draftKey = 'draft_message_${widget.chatId}';
    
    // Khôi phục tin nhắn nháp
    _loadDraft();
    
    // Lắng nghe thay đổi văn bản
    _textController.addListener(_handleTextChanged);
  }

  @override
  void dispose() {
    // Lưu bản nháp khi thoát
    _saveDraft();
    
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }
  
  /// Tải bản nháp từ bộ nhớ
  Future<void> _loadDraft() async {
    // Trong ứng dụng thực, sẽ lấy từ SharedPreferences hoặc một nơi lưu trữ khác
    // _textController.text = await _draftService.getDraft(_draftKey) ?? '';
    
    // Ví dụ đơn giản này chỉ là demo
    final draft = ''; // Giả sử draft trống
    if (draft.isNotEmpty) {
      setState(() {
        _textController.text = draft;
        _isComposing = draft.trim().isNotEmpty;
      });
    }
  }
  
  /// Lưu bản nháp
  Future<void> _saveDraft() async {
    // Trong ứng dụng thực, sẽ lưu vào SharedPreferences hoặc một nơi lưu trữ khác
    // if (_textController.text.trim().isNotEmpty) {
    //   await _draftService.saveDraft(_draftKey, _textController.text);
    // } else {
    //   await _draftService.removeDraft(_draftKey);
    // }
  }
  
  /// Xử lý khi văn bản thay đổi
  void _handleTextChanged() {
    final newIsComposing = _textController.text.trim().isNotEmpty;
    if (newIsComposing != _isComposing) {
      setState(() {
        _isComposing = newIsComposing;
      });
    }
  }
  
  /// Chọn tệp đính kèm
  Future<void> _pickAttachment() async {
    // Mở hộp thoại chọn file
    // Trong ứng dụng thực, sẽ xử lý chọn hình, video, tệp... và tải lên để lấy ID
    // Ví dụ:
    // final result = await FilePicker.platform.pickFiles();
    // if (result != null) {
    //   final file = result.files.first;
    //   final uploadResult = await _uploadService.uploadFile(file);
    //   final attachmentId = uploadResult.id;
    
    // Ví dụ đơn giản này, tạo ID ngẫu nhiên
    final attachmentId = 'attachment_${DateTime.now().millisecondsSinceEpoch}';
    
    setState(() {
      _attachmentIds.add(attachmentId);
    });
  }
  
  /// Gửi tin nhắn
  void _handleSubmitted() {
    final text = _textController.text.trim();
    if (text.isEmpty && _attachmentIds.isEmpty) {
      return;
    }
    
    // Đặt lại controller và trạng thái
    _textController.clear();
    setState(() {
      _isComposing = false;
    });
    
    // Xác định loại nội dung
    ContentType contentType = ContentType.text;
    if (_attachmentIds.isNotEmpty) {
      if (text.isEmpty) {
        contentType = ContentType.file; // Use 'file' instead of 'media'
      } else {
        contentType = ContentType.text; // Use 'text' instead of 'mixed'
      }
    }
    
    // Gửi tin nhắn thông qua MessageQueueBloc
    context.read<MessageQueueBloc>().add(
      MessageQueueEvent.enqueueMessage(
        chatId: widget.chatId,
        content: text,
        contentType: contentType,
        attachments: [], // TODO: Convert _attachmentIds to List<Attachment>
      ),
    );
    
    // TODO: Handle message enqueued callback properly with BlocListener
    // This approach doesn't work as state is not immediately updated
    
    // Xóa danh sách tệp đính kèm
    setState(() {
      _attachmentIds.clear();
    });
    
    // Xóa bản nháp vì tin nhắn đã được gửi
    _saveDraft();
    
    // Đặt focus vào ô nhập để tiếp tục nhập tin nhắn
    _focusNode.requestFocus();
  }
  
  /// Xóa tệp đính kèm
  void _removeAttachment(String attachmentId) {
    setState(() {
      _attachmentIds.remove(attachmentId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Hiển thị preview các tệp đính kèm
          if (_attachmentIds.isNotEmpty) 
            Container(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
                itemCount: _attachmentIds.length,
                itemBuilder: (context, index) {
                  final attachmentId = _attachmentIds[index];
                  return AttachmentPreview(
                    attachmentId: attachmentId,
                    onRemove: () => _removeAttachment(attachmentId),
                  );
                },
              ),
            ),
            
          // Hàng nhập tin nhắn
          Row(
            children: [
              // Nút đính kèm
              if (widget.allowMedia)
                IconButton(
                  icon: const Icon(Icons.add_photo_alternate),
                  onPressed: _pickAttachment,
                ),
              
              // Ô nhập văn bản
              Expanded(
                child: TextField(
                  controller: _textController,
                  focusNode: _focusNode,
                  decoration: InputDecoration(
                    hintText: widget.hintText,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16.0, 
                      vertical: 8.0,
                    ),
                  ),
                  maxLines: null,
                  keyboardType: TextInputType.multiline,
                  textCapitalization: TextCapitalization.sentences,
                ),
              ),
              
              // Nút gửi
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                child: IconButton(
                  icon: Icon(Icons.send),
                  color: _isComposing || _attachmentIds.isNotEmpty
                      ? Theme.of(context).primaryColor
                      : Colors.grey,
                  onPressed: (_isComposing || _attachmentIds.isNotEmpty)
                      ? _handleSubmitted
                      : null,
                ),
              ),
            ],
          ),
          
          // Lắng nghe trạng thái MessageQueueBloc để cập nhật UI
          BlocListener<MessageQueueBloc, MessageQueueState>(
            listener: (context, state) {
              state.maybeWhen(
                messageEnqueued: (messageId) {
                  if (widget.onMessageSent != null) {
                    widget.onMessageSent!(messageId);
                  }
                },
                orElse: () {},
              );
            },
            child: const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
} 