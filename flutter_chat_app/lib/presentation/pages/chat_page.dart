/// **CHAT PAGE**
/// 
/// Individual chat page for messaging.
/// This is a basic stub for testing purposes.

import 'package:flutter/material.dart';
import 'package:flutter_chat_app/l10n/l10n.dart';

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
        title: Text(context.l10n.chatTitle(chatId)),
      ),
      body: Center(
        child: Text('Chat Page - ${context.l10n.comingSoon}'),
      ),
    );
  }
}
