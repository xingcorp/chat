import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_chat_app/core/base/base_widget.dart';
import 'package:flutter_chat_app/core/constants/app_dimens.dart';
import 'package:flutter_chat_app/core/services/current_user_provider.dart';
import 'package:flutter_chat_app/core/theme/app_colors.dart';
import 'package:flutter_chat_app/core/theme/app_text_styles.dart';
import 'package:flutter_chat_app/generated/l10n/app_localizations.dart';
import 'package:flutter_chat_app/l10n/l10n.dart';
import 'package:flutter_chat_app/presentation/blocs/chat_members/chat_members_bloc.dart';
import 'package:flutter_chat_app/presentation/blocs/chat_members/chat_members_event.dart';
import 'package:flutter_chat_app/presentation/blocs/chat_members/chat_members_state.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/buttons/app_button.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/buttons/app_icon_button.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/buttons/button_enums.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/dialogs/app_confirm_dialog.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/dialogs/app_modal_bottom_sheet.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/feedback/app_progress_indicator.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/feedback/app_snack_bar.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/inputs/app_text_field.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/lists/app_list_tile.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/media/app_avatar.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/navigation/app_scaffold.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/typography/app_text.dart';
import 'package:flutter_chat_app/shared/domain/entities/chat.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/intl.dart';

/// Page displaying full list of group members with search and admin actions.
class ChatMembersPage extends BaseStatefulWidget {
  final Chat chat;
  final String? currentUserId;

  const ChatMembersPage({
    super.key,
    required this.chat,
    this.currentUserId,
  });

  @override
  BaseState<ChatMembersPage> createState() => _ChatMembersPageState();
}

