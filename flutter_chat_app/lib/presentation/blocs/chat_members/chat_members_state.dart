import 'package:flutter_chat_app/shared/domain/entities/chat.dart';
import 'package:flutter_chat_app/presentation/blocs/chat_members/chat_members_event.dart';
import 'package:flutter_chat_app/presentation/blocs/base/base_state.dart';

/// Base state for ChatMembers BLoC
abstract class ChatMembersState extends BaseState {
  const ChatMembersState();
}

/// Initial state
class ChatMembersInitial extends ChatMembersState {
  const ChatMembersInitial();

  @override
  List<Object?> get props => [];
}

/// Loading state
class ChatMembersLoading extends ChatMembersState {
  final String? message;

  const ChatMembersLoading({this.message});

  @override
  List<Object?> get props => [message];
}

/// Members loaded successfully
class ChatMembersLoaded extends ChatMembersState {
  final List<ConversationMember> members;
  final List<ConversationMember> filteredMembers;
  final String? searchKeyword;
  final MembersSortType sortType;
  final String? creatorName;
  final DateTime? createdAt;

  const ChatMembersLoaded({
    required this.members,
    required this.filteredMembers,
    this.searchKeyword,
    this.sortType = MembersSortType.adminFirst,
    this.creatorName,
    this.createdAt,
  });

  /// Check if search is active
  bool get isSearching => searchKeyword != null && searchKeyword!.isNotEmpty;

  /// Get member count
  int get memberCount => members.length;

  /// Get filtered member count
  int get filteredCount => filteredMembers.length;

  /// Check if current user is admin
  bool isCurrentUserAdmin(String? currentUserId) {
    if (currentUserId == null) return false;
    return members.any((m) => m.userId == currentUserId && m.isAdmin);
  }

  ChatMembersLoaded copyWith({
    List<ConversationMember>? members,
    List<ConversationMember>? filteredMembers,
    String? searchKeyword,
    MembersSortType? sortType,
    String? creatorName,
    DateTime? createdAt,
    bool clearSearch = false,
  }) {
    return ChatMembersLoaded(
      members: members ?? this.members,
      filteredMembers: filteredMembers ?? this.filteredMembers,
      searchKeyword: clearSearch ? null : (searchKeyword ?? this.searchKeyword),
      sortType: sortType ?? this.sortType,
      creatorName: creatorName ?? this.creatorName,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        members,
        filteredMembers,
        searchKeyword,
        sortType,
        creatorName,
        createdAt,
      ];
}

/// Error state
class ChatMembersError extends ChatMembersState {
  final String message;
  final Exception? error;

  const ChatMembersError({
    required this.message,
    this.error,
  });

  @override
  List<Object?> get props => [message, error];
}

/// Member removed successfully
class ChatMembersMemberRemoved extends ChatMembersState {
  final String memberId;
  final List<ConversationMember> remainingMembers;

  const ChatMembersMemberRemoved({
    required this.memberId,
    required this.remainingMembers,
  });

  @override
  List<Object?> get props => [memberId, remainingMembers];
}

/// Left group successfully
class ChatMembersLeftGroup extends ChatMembersState {
  const ChatMembersLeftGroup();
}

/// Admin role updated
class ChatMembersAdminUpdated extends ChatMembersState {
  final String memberId;
  final bool isAdmin;
  final List<ConversationMember> members;

  const ChatMembersAdminUpdated({
    required this.memberId,
    required this.isAdmin,
    required this.members,
  });

  @override
  List<Object?> get props => [memberId, isAdmin, members];
}
