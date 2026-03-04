import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_chat_app/features/chat/presentation/pages/chat/chat_details_page.dart';
import 'package:flutter_chat_app/features/chat/presentation/blocs/chat_draft/chat_draft_bloc.dart';
import 'package:flutter_chat_app/features/chat/presentation/widgets/chat/chat_list_panel.dart';
import 'package:flutter_chat_app/features/home/presentation/pages/main_home_page.dart';
import 'package:flutter_chat_app/l10n/l10n.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/layouts/app_responsive_layout.dart';
import 'package:get_it/get_it.dart';

class ChatHomePage extends StatefulWidget {
  const ChatHomePage({super.key});

  @override
  State<ChatHomePage> createState() => _ChatHomePageState();
}

class _ChatHomePageState extends State<ChatHomePage> {
  String? _selectedChatId;
  late final ChatDraftBloc _chatDraftBloc;

  @override
  void initState() {
    super.initState();
    _chatDraftBloc = GetIt.instance<ChatDraftBloc>();
  }

  @override
  void dispose() {
    _chatDraftBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppResponsiveBuilder(
      builder: (context, layoutType) {
        if (!layoutType.isDesktop) {
          return const MainHomePage();
        }

        return BlocProvider<ChatDraftBloc>.value(
          value: _chatDraftBloc,
          child: Scaffold(
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
    return ColoredBox(
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
                    context.l10n.selectConversationToStart,
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
