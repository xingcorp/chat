import 'package:flutter/material.dart';

/// Chat details page
class ChatDetailsPage extends StatefulWidget {
  /// Chat ID
  final String chatId;
  
  /// Constructor
  const ChatDetailsPage({
    Key? key,
    required this.chatId,
  }) : super(key: key);

  @override
  State<ChatDetailsPage> createState() => _ChatDetailsPageState();
}

class _ChatDetailsPageState extends State<ChatDetailsPage> {
  final TextEditingController _messageController = TextEditingController();
  final List<Map<String, dynamic>> _mockMessages = [];
  final ScrollController _scrollController = ScrollController();
  
  final String _mockUserName = 'Nhóm Flutter Developers';
  final bool _isGroup = true;
  
  @override
  void initState() {
    super.initState();
    
    // Simulating mock messages
    _mockMessages.addAll([
      {
        'id': '1',
        'text': 'Chào mọi người!',
        'isMe': false,
        'sender': 'Nguyễn Văn A',
        'time': '10:30',
        'status': 'read',
      },
      {
        'id': '2',
        'text': 'Chào bạn, bạn khỏe không?',
        'isMe': true,
        'sender': 'Tôi',
        'time': '10:31',
        'status': 'read',
      },
      {
        'id': '3',
        'text': 'Mọi người nhớ hoàn thành nhiệm vụ trước deadline nhé',
        'isMe': false,
        'sender': 'Trần Thị B',
        'time': '10:35',
        'status': 'read',
      },
      {
        'id': '4',
        'text': 'Tôi đã hoàn thành phần UI rồi, đang làm tiếp phần API',
        'isMe': true,
        'sender': 'Tôi',
        'time': '10:36',
        'status': 'read',
      },
      {
        'id': '5',
        'text': 'Tuyệt vời! Mình sẽ review code của bạn',
        'isMe': false,
        'sender': 'Lê Văn C',
        'time': '10:40',
        'status': 'read',
      },
    ]);
  }
  
  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
  
  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;
    
    setState(() {
      _mockMessages.add({
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'text': _messageController.text,
        'isMe': true,
        'sender': 'Tôi',
        'time': '${DateTime.now().hour}:${DateTime.now().minute}',
        'status': 'sending',
      });
      
      _messageController.clear();
    });
    
    // Scroll to bottom
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
    
    // Simulate message sent
    Future.delayed(const Duration(seconds: 1), () {
      setState(() {
        _mockMessages.last['status'] = 'sent';
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: _isGroup ? Colors.green : Colors.blue,
              child: Icon(
                _isGroup ? Icons.group : Icons.person,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _mockUserName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    _isGroup 
                        ? '5 thành viên' 
                        : 'Trực tuyến',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.videocam),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.call),
            onPressed: () {},
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              // Handle menu selection
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'viewProfile',
                child: Text('Xem thông tin'),
              ),
              const PopupMenuItem(
                value: 'search',
                child: Text('Tìm kiếm'),
              ),
              const PopupMenuItem(
                value: 'mute',
                child: Text('Tắt thông báo'),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Chat messages
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _mockMessages.length,
              itemBuilder: (context, index) {
                final message = _mockMessages[index];
                final isMe = message['isMe'] as bool;
                
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Align(
                    alignment: isMe 
                        ? Alignment.centerRight 
                        : Alignment.centerLeft,
                    child: Container(
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.75,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: isMe 
                            ? Colors.blue 
                            : Colors.grey[200],
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_isGroup && !isMe)
                            Text(
                              message['sender'] as String,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                color: isMe ? Colors.white70 : Colors.black87,
                              ),
                            ),
                          Text(
                            message['text'] as String,
                            style: TextStyle(
                              color: isMe ? Colors.white : Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Align(
                            alignment: Alignment.bottomRight,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  message['time'] as String,
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: isMe 
                                        ? Colors.white70 
                                        : Colors.black54,
                                  ),
                                ),
                                if (isMe) ...[
                                  const SizedBox(width: 4),
                                  Icon(
                                    message['status'] == 'sending'
                                        ? Icons.access_time
                                        : message['status'] == 'sent'
                                            ? Icons.check
                                            : Icons.done_all,
                                    size: 14,
                                    color: Colors.white70,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          
          // Message input
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 3,
                  offset: const Offset(0, -1),
                ),
              ],
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () {},
                ),
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: 'Nhập tin nhắn...',
                      border: InputBorder.none,
                    ),
                    textCapitalization: TextCapitalization.sentences,
                    minLines: 1,
                    maxLines: 5,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.emoji_emotions_outlined),
                  onPressed: () {},
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  color: Colors.blue,
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 