class _ChatMembersPageState extends BaseState<ChatMembersPage> {
  late final ChatMembersBloc _bloc;
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _bloc = GetIt.instance<ChatMembersBloc>();
    _bloc.init(widget.chat);
    _bloc.add(ChatMembersLoad(chatId: widget.chat.id));
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController
      ..removeListener(_onSearchChanged)
      ..dispose();
    _bloc.close();
    super.dispose();
  }

  void _onSearchChanged() {
    final keyword = _searchController.text;
    if (keyword.isEmpty) {
      _bloc.add(const ChatMembersClearSearch());
      return;
    }

    _bloc.add(ChatMembersSearch(keyword: keyword));
  }

  bool get _isDark => Theme.of(context).brightness == Brightness.dark;

  String get _effectiveCurrentUserId {
    final providedUserId = widget.currentUserId?.trim() ?? '';
    if (providedUserId.isNotEmpty) {
      return providedUserId;
    }
    return GetIt.instance<CurrentUserProvider>().currentUserId;
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _bloc,
      child: AppScaffold(
        backgroundColor:
            _isDark ? AppColors.backgroundDarkMode : AppColors.background,
        appBar: _buildAppBar(context),
        body: BlocConsumer<ChatMembersBloc, ChatMembersState>(
          listener: _onStateChange,
          builder: (context, state) => _buildBody(context, state),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    final l10n = context.l10n;

    return AppBar(
      title: AppText(
        l10n.members,
        style: AppTextStyles.titleLarge.copyWith(
          color:
              _isDark ? AppColors.textPrimaryDarkMode : AppColors.textPrimary,
        ),
      ),
      backgroundColor: _isDark ? AppColors.surfaceDarkMode : AppColors.surface,
      foregroundColor:
          _isDark ? AppColors.textPrimaryDarkMode : AppColors.textPrimary,
      elevation: 0,
      actions: [
        AppIconButton(
          icon: _isSearching ? Icons.close : Icons.search,
          tooltip: _isSearching ? l10n.cancel : l10n.searchMembers,
          onPressed: () {
            safeSetState(() {
              _isSearching = !_isSearching;
              if (!_isSearching) {
                _searchController.clear();
                _bloc.add(const ChatMembersClearSearch());
              }
            });
          },
        ),
      ],
      bottom: _isSearching
          ? PreferredSize(
              preferredSize: const Size.fromHeight(72),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppDimens.paddingMedium,
                  0,
                  AppDimens.paddingMedium,
                  AppDimens.paddingSmall,
                ),
                child: AppTextField(
                  controller: _searchController,
                  hint: l10n.searchMembers,
                  prefixIcon: Icons.search,
                  autofocus: true,
                  suffixIcon: _searchController.text.isNotEmpty
                      ? AppIconButton(
                          icon: Icons.close_rounded,
                          size: ButtonSize.small,
                          tooltip: l10n.cancel,
                          onPressed: _searchController.clear,
                        )
                      : null,
                ),
              ),
            )
          : null,
    );
  }

  void _onStateChange(BuildContext context, ChatMembersState state) {
    if (state is ChatMembersLeftGroup) {
      Navigator.of(context).pop();
      Navigator.of(context).pop();
      return;
    }

    if (state is ChatMembersMemberRemoved) {
      AppSnackBar.success(
        context: context,
        message: context.l10n.memberRemovedSuccessfully,
      );
      return;
    }

    if (state is ChatMembersAdminUpdated) {
      AppSnackBar.success(
        context: context,
        message: state.isAdmin
            ? context.l10n.adminRoleGranted
            : context.l10n.adminRoleRemoved,
      );
      return;
    }

    if (state is ChatMembersError) {
      AppSnackBar.error(
        context: context,
        message: state.message,
      );
    }
  }

  Widget _buildBody(BuildContext context, ChatMembersState state) {
    if (state is ChatMembersLoading) {
      return const Center(
        child: AppProgressIndicator.circular(),
      );
    }

    if (state is ChatMembersError) {
      return _buildErrorState(context, state);
    }

    if (state is ChatMembersLoaded) {
      return Column(
        children: [
          _buildGroupCreateInfo(context, state),
          Divider(
            color: _isDark ? AppColors.borderDarkMode : AppColors.border,
            height: 1,
          ),
          Padding(
            padding: const EdgeInsets.all(AppDimens.paddingMedium),
            child: Row(
              children: [
                AppText(
                  context.l10n.membersCount(state.filteredCount),
                  style: AppTextStyles.bodySmall.copyWith(
                    color: _isDark
                        ? AppColors.textSecondaryDarkMode
                        : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: state.filteredMembers.isEmpty
                ? _buildEmptyState(context, state.isSearching)
                : _buildMembersList(context, state),
          ),
        ],
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildErrorState(BuildContext context, ChatMembersError state) {
    final l10n = context.l10n;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimens.paddingLarge),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: AppDimens.iconSizeXLarge * 2,
              color: AppColors.error,
            ),
            const SizedBox(height: AppDimens.spaceMedium),
            AppText(
              state.message,
              style: AppTextStyles.bodyLarge.copyWith(
                color: _isDark
                    ? AppColors.textPrimaryDarkMode
                    : AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppDimens.spaceMedium),
            AppButton.outlined(
              text: l10n.retry,
              onPressed: () =>
                  _bloc.add(ChatMembersLoad(chatId: widget.chat.id)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupCreateInfo(
    BuildContext context,
    ChatMembersLoaded state,
  ) {
    if (state.creatorName == null && state.createdAt == null) {
      return const SizedBox.shrink();
    }

    final l10n = context.l10n;

    return Container(
      padding: const EdgeInsets.all(AppDimens.paddingMedium),
      color: _isDark ? AppColors.surfaceDarkMode : AppColors.surface,
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            size: AppDimens.iconSizeSmall,
            color: _isDark
                ? AppColors.textSecondaryDarkMode
                : AppColors.textSecondary,
          ),
          const SizedBox(width: AppDimens.spaceSmall),
          Expanded(
            child: AppText(
              _buildCreateInfoText(l10n, state),
              style: AppTextStyles.bodySmall.copyWith(
                color: _isDark
                    ? AppColors.textSecondaryDarkMode
                    : AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _buildCreateInfoText(AppLocalizations l10n, ChatMembersLoaded state) {
    final parts = <String>[];
    if (state.creatorName != null) {
      parts.add('${l10n.createdBy} ${state.creatorName}');
    }
    if (state.createdAt != null) {
      parts.add(DateFormat('dd/MM/yyyy HH:mm').format(state.createdAt!));
    }
    return parts.join(' • ');
  }

  Widget _buildEmptyState(BuildContext context, bool isSearching) {
    final l10n = context.l10n;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isSearching ? Icons.search_off : Icons.people_outline,
            size: AppDimens.iconSizeXLarge * 2,
            color: _isDark
                ? AppColors.textSecondaryDarkMode
                : AppColors.textSecondary,
          ),
          const SizedBox(height: AppDimens.spaceMedium),
          AppText(
            isSearching ? l10n.noSearchResults : l10n.noMembers,
            style: AppTextStyles.bodyLarge.copyWith(
              color: _isDark
                  ? AppColors.textSecondaryDarkMode
                  : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMembersList(BuildContext context, ChatMembersLoaded state) {
    final isCurrentUserAdmin =
        state.isCurrentUserAdmin(_effectiveCurrentUserId);
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: AppDimens.paddingSmall),
      itemCount: state.filteredMembers.length,
      itemBuilder: (context, index) => _buildMemberItem(
        context,
        state: state,
        member: state.filteredMembers[index],
        currentUserId: _effectiveCurrentUserId,
        isCurrentUserAdmin: isCurrentUserAdmin,
      ),
    );
  }

  Widget _buildMemberItem(
    BuildContext context, {
    required ChatMembersLoaded state,
    required ConversationMember member,
    required String currentUserId,
    required bool isCurrentUserAdmin,
  }) {
    final isCurrentUser =
        currentUserId.isNotEmpty && member.userId == currentUserId;

    return AppListTile(
      leading: _buildAvatar(member),
      title: member.fullName ?? context.l10n.unknownUser,
      subtitle: _buildMemberSubtitle(context, member),
      trailing: _canManageMember(
        member: member,
        currentUserId: currentUserId,
        isCurrentUserAdmin: isCurrentUserAdmin,
      )
          ? AppIconButton(
              icon: Icons.more_horiz_rounded,
              size: ButtonSize.small,
              tooltip: context.l10n.memberActions,
              onPressed: () => _showMemberActions(
                context,
                state: state,
                member: member,
                currentUserId: currentUserId,
              ),
            )
          : (isCurrentUser
              ? AppText(
                  context.l10n.you,
                  style: AppTextStyles.labelSmall.copyWith(
                    color:
                        _isDark ? AppColors.primaryDarkMode : AppColors.primary,
                  ),
                )
              : null),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppDimens.paddingMedium,
        vertical: AppDimens.paddingXSmall,
      ),
    );
  }

  Widget _buildAvatar(ConversationMember member) {
    final avatarUrl = member.avatarUrl?.trim();
    final avatar = avatarUrl != null && avatarUrl.isNotEmpty
        ? AppAvatar.network(
            imageUrl: avatarUrl,
            size: AvatarSize.medium,
          )
        : AppAvatar.initials(
            name: member.fullName ?? '?',
            size: AvatarSize.medium,
            backgroundColor:
                _isDark ? AppColors.primaryDarkMode : AppColors.primary,
            foregroundColor: AppColors.textPrimaryDarkMode,
          );

    if (!member.isAdmin) {
      return avatar;
    }

    return SizedBox(
      width: AppDimens.avatarSizeMedium,
      height: AppDimens.avatarSizeMedium,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          avatar,
          Positioned(
            right: -AppDimens.spaceXSmall / 2,
            bottom: -AppDimens.spaceXSmall / 2,
            child: Container(
              key: ValueKey<String>('chat_member_admin_badge_${member.userId}'),
              padding: const EdgeInsets.all(AppDimens.paddingXSmall / 2),
              decoration: BoxDecoration(
                color: _isDark ? AppColors.surfaceDarkMode : AppColors.surface,
                shape: BoxShape.circle,
                border: Border.all(
                  color: _isDark ? AppColors.borderDarkMode : AppColors.border,
                ),
              ),
              child: Icon(
                Icons.key_rounded,
                size: AppDimens.iconSizeXSmall,
                color: AppColors.warning,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _buildMemberSubtitle(
    BuildContext context,
    ConversationMember member,
  ) {
    final parts = <String>[];
    if (member.isAdmin) {
      parts.add(context.l10n.groupAdmin);
    }
    if (member.departmentName != null && member.departmentName!.isNotEmpty) {
      parts.add(member.departmentName!);
    }
    if (member.titleName != null && member.titleName!.isNotEmpty) {
      parts.add(member.titleName!);
    }
    if (member.code != null && member.code!.isNotEmpty) {
      parts.add(member.code!);
    }
    return parts.join(' • ');
  }

  bool _canManageMember({
    required ConversationMember member,
    required String currentUserId,
    required bool isCurrentUserAdmin,
  }) {
    return isCurrentUserAdmin &&
        currentUserId.isNotEmpty &&
        member.userId != currentUserId;
  }

  Future<void> _showMemberActions(
    BuildContext context, {
    required ChatMembersLoaded state,
    required ConversationMember member,
    required String currentUserId,
  }) async {
    final canPromote = !member.isAdmin;
    final canDemote = member.isAdmin &&
        member.userId != currentUserId &&
        _hasAnotherAdmin(state.members, member.userId);
    final canRemove = member.userId != currentUserId;

    await AppModalBottomSheet.show<void>(
      context: context,
      title: member.fullName ?? context.l10n.memberActions,
      initialChildSize: 0.35,
      minChildSize: 0.25,
      maxChildSize: 0.5,
      builder: (sheetContext) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (canPromote)
              AppListTile(
                leading: Icon(
                  Icons.key_rounded,
                  color: _isDark ? AppColors.iconDarkMode : AppColors.icon,
                ),
                title: context.l10n.makeGroupAdmin,
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _bloc.add(
                    ChatMembersMakeAdmin(
                      chatId: widget.chat.id,
                      memberId: member.userId,
                    ),
                  );
                },
              ),
            if (canDemote)
              AppListTile(
                leading: Icon(
                  Icons.person_remove,
                  color: _isDark ? AppColors.iconDarkMode : AppColors.icon,
                ),
                title: context.l10n.removeGroupAdmin,
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _bloc.add(
                    ChatMembersRemoveAdmin(
                      chatId: widget.chat.id,
                      memberId: member.userId,
                    ),
                  );
                },
              ),
            if (canRemove)
              AppListTile(
                leading: const Icon(
                  Icons.clear,
                  color: AppColors.error,
                ),
                title: context.l10n.removeMemberFromGroup,
                textColor: AppColors.error,
                iconColor: AppColors.error,
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _confirmRemoveMember(context, member);
                },
              ),
          ],
        );
      },
    );
  }

  bool _hasAnotherAdmin(
      List<ConversationMember> members, String excludedUserId) {
    return members.any(
      (member) => member.isAdmin && member.userId != excludedUserId,
    );
  }

  void _confirmRemoveMember(BuildContext context, ConversationMember member) {
    AppConfirmDialog.show(
      context: context,
      title: context.l10n.removeMemberFromGroup,
      content: context.l10n.confirmRemoveMember(
        member.fullName ?? context.l10n.unknownUser,
      ),
      confirmText: context.l10n.remove,
      cancelText: context.l10n.cancel,
      isDestructive: true,
    ).then((confirmed) {
      if (confirmed != true || !mounted) {
        return;
      }

      _bloc.add(
        ChatMembersRemove(
          chatId: widget.chat.id,
          memberId: member.userId,
        ),
      );
    });
  }
}
