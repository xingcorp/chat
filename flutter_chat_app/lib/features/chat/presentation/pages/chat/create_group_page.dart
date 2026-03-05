import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_chat_app/core/base/base_widget.dart';
import 'package:flutter_chat_app/core/di/injection.dart';
import 'package:flutter_chat_app/core/navigation/chat_navigation_helper.dart';
import 'package:flutter_chat_app/core/services/current_user_provider.dart';
import 'package:flutter_chat_app/core/utils/logger.dart';
import 'package:flutter_chat_app/domain/repositories/user_repository.dart';
import 'package:flutter_chat_app/shared/domain/entities/chat.dart';
import 'package:flutter_chat_app/shared/domain/entities/user.dart';
import 'package:flutter_chat_app/features/auth/presentation/blocs/auth/auth_bloc.dart';
import 'package:flutter_chat_app/features/chat/presentation/blocs/chat/chat_bloc.dart';
import 'package:flutter_chat_app/l10n/l10n.dart';
import 'package:flutter_chat_app/presentation/widgets/common/hero_avatar.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/indicators/user_presence_indicator.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/lists/app_sliver_list_view.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/media/app_avatar.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/navigation/app_scaffold.dart';
import 'package:get_it/get_it.dart';
import 'package:image_picker/image_picker.dart';

/// **Create Group Page**
///
/// Allows users to create a new group conversation by:
/// 1. Entering group name
/// 2. Selecting members from contacts
/// 3. Optionally adding group avatar
class CreateGroupPage extends BaseStatefulWidget {
  const CreateGroupPage({super.key});

  @override
  State<CreateGroupPage> createState() => _CreateGroupPageState();
}

class _CreateGroupPageState extends BaseState<CreateGroupPage> {
  static const int _pageSize = 20;

  final TextEditingController _groupNameController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _contactsScrollController = ScrollController();
  final UserRepository _userRepository = GetIt.instance<UserRepository>();
  final CurrentUserProvider _currentUserProvider =
      GetIt.instance<CurrentUserProvider>();
  final AppLogger _logger = getIt<AppLogger>();
  final List<String> _selectedUserIds = [];
  final List<User> _selectedUsers = [];

  List<User> _contacts = [];
  bool _isLoading = true;
  Uint8List? _avatarBytes;
  String? _avatarFileName;
  String _searchQuery = '';
  String _activeKeyword = '';
  Timer? _debounceTimer;
  int _currentPage = 0;
  bool _hasMoreContacts = true;
  bool _isLoadingMore = false;
  final Set<String> _loggedSelfLeakIds = <String>{};

