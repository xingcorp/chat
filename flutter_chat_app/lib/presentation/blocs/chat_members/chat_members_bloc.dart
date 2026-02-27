import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:flutter_chat_app/core/utils/logger.dart';
import 'package:flutter_chat_app/presentation/blocs/base/base_bloc.dart';
import 'package:flutter_chat_app/presentation/blocs/chat_members/chat_members_event.dart';
import 'package:flutter_chat_app/presentation/blocs/chat_members/chat_members_state.dart';
import 'package:flutter_chat_app/shared/domain/entities/chat.dart';
import 'package:flutter_chat_app/features/chat/domain/repositories/i_chat_repository.dart';

/// BLoC cho ChatMembers operations
/// TUÂN THỦ: PHẢI extend BaseBloc, KHÔNG extend Bloc trực tiếp
@injectable
class ChatMembersBloc extends BaseBloc<ChatMembersEvent, ChatMembersState> {
  final AppLogger _logger;
  final IChatRepository _chatRepository;
  Chat? _currentChat;
  List<ConversationMember> _allMembers = [];

  ChatMembersBloc({
    required AppLogger logger,
    required IChatRepository chatRepository,
  })  : _logger = logger,
        _chatRepository = chatRepository,
        super(const ChatMembersInitial()) {
    // Register event handlers
    on<ChatMembersLoad>(_onLoadMembers);
    on<ChatMembersSearch>(_onSearchMembers);
    on<ChatMembersClearSearch>(_onClearSearch);
    on<ChatMembersSort>(_onSortMembers);
    on<ChatMembersRemove>(_onRemoveMember);
    on<ChatMembersMakeAdmin>(_onMakeAdmin);
    on<ChatMembersRemoveAdmin>(_onRemoveAdmin);
    on<ChatMembersLeaveGroup>(_onLeaveGroup);
  }

  /// Initialize with chat data (call this before navigating to the page)
  void init(Chat chat) {
    _currentChat = chat;
    _allMembers = List.from(chat.members);
  }

  /// Get current chat
  Chat? get currentChat => _currentChat;

  /// Handler: Load members from API
  Future<void> _onLoadMembers(
    ChatMembersLoad event,
    Emitter<ChatMembersState> emit,
  ) async {
    emit(const ChatMembersLoading(message: 'Loading members...'));

    _logger.d('Loading members: chatId=${event.chatId}');

    // Fetch members from API
    final result = await _chatRepository.getConversationMembers(event.chatId);

    result.fold(
      (failure) {
        _logger.e('Failed to load members: ${failure.message}');
        emit(ChatMembersError(message: failure.message));
      },
      (chat) {
        _currentChat = chat;
        _allMembers = List.from(chat.members);
        final sortedMembers = _sortMembers(_allMembers, MembersSortType.adminFirst);
        emit(ChatMembersLoaded(
          members: _allMembers,
          filteredMembers: sortedMembers,
          sortType: MembersSortType.adminFirst,
          creatorName: chat.creatorName,
          createdAt: chat.createdAt,
        ));
      },
    );
  }

  /// Handler: Search members
  void _onSearchMembers(
    ChatMembersSearch event,
    Emitter<ChatMembersState> emit,
  ) {
    final currentState = state;
    if (currentState is! ChatMembersLoaded) return;

    _logger.d('Searching members: keyword=${event.keyword}');

    final keyword = event.keyword.toLowerCase().trim();
    
    if (keyword.isEmpty) {
      // Clear search
      final sortedMembers = _sortMembers(_allMembers, currentState.sortType);
      emit(currentState.copyWith(
        filteredMembers: sortedMembers,
        clearSearch: true,
      ));
      return;
    }

    // Filter members
    final filteredMembers = _allMembers.where((member) {
      final name = member.fullName?.toLowerCase() ?? '';
      final department = member.departmentName?.toLowerCase() ?? '';
      final title = member.titleName?.toLowerCase() ?? '';
      final code = member.code?.toLowerCase() ?? '';
      return name.contains(keyword) ||
          department.contains(keyword) ||
          title.contains(keyword) ||
          code.contains(keyword);
    }).toList();

    // Sort filtered results
    final sortedMembers = _sortMembers(filteredMembers, currentState.sortType);

    emit(currentState.copyWith(
      filteredMembers: sortedMembers,
      searchKeyword: keyword,
    ));
  }

  /// Handler: Clear search
  void _onClearSearch(
    ChatMembersClearSearch event,
    Emitter<ChatMembersState> emit,
  ) {
    final currentState = state;
    if (currentState is! ChatMembersLoaded) return;

    final sortedMembers = _sortMembers(_allMembers, currentState.sortType);
    emit(currentState.copyWith(
      filteredMembers: sortedMembers,
      clearSearch: true,
    ));
  }

  /// Handler: Sort members
  void _onSortMembers(
    ChatMembersSort event,
    Emitter<ChatMembersState> emit,
  ) {
    final currentState = state;
    if (currentState is! ChatMembersLoaded) return;

    _logger.d('Sorting members: type=${event.sortType}');

    final sortedMembers = _sortMembers(currentState.filteredMembers, event.sortType);
    emit(currentState.copyWith(
      filteredMembers: sortedMembers,
      sortType: event.sortType,
    ));
  }

