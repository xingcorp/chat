import 'package:equatable/equatable.dart';

/// Base event for ConversationDetail BLoC
abstract class ConversationDetailEvent extends Equatable {
  const ConversationDetailEvent();

  @override
  List<Object?> get props => [];
}

/// Load conversation detail (members, name, avatar, type...)
///
/// Set [forceRemote] to bypass local cache (e.g. after membership changes).
class LoadConversationDetail extends ConversationDetailEvent {
  final String chatId;
  final bool forceRemote;

  const LoadConversationDetail({
    required this.chatId,
    this.forceRemote = false,
  });

  @override
  List<Object?> get props => [chatId, forceRemote];
}

/// Add members to group conversation
class AddMembersToGroup extends ConversationDetailEvent {
  final String chatId;
  final List<String> userIds;

  const AddMembersToGroup({
    required this.chatId,
    required this.userIds,
  });

  @override
  List<Object?> get props => [chatId, userIds];
}
