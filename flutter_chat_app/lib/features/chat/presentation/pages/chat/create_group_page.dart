import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_chat_app/core/base/base_widget.dart';
import 'package:flutter_chat_app/core/di/injection.dart';
import 'package:flutter_chat_app/core/navigation/chat_navigation_helper.dart';
import 'package:flutter_chat_app/domain/repositories/user_repository.dart';
import 'package:flutter_chat_app/shared/domain/entities/chat.dart';
import 'package:flutter_chat_app/shared/domain/entities/user.dart';
import 'package:flutter_chat_app/l10n/l10n.dart';
import 'package:flutter_chat_app/features/chat/presentation/blocs/chat/chat_bloc.dart';
import 'package:flutter_chat_app/presentation/widgets/common/hero_avatar.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/indicators/user_presence_indicator.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/media/app_avatar.dart';
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
  final TextEditingController _groupNameController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final UserRepository _userRepository = GetIt.instance<UserRepository>();
  final List<String> _selectedUserIds = [];
  final List<User> _selectedUsers = [];

  List<User> _contacts = [];
  bool _isLoading = true;
  File? _avatarFile;
  String _searchQuery = '';
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _loadContacts('');
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _groupNameController.dispose();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onSearchChanged() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      _loadContacts(_searchController.text.trim());
    });
    safeSetState(() {
      _searchQuery = _searchController.text.toLowerCase();
    });
  }

  Future<void> _loadContacts(String keyword) async {
    safeSetState(() => _isLoading = true);

    final result = await _userRepository.searchUsers(keyword);

    result.fold(
      (failure) => safeSetState(() => _isLoading = false),
      (users) => safeSetState(() {
        _isLoading = false;
        _contacts = users;
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
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 85,
    );
    if (picked != null) {
      safeSetState(() => _avatarFile = File(picked.path));
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
          ),
        );
  }

  List<User> get _filteredContacts {
    if (_searchQuery.isEmpty) return _contacts;
    return _contacts
        .where((u) => (u.fullName ?? u.username).toLowerCase().contains(_searchQuery))
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
              ChatNavigationHelper.replaceToChatDetail(
                context,
                chatId: chat.id,
              );
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

          return Scaffold(
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
            body: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      // Group avatar picker
                      GestureDetector(
                        onTap: _pickAvatar,
                        child: Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            _avatarFile != null
                                ? CircleAvatar(
                                    radius: 40,
                                    backgroundImage:
                                        FileImage(_avatarFile!),
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

                      // Group name field
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

                      // Search contacts
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

                // Selected members chip row
                if (_selectedUsers.isNotEmpty)
                  Container(
                    height: 90,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      border: Border(
                        top: BorderSide(color: Theme.of(context).dividerColor),
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
                                    displayName: user.fullName ?? user.username,
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

                // Contacts list
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _filteredContacts.isEmpty
                          ? Center(
                              child: Text(
                                context.l10n.noSearchResults,
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                            )
                          : ListView.builder(
                              itemCount: _filteredContacts.length,
                              itemBuilder: (context, index) {
                                final user = _filteredContacts[index];
                                final isSelected =
                                    _selectedUserIds.contains(user.id);

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
                                      ? const Icon(Icons.check_circle,
                                          color: Colors.green)
                                      : const Icon(Icons.check_circle_outline,
                                          color: Colors.grey),
                                  onTap: () => _toggleUser(user),
                                );
                              },
                            ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
