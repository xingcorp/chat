import 'package:flutter/material.dart';
import 'package:flutter_chat_app/core/formatters/relative_time_formatter.dart';
import 'package:flutter_chat_app/core/services/current_user_provider.dart';
import 'package:flutter_chat_app/core/theme/app_colors.dart';
import 'package:flutter_chat_app/core/theme/app_text_styles.dart';
import 'package:flutter_chat_app/features/chat/presentation/widgets/typing_indicator_widget.dart';
import 'package:flutter_chat_app/l10n/l10n.dart';
import 'package:flutter_chat_app/presentation/widgets/common/hero_avatar.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/design_system.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/indicators/user_presence_indicator.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/typography/app_text.dart';
import 'package:flutter_chat_app/shared/domain/entities/chat.dart';
import 'package:get_it/get_it.dart';


class ChatConversationTile extends StatelessWidget {
  final Chat chat;
  final String previewText;
  final VoidCallback? onTap;

  const ChatConversationTile({
    super.key,
    required this.chat,
    required this.previewText,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasUnread = chat.unreadCount > 0;
    final isTyping = chat.typingUserIds.isNotEmpty;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Theme-aware text colors
    final primaryTextColor = isDark ? AppColors.textPrimaryDarkMode : AppColors.textPrimary;
    final secondaryTextColor = isDark ? AppColors.textSecondaryDarkMode : AppColors.textSecondary;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(
          // horizontal: 12,
          top: 10,
          left: 6,
          bottom: 10,
          right: 12
        ),
        child: Row(
          children: [
            _buildAvatarWithPresence(),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: AppText(
                          chat.name ?? context.l10n.unknownUser,
                          style: AppTextStyles.titleMedium.copyWith(
                            fontWeight: hasUnread ? FontWeight.bold : FontWeight.w500,
                            color: primaryTextColor,
                            fontSize: 16,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      AppText(
                        RelativeTimeFormatter.format(context, chat.lastMessageAt),
                        style: AppTextStyles.labelSmall.copyWith(
                          color: hasUnread ? AppColors.primary : secondaryTextColor,
                          fontWeight: hasUnread ? FontWeight.w600 : FontWeight.normal,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (isTyping) ...[
                        const TypingIndicatorWidget(),
                        const SizedBox(width: 4),
                      ],
                      Expanded(
                        child: AppText(
                          isTyping
                              ? context.l10n.typing
                              : previewText,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: hasUnread ? primaryTextColor : secondaryTextColor,
                            fontWeight: hasUnread ? FontWeight.w500 : FontWeight.normal,
                            fontStyle: isTyping ? FontStyle.italic : FontStyle.normal,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (hasUnread) ...[
                        const SizedBox(width: 8),
                        _UnreadBadge(count: chat.unreadCount),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build avatar with presence indicator for direct chats
  Widget _buildAvatarWithPresence() {
    // Only show presence for direct chats (1-1)
    if (chat.type == ChatType.direct && chat.members.isNotEmpty) {
      final currentUserId = GetIt.instance<CurrentUserProvider>().currentUserId;

      // Get other user (not current user)
      final otherMember = chat.members.firstWhere(
        (m) => m.userId != currentUserId,
        orElse: () => chat.members.first,
      );

      return UserPresenceBadge(
        isConnected: otherMember.isConnected,
        lastSeenAt: otherMember.viewMessagesFrom,
        indicatorSize: 14.0,
        child: AppHeroAvatar(
          id: chat.id,
          imageUrl: chat.avatarUrl,
          displayName: chat.name,
          size: AvatarSize.large,
          hasBorder: false,
        ),
      );
    }

    // For group chats, show normal avatar without presence
    return AppHeroAvatar(
      id: chat.id,
      imageUrl: chat.avatarUrl,
      displayName: chat.name,
      size: AvatarSize.large,
      hasBorder: false,
    );
  }
}

class _UnreadBadge extends StatelessWidget {
  final int count;

  const _UnreadBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    final display = count > 99 ? '99+' : count.toString();

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 6,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(10),
      ),
      constraints: const BoxConstraints(minWidth: 20),
      child: AppText(
        display,
        style: AppTextStyles.labelSmall.copyWith(
          color: AppColors.textButton,
          fontWeight: FontWeight.bold,
          fontSize: 11,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
