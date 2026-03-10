import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_chat_app/core/services/chat_conversation_selection_service.dart';
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
  SelectedConversation? _selectedConversation;
  late final ChatDraftBloc _chatDraftBloc;
  late final ChatConversationSelectionService _conversationSelectionService;
  StreamSubscription<SelectedConversation?>? _selectedConversationSubscription;

  @override
  void initState() {
    super.initState();
    _chatDraftBloc = GetIt.instance<ChatDraftBloc>();
    _conversationSelectionService =
        GetIt.instance<ChatConversationSelectionService>();
    _selectedConversation = _conversationSelectionService.selectedConversation;
    _selectedConversationSubscription =
        _conversationSelectionService.selectedConversationStream.listen(
      (selection) {
        if (!mounted || _selectedConversation == selection) {
          return;
        }

        setState(() {
          _selectedConversation = selection;
        });
      },
    );
  }

  @override
  void dispose() {
    _selectedConversationSubscription?.cancel();
    _conversationSelectionService
        .clearSelection(_selectedConversation?.conversationId);
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
                      // ChatListPanel already calls
                      // _selectConversationWithReceiverId() which sets both
                      // chatId AND receiverId on the selection service. Only
                      // fall back to selectConversation() here if the service
                      // wasn't updated (e.g. race condition or older caller).
                      if (_conversationSelectionService.selectedConversationId !=
                          chatId) {
                        _conversationSelectionService
                            .selectConversation(chatId);
                      }
                    },
                  ),
                ),
                Expanded(
                  child: _selectedConversation == null
                      ? const _DesktopEmptyChatPane()
                      : ChatDetailsPage(
                          key: ValueKey(
                              _selectedConversation!.conversationId),
                          chatId: _selectedConversation!.conversationId,
                          receiverId: _selectedConversation!.receiverId,
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
