import 'package:flutter/material.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/design_system.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/indicators/user_presence_indicator.dart';
import 'package:flutter_chat_app/core/services/current_user_provider.dart';
import 'package:flutter_chat_app/shared/domain/entities/chat.dart';
import 'package:flutter_chat_app/presentation/widgets/common/hero_avatar.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:get_it/get_it.dart';
import 'package:flutter_chat_app/core/services/animation_service.dart';

/// Widget hiển thị một mục chat trong danh sách
class ChatListItem extends StatelessWidget {
  /// Dữ liệu chat
  final Chat chat;
  
  /// Callback khi nhấn vào item
  final Function(Chat) onTap;
  
  /// Đang được chọn không
  final bool isSelected;
  
  /// Constructor
  const ChatListItem({
    Key? key,
    required this.chat,
    required this.onTap,
    this.isSelected = false,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    final animationService = GetIt.I<AnimationService>();
    final theme = Theme.of(context);
    
    // Format thời gian hiển thị
    final formattedTime = chat.lastMessageTime != null
        ? timeago.format(chat.lastMessageTime!, locale: 'vi')
        : '';
    
    return Material(
      color: isSelected
          ? theme.colorScheme.primaryContainer.withOpacity(0.3)
          : Colors.transparent,
      child: InkWell(
        onTap: () => onTap(chat),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              // Avatar với Hero animation + presence badge
              _buildAvatarWithPresence(context, theme),
              const SizedBox(width: 12),
              
              // Nội dung chat
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Dòng trên: Tên chat và thời gian
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Tên chat với Hero animation cho transition mượt mà
                        Hero(
                          tag: 'chat-name-${chat.id}',
                          child: Material(
                            color: Colors.transparent,
                            child: Text(
                              chat.name ?? 'Chat',
                              style: TextStyle(
                                fontWeight: chat.unreadCount > 0
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                fontSize: 16,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        
                        // Thời gian tin nhắn cuối
                        Text(
                          formattedTime,
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.textTheme.bodySmall?.color,
                            fontWeight: chat.unreadCount > 0
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 4),
                    
                    // Dòng dưới: Preview tin nhắn và số tin nhắn chưa đọc
                    Row(
                      children: [
                        // Preview tin nhắn
                        Expanded(
                          child: Text(
                            chat.lastMessagePreview ?? '',
                            style: TextStyle(
                              fontSize: 14,
                              color: theme.textTheme.bodyMedium?.color?.withOpacity(0.8),
                              fontWeight: chat.unreadCount > 0
                                  ? FontWeight.w500
                                  : FontWeight.normal,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        
                        // Số tin nhắn chưa đọc
                        if (chat.unreadCount > 0) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              chat.unreadCount.toString(),
                              style: TextStyle(
                                color: theme.colorScheme.onPrimary,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build avatar with presence indicator for direct chats
  Widget _buildAvatarWithPresence(BuildContext context, ThemeData theme) {
    // Only show presence for direct chats
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
        indicatorSize: 16.0,
        child: AppHeroAvatar(
          id: chat.id,
          imageUrl: chat.avatarUrl,
          displayName: chat.name,
          size: AvatarSize.large,
          hasBorder: true,
          borderColor: theme.colorScheme.primary,
        ),
      );
    }

    // For group chats, show normal avatar without presence
    return AppHeroAvatar(
      id: chat.id,
      imageUrl: chat.avatarUrl,
      displayName: chat.name,
      size: AvatarSize.large,
      hasBorder: true,
      borderColor: theme.colorScheme.primary,
    );
  }
} 