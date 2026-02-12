import 'package:flutter_chat_app/shared/domain/entities/chat.dart';

class PagedChatsResult {
  final List<Chat> chats;
  final int total;

  const PagedChatsResult({
    required this.chats,
    required this.total,
  });
}
