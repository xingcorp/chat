import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_chat_app/core/constants/app_icons.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/media/app_icon.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_chat_app/core/base/base_widget.dart';
import 'package:flutter_chat_app/core/constants/app_dimens.dart';
import 'package:flutter_chat_app/core/navigation/chat_navigation_helper.dart';
import 'package:flutter_chat_app/core/theme/app_colors.dart';
import 'package:flutter_chat_app/core/theme/app_text_styles.dart';
import 'package:flutter_chat_app/domain/repositories/user_repository.dart';
import 'package:flutter_chat_app/features/chat/domain/repositories/i_chat_repository.dart';
import 'package:flutter_chat_app/features/chat/presentation/blocs/chat/chat_bloc.dart';
import 'package:flutter_chat_app/l10n/l10n.dart';
import 'package:flutter_chat_app/presentation/widgets/common/dismiss_keyboard_on_tap.dart';
import 'package:flutter_chat_app/presentation/widgets/common/hero_avatar.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/feedback/app_progress_indicator.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/indicators/user_presence_indicator.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/media/app_avatar.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/typography/app_text.dart';
import 'package:flutter_chat_app/shared/domain/entities/chat.dart';
import 'package:flutter_chat_app/shared/domain/entities/user.dart';
import 'package:get_it/get_it.dart';

/// Contacts page - displays list of users/contacts
class ContactsPage extends BaseStatefulWidget {
  const ContactsPage({
    super.key,
    this.selectionMode = false,
  });

  final bool selectionMode;

  @override
  State<ContactsPage> createState() => _ContactsPageState();
}

class _ContactsPageState extends BaseState<ContactsPage> {
  final UserRepository _userRepository = GetIt.instance<UserRepository>();
  final IChatRepository _chatRepository = GetIt.instance<IChatRepository>();
  final TextEditingController _searchController = TextEditingController();