  /// Handler: Remove member
  Future<void> _onRemoveMember(
    ChatMembersRemove event,
    Emitter<ChatMembersState> emit,
  ) async {
    final currentState = state;
    MembersSortType sortType = MembersSortType.adminFirst;
    if (currentState is ChatMembersLoaded) {
      sortType = currentState.sortType;
    }

    emit(const ChatMembersLoading(message: 'Removing member...'));

    _logger.d('Removing member: chatId=${event.chatId}, memberId=${event.memberId}');

    final result = await _chatRepository.removeParticipants(
      chatId: event.chatId,
      userIds: [event.memberId],
    );

    result.fold(
      (failure) {
        _logger.e('Failed to remove member: ${failure.message}');
        emit(ChatMembersError(message: failure.message));
      },
      (_) {
        _allMembers = _allMembers.where((m) => m.userId != event.memberId).toList();
        final sortedMembers = _sortMembers(_allMembers, sortType);
        // Emit removed state first so listener can show SnackBar
        emit(ChatMembersMemberRemoved(
          memberId: event.memberId,
          remainingMembers: sortedMembers,
        ));
        // Then emit loaded state so UI rebuilds with updated members list
        emit(ChatMembersLoaded(
          members: _allMembers,
          filteredMembers: sortedMembers,
          sortType: sortType,
          creatorName: _currentChat?.creatorName,
          createdAt: _currentChat?.createdAt,
        ));
      },
    );
  }

  /// Handler: Make admin
  Future<void> _onMakeAdmin(
    ChatMembersMakeAdmin event,
    Emitter<ChatMembersState> emit,
  ) async {
    emit(const ChatMembersLoading(message: 'Making admin...'));

    _logger.d('Making admin: memberId=${event.memberId}');

    // TODO: Call repository to make admin
    // For now, just update local state
    _allMembers = _allMembers.map((m) {
      if (m.userId == event.memberId) {
        return ConversationMember(
          id: m.id,
          userId: m.userId,
          fullName: m.fullName,
          avatarUrl: m.avatarUrl,
          departmentName: m.departmentName,
          titleName: m.titleName,
          code: m.code,
          isAdmin: true,
          isConnected: m.isConnected,
          isHidden: m.isHidden,
          unreadCount: m.unreadCount,
          lastMessageReadId: m.lastMessageReadId,
          viewMessagesFrom: m.viewMessagesFrom,
        );
      }
      return m;
    }).toList();

    final currentState = state;
    MembersSortType sortType = MembersSortType.adminFirst;
    if (currentState is ChatMembersLoaded) {
      sortType = currentState.sortType;
    }

    final sortedMembers = _sortMembers(_allMembers, sortType);
    emit(ChatMembersAdminUpdated(
      memberId: event.memberId,
      isAdmin: true,
      members: sortedMembers,
    ));
  }

  /// Handler: Remove admin
  Future<void> _onRemoveAdmin(
    ChatMembersRemoveAdmin event,
    Emitter<ChatMembersState> emit,
  ) async {
    emit(const ChatMembersLoading(message: 'Removing admin...'));

    _logger.d('Removing admin: memberId=${event.memberId}');

    // TODO: Call repository to remove admin
    // For now, just update local state
    _allMembers = _allMembers.map((m) {
      if (m.userId == event.memberId) {
        return ConversationMember(
          id: m.id,
          userId: m.userId,
          fullName: m.fullName,
          avatarUrl: m.avatarUrl,
          departmentName: m.departmentName,
          titleName: m.titleName,
          code: m.code,
          isAdmin: false,
          isConnected: m.isConnected,
          isHidden: m.isHidden,
          unreadCount: m.unreadCount,
          lastMessageReadId: m.lastMessageReadId,
          viewMessagesFrom: m.viewMessagesFrom,
        );
      }
      return m;
    }).toList();

    final currentState = state;
    MembersSortType sortType = MembersSortType.adminFirst;
    if (currentState is ChatMembersLoaded) {
      sortType = currentState.sortType;
    }

    final sortedMembers = _sortMembers(_allMembers, sortType);
    emit(ChatMembersAdminUpdated(
      memberId: event.memberId,
      isAdmin: false,
      members: sortedMembers,
    ));
  }

  /// Handler: Leave group
  Future<void> _onLeaveGroup(
    ChatMembersLeaveGroup event,
    Emitter<ChatMembersState> emit,
  ) async {
    emit(const ChatMembersLoading(message: 'Leaving group...'));

    _logger.d('Leaving group: chatId=${event.chatId}');

    // TODO: Call repository to leave group
    emit(const ChatMembersLeftGroup());
  }

  /// Helper: Sort members by sort type
  List<ConversationMember> _sortMembers(
    List<ConversationMember> members,
    MembersSortType sortType,
  ) {
    final sortedList = List<ConversationMember>.from(members);

    switch (sortType) {
      case MembersSortType.adminFirst:
        sortedList.sort((a, b) {
          if (a.isAdmin != b.isAdmin) {
            return a.isAdmin ? -1 : 1;
          }
          return (a.fullName ?? '').compareTo(b.fullName ?? '');
        });
        break;

      case MembersSortType.alphabetical:
        sortedList.sort((a, b) =>
            (a.fullName ?? '').compareTo(b.fullName ?? ''));
        break;

      case MembersSortType.reverseAlphabetical:
        sortedList.sort((a, b) =>
            (b.fullName ?? '').compareTo(a.fullName ?? ''));
        break;

      case MembersSortType.newestFirst:
        sortedList.sort((a, b) {
          final aTime = a.viewMessagesFrom;
          final bTime = b.viewMessagesFrom;
          if (aTime == null && bTime == null) return 0;
          if (aTime == null) return 1;
          if (bTime == null) return -1;
          return bTime.compareTo(aTime);
        });
        break;

      case MembersSortType.oldestFirst:
        sortedList.sort((a, b) {
          final aTime = a.viewMessagesFrom;
          final bTime = b.viewMessagesFrom;
          if (aTime == null && bTime == null) return 0;
          if (aTime == null) return 1;
          if (bTime == null) return -1;
          return aTime.compareTo(bTime);
        });
        break;
    }

    return sortedList;
  }
}
