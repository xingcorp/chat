import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_chat_app/core/constants/app_dimens.dart';
import 'package:flutter_chat_app/core/theme/app_colors.dart';
import 'package:flutter_chat_app/core/theme/app_text_styles.dart';
import 'package:flutter_chat_app/generated/l10n/app_localizations.dart';
import 'package:flutter_chat_app/l10n/l10n.dart';
import 'package:flutter_chat_app/shared/domain/entities/chat.dart';
import 'package:flutter_chat_app/presentation/blocs/chat_members/chat_members_bloc.dart';
import 'package:flutter_chat_app/presentation/blocs/chat_members/chat_members_event.dart';
import 'package:flutter_chat_app/presentation/blocs/chat_members/chat_members_state.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/typography/app_text.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/intl.dart';

/// Page displaying full list of group members with search functionality
class ChatMembersPage extends StatefulWidget {
  final Chat chat;
  final String? currentUserId;

  const ChatMembersPage({
    super.key,
    required this.chat,
    this.currentUserId,
  });

  @override
  State<ChatMembersPage> createState() => _ChatMembersPageState();
}

class _ChatMembersPageState extends State<ChatMembersPage> {
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
    _searchController.dispose();
    _bloc.close();
    super.dispose();
  }

  void _onSearchChanged() {
    final keyword = _searchController.text;
    if (keyword.isEmpty) {
      _bloc.add(const ChatMembersClearSearch());
    } else {
      _bloc.add(ChatMembersSearch(keyword: keyword));
    }
  }

  bool get isDark => Theme.of(context).brightness == Brightness.dark;

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _bloc,
      child: Scaffold(
        backgroundColor: isDark ? AppColors.backgroundDarkMode : AppColors.background,
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
          color: isDark ? AppColors.textPrimaryDarkMode : AppColors.textPrimary,
        ),
      ),
      backgroundColor: isDark ? AppColors.surfaceDarkMode : AppColors.surface,
      foregroundColor: isDark ? AppColors.textPrimaryDarkMode : AppColors.textPrimary,
      elevation: 0,
      actions: [
        IconButton(
          icon: Icon(
            _isSearching ? Icons.close : Icons.search,
            color: isDark ? AppColors.textPrimaryDarkMode : AppColors.textPrimary,
          ),
          onPressed: () {
            setState(() {
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
              preferredSize: const Size.fromHeight(56),
              child: _buildSearchField(context),
            )
          : null,
    );
  }

  Widget _buildSearchField(BuildContext context) {
    final l10n = context.l10n;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimens.paddingMedium,
        vertical: AppDimens.paddingSmall,
      ),
      child: TextField(
        controller: _searchController,
        autofocus: true,
        decoration: InputDecoration(
          hintText: l10n.searchMembers,
          hintStyle: AppTextStyles.bodyMedium.copyWith(
            color: isDark ? AppColors.textSecondaryDarkMode : AppColors.textSecondary,
          ),
          filled: true,
          fillColor: isDark ? AppColors.backgroundDarkMode : AppColors.background,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppDimens.radiusMedium),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppDimens.paddingMedium,
            vertical: AppDimens.paddingSmall,
          ),
          prefixIcon: Icon(
            Icons.search,
            color: isDark ? AppColors.textSecondaryDarkMode : AppColors.textSecondary,
          ),
        ),
        style: AppTextStyles.bodyMedium.copyWith(
          color: isDark ? AppColors.textPrimaryDarkMode : AppColors.textPrimary,
        ),
      ),
    );
  }

  void _onStateChange(BuildContext context, ChatMembersState state) {
    if (state is ChatMembersLeftGroup) {
      Navigator.of(context).pop();
      Navigator.of(context).pop();
    }
  }

  Widget _buildBody(BuildContext context, ChatMembersState state) {
    final l10n = context.l10n;

    if (state is ChatMembersLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state is ChatMembersError) {
      return _buildErrorState(context, state);
    }

    if (state is ChatMembersLoaded) {
      return Column(
        children: [
          _buildGroupCreateInfo(context, state),
          Divider(
            color: isDark ? AppColors.borderDarkMode : AppColors.border,
            height: 1,
          ),
          Padding(
            padding: const EdgeInsets.all(AppDimens.paddingMedium),
            child: Row(
              children: [
                AppText(
                  '${state.filteredCount} ${l10n.members}',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: isDark ? AppColors.textSecondaryDarkMode : AppColors.textSecondary,
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
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: AppColors.error),
          const SizedBox(height: AppDimens.spaceMedium),
          AppText(
            state.message,
            style: AppTextStyles.bodyLarge.copyWith(
              color: isDark ? AppColors.textPrimaryDarkMode : AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppDimens.spaceMedium),
          ElevatedButton(
            onPressed: () => _bloc.add(ChatMembersLoad(chatId: widget.chat.id)),
            child: AppText(l10n.retry),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupCreateInfo(BuildContext context, ChatMembersLoaded state) {
    if (state.creatorName == null && state.createdAt == null) {
      return const SizedBox.shrink();
    }

    final l10n = context.l10n;

    return Container(
      padding: const EdgeInsets.all(AppDimens.paddingMedium),
      color: isDark ? AppColors.surfaceDarkMode : AppColors.surface,
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            size: AppDimens.iconSizeSmall,
            color: isDark ? AppColors.textSecondaryDarkMode : AppColors.textSecondary,
          ),
          const SizedBox(width: AppDimens.spaceSmall),
          Expanded(
            child: AppText(
              _buildCreateInfoText(l10n, state),
              style: AppTextStyles.bodySmall.copyWith(
                color: isDark ? AppColors.textSecondaryDarkMode : AppColors.textSecondary,
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
            size: 64,
            color: isDark ? AppColors.textSecondaryDarkMode : AppColors.textSecondary,
          ),
          const SizedBox(height: AppDimens.spaceMedium),
          AppText(
            isSearching ? l10n.noSearchResults : l10n.noMembers,
            style: AppTextStyles.bodyLarge.copyWith(
              color: isDark ? AppColors.textSecondaryDarkMode : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMembersList(BuildContext context, ChatMembersLoaded state) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: AppDimens.paddingSmall),
      itemCount: state.filteredMembers.length,
      itemBuilder: (context, index) => _buildMemberItem(context, state.filteredMembers[index]),
    );
  }

  Widget _buildMemberItem(BuildContext context, ConversationMember member) {
    final l10n = context.l10n;
    final isCurrentUser = widget.currentUserId != null && member.userId == widget.currentUserId;

    return InkWell(
      onTap: () {},
      borderRadius: BorderRadius.circular(AppDimens.radiusSmall),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimens.paddingMedium,
          vertical: AppDimens.paddingSmall,
        ),
        child: Row(
          children: [
            Stack(
              children: [
                Container(
                  width: AppDimens.avatarSizeMedium,
                  height: AppDimens.avatarSizeMedium,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDark ? AppColors.surfaceDarkMode : AppColors.surface,
                  ),
                  child: ClipOval(
                    child: member.avatarUrl != null && member.avatarUrl!.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: member.avatarUrl!,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              color: isDark ? AppColors.surfaceDarkMode : AppColors.surface,
                              child: Center(
                                child: SizedBox(
                                  width: AppDimens.iconSizeSmall,
                                  height: AppDimens.iconSizeSmall,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: isDark ? AppColors.primaryDarkMode : AppColors.primary,
                                  ),
                                ),
                              ),
                            ),
                            errorWidget: (context, url, error) => _buildAvatarPlaceholder(member),
                          )
                        : _buildAvatarPlaceholder(member),
                  ),
                ),
                if (member.isAdmin)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.surfaceDarkMode : Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.key, size: 14, color: Colors.amber),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: AppDimens.spaceSmall),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: AppText(
                          member.fullName ?? l10n.unknownUser,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: isDark ? AppColors.textPrimaryDarkMode : AppColors.textPrimary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      if (isCurrentUser)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppDimens.paddingXSmall,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.primaryDarkMode.withValues(alpha: 0.2)
                                : AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(AppDimens.radiusXSmall),
                          ),
                          child: AppText(
                            l10n.you,
                            style: AppTextStyles.labelSmall.copyWith(
                              color: isDark ? AppColors.primaryDarkMode : AppColors.primary,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  AppText(
                    _buildMemberSubtitle(member),
                    style: AppTextStyles.bodySmall.copyWith(
                      color: isDark ? AppColors.textSecondaryDarkMode : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarPlaceholder(ConversationMember member) {
    final initials = member.fullName?.isNotEmpty == true
        ? member.fullName!.substring(0, 1).toUpperCase()
        : '?';

    return Container(
      width: AppDimens.avatarSizeMedium,
      height: AppDimens.avatarSizeMedium,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isDark ? AppColors.primaryDarkMode : AppColors.primary,
      ),
      child: Center(
        child: AppText(
          initials,
          style: AppTextStyles.titleMedium.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  String _buildMemberSubtitle(ConversationMember member) {
    final parts = <String>[];
    if (member.departmentName != null && member.departmentName!.isNotEmpty) {
      parts.add(member.departmentName!);
    }
    if (member.titleName != null && member.titleName!.isNotEmpty) {
      parts.add(member.titleName!);
    }
    if (member.code != null && member.code!.isNotEmpty) {
      parts.add(member.code!);
    }
    return parts.isEmpty ? '' : parts.join(' • ');
  }
}
