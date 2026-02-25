import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_chat_app/core/base/base_widget.dart';
import 'package:flutter_chat_app/core/constants/app_dimens.dart';
import 'package:flutter_chat_app/shared/domain/entities/chat.dart';
import 'package:flutter_chat_app/domain/entities/chat_info/shared_media.dart';
import 'package:flutter_chat_app/domain/entities/chat_info/notification_settings.dart';
import 'package:flutter_chat_app/presentation/blocs/chat_info/chat_info_bloc.dart';
import 'package:flutter_chat_app/presentation/blocs/chat_info/chat_info_event.dart';
import 'package:flutter_chat_app/presentation/blocs/chat_info/chat_info_state.dart';
import 'package:flutter_chat_app/presentation/widgets/chat_info/chat_info_header.dart';
import 'package:flutter_chat_app/presentation/widgets/chat_info/chat_info_shared_media_section.dart';
import 'package:flutter_chat_app/presentation/widgets/chat_info/chat_info_settings_section.dart';

/// Main Chat Info Panel widget
/// Displays comprehensive chat information including header, shared media, and settings
class ChatInfoPanel extends BaseStatefulWidget {
  final Chat chat;
  final VoidCallback? onClose;

  const ChatInfoPanel({
    super.key,
    required this.chat,
    this.onClose,
  });

  @override
  State<ChatInfoPanel> createState() => _ChatInfoPanelState();
}

