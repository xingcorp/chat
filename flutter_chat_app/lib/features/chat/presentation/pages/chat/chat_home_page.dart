import 'package:flutter/material.dart';
import 'package:flutter_chat_app/features/chat/presentation/pages/chat/chat_details_page.dart';
import 'package:flutter_chat_app/features/chat/presentation/pages/chat/chat_list_page.dart';
import 'package:flutter_chat_app/features/chat/presentation/widgets/chat/chat_list_panel.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/layouts/app_responsive_layout.dart';

class ChatHomePage extends StatefulWidget {
  const ChatHomePage({super.key});

  @override
  State<ChatHomePage> createState() => _ChatHomePageState();
}

class _ChatHomePageState extends State<ChatHomePage> {
  String? _selectedChatId;

  @override
  Widget build(BuildContext context) {
    return AppResponsiveBuilder(
      builder: (context, layoutType) {
        if (!layoutType.isDesktop) {
          return const ChatListPage();
        }

        return Scaffold(
          body: Row(
            children: [
              SizedBox(
                width: 360,
                child: ChatListPanel(
                  onChatSelected: (chatId) {
                    if (_selectedChatId == chatId) return;
                    setState(() {
                      _selectedChatId = chatId;
                    });
                  },
                ),
              ),
              Expanded(
                child: _selectedChatId == null
                    ? const _DesktopEmptyChatPane()
                    : ChatDetailsPage(
                        key: ValueKey(_selectedChatId),
                        chatId: _selectedChatId!,
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _DesktopEmptyChatPane extends StatelessWidget {
  const _DesktopEmptyChatPane();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: Color(0xFFF3F4F6),
      child: Center(
        child: SizedBox(
          width: 420,
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.chat_bubble_outline, size: 44),
                  SizedBox(height: 12),
                  Text(
                    'Chọn một cuộc trò chuyện để bắt đầu',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