  @override
  void initState() {
    super.initState();
    unawaited(_primeCurrentUserIdentity());
    _reloadContacts('');
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _groupNameController.dispose();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _contactsScrollController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onSearchChanged() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      _reloadContacts(_searchController.text.trim());
    });
    safeSetState(() {
      _searchQuery = _searchController.text.toLowerCase();
    });
  }

  Future<void> _primeCurrentUserIdentity() async {
    try {
      await _currentUserProvider.refresh();
      final identity = _resolveCurrentUserIdentity();
      _logger.i('[CreateGroupPage] Current user identity primed', {
        'providerId': identity.providerId,
        'authId': identity.authId,
        'lookupKeyCount': identity.lookupKeys.length,
      });
    } catch (e, st) {
      _logger.w(
        '[CreateGroupPage] Failed to prime current user identity',
        error: e,
        stackTrace: st,
      );
    }
  }

  _CurrentUserIdentity _resolveCurrentUserIdentity() {
    final providerUser = _currentUserProvider.currentUser;
    final providerId = _currentUserProvider.currentUserId.trim();

    String authId = '';
    String authUsername = '';
    String authEmail = '';
    try {
      final authState = context.read<AuthBloc>().state;
      if (authState is AuthAuthenticated) {
        authId = authState.user.id.trim();
        authUsername = authState.user.username.trim();
        authEmail = authState.user.email.trim();
      }
    } catch (_) {
      // CreateGroupPage can be used in package mode where AuthBloc may differ.
    }

    final lookupKeys = <String>{
      providerId.toLowerCase(),
      (providerUser?.username ?? '').trim().toLowerCase(),
      (providerUser?.email ?? '').trim().toLowerCase(),
      authId.toLowerCase(),
      authUsername.toLowerCase(),
      authEmail.toLowerCase(),
    }..removeWhere((value) => value.isEmpty);

    return _CurrentUserIdentity(
      providerId: providerId,
      authId: authId,
      lookupKeys: lookupKeys,
    );
  }

  bool _isCurrentUser(User user, _CurrentUserIdentity identity) {
    final userKeys = <String>{
      user.id.trim().toLowerCase(),
      user.username.trim().toLowerCase(),
      user.email.trim().toLowerCase(),
    }..removeWhere((value) => value.isEmpty);

    return userKeys.any(identity.lookupKeys.contains);
  }

  Map<String, String> _debugUser(User user) {
    return <String, String>{
      'id': user.id,
      'username': user.username,
      'email': user.email,
      'fullName': user.fullName ?? '',
    };
  }

  Future<void> _reloadContacts(String keyword) async {
    _activeKeyword = keyword;
    _currentPage = 0;
    _hasMoreContacts = true;
    _loggedSelfLeakIds.clear();
    await _loadContacts(keyword: keyword, isLoadMore: false);
  }

  Future<void> _loadMoreContacts() async {
    if (_isLoading || _isLoadingMore || !_hasMoreContacts) return;
    _logger.i('[CreateGroupPage] Load more contacts', {
      'nextPage': _currentPage + 1,
      'keyword': _activeKeyword,
      'currentCount': _contacts.length,
      'hasMore': _hasMoreContacts,
    });
    await _loadContacts(keyword: _activeKeyword, isLoadMore: true);
  }

  Future<void> _loadContacts({
    required String keyword,
    required bool isLoadMore,
  }) async {
    final targetPage = isLoadMore ? _currentPage + 1 : 0;
    safeSetState(() {
      if (isLoadMore) {
        _isLoadingMore = true;
      } else {
        _isLoading = true;
      }
    });

    final result = await _userRepository.searchUsers(
      keyword,
      limit: _pageSize,
      page: targetPage,
    );
    final identity = _resolveCurrentUserIdentity();

    result.fold(
      (failure) => safeSetState(() {
        _logger.w('[CreateGroupPage] searchUsers failed', context: {
          'keyword': keyword,
          'page': targetPage,
          'isLoadMore': isLoadMore,
          'error': failure.message,
        });
        _isLoading = false;
        _isLoadingMore = false;
      }),
      (users) => safeSetState(() {
        _logger.i('[CreateGroupPage] searchUsers result', {
          'keyword': keyword,
          'page': targetPage,
          'isLoadMore': isLoadMore,
          'rawCount': users.length,
          'providerId': identity.providerId,
          'authId': identity.authId,
          'lookupKeyCount': identity.lookupKeys.length,
        });

        final filteredUsers = <User>[];
        final removedSelfUsers = <Map<String, String>>[];
        for (final user in users) {
          if (_isCurrentUser(user, identity)) {
            removedSelfUsers.add(_debugUser(user));
            continue;
          }
          filteredUsers.add(user);
        }

        if (removedSelfUsers.isNotEmpty) {
          _logger.w('[CreateGroupPage] Removed current user from contacts',
              context: {
                'removedCount': removedSelfUsers.length,
                'samples': removedSelfUsers.take(3).toList(),
              });
        }

        final mergedContacts =
            isLoadMore ? List<User>.from(_contacts) : <User>[];
        final existingIds = mergedContacts.map((u) => u.id).toSet();
        var uniqueAddedCount = 0;
        for (final user in filteredUsers) {
          if (existingIds.add(user.id)) {
            mergedContacts.add(user);
            uniqueAddedCount++;
          }
        }

        final hasServerMore = users.length >= _pageSize;
        _hasMoreContacts = hasServerMore;
        if (isLoadMore && hasServerMore && uniqueAddedCount == 0) {
          _hasMoreContacts = false;
          _logger.w(
            '[CreateGroupPage] Stop pagination because page has no unique users',
            context: {
              'keyword': keyword,
              'page': targetPage,
              'rawCount': users.length,
              'filteredCount': filteredUsers.length,
            },
          );
        }

        _currentPage = targetPage;
        _activeKeyword = keyword;
        _isLoading = false;
        _isLoadingMore = false;
        _contacts = mergedContacts;

        _logger.i('[CreateGroupPage] contacts merged', {
          'page': _currentPage,
          'totalContacts': _contacts.length,
          'added': uniqueAddedCount,
          'hasMore': _hasMoreContacts,
        });
      }),
    );
  }

  void _toggleUser(User user) {
    safeSetState(() {
      if (_selectedUserIds.contains(user.id)) {
        _selectedUserIds.remove(user.id);
        _selectedUsers.removeWhere((u) => u.id == user.id);
      } else {
        _selectedUserIds.add(user.id);
        _selectedUsers.add(user);
      }
    });
  }

  Future<void> _pickAvatar() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );
    if (picked != null) {
      final bytes = await picked.readAsBytes();
      if (bytes.isEmpty) return;

      safeSetState(() {
        _avatarBytes = bytes;
        _avatarFileName = picked.name.isNotEmpty
            ? picked.name
            : 'group_avatar_${DateTime.now().millisecondsSinceEpoch}.jpg';
      });
    }
  }

  void _createGroup(BuildContext context) {
    final groupName = _groupNameController.text.trim();

    if (groupName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.pleaseEnterGroupName),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_selectedUserIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.pleaseSelectMembers),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    context.read<ChatBloc>().add(
          ChatEvent.createChat(
            type: ChatType.group,
            name: groupName,
            participantIds: _selectedUserIds,
            avatarBytes: _avatarBytes,
            avatarFileName: _avatarFileName,
          ),
        );
  }

  List<User> get _filteredContacts {
    final identity = _resolveCurrentUserIdentity();
    final contacts =
        _contacts.where((u) => !_isCurrentUser(u, identity)).toList();

    for (final user in _contacts) {
      if (!_isCurrentUser(user, identity)) continue;
      if (_loggedSelfLeakIds.add(user.id)) {
        _logger
            .w('[CreateGroupPage] Self user leaked into _contacts', context: {
          'user': _debugUser(user),
          'providerId': identity.providerId,
          'authId': identity.authId,
        });
      }
    }

    if (_searchQuery.isEmpty) return contacts;
    return contacts
        .where(
          (u) =>
              (u.fullName ?? u.username).toLowerCase().contains(_searchQuery),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<ChatBloc>(),
      child: BlocConsumer<ChatBloc, ChatState>(
        listener: (context, state) {
          state.maybeWhen(
            chatDetailsLoaded: (chat) {
              ChatNavigationHelper.replaceToChatDetail(context,
                  chatId: chat.id);
            },
            error: (message) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(message),
                  backgroundColor: Colors.red,
                ),
              );
            },
            orElse: () {},
          );
        },
        builder: (context, state) {
          final isCreating = state.maybeWhen(
            loading: () => true,
            orElse: () => false,
          );
          final filteredContacts = _filteredContacts;

          return AppScaffold(
            dismissKeyboardOnTap: true,
            appBar: AppBar(
              title: Text(context.l10n.createNewGroup),
              actions: [
                TextButton(
                  onPressed: isCreating || _selectedUserIds.isEmpty
                      ? null
                      : () => _createGroup(context),
                  child: isCreating
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          context.l10n.create,
                          style: TextStyle(
                            color: _selectedUserIds.isEmpty
                                ? Colors.grey
                                : Theme.of(context).primaryColor,
                          ),
                        ),
                ),
              ],
            ),
            body: CustomScrollView(
              controller: _contactsScrollController,
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        // Group avatar picker
                        GestureDetector(
                          onTap: isCreating ? null : _pickAvatar,
                          child: Stack(
                            alignment: Alignment.bottomRight,
                            children: [
                              _avatarBytes != null
                                  ? CircleAvatar(
                                      radius: 40,
                                      backgroundImage:
                                          MemoryImage(_avatarBytes!),
                                    )
                                  : AppAvatar.initials(
                                      name: _groupNameController.text.isNotEmpty
                                          ? _groupNameController.text
                                          : context.l10n.groupName,
                                      size: AvatarSize.large,
                                      backgroundColor:
                                          Theme.of(context).primaryColor,
                                      foregroundColor: Colors.white,
                                    ),
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color:
                                      Theme.of(context).colorScheme.secondary,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.camera_alt,
                                  size: 16,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _groupNameController,
                          enabled: !isCreating,
                          onChanged: (_) => safeSetState(() {}),
                          decoration: InputDecoration(
                            labelText: context.l10n.groupName,
                            border: const OutlineInputBorder(),
                            prefixIcon: const Icon(Icons.group),
                          ),
                          textInputAction: TextInputAction.next,
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _searchController,
                          enabled: !isCreating,
                          decoration: InputDecoration(
                            labelText: context.l10n.search,
                            border: const OutlineInputBorder(),
                            prefixIcon: const Icon(Icons.search),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear),
                                    onPressed: () => _searchController.clear(),
                                  )
                                : null,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (_selectedUsers.isNotEmpty)
                  SliverToBoxAdapter(
                    child: Container(
                      height: 90,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        border: Border(
                          top:
                              BorderSide(color: Theme.of(context).dividerColor),
                          bottom:
                              BorderSide(color: Theme.of(context).dividerColor),
                        ),
                      ),
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _selectedUsers.length,
                        itemBuilder: (context, index) {
                          final user = _selectedUsers[index];
                          return Padding(
                            padding: const EdgeInsets.only(right: 16),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Stack(
                                  alignment: Alignment.topRight,
                                  children: [
                                    AppHeroAvatar(
                                      id: user.id,
                                      imageUrl: user.avatar,
                                      displayName:
                                          user.fullName ?? user.username,
                                      size: AvatarSize.medium,
                                      hasBorder: false,
                                    ),
                                    GestureDetector(
                                      onTap: () => _toggleUser(user),
                                      child: Container(
                                        padding: const EdgeInsets.all(2),
                                        decoration: const BoxDecoration(
                                          color: Colors.red,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(Icons.close,
                                            size: 14, color: Colors.white),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                SizedBox(
                                  width: 60,
                                  child: Text(
                                    user.fullName ?? user.username,
                                    style: const TextStyle(fontSize: 12),
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                AppSliverListView<User>(
                  items: filteredContacts,
                  controller: _contactsScrollController,
                  isLoading: _isLoading,
                  isLoadingMore: _isLoadingMore,
                  hasMore: _hasMoreContacts,
                  onLoadMore: _loadMoreContacts,
                  emptyWidget: Center(
                    child: Text(
                      context.l10n.noSearchResults,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ),
                  itemBuilder: (context, user, index) {
                    final isSelected = _selectedUserIds.contains(user.id);

                    return ListTile(
                      enabled: !isCreating,
                      leading: UserPresenceBadge(
                        isConnected: user.isOnline,
                        lastSeenAt: user.lastSeen,
                        indicatorSize: 12.0,
                        child: AppHeroAvatar(
                          id: user.id,
                          imageUrl: user.avatar,
                          displayName: user.fullName ?? user.username,
                          size: AvatarSize.medium,
                          hasBorder: false,
                        ),
                      ),
                      title: Text(user.fullName ?? user.username),
                      trailing: isSelected
                          ? const Icon(Icons.check_circle, color: Colors.green)
                          : const Icon(Icons.check_circle_outline,
                              color: Colors.grey),
                      onTap: () => _toggleUser(user),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _CurrentUserIdentity {
  final String providerId;
  final String authId;
  final Set<String> lookupKeys;

  const _CurrentUserIdentity({
    required this.providerId,
    required this.authId,
    required this.lookupKeys,
  });
}