class _ChatInfoPanelState extends BaseState<ChatInfoPanel> {
  // Local state
  bool _isMuted = false;
  bool _isBlocked = false;
  List<SharedMedia> _photos = [];
  List<SharedMedia> _videos = [];
  List<SharedMedia> _files = [];
  List<SharedMedia> _links = [];

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  void _loadInitialData() {
    final bloc = context.read<ChatInfoBloc>();

    // Load notification settings
    bloc.add(ChatInfoLoadNotificationSettings(chatId: widget.chat.id));

    // Load shared media for all types
    bloc.add(ChatInfoLoadSharedMedia(
      chatId: widget.chat.id,
      type: SharedMediaType.photo,
    ));
    bloc.add(ChatInfoLoadSharedMedia(
      chatId: widget.chat.id,
      type: SharedMediaType.video,
    ));
    bloc.add(ChatInfoLoadSharedMedia(
      chatId: widget.chat.id,
      type: SharedMediaType.file,
    ));
    bloc.add(ChatInfoLoadSharedMedia(
      chatId: widget.chat.id,
      type: SharedMediaType.link,
    ));

    // Check if user is blocked (for 1-1 chats)
    if (widget.chat.type == ChatType.direct) {
      // Assuming the other user ID is available in chat.otherUserId or similar
      // For now, we'll skip this check
      // bloc.add(ChatInfoCheckUserBlocked(userId: widget.chat.otherUserId));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ChatInfoBloc, ChatInfoState>(
      listener: (context, state) {
        // Handle state changes
        if (state is ChatInfoNotificationSettingsLoaded ||
            state is ChatInfoNotificationSettingsUpdated) {
          if (state is ChatInfoNotificationSettingsLoaded) {
            setState(() {
              _isMuted = state.settings.isMuted;
            });
          } else if (state is ChatInfoNotificationSettingsUpdated) {
            setState(() {
              _isMuted = state.settings.isMuted;
            });
            // Show success message
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(_isMuted
                    ? 'Notifications muted'
                    : 'Notifications unmuted'),
              ),
            );
          }
        }

        if (state is ChatInfoSharedMediaLoaded) {
          setState(() {
            switch (state.type) {
              case SharedMediaType.photo:
                _photos = state.media;
                break;
              case SharedMediaType.video:
                _videos = state.media;
                break;
              case SharedMediaType.file:
                _files = state.media;
                break;
              case SharedMediaType.link:
                _links = state.media;
                break;
            }
          });
        }

        if (state is ChatInfoUserBlockStatusChecked) {
          setState(() {
            _isBlocked = state.isBlocked;
          });
        }

        if (state is ChatInfoUserBlocked) {
          setState(() {
            _isBlocked = true;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('User blocked successfully')),
          );
        }

        if (state is ChatInfoUserUnblocked) {
          setState(() {
            _isBlocked = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('User unblocked successfully')),
          );
        }

        if (state is ChatInfoChatReported) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Chat reported successfully')),
          );
        }

        if (state is ChatInfoError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      child: Scaffold(
        body: CustomScrollView(
          slivers: [
            // Header with close button
            SliverAppBar(
              pinned: true,
              expandedHeight: 0,
              leading: IconButton(
                icon: Icon(Icons.close),
                onPressed: widget.onClose ?? () => Navigator.of(context).pop(),
              ),
              title: Text('Chat Info'),
            ),

            // Chat Info Header
            SliverToBoxAdapter(
              child: ChatInfoHeader(chat: widget.chat),
            ),

            SliverToBoxAdapter(
              child: SizedBox(height: AppDimens.spaceMedium),
            ),

            // Shared Media Section
            SliverToBoxAdapter(
              child: ChatInfoSharedMediaSection(
                photos: _photos,
                videos: _videos,
                files: _files,
                links: _links,
                onViewAllPhotos: () => _handleViewAllMedia(SharedMediaType.photo),
                onViewAllVideos: () => _handleViewAllMedia(SharedMediaType.video),
                onViewAllFiles: () => _handleViewAllMedia(SharedMediaType.file),
                onViewAllLinks: () => _handleViewAllMedia(SharedMediaType.link),
              ),
            ),

            SliverToBoxAdapter(
              child: SizedBox(height: AppDimens.spaceMedium),
            ),

            // Settings Section
            SliverToBoxAdapter(
              child: ChatInfoSettingsSection(
                isMuted: _isMuted,
                isBlocked: _isBlocked,
                isGroup: widget.chat.type == ChatType.group,
                onMuteToggle: _handleMuteToggle,
                onBlockToggle: _handleBlockToggle,
                onReport: _handleReport,
                onLeaveGroup: _handleLeaveGroup,
                onDeleteChat: _handleDeleteChat,
              ),
            ),

            // Bottom padding
            SliverToBoxAdapter(
              child: SizedBox(height: AppDimens.spaceLarge),
            ),
          ],
        ),
      ),
    );
  }

  // Event handlers
  void _handleMuteToggle() {
    final bloc = context.read<ChatInfoBloc>();
    if (_isMuted) {
      bloc.add(ChatInfoUnmuteNotifications(chatId: widget.chat.id));
    } else {
      // Show duration picker
      _showMuteDurationPicker();
    }
  }

  void _showMuteDurationPicker() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: EdgeInsets.all(AppDimens.paddingMedium),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.schedule),
              title: Text('1 hour'),
              onTap: () {
                Navigator.pop(context);
                _muteForDuration(MuteDuration.oneHour);
              },
            ),
            ListTile(
              leading: Icon(Icons.schedule),
              title: Text('8 hours'),
              onTap: () {
                Navigator.pop(context);
                _muteForDuration(MuteDuration.eightHours);
              },
            ),
            ListTile(
              leading: Icon(Icons.schedule),
              title: Text('1 day'),
              onTap: () {
                Navigator.pop(context);
                _muteForDuration(MuteDuration.oneDay);
              },
            ),
            ListTile(
              leading: Icon(Icons.block),
              title: Text('Forever'),
              onTap: () {
                Navigator.pop(context);
                _muteForDuration(MuteDuration.forever);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _muteForDuration(MuteDuration duration) {
    final bloc = context.read<ChatInfoBloc>();
    bloc.add(ChatInfoMuteNotifications(
      chatId: widget.chat.id,
      duration: duration,
    ));
  }

  void _handleBlockToggle() {
    // Show confirmation dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_isBlocked ? 'Unblock User?' : 'Block User?'),
        content: Text(
          _isBlocked
              ? 'Are you sure you want to unblock this user?'
              : 'Are you sure you want to block this user? You will no longer receive messages from them.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              final bloc = context.read<ChatInfoBloc>();
              // Note: We need the other user's ID here
              // For now, using chat.id as placeholder
              if (_isBlocked) {
                bloc.add(ChatInfoUnblockUser(userId: widget.chat.id));
              } else {
                bloc.add(ChatInfoBlockUser(userId: widget.chat.id));
              }
            },
            child: Text(_isBlocked ? 'Unblock' : 'Block'),
          ),
        ],
      ),
    );
  }

  void _handleReport() {
    // Show report dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Report Chat?'),
        content: Text(
          'Are you sure you want to report this chat? Our team will review it.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              final bloc = context.read<ChatInfoBloc>();
              bloc.add(ChatInfoReportChat(
                chatId: widget.chat.id,
                reason: 'Spam or abuse', // Could show a reason picker
              ));
            },
            child: Text('Report'),
          ),
        ],
      ),
    );
  }

  void _handleLeaveGroup() {
    // Show confirmation dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Leave Group?'),
        content: Text(
          'Are you sure you want to leave this group? You will no longer receive messages.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implement leave group logic
              // This would typically be handled by a different BLoC
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Leave group functionality coming soon')),
              );
            },
            child: Text('Leave'),
          ),
        ],
      ),
    );
  }

  void _handleDeleteChat() {
    // Show confirmation dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Chat?'),
        content: Text(
          'Are you sure you want to delete this chat? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implement delete chat logic
              // This would typically be handled by a different BLoC
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Delete chat functionality coming soon')),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _handleViewAllMedia(SharedMediaType type) {
    // TODO: Navigate to media gallery view
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('View all ${type.name} - Coming soon')),
    );
  }
}
