import 'package:flutter/material.dart';
import 'package:flutter_chat_app/l10n/l10n.dart';
import 'package:flutter_chat_app/shared/domain/entities/chat.dart';
import 'package:flutter_chat_app/presentation/widgets/common/hero_avatar.dart';

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
            child: HeroAvatar(
              id: chat.id,
              imageUrl: chat.avatarUrl,
              displayName: chat.name,
              size: 40,
              hasBorder: true,
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
    // Đây là một placeholder, trong triển khai thực tế cần lấy trạng thái từ user service
    // hoặc connectivity service
    const bool isOnline = true;
    
    return Text(
      isOnline ? context.l10n.online : context.l10n.offline,
      style: TextStyle(
        fontSize: 12,
        color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
      ),
    );
  }
  
  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
} 