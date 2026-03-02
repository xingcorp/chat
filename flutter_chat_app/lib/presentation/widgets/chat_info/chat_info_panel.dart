import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_chat_app/core/base/base_widget.dart';
import 'package:flutter_chat_app/core/constants/app_dimens.dart';
import 'package:flutter_chat_app/core/di/injection.dart';
import 'package:flutter_chat_app/core/services/current_user_provider.dart';
import 'package:flutter_chat_app/domain/entities/chat_info/notification_settings.dart';
import 'package:flutter_chat_app/domain/entities/chat_info/shared_media.dart';
import 'package:flutter_chat_app/features/chat/domain/repositories/i_chat_repository.dart';
import 'package:flutter_chat_app/l10n/l10n.dart';
import 'package:flutter_chat_app/presentation/blocs/chat_info/chat_info_bloc.dart';
import 'package:flutter_chat_app/presentation/blocs/chat_info/chat_info_event.dart';
import 'package:flutter_chat_app/presentation/blocs/chat_info/chat_info_state.dart';
import 'package:flutter_chat_app/presentation/blocs/conversation_detail/conversation_detail_bloc.dart';
import 'package:flutter_chat_app/presentation/blocs/conversation_detail/conversation_detail_event.dart';
import 'package:flutter_chat_app/presentation/blocs/conversation_detail/conversation_detail_state.dart';
import 'package:flutter_chat_app/presentation/pages/chat_members_page.dart';
import 'package:flutter_chat_app/presentation/pages/group_edit_page.dart';
import 'package:flutter_chat_app/presentation/pages/shared_media_gallery_page.dart';
import 'package:flutter_chat_app/presentation/widgets/chat_info/chat_info_header.dart';
import 'package:flutter_chat_app/presentation/widgets/chat_info/chat_info_members_section.dart';
import 'package:flutter_chat_app/presentation/widgets/chat_info/chat_info_settings_section.dart';
import 'package:flutter_chat_app/presentation/widgets/chat_info/chat_info_shared_media_section.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/typography/app_text.dart';
import 'package:flutter_chat_app/shared/domain/entities/chat.dart';

/// Main Chat Info Panel widget
/// Displays comprehensive chat information including header, shared media, and settings
class ChatInfoPanel extends BaseStatefulWidget {
  final Chat chat;
  final VoidCallback? onClose;
  final String? currentUserId;

  const ChatInfoPanel({
    super.key,
    required this.chat,
    this.onClose,
    this.currentUserId,
  });

  @override
  State<ChatInfoPanel> createState() => _ChatInfoPanelState();
}

class _ChatInfoPanelState extends BaseState<ChatInfoPanel> {
  static const String _editGroupMenuAction = 'edit_group';

  // Local state
  late Chat _chat;
  bool _isMuted = false;
  bool _isBlocked = false;
  List<SharedMedia> _photos = [];
  List<SharedMedia> _videos = [];
  List<SharedMedia> _files = [];
  List<SharedMedia> _links = [];
  final IChatRepository _chatRepository = getIt<IChatRepository>();