  List<User> _contacts = [];
  bool _isLoading = true;
  String? _errorMessage;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _loadContacts('');
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      _loadContacts(_searchController.text.trim());
    });
  }

  Future<void> _loadContacts(String keyword) async {
    safeSetState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await _userRepository.searchUsers(keyword);

    result.fold(
      (failure) {
        safeSetState(() {
          _isLoading = false;
          _errorMessage = failure.message;
        });
      },
      (users) {
        safeSetState(() {
          _isLoading = false;
          _contacts = users;
        });
      },
    );
  }

  Future<void> _onRefresh() async {
    await _loadContacts(_searchController.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: AppText(context.l10n.contacts),
        actions: [
          IconButton(
            icon: const AppIcon.svg(AppIcons.personAdd),
            onPressed: () {
              // TODO: Navigate to add contact page
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          DismissKeyboardOnTap(
            child: Padding(
              padding: const EdgeInsets.all(AppDimens.paddingMedium),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: context.l10n.search,
                  prefixIcon: const AppIcon.svg(AppIcons.search),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const AppIcon.svg(AppIcons.close),
                          onPressed: () {
                            _searchController.clear();
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppDimens.radiusMedium),
                  ),
                  filled: true,
                  fillColor: isDark
                      ? theme.colorScheme.surface
                      : AppColors.inputBackground,
                ),
              ),
            ),
          ),
          // Content
          Expanded(
            child: _buildContent(context),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    if (_isLoading) {
      return Center(
        child: AppProgressIndicator.circular(
          label: context.l10n.loading,
        ),
      );
    }

    if (_errorMessage != null) {
      return _buildErrorState(context);
    }

    if (_contacts.isEmpty) {
      return _buildEmptyState(context);
    }

    return RefreshIndicator(
      onRefresh: _onRefresh,
      child: ListView.separated(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.manual,
        padding: const EdgeInsets.symmetric(vertical: AppDimens.paddingSmall),
        itemCount: _contacts.length,
        separatorBuilder: (context, index) => const Divider(
          height: 1,
          indent: AppDimens.spaceHuge,
        ),
        itemBuilder: (context, index) {
          return _buildContactItem(context, _contacts[index]);
        },
      ),
    );
  }

  Widget _buildContactItem(BuildContext context, User user) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryTextColor =
        isDark ? AppColors.textPrimaryDarkMode : AppColors.textPrimary;
    final secondaryTextColor =
        isDark ? AppColors.textSecondaryDarkMode : AppColors.textSecondary;

    return ListTile(
      leading: UserPresenceBadge(
        isConnected: user.isOnline,
        lastSeenAt: user.lastSeen,
        indicatorSize: 12.0,
        child: AppHeroAvatar(
          id: user.id,
          imageUrl: user.avatar,
          displayName: user.fullName,
          size: AvatarSize.medium,
          hasBorder: false,
          enableHero: false,
        ),
      ),
      title: AppText(
        user.fullName ?? user.username,
        style: AppTextStyles.titleMedium.copyWith(
          color: primaryTextColor,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: AppText(
        user.email,
        style: AppTextStyles.bodySmall.copyWith(
          color: secondaryTextColor,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: IconButton(
        icon: const AppIcon.svg(AppIcons.chatBubble),
        onPressed: () => _startChat(user),
      ),
      onTap: () => _navigateToChat(user),
    );
  }

  Future<void> _startChat(User user) async {
    await _navigateToChat(user);
  }

  Future<void> _navigateToChat(User user) async {
    final fullName = user.fullName?.trim();
    final displayName =
        fullName != null && fullName.isNotEmpty ? fullName : user.username;
    final result = await _chatRepository.createChat(
      name: displayName,
      participantIds: <String>[user.id],
    );

    if (!mounted) {
      return;
    }

    await result.fold(
      (_) async {
        if (widget.selectionMode) {
          Navigator.of(context).pop(user.id);
          return;
        }

        await ChatNavigationHelper.navigateToChatDetail(
          context,
          chatId: user.id,
        );
      },
      (chat) async {
        _notifyChatUpdated(chat);

        if (widget.selectionMode) {
          Navigator.of(context).pop(chat);
          return;
        }

        // For pending direct chats (no server conversation yet), pass the
        // receiverId so ChatDetailsPage/MessageBloc can auto-create the
        // conversation on first message send.
        final isPendingDirect = chat.type == ChatType.direct &&
            chat.participantIds.isNotEmpty &&
            chat.members.isEmpty;
        final receiverId = isPendingDirect ? user.id : null;

        await ChatNavigationHelper.navigateToChatDetail(
          context,
          chatId: chat.id,
          receiverId: receiverId,
        );
      },
    );
  }

  void _notifyChatUpdated(Chat chat) {
    try {
      context.read<ChatBloc>().add(ChatEvent.chatUpdated(chat: chat));
    } catch (_) {
      // ContactsPage can be embedded without a shared ChatBloc ancestor.
    }
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final secondaryTextColor =
        isDark ? AppColors.textSecondaryDarkMode : AppColors.textSecondary;

    return DismissKeyboardOnTap(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AppIcon.svg(
              AppIcons.emptyContacts,
              size: AppDimens.iconSizeXXLarge,
              color: secondaryTextColor,
            ),
            const SizedBox(height: AppDimens.spaceMedium),
            AppText(
              _searchController.text.isNotEmpty
                  ? context.l10n.noResults
                  : context.l10n.noConversations,
              style: AppTextStyles.bodyMedium.copyWith(
                color: secondaryTextColor,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final secondaryTextColor =
        isDark ? AppColors.textSecondaryDarkMode : AppColors.textSecondary;

    return DismissKeyboardOnTap(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AppIcon.svg(
              AppIcons.errorOutline,
              size: AppDimens.iconSizeXXLarge,
              color: AppColors.error,
            ),
            const SizedBox(height: AppDimens.spaceMedium),
            AppText(
              _errorMessage ?? context.l10n.errorOccurred,
              style: AppTextStyles.bodyMedium.copyWith(
                color: secondaryTextColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppDimens.spaceLarge),
            ElevatedButton.icon(
              onPressed: () => _loadContacts(_searchController.text.trim()),
              icon: const AppIcon.svg(AppIcons.refresh),
              label: Text(context.l10n.retryOperation),
            ),
          ],
        ),
      ),
    );
  }
}
