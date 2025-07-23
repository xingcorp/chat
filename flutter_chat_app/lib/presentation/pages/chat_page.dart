/// **CHAT PAGE**
/// 
/// Individual chat page for messaging.
/// This is a basic stub for testing purposes.

import 'package:flutter/material.dart';

/// **CHAT PAGE**
/// 
/// Displays individual chat conversation
class ChatPage extends StatelessWidget {
  final String chatId;
  
  const ChatPage({
    super.key,
    required this.chatId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chat $chatId'),
      ),
      body: const Center(
        child: Text('Chat Page - Coming Soon'),
      ),
    );
  }
}