  @override
  void initState() {
    super.initState();
    _chat = widget.chat;
    _hydrateFromConversationDetailState();
    _loadInitialData();
    _refreshConversationDetail();
    _refreshMembersForAdminPermission();
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

  void _hydrateFromConversationDetailState() {
    final state = context.read<ConversationDetailBloc>().state;
    if (state is! ConversationDetailLoaded) return;
    if (state.chat.id != widget.chat.id) return;
    _chat = state.chat;
  }

  void _refreshConversationDetail() {
    context.read<ConversationDetailBloc>().add(
          LoadConversationDetail(chatId: widget.chat.id),
        );
  }

  Future<void> _refreshMembersForAdminPermission() async {
    final result = await _chatRepository.getConversationMembers(widget.chat.id);
    if (!mounted) return;

    result.fold(
      (_) {},
      (chat) {
        safeSetState(() {
          _chat = _chat.copyWith(
            members: chat.members,
            creatorId: chat.creatorId ?? _chat.creatorId,
            creatorName: chat.creatorName ?? _chat.creatorName,
            createdAt: chat.createdAt ?? _chat.createdAt,
          );
        });
      },
    );
  }

  bool get _isCurrentUserGroupAdmin {
    if (_chat.type != ChatType.group) return false;
    final currentUserId = (widget.currentUserId?.trim().isNotEmpty ?? false)
        ? widget.currentUserId!.trim()
        : getIt<CurrentUserProvider>().currentUserId;
    if (currentUserId.isEmpty) return false;
    return _isUserAdminInChat(currentUserId);
  }

  bool _isUserAdminInChat(String userId) {
    return _chat.members.any(
      (member) => member.userId == userId && member.isAdmin,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ConversationDetailBloc, ConversationDetailState>(
      listener: (context, convState) {
        if (convState is ConversationDetailLoaded) {
          setState(() {
            _chat = convState.chat;
          });
        }
      },
      child: BlocListener<ChatInfoBloc, ChatInfoState>(
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
                  onPressed:
                      widget.onClose ?? () => Navigator.of(context).pop(),
                ),
                title: AppText(context.l10n.chatInfo),
                actions: [
                  if (_isCurrentUserGroupAdmin)
                    PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == _editGroupMenuAction) {
                          _handleEditGroup();
                        }
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem<String>(
                          value: _editGroupMenuAction,
                          child: AppText(context.l10n.editGroup),
                        ),
                      ],
                    ),
                ],
              ),

              // Chat Info Header
              SliverToBoxAdapter(
                child: ChatInfoHeader(chat: _chat),
              ),

              // Members Section (for group chats)
              if (_chat.type == ChatType.group) ...[
                SliverToBoxAdapter(
                  child: ChatInfoMembersSection(
                    chat: _chat,
                    onTap: () => _handleViewMembers(context),
                  ),
                ),
                SliverToBoxAdapter(
                  child: SizedBox(height: AppDimens.spaceMedium),
                ),
              ],

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
                  onViewAllPhotos: () =>
                      _handleViewAllMedia(SharedMediaType.photo),
                  onViewAllVideos: () =>
                      _handleViewAllMedia(SharedMediaType.video),
                  onViewAllFiles: () =>
                      _handleViewAllMedia(SharedMediaType.file),
                  onViewAllLinks: () =>
                      _handleViewAllMedia(SharedMediaType.link),
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
                SnackBar(
                    content: Text('Leave group functionality coming soon')),
              );
            },
            child: Text('Leave'),
          ),
        ],
      ),
    );
  }

  void _handleViewMembers(BuildContext context) {
    final convDetailBloc = context.read<ConversationDetailBloc>();
    final chatId = _chat.id;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatMembersPage(
          chat: _chat,
        ),
      ),
    ).then((_) {
      // Refresh conversation detail when returning from members page
      if (mounted) {
        convDetailBloc.add(LoadConversationDetail(chatId: chatId));
      }
    });
  }

  void _handleEditGroup() {
    final convDetailBloc = context.read<ConversationDetailBloc>();
    final chatId = _chat.id;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GroupEditPage(chat: _chat),
      ),
    ).then((_) {
      if (!mounted) return;
      convDetailBloc.add(LoadConversationDetail(chatId: chatId));
    });
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
                SnackBar(
                    content: Text('Delete chat functionality coming soon')),
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
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SharedMediaGalleryPage(
          chatId: widget.chat.id,
          chatName: widget.chat.name ?? 'Chat',
          initialPhotos: _photos,
          initialVideos: _videos,
          initialFiles: _files,
          initialLinks: _links,
          initialTab: type,
          onLoadMore: _loadMoreMedia,
        ),
      ),
    );
  }

  Future<List<SharedMedia>> _loadMoreMedia(
    String chatId,
    SharedMediaType type,
    int offset,
  ) async {
    final bloc = context.read<ChatInfoBloc>();

    // Load more media via BLoC
    bloc.add(ChatInfoLoadSharedMedia(
      chatId: chatId,
      type: type,
      offset: offset,
    ));

    // Return current list (in real implementation, would wait for state update)
    return _getMediaListForType(type);
  }

  List<SharedMedia> _getMediaListForType(SharedMediaType type) {
    switch (type) {
      case SharedMediaType.photo:
        return _photos;
      case SharedMediaType.video:
        return _videos;
      case SharedMediaType.file:
        return _files;
      case SharedMediaType.link:
        return _links;
    }
  }
}
