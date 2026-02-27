import 'package:equatable/equatable.dart';

/// Base event for ConversationDetail BLoC
abstract class ConversationDetailEvent extends Equatable {
  const ConversationDetailEvent();

  @override
  List<Object?> get props => [];
}

/// Load conversation detail (members, name, avatar, type...)
class LoadConversationDetail extends ConversationDetailEvent {
  final String chatId;

  const LoadConversationDetail({required this.chatId});

  @override
  List<Object?> get props => [chatId];
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
