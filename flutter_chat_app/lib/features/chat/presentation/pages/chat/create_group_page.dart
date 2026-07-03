import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_app/core/constants/app_icons.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/app_icon.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_chat_app/core/base/base_widget.dart';
import 'package:flutter_chat_app/core/constants/app_dimens.dart';
import 'package:flutter_chat_app/core/di/injection.dart';
import 'package:flutter_chat_app/core/services/current_user_provider.dart';
import 'package:flutter_chat_app/core/theme/app_colors.dart';
import 'package:flutter_chat_app/core/theme/app_text_styles.dart';
import 'package:flutter_chat_app/core/utils/logger.dart';
import 'package:flutter_chat_app/domain/repositories/user_repository.dart';
import 'package:flutter_chat_app/features/auth/presentation/blocs/auth/auth_bloc.dart';
import 'package:flutter_chat_app/features/chat/presentation/blocs/chat/chat_bloc.dart';
import 'package:flutter_chat_app/l10n/l10n.dart';
import 'package:flutter_chat_app/presentation/widgets/common/dismiss_keyboard_on_tap.dart';
import 'package:flutter_chat_app/presentation/widgets/common/hero_avatar.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/buttons/app_button.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/buttons/app_icon_button.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/buttons/button_enums.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/feedback/app_snack_bar.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/forms/app_dropdown.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/indicators/user_presence_indicator.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/inputs/app_text_field.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/lists/app_sliver_list_view.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/media/app_avatar.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/navigation/app_scaffold.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/typography/app_text.dart';
import 'package:flutter_chat_app/shared/domain/entities/chat.dart';
import 'package:flutter_chat_app/shared/domain/entities/user.dart';
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
  static const Set<PointerDeviceKind> _scrollDragDevices = <PointerDeviceKind>{
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    PointerDeviceKind.stylus,
    PointerDeviceKind.invertedStylus,
    PointerDeviceKind.trackpad,
    PointerDeviceKind.unknown,
  };

  final TextEditingController _groupNameController = TextEditingController();
  final TextEditingController _groupDescriptionController =
      TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _contactsScrollController = ScrollController();
  final UserRepository _userRepository = getIt<UserRepository>();
  final CurrentUserProvider _currentUserProvider = getIt<CurrentUserProvider>();
  final AppLogger _logger = getIt<AppLogger>();
  final List<String> _selectedUserIds = [];
  final List<User> _selectedUsers = [];

  List<User> _contacts = [];
  bool _isLoading = true;
  Uint8List? _avatarBytes;
  String? _avatarFileName;
  String? _avatarFilePath;
  String _searchQuery = '';
  String _activeKeyword = '';
  Timer? _debounceTimer;
  int _currentPage = 0;
  bool _hasMoreContacts = true;
  bool _isLoadingMore = false;
  final Set<String> _loggedSelfLeakIds = <String>{};
  GroupType _selectedGroupType = GroupType.private;

  @override
  void initState() {
    super.initState();
    unawaited(_primeCurrentUserIdentity());
    _contactsScrollController.addListener(_onContactsControllerChanged);
    _reloadContacts('');
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _groupNameController.dispose();
    _groupDescriptionController.dispose();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _contactsScrollController.removeListener(_onContactsControllerChanged);
    _contactsScrollController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Search & Pagination
  // ---------------------------------------------------------------------------

  void _onSearchChanged() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      _reloadContacts(_searchController.text.trim());
    });
    safeSetState(() {
      _searchQuery = _searchController.text.toLowerCase();
    });
  }

  void _onContactsControllerChanged() {
    if (!_contactsScrollController.hasClients) return;
    // Pagination trigger is handled by AppSliverListView.onLoadMore
  }

  // ---------------------------------------------------------------------------
  // Current User Identity
  // ---------------------------------------------------------------------------

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

  // ---------------------------------------------------------------------------
  // Contacts Loading
  // ---------------------------------------------------------------------------

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
        for (final user in users) {
          if (_isCurrentUser(user, identity)) continue;
          filteredUsers.add(user);
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
            '[CreateGroupPage] Stop pagination — no unique users on page',
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

  // ---------------------------------------------------------------------------
  // User Selection & Avatar
  // ---------------------------------------------------------------------------

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
        _avatarFilePath = picked.path.trim().isNotEmpty ? picked.path : null;
      });
    }
  }

  // ---------------------------------------------------------------------------
  // Create Group Action
  // ---------------------------------------------------------------------------

  void _createGroup(BuildContext context) {
    final groupName = _groupNameController.text.trim();
    final groupDescription = _groupDescriptionController.text.trim();

    if (groupName.isEmpty) {
      AppSnackBar.error(
        context: context,
        message: context.l10n.pleaseEnterGroupName,
      );
      return;
    }

    if (_selectedUserIds.isEmpty) {
      AppSnackBar.error(
        context: context,
        message: context.l10n.pleaseSelectMembers,
      );
      return;
    }

    context.read<ChatBloc>().add(
          ChatEvent.createChat(
            type: ChatType.group,
            name: groupName,
            description: groupDescription,
            groupType: _selectedGroupType,
            participantIds: _selectedUserIds,
            avatarBytes: _avatarBytes,
            avatarFileName: _avatarFileName,
            avatarFilePath: _avatarFilePath,
          ),
        );
  }

  // ---------------------------------------------------------------------------
  // Filtered Contacts
  // ---------------------------------------------------------------------------

  List<User> get _filteredContacts {
    final identity = _resolveCurrentUserIdentity();
    final contacts =
        _contacts.where((u) => !_isCurrentUser(u, identity)).toList();

    for (final user in _contacts) {
      if (!_isCurrentUser(user, identity)) continue;
      if (_loggedSelfLeakIds.add(user.id)) {
        _logger
            .w('[CreateGroupPage] Self user leaked into _contacts', context: {
          'userId': user.id,
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

  List<_GroupTypeOption> _buildGroupTypeOptions(BuildContext context) {
    return <_GroupTypeOption>[
      _GroupTypeOption(
        type: GroupType.private,
        label: context.l10n.privateGroup,
      ),
      _GroupTypeOption(
        type: GroupType.public,
        label: context.l10n.publicGroup,
      ),
    ];
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final groupTypeOptions = _buildGroupTypeOptions(context);
    final selectedGroupTypeOption = groupTypeOptions.firstWhere(
      (option) => option.type == _selectedGroupType,
      orElse: () => groupTypeOptions.first,
    );

    return BlocProvider(
      create: (_) => getIt<ChatBloc>(),
      child: BlocConsumer<ChatBloc, ChatState>(
        listener: (context, state) {
          state.maybeWhen(
            chatDetailsLoaded: (chat) {
              Navigator.of(context).pop(chat);
            },
            error: (message) {
              AppSnackBar.error(
                context: context,
                message: message,
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
          final canCreate = !isCreating && _selectedUserIds.isNotEmpty;
          final filteredContacts = _filteredContacts;

          return AppScaffold(
            dismissKeyboardOnTap: false,
            appBar: AppBar(
              title: AppText(
                context.l10n.createNewGroup,
                style: AppTextStyles.heading5(),
              ),
            ),
            bottomNavigationBar: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppDimens.paddingMedium,
                  0,
                  AppDimens.paddingMedium,
                  AppDimens.paddingMedium,
                ),
                child: AppButton.primary(
                  text: context.l10n.create,
                  size: ButtonSize.large,
                  isFullWidth: true,
                  isLoading: isCreating,
                  onPressed: canCreate ? () => _createGroup(context) : null,
                ),
              ),
            ),
            body: ScrollConfiguration(
              behavior: const MaterialScrollBehavior()
                  .copyWith(dragDevices: _scrollDragDevices),
              child: CustomScrollView(
                controller: _contactsScrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.manual,
                slivers: [
                  // Header: avatar picker + group name + search
                  SliverToBoxAdapter(
                    child: DismissKeyboardOnTap(
                      child: Padding(
                        padding: const EdgeInsets.all(AppDimens.paddingMedium),
                        child: Column(
                          children: [
                            _buildAvatarPicker(context, isCreating, isDark),
                            const SizedBox(height: AppDimens.spaceMedium),
                            _buildGroupNameField(context, isCreating),
                            const SizedBox(height: AppDimens.spaceMedium),
                            _buildGroupDescriptionField(context, isCreating),
                            const SizedBox(height: AppDimens.spaceMedium),
                            _buildGroupTypeField(
                              context,
                              isCreating,
                              groupTypeOptions,
                              selectedGroupTypeOption,
                            ),
                            const SizedBox(height: AppDimens.spaceMedium),
                            _buildSearchField(context, isCreating),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Selected members horizontal strip
                  if (_selectedUsers.isNotEmpty)
                    SliverToBoxAdapter(
                      child: DismissKeyboardOnTap(
                        child: _buildSelectedMembersStrip(context, isDark),
                      ),
                    ),

                  // Contact list
                  AppSliverListView<User>(
                    items: filteredContacts,
                    controller: _contactsScrollController,
                    isLoading: _isLoading,
                    isLoadingMore: _isLoadingMore,
                    hasMore: _hasMoreContacts,
                    onLoadMore: _loadMoreContacts,
                    emptyWidget: Center(
                      child: DismissKeyboardOnTap(
                        child: AppText(
                          context.l10n.noSearchResults,
                          style: AppTextStyles.bodyLarge,
                        ),
                      ),
                    ),
                    itemBuilder: (context, user, index) {
                      return _buildContactTile(
                        context,
                        user: user,
                        isCreating: isCreating,
                        isDark: isDark,
                      );
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Sub-widgets
  // ---------------------------------------------------------------------------

  /// Avatar picker with camera overlay badge.
  Widget _buildAvatarPicker(
    BuildContext context,
    bool isCreating,
    bool isDark,
  ) {
    final avatarData = _avatarBytes;

    return GestureDetector(
      onTap: isCreating ? null : _pickAvatar,
      child: Stack(
        alignment: Alignment.bottomRight,
        children: [
          if (avatarData != null)
            CircleAvatar(
              radius: AppDimens.avatarMedium,
              backgroundImage: MemoryImage(avatarData),
            )
          else
            AppAvatar.initials(
              name: _groupNameController.text.isNotEmpty
                  ? _groupNameController.text
                  : context.l10n.groupName,
              size: AvatarSize.xlarge,
              backgroundColor: AppColors.primary,
              foregroundColor: isDark
                  ? AppColors.textPrimaryDarkMode
                  : AppColors.cardBackground,
            ),
          Container(
            padding: const EdgeInsets.all(AppDimens.paddingXSmall),
            decoration: const BoxDecoration(
              color: AppColors.secondary,
              shape: BoxShape.circle,
            ),
            child: AppIcon(
              AppIcons.cameraAlt,
              size: AppDimens.iconXSmall,
              color: isDark
                  ? AppColors.textPrimaryDarkMode
                  : AppColors.cardBackground,
            ),
          ),
        ],
      ),
    );
  }

  /// Group name input field.
  Widget _buildGroupNameField(BuildContext context, bool isCreating) {
    return AppTextField(
      controller: _groupNameController,
      label: context.l10n.groupName,
      prefixIcon: AppIcons.group,
      enabled: !isCreating,
      textInputAction: TextInputAction.next,
      onChanged: (_) => safeSetState(() {}),
    );
  }

  Widget _buildGroupDescriptionField(BuildContext context, bool isCreating) {
    return AppTextField(
      controller: _groupDescriptionController,
      label: context.l10n.groupDescription,
      prefixIcon: AppIcons.notes,
      enabled: !isCreating,
      maxLines: 3,
      minLines: 3,
      textInputAction: TextInputAction.newline,
    );
  }

  Widget _buildGroupTypeField(
    BuildContext context,
    bool isCreating,
    List<_GroupTypeOption> options,
    _GroupTypeOption selectedOption,
  ) {
    return AppDropdown<_GroupTypeOption>(
      items: options,
      value: selectedOption,
      onChanged: isCreating
          ? null
          : (option) {
              if (option == null) {
                return;
              }
              safeSetState(() {
                _selectedGroupType = option.type;
              });
            },
      label: context.l10n.groupType,
      itemBuilder: (option) => AppText(option.label),
    );
  }

  /// Contact search field.
  Widget _buildSearchField(BuildContext context, bool isCreating) {
    return AppTextField(
      controller: _searchController,
      label: context.l10n.search,
      prefixIcon: AppIcons.search,
      enabled: !isCreating,
      suffixIcon: _searchQuery.isNotEmpty
          ? AppIconButton(
              icon: Icons.close_rounded, // TODO: Change to AppIcons.close when AppIconButton supports String iconPath
              size: ButtonSize.small,
              tooltip: context.l10n.cancel,
              onPressed: _searchController.clear,
            )
          : null,
    );
  }

  /// Horizontal strip of selected members with remove action.
  Widget _buildSelectedMembersStrip(BuildContext context, bool isDark) {
    return Container(
      height: AppDimens.avatarXLarge + AppDimens.spaceSmall,
      padding: const EdgeInsets.symmetric(vertical: AppDimens.paddingSmall),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDarkMode : AppColors.surface,
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.dividerDarkMode : AppColors.divider,
          ),
          bottom: BorderSide(
            color: isDark ? AppColors.dividerDarkMode : AppColors.divider,
          ),
        ),
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding:
            const EdgeInsets.symmetric(horizontal: AppDimens.paddingMedium),
        itemCount: _selectedUsers.length,
        itemBuilder: (context, index) {
          final user = _selectedUsers[index];
          return Padding(
            padding: const EdgeInsets.only(right: AppDimens.paddingMedium),
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
                        padding: const EdgeInsets.all(
                          AppDimens.paddingXSmall / 2,
                        ),
                        decoration: const BoxDecoration(
                          color: AppColors.error,
                          shape: BoxShape.circle,
                        ),
                        child: const AppIcon(
                          AppIcons.close,
                          size: AppDimens.iconXSmall - 2,
                          color: AppColors.cardBackground,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppDimens.spaceXSmall),
                SizedBox(
                  width: AppDimens.avatarLarge + AppDimens.spaceXSmall,
                  child: AppText(
                    user.fullName ?? user.username,
                    style: AppTextStyles.bodySmall,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Single contact list tile with selection state.
  Widget _buildContactTile(
    BuildContext context, {
    required User user,
    required bool isCreating,
    required bool isDark,
  }) {
    final isSelected = _selectedUserIds.contains(user.id);

    return ListTile(
      enabled: !isCreating,
      leading: UserPresenceBadge(
        isConnected: user.isOnline,
        lastSeenAt: user.lastSeen,
        indicatorSize: AppDimens.iconXSmall - 4,
        child: AppHeroAvatar(
          id: user.id,
          imageUrl: user.avatar,
          displayName: user.fullName ?? user.username,
          size: AvatarSize.medium,
          hasBorder: false,
        ),
      ),
      title: AppText(
        user.fullName ?? user.username,
        style: AppTextStyles.bodyLargeCustom(
          color: isDark ? AppColors.textPrimaryDarkMode : AppColors.textPrimary,
        ),
      ),
      trailing: AppIcon(
        isSelected ? AppIcons.checkCircle : AppIcons.checkCircleOutline,
        color: isSelected ? AppColors.success : AppColors.textHint,
      ),
      onTap: () => _toggleUser(user),
    );
  }
}

// -----------------------------------------------------------------------------
// Helper model
// -----------------------------------------------------------------------------

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

class _GroupTypeOption {
  final GroupType type;
  final String label;

  const _GroupTypeOption({
    required this.type,
    required this.label,
  });

  @override
  String toString() => label;
}
