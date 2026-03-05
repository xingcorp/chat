import 'package:flutter/material.dart';
import 'package:flutter_chat_app/core/services/current_user_provider.dart';
import 'package:flutter_chat_app/core/theme/app_colors.dart';
import 'package:flutter_chat_app/core/theme/app_text_styles.dart';
import 'package:flutter_chat_app/domain/entities/user_presence.dart';
import 'package:flutter_chat_app/features/chat/presentation/widgets/chat/presence_indicator.dart';
import 'package:flutter_chat_app/l10n/l10n.dart';
import 'package:flutter_chat_app/presentation/widgets/common/hero_avatar.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/media/media.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/typography/app_text.dart';
import 'package:flutter_chat_app/shared/domain/entities/chat.dart';
import 'package:get_it/get_it.dart';

/// Header cho màn hình chi tiết chat.
class ChatHeader extends StatelessWidget implements PreferredSizeWidget {
  final Chat chat;
  final bool showBackButton;
  final VoidCallback? onBackPressed;
  final VoidCallback? onAvatarTap;
  final VoidCallback? onInfoPressed;
  final VoidCallback? onAddMemberPressed;
  final VoidCallback? onSearchPressed;

  const ChatHeader({
    super.key,
    required this.chat,
    this.showBackButton = true,
    this.onBackPressed,
    this.onAvatarTap,
    this.onInfoPressed,
    this.onAddMemberPressed,
    this.onSearchPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final directPresence = _resolveDirectChatPresence();

    return AppBar(
      automaticallyImplyLeading: false,
      titleSpacing: showBackButton ? 0 : 8,
      leading: showBackButton
          ? IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: onBackPressed ?? () => Navigator.of(context).pop(),
            )
          : null,
      title: Row(
        children: <Widget>[
          GestureDetector(
            onTap: onAvatarTap,
            child: _buildAvatar(directPresence),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Hero(
                  tag: 'chat-name-${chat.id}',
                  child: Material(
                    color: Colors.transparent,
                    child: AppText(
                      chat.name ?? context.l10n.chats,
                      style: AppTextStyles.titleMedium.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                _buildStatusText(context, theme, directPresence),
              ],
            ),
          ),
        ],
      ),
      actions: <Widget>[
        IconButton(
          icon: const Icon(Icons.search),
          onPressed: onSearchPressed,
        ),
        if (chat.type == ChatType.group)
          IconButton(
            icon: const Icon(Icons.person_add),
            onPressed: onAddMemberPressed,
          ),
        IconButton(
          icon: const Icon(Icons.info_outline),
          onPressed: onInfoPressed,
        ),
      ],
    );
  }

  Widget _buildAvatar(_DirectChatPresence? directPresence) {
    final avatar = AppHeroAvatar(
      id: chat.id,
      imageUrl: chat.avatarUrl,
      displayName: chat.name,
      size: AvatarSize.medium,
      hasBorder: true,
    );

    if (directPresence == null) {
      return avatar;
    }

    return Stack(
      clipBehavior: Clip.none,
      children: <Widget>[
        avatar,
        Positioned(
          right: 0,
          bottom: 0,
          child: LivePresenceIndicator(
            userId: directPresence.userId,
            showLabel: false,
            dotSize: 14.0,
            fallbackPresence: directPresence.fallbackPresence,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusText(
    BuildContext context,
    ThemeData theme,
    _DirectChatPresence? directPresence,
  ) {
    if (directPresence != null) {
      final secondaryColor = theme.brightness == Brightness.dark
          ? AppColors.textSecondaryDarkMode
          : AppColors.textSecondary;

      return LivePresenceIndicator(
        userId: directPresence.userId,
        showLabel: true,
        showDot: false,
        textStyle: AppTextStyles.bodySmall.copyWith(color: secondaryColor),
        fallbackPresence: directPresence.fallbackPresence,
      );
    }

    final secondaryColor = theme.brightness == Brightness.dark
        ? AppColors.textSecondaryDarkMode
        : AppColors.textSecondary;

    return AppText(
      context.l10n.membersCount(chat.members.length),
      style: AppTextStyles.bodySmall.copyWith(color: secondaryColor),
    );
  }

  _DirectChatPresence? _resolveDirectChatPresence() {
    if (chat.type != ChatType.direct || chat.members.isEmpty) {
      return null;
    }

    final currentUserId = GetIt.instance<CurrentUserProvider>().currentUserId;
    final otherMember = chat.members.firstWhere(
      (member) => member.userId != currentUserId,
      orElse: () => chat.members.first,
    );

    final otherUserId = otherMember.userId.trim().isNotEmpty
        ? otherMember.userId.trim()
        : otherMember.id.trim();
    if (otherUserId.isEmpty) {
      return null;
    }

    return _DirectChatPresence(
      userId: otherUserId,
      fallbackPresence: UserPresence(
        userId: otherUserId,
        isOnline: otherMember.isConnected,
        lastSeen: otherMember.viewMessagesFrom,
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _DirectChatPresence {
  const _DirectChatPresence({
    required this.userId,
    required this.fallbackPresence,
  });

  final String userId;
  final UserPresence fallbackPresence;
}
