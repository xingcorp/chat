import 'package:flutter/material.dart';
import 'package:flutter_chat_app/l10n/l10n.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/media/media.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/indicators/user_presence_indicator.dart';
import 'package:flutter_chat_app/core/services/current_user_provider.dart';
import 'package:flutter_chat_app/shared/domain/entities/chat.dart';
import 'package:flutter_chat_app/presentation/widgets/common/hero_avatar.dart';
import 'package:get_it/get_it.dart';

/// Header cho màn hình chi tiết chat
class ChatHeader extends StatelessWidget implements PreferredSizeWidget {
  /// Dữ liệu chat
  final Chat chat;
  
  /// Callback khi nhấn nút back
  final VoidCallback? onBackPressed;
  
  /// Callback khi nhấn vào avatar
  final VoidCallback? onAvatarTap;
  
  /// Callback khi nhấn vào nút thông tin
  final VoidCallback? onInfoPressed;
  
  /// Constructor
  const ChatHeader({
    Key? key,
    required this.chat,
    this.onBackPressed,
    this.onAvatarTap,
    this.onInfoPressed,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return AppBar(
      titleSpacing: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: onBackPressed ?? () => Navigator.of(context).pop(),
      ),
      title: Row(
        children: [
          // Avatar với Hero animation từ danh sách chat
          GestureDetector(
            onTap: onAvatarTap,
            child: UserPresenceBadge(
              isConnected: _getIsConnected(),
              lastSeenAt: _getLastSeenAt(),
              indicatorSize: 14.0,
              child: AppHeroAvatar(
                id: chat.id,
                imageUrl: chat.avatarUrl,
                displayName: chat.name,
                size: AvatarSize.medium,
                hasBorder: true,
              ),
            ),
          ),
          
          const SizedBox(width: 12),
          
          // Tên chat với Hero animation
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Hero(
                  tag: 'chat-name-${chat.id}',
                  child: Material(
                    color: Colors.transparent,
                    child: Text(
                      chat.name ?? context.l10n.chats,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                
                // Trạng thái (online/offline, đang nhập,...)
                _buildStatusText(context, theme),
              ],
            ),
          ),
        ],
      ),
      actions: [
        // Nút thông tin chat
        IconButton(
          icon: const Icon(Icons.info_outline),
          onPressed: onInfoPressed,
        ),
      ],
    );
  }
  
  /// Hiển thị trạng thái chat
  Widget _buildStatusText(BuildContext context, ThemeData theme) {
    // For direct chat (1-1), show other user's presence
    // For group chat, show member count
    if (chat.type == ChatType.direct && chat.members.isNotEmpty) {
      final currentUserId = GetIt.instance<CurrentUserProvider>().currentUserId;

      // Get other user (not current user)
      final otherMember = chat.members.firstWhere(
        (m) => m.userId != currentUserId,
        orElse: () => chat.members.first,
      );

      return UserPresenceText(
        isConnected: otherMember.isConnected,
        lastSeenAt: otherMember.viewMessagesFrom,
      );
    }

    // Group chat: show member count
    return Text(
      '${chat.members.length} ${context.l10n.members}',
      style: TextStyle(
        fontSize: 12,
        color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
      ),
    );
  }

  /// Get isConnected for direct chat (other user)
  bool _getIsConnected() {
    if (chat.type != ChatType.direct || chat.members.isEmpty) {
      return false;
    }

    final currentUserId = GetIt.instance<CurrentUserProvider>().currentUserId;

    // Get other user (not self)
    final otherMember = chat.members.firstWhere(
      (m) => m.userId != currentUserId,
      orElse: () => chat.members.first,
    );

    return otherMember.isConnected;
  }

  /// Get lastSeenAt for direct chat (other user)
  DateTime? _getLastSeenAt() {
    if (chat.type != ChatType.direct || chat.members.isEmpty) {
      return null;
    }

    final currentUserId = GetIt.instance<CurrentUserProvider>().currentUserId;

    final otherMember = chat.members.firstWhere(
      (m) => m.userId != currentUserId,
      orElse: () => chat.members.first,
    );

    return otherMember.viewMessagesFrom;
  }
  
  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
} 