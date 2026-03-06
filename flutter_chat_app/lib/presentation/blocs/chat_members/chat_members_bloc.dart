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
        final sortedMembers =
            _sortMembers(_allMembers, MembersSortType.adminFirst);
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

    final sortedMembers =
        _sortMembers(currentState.filteredMembers, event.sortType);
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
    final previousLoadedState =
        state is ChatMembersLoaded ? state as ChatMembersLoaded : null;

    emit(const ChatMembersLoading(message: 'Removing member...'));

    _logger.d(
        'Removing member: chatId=${event.chatId}, memberId=${event.memberId}');

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
        _allMembers =
            _allMembers.where((m) => m.userId != event.memberId).toList();
        final nextState = _buildLoadedState(previousLoadedState);
        // Emit removed state first so listener can show SnackBar
        emit(ChatMembersMemberRemoved(
          memberId: event.memberId,
          remainingMembers: nextState.filteredMembers,
        ));
        emit(nextState);
      },
    );
  }

  /// Handler: Make admin
  Future<void> _onMakeAdmin(
    ChatMembersMakeAdmin event,
    Emitter<ChatMembersState> emit,
  ) async {
    final previousLoadedState =
        state is ChatMembersLoaded ? state as ChatMembersLoaded : null;
    emit(const ChatMembersLoading(message: 'Making admin...'));

    _logger
        .d('Making admin: chatId=${event.chatId}, memberId=${event.memberId}');

    // Build new admin list: current admins + new admin
    final currentAdminIds =
        _allMembers.where((m) => m.isAdmin).map((m) => m.userId).toList();

    if (!currentAdminIds.contains(event.memberId)) {
      currentAdminIds.add(event.memberId);
    }

    final result = await _chatRepository.updateAdmins(
      chatId: event.chatId,
      adminIds: currentAdminIds,
    );

    result.fold(
      (failure) {
        _logger.e('Failed to make admin: ${failure.message}');
        emit(ChatMembersError(message: failure.message));
      },
      (_) {
        _allMembers = _allMembers
            .map((member) => member.userId == event.memberId
                ? _copyMemberWithAdmin(member, isAdmin: true)
                : member)
            .toList();
        final nextState = _buildLoadedState(previousLoadedState);
        emit(ChatMembersAdminUpdated(
          memberId: event.memberId,
          isAdmin: true,
          members: nextState.filteredMembers,
        ));
        emit(nextState);
      },
    );
  }

  /// Handler: Remove admin
  Future<void> _onRemoveAdmin(
    ChatMembersRemoveAdmin event,
    Emitter<ChatMembersState> emit,
  ) async {
    final previousLoadedState =
        state is ChatMembersLoaded ? state as ChatMembersLoaded : null;
    emit(const ChatMembersLoading(message: 'Removing admin...'));

    _logger.d(
        'Removing admin: chatId=${event.chatId}, memberId=${event.memberId}');

    // Build new admin list: current admins minus the target
    final currentAdminIds = _allMembers
        .where((m) => m.isAdmin && m.userId != event.memberId)
        .map((m) => m.userId)
        .toList();

    final result = await _chatRepository.updateAdmins(
      chatId: event.chatId,
      adminIds: currentAdminIds,
    );

    result.fold(
      (failure) {
        _logger.e('Failed to remove admin: ${failure.message}');
        emit(ChatMembersError(message: failure.message));
      },
      (_) {
        _allMembers = _allMembers
            .map((member) => member.userId == event.memberId
                ? _copyMemberWithAdmin(member, isAdmin: false)
                : member)
            .toList();
        final nextState = _buildLoadedState(previousLoadedState);
        emit(ChatMembersAdminUpdated(
          memberId: event.memberId,
          isAdmin: false,
          members: nextState.filteredMembers,
        ));
        emit(nextState);
      },
    );
  }

  /// Handler: Leave group
  Future<void> _onLeaveGroup(
    ChatMembersLeaveGroup event,
    Emitter<ChatMembersState> emit,
  ) async {
    emit(const ChatMembersLoading(message: 'Leaving group...'));

    _logger.d('Leaving group: chatId=${event.chatId}');

    final result = await _chatRepository.leaveChat(event.chatId);

    result.fold(
      (failure) {
        _logger.e('Failed to leave group: ${failure.message}');
        emit(ChatMembersError(message: failure.message));
      },
      (_) {
        _logger.i('Left group successfully: chatId=${event.chatId}');
        emit(const ChatMembersLeftGroup());
      },
    );
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
        sortedList
            .sort((a, b) => (a.fullName ?? '').compareTo(b.fullName ?? ''));
        break;

      case MembersSortType.reverseAlphabetical:
        sortedList
            .sort((a, b) => (b.fullName ?? '').compareTo(a.fullName ?? ''));
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

  ChatMembersLoaded _buildLoadedState(ChatMembersLoaded? previousState) {
    final sortType = previousState?.sortType ?? MembersSortType.adminFirst;
    final searchKeyword = previousState?.searchKeyword?.trim().toLowerCase();

    List<ConversationMember> filteredMembers = List<ConversationMember>.from(
      _allMembers,
    );

    if (searchKeyword != null && searchKeyword.isNotEmpty) {
      filteredMembers = filteredMembers.where((member) {
        final name = member.fullName?.toLowerCase() ?? '';
        final department = member.departmentName?.toLowerCase() ?? '';
        final title = member.titleName?.toLowerCase() ?? '';
        final code = member.code?.toLowerCase() ?? '';
        return name.contains(searchKeyword) ||
            department.contains(searchKeyword) ||
            title.contains(searchKeyword) ||
            code.contains(searchKeyword);
      }).toList();
    }

    return ChatMembersLoaded(
      members: _allMembers,
      filteredMembers: _sortMembers(filteredMembers, sortType),
      searchKeyword: searchKeyword,
      sortType: sortType,
      creatorName: _currentChat?.creatorName ?? previousState?.creatorName,
      createdAt: _currentChat?.createdAt ?? previousState?.createdAt,
    );
  }

  ConversationMember _copyMemberWithAdmin(
    ConversationMember member, {
    required bool isAdmin,
  }) {
    return ConversationMember(
      id: member.id,
      userId: member.userId,
      fullName: member.fullName,
      avatarUrl: member.avatarUrl,
      departmentName: member.departmentName,
      titleName: member.titleName,
      code: member.code,
      isAdmin: isAdmin,
      isConnected: member.isConnected,
      isHidden: member.isHidden,
      unreadCount: member.unreadCount,
      lastMessageReadId: member.lastMessageReadId,
      viewMessagesFrom: member.viewMessagesFrom,
    );
  }
}
