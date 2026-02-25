import 'package:equatable/equatable.dart';

/// Base event for ChatMembers BLoC
abstract class ChatMembersEvent extends Equatable {
  const ChatMembersEvent();

  @override
  List<Object?> get props => [];
}

/// Load members for a chat
class ChatMembersLoad extends ChatMembersEvent {
  final String chatId;

  const ChatMembersLoad({required this.chatId});

  @override
  List<Object?> get props => [chatId];
}

/// Search members by keyword
class ChatMembersSearch extends ChatMembersEvent {
  final String keyword;

  const ChatMembersSearch({required this.keyword});

  @override
  List<Object?> get props => [keyword];
}

/// Clear search and show all members
class ChatMembersClearSearch extends ChatMembersEvent {
  const ChatMembersClearSearch();
}

/// Sort members by different criteria
class ChatMembersSort extends ChatMembersEvent {
  final MembersSortType sortType;

  const ChatMembersSort({required this.sortType});

  @override
  List<Object?> get props => [sortType];
}

/// Remove member from group (admin only)
class ChatMembersRemove extends ChatMembersEvent {
  final String chatId;
  final String memberId;

  const ChatMembersRemove({
    required this.chatId,
    required this.memberId,
  });

  @override
  List<Object?> get props => [chatId, memberId];
}

/// Make member admin
class ChatMembersMakeAdmin extends ChatMembersEvent {
  final String chatId;
  final String memberId;

  const ChatMembersMakeAdmin({
    required this.chatId,
    required this.memberId,
  });

  @override
  List<Object?> get props => [chatId, memberId];
}

/// Remove admin role
class ChatMembersRemoveAdmin extends ChatMembersEvent {
  final String chatId;
  final String memberId;

  const ChatMembersRemoveAdmin({
    required this.chatId,
    required this.memberId,
  });

  @override
  List<Object?> get props => [chatId, memberId];
}

/// Leave group
class ChatMembersLeaveGroup extends ChatMembersEvent {
  final String chatId;

  const ChatMembersLeaveGroup({required this.chatId});

  @override
  List<Object?> get props => [chatId];
}

/// Enum for sort type
enum MembersSortType {
  /// Admins first, then alphabetically
  adminFirst,
  
  /// Alphabetically by name
  alphabetical,
  
  /// Reverse alphabetical
  reverseAlphabetical,
  
  /// By join date (newest first)
  newestFirst,
  
  /// By join date (oldest first)
  oldestFirst,
}
