import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_chat_app/core/constants/app_icons.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/media/app_icon.dart';
import 'package:flutter_chat_app/core/constants/app_dimens.dart';
import 'package:flutter_chat_app/core/services/current_user_provider.dart';
import 'package:flutter_chat_app/core/theme/app_colors.dart';
import 'package:flutter_chat_app/core/theme/app_text_styles.dart';
import 'package:flutter_chat_app/core/utils/logger.dart';
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

  /// For pending direct chats (no server conversation yet).
  /// Used to show the receiver's presence status before the first message.
  final String? receiverId;

  final bool showBackButton;
  final VoidCallback? onBackPressed;
  final VoidCallback? onAvatarTap;
  final VoidCallback? onMembersPressed;
  final VoidCallback? onInfoPressed;
  final VoidCallback? onAddMemberPressed;
  final VoidCallback? onSearchPressed;

  const ChatHeader({
    super.key,
    required this.chat,
    this.receiverId,
    this.showBackButton = true,
    this.onBackPressed,
    this.onAvatarTap,
    this.onMembersPressed,
    this.onInfoPressed,
    this.onAddMemberPressed,
    this.onSearchPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final directPresence = _resolveDirectChatPresence();

    return AppBar(
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: Colors.transparent,
      flexibleSpace: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: AppDimens.glassBlurSigma,
            sigmaY: AppDimens.glassBlurSigma,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: theme.brightness == Brightness.dark
                  ? AppColors.glassBgDark
                  : AppColors.glassBgLight,
              border: Border(
                bottom: BorderSide(
                  color: theme.brightness == Brightness.dark
                      ? AppColors.dividerDarkMode
                      : AppColors.divider,
                  width: 0.5,
                ),
              ),
            ),
          ),
        ),
      ),
      automaticallyImplyLeading: false,
      titleSpacing: showBackButton ? 0 : 8,
      leading: showBackButton
          ? IconButton(
              icon: const AppIcon.svg(AppIcons.arrowBack),
              onPressed: onBackPressed ?? () => Navigator.of(context).pop(),
            )
          : null,
      title: Row(
        children: <Widget>[
          GestureDetector(
            onTap: onAvatarTap ?? onInfoPressed,
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
          icon: const AppIcon.svg(AppIcons.search),
          onPressed: onSearchPressed,
        ),
        if (chat.type == ChatType.group)
          IconButton(
            icon: const AppIcon.svg(AppIcons.personAdd),
            onPressed: onAddMemberPressed,
          ),
        IconButton(
          icon: const AppIcon.svg(AppIcons.info),
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
        Builder(
          builder: (context) {
            final dotSize = AppDimens.presenceDotSize;
            final borderWidth = AppDimens.presenceDotBorder;
            final scale = AppDimens.presencePulseMaxScale;
            final dotWithBorder = dotSize + borderWidth * 2;
            final pulseOffset = dotWithBorder * (scale - 1) / 2;

            return Positioned(
              right: -pulseOffset,
              bottom: -pulseOffset,
              child: LivePresenceIndicator(
                userId: directPresence.userId,
                showLabel: false,
                dotSize: dotSize,
                fallbackPresence: directPresence.fallbackPresence,
              ),
            );
          },
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

    return _buildMembersText(context, secondaryColor);
  }

  Widget _buildMembersText(BuildContext context, Color secondaryColor) {
    final child = AppText(
      context.l10n.membersCount(chat.members.length),
      style: AppTextStyles.bodySmall.copyWith(color: secondaryColor),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );

    final onTap = onMembersPressed;
    if (onTap == null) {
      return child;
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: child,
    );
  }

  _DirectChatPresence? _resolveDirectChatPresence() {
    final logger = GetIt.instance<AppLogger>();

    if (chat.type != ChatType.direct) {
      return null;
    }

    // Normal direct chat with members loaded from server
    if (chat.members.isNotEmpty) {
      final currentUserId =
          GetIt.instance<CurrentUserProvider>().currentUserId;
      final otherMember = chat.members.firstWhere(
        (member) => member.userId != currentUserId,
        orElse: () => chat.members.first,
      );

      final otherUserId = otherMember.userId.trim().isNotEmpty
          ? otherMember.userId.trim()
          : otherMember.id.trim();
      if (otherUserId.isEmpty) {
        logger.w('[ChatHeader] Direct chat has members but otherUserId is empty');
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

    // Pending direct chat — no members yet (conversation not created on server).
    // Try receiverId first, then fall back to chat.participantIds (the
    // optimistic chat stores receiverId in participantIds when created locally).
    final effectiveReceiverId = _resolveEffectiveReceiverId();

    logger.d('[ChatHeader] Pending direct chat resolution', {
      'chatId': chat.id,
      'receiverId': receiverId,
      'participantIds': chat.participantIds,
      'effectiveReceiverId': effectiveReceiverId,
      'membersCount': chat.members.length,
    });

    if (effectiveReceiverId != null && effectiveReceiverId.trim().isNotEmpty) {
      return _DirectChatPresence(
        userId: effectiveReceiverId,
        fallbackPresence: UserPresence(
          userId: effectiveReceiverId,
          isOnline: false,
          lastSeen: null,
        ),
      );
    }

    logger.w('[ChatHeader] Direct chat with empty members and no receiverId', context: {
      'chatId': chat.id,
      'chatType': chat.type.name,
      'receiverId': receiverId,
      'participantIds': chat.participantIds,
    });
    return null;
  }

  /// Resolve the effective receiverId from multiple sources:
  /// 1. Explicit receiverId passed from ChatDetailsPage (highest priority)
  /// 2. chat.participantIds — the optimistic local chat stores
  ///    [receiverId] in participantIds when created by createDirectChat()
  String? _resolveEffectiveReceiverId() {
    // 1. Explicit receiverId from widget parameter
    if (receiverId != null && receiverId!.trim().isNotEmpty) {
      return receiverId;
    }

    // 2. Fall back to participantIds — the optimistic chat stores the
    //    receiver's userId here during createChat() in ChatRepository.
    //    Filter out the current user's ID to get the receiver.
    if (chat.participantIds.isNotEmpty) {
      try {
        final currentUserId =
            GetIt.instance<CurrentUserProvider>().currentUserId;
        // Find the participant that is NOT the current user
        final otherParticipant = chat.participantIds
            .where((id) => id.trim().isNotEmpty && id != currentUserId)
            .firstOrNull;
        if (otherParticipant != null) {
          return otherParticipant;
        }
        // If all participants are current user (shouldn't happen), use first
        final firstParticipant = chat.participantIds.firstOrNull;
        if (firstParticipant != null && firstParticipant.trim().isNotEmpty) {
          return firstParticipant;
        }
      } catch (_) {
        // CurrentUserProvider not available — use first participantId
        final firstParticipant = chat.participantIds.firstOrNull;
        if (firstParticipant != null && firstParticipant.trim().isNotEmpty) {
          return firstParticipant;
        }
      }
    }

    return null;
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
