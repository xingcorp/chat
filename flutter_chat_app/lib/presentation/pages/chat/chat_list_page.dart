import 'package:flutter/material.dart';

/// Chat list page
class ChatListPage extends StatefulWidget {
  /// Constructor
  const ChatListPage({Key? key}) : super(key: key);

  @override
  State<ChatListPage> createState() => _ChatListPageState();
}

class _ChatListPageState extends State<ChatListPage> {
  final List<Map<String, dynamic>> _mockChats = [
    {
      'id': '1',
      'name': 'Nhóm Flutter Developers',
      'lastMessage': 'Bạn đã xem các tài liệu mới chưa?',
      'time': '10:30',
      'unread': 3,
      'isGroup': true,
      'avatarUrl': null,
    },
    {
      'id': '2',
      'name': 'Nguyễn Văn A',
      'lastMessage': 'Oke bạn, hẹn gặp lại',
      'time': '09:15',
      'unread': 0,
      'isGroup': false,
      'avatarUrl': null,
    },
    {
      'id': '3',
      'name': 'Trần Thị B',
      'lastMessage': 'Anh có thể giúp em vấn đề này được không?',
      'time': 'Hôm qua',
      'unread': 1,
      'isGroup': false,
      'avatarUrl': null,
    },
    {
      'id': '4',
      'name': 'Dự án Mobile App',
      'lastMessage': 'Deadline dự án là tuần sau nhé mọi người',
      'time': 'Hôm qua',
      'unread': 5,
      'isGroup': true,
      'avatarUrl': null,
    },
    {
      'id': '5',
      'name': 'Lê Văn C',
      'lastMessage': 'Tài liệu đã được gửi qua email rồi nhé',
      'time': '23/03',
      'unread': 0,
      'isGroup': false,
      'avatarUrl': null,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tin nhắn'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {},
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              // Handle menu selection
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'newGroup',
                child: Text('Tạo nhóm mới'),
              ),
              const PopupMenuItem(
                value: 'settings',
                child: Text('Cài đặt'),
              ),
            ],
          ),
        ],
      ),
      body: ListView.separated(
        itemCount: _mockChats.length,
        separatorBuilder: (context, index) => const Divider(
          height: 1,
          indent: 72,
        ),
        itemBuilder: (context, index) {
          final chat = _mockChats[index];
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: chat['isGroup'] 
                  ? Colors.green 
                  : Colors.blue,
              radius: 24,
              child: chat['avatarUrl'] != null
                  ? null
                  : Icon(
                      chat['isGroup'] ? Icons.group : Icons.person,
                      color: Colors.white,
                    ),
            ),
            title: Text(
              chat['name'],
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text(
              chat['lastMessage'],
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  chat['time'],
                  style: TextStyle(
                    fontSize: 12,
                    color: chat['unread'] > 0 ? Colors.blue : Colors.grey,
                  ),
                ),
                const SizedBox(height: 4),
                if (chat['unread'] > 0)
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      chat['unread'].toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            onTap: () {
              // Navigate to chat details
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navigate to contacts or new chat
        },
        child: const Icon(Icons.chat),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.chat),
            label: 'Tin nhắn',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.contacts),
            label: 'Danh bạ',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Cài đặt',
          ),
        ],
        onTap: (index) {
          // Handle navigation
        },
      ),
    );
  }
} 