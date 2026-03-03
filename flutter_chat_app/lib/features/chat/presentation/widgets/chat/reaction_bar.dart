import 'package:flutter/material.dart';
import 'package:flutter_chat_app/features/chat/presentation/models/message_ui_state.dart';
import 'package:flutter_chat_app/l10n/l10n.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/media/app_avatar.dart';

/// Widget hiển thị reactions gom nhóm dưới message bubble
///
/// Khớp với:
/// - Angular: countReactions(), getUniqueReactors()
/// - stream_chat_flutter: reaction_bubble.dart + reaction_indicator.dart
///
/// Features:
/// - Hiển thị emoji với số lượng reactors
/// - Highlight emoji mà currentUser đã react
/// - Tap emoji → hiện modal danh sách reactors (như Messenger/WhatsApp)
/// - Long press emoji → toggle thu hồi reaction (nếu mình đã react)
/// - Tap "+" → hiện emoji picker để thêm reaction
/// - Smooth animations cho add/remove/scale effects
class ReactionBar extends StatelessWidget {
  /// Reactions đã gom nhóm theo emoji
  final List<ReactionGroup> groupedReactions;

  /// Callback khi user tap vào emoji để xem danh sách reactors (như Messenger/WhatsApp)
  /// Tham số: emoji code, reactor IDs, reactor names
  final void Function(
    String emojiCode,
    List<String> reactorIds,
    Map<String, String> reactorNameById,
    Map<String, String?> reactorAvatarById,
  )? onReactionTap;

  /// Callback khi user long press vào emoji để thu hồi reaction (nếu mình đã react)
  /// Tham số: emoji code, isCurrentlyReacted
  final void Function(String emojiCode, bool isCurrentlyReacted)?
      onReactionLongPress;

  /// Callback khi user tap nút "+" để thêm reaction mới
  final VoidCallback? onAddReaction;

  /// Hiển thị nút "+" để thêm reaction không
  final bool showAddButton;

  /// Tin nhắn có phải từ current user không (để điều chỉnh màu trên bubble primary)
  final bool isFromCurrentUser;

  const ReactionBar({
    Key? key,
    required this.groupedReactions,
    this.onReactionTap,
    this.onReactionLongPress,
    this.onAddReaction,
    this.showAddButton = true,
    this.isFromCurrentUser = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (groupedReactions.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.only(top: 6.0, bottom: 2.0),
      child: Wrap(
        spacing: 6.0,
        runSpacing: 6.0,
        children: [
          // Render từng reaction group với animation
          for (int i = 0; i < groupedReactions.length; i++)
            TweenAnimationBuilder<double>(
              duration: Duration(milliseconds: 200 + (i * 50)),
              curve: Curves.elasticOut,
              tween: Tween(begin: 0.0, end: 1.0),
              builder: (context, value, child) {
                final clamped = value.clamp(0.0, 1.0);
                return Transform.scale(
                  scale: clamped,
                  child: Opacity(
                    opacity: clamped,
                    child:
                        _buildReactionChip(context, theme, groupedReactions[i]),
                  ),
                );
              },
            ),

          // Nút "+" để thêm reaction
          if (showAddButton && onAddReaction != null)
            TweenAnimationBuilder<double>(
              duration:
                  Duration(milliseconds: 200 + (groupedReactions.length * 50)),
              curve: Curves.elasticOut,
              tween: Tween(begin: 0.0, end: 1.0),
              builder: (context, value, child) {
                final clamped = value.clamp(0.0, 1.0);
                return Transform.scale(
                  scale: clamped,
                  child: Opacity(
                    opacity: clamped,
                    child: _buildAddButton(context, theme),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildReactionChip(
    BuildContext context,
    ThemeData theme,
    ReactionGroup reaction,
  ) {
    final isReacted = reaction.isReactedByCurrentUser;
    // For current user's messages (blue bubble): use white-based colors for visibility
    // For other users' messages (light bubble): use primary-based colors
    final backgroundColor = isReacted
        ? (isFromCurrentUser
            ? theme.colorScheme.onPrimary.withValues(alpha: 0.25)
            : theme.colorScheme.primary.withValues(alpha: 0.15))
        : (isFromCurrentUser
            ? theme.colorScheme.onPrimary.withValues(alpha: 0.15)
            : theme.colorScheme.surfaceContainerHighest);
    final borderColor = isReacted
        ? (isFromCurrentUser
            ? theme.colorScheme.onPrimary.withValues(alpha: 0.6)
            : theme.colorScheme.primary)
        : theme.colorScheme.outline.withValues(alpha: 0.3);

    return _AnimatedReactionChip(
      isReacted: isReacted,
      backgroundColor: backgroundColor,
      borderColor: borderColor,
      // Tap → xem danh sách reactors (như Messenger/WhatsApp)
      onTap: () => onReactionTap?.call(
        reaction.code,
        reaction.reactorIds,
        reaction.reactorNameById,
        reaction.reactorAvatarById,
      ),
      // Long press → thu hồi reaction (nếu mình đã react)
      onLongPress: () => onReactionLongPress?.call(reaction.code, isReacted),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Emoji
          Text(
            reaction.code,
            style: const TextStyle(fontSize: 18.0),
          ),
          const SizedBox(width: 4.0),
          // Số lượng reactors
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 200),
            style: TextStyle(
              fontSize: 13.0,
              fontWeight: isReacted ? FontWeight.w700 : FontWeight.w500,
              // For current user's messages: use onPrimary (white) text
              // For other users' messages: use primary (blue) for reacted, default otherwise
              color: isReacted
                  ? (isFromCurrentUser
                      ? theme.colorScheme.onPrimary
                      : theme.colorScheme.primary)
                  : (isFromCurrentUser
                      ? theme.colorScheme.onPrimary.withValues(alpha: 0.9)
                      : theme.textTheme.bodyMedium?.color),
            ),
            child: Text('${reaction.count}'),
          ),
        ],
      ),
    );
  }

  Widget _buildAddButton(BuildContext context, ThemeData theme) {
    // For current user's messages: use white-based colors
    final bgColor = isFromCurrentUser
        ? theme.colorScheme.onPrimary.withValues(alpha: 0.15)
        : theme.colorScheme.surfaceContainerHighest;
    final borderColor = isFromCurrentUser
        ? theme.colorScheme.onPrimary.withValues(alpha: 0.4)
        : theme.colorScheme.outline.withValues(alpha: 0.3);
    final iconColor = isFromCurrentUser
        ? theme.colorScheme.onPrimary.withValues(alpha: 0.8)
        : theme.colorScheme.onSurfaceVariant;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onAddReaction,
        borderRadius: BorderRadius.circular(16.0),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 32.0,
          height: 32.0,
          decoration: BoxDecoration(
            color: bgColor,
            border: Border.all(
              color: borderColor,
              width: 1.0,
            ),
            borderRadius: BorderRadius.circular(16.0),
          ),
          child: Icon(
            Icons.add_rounded,
            size: 18.0,
            color: iconColor,
          ),
        ),
      ),
    );
  }
}

/// Animated wrapper cho reaction chip với scale effect khi tap
class _AnimatedReactionChip extends StatefulWidget {
  final bool isReacted;
  final Color backgroundColor;
  final Color borderColor;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final Widget child;

  const _AnimatedReactionChip({
    required this.isReacted,
    required this.backgroundColor,
    required this.borderColor,
    this.onTap,
    this.onLongPress,
    required this.child,
  });

  @override
  State<_AnimatedReactionChip> createState() => _AnimatedReactionChipState();
}

class _AnimatedReactionChipState extends State<_AnimatedReactionChip>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.9).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    _controller.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    _controller.reverse();
    widget.onTap?.call();
  }

  void _handleTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ScaleTransition(
      scale: _scaleAnimation,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTapDown: _handleTapDown,
          onTapUp: _handleTapUp,
          onTapCancel: _handleTapCancel,
          onLongPress: widget.onLongPress,
          borderRadius: BorderRadius.circular(16.0),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            padding:
                const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
            decoration: BoxDecoration(
              color: widget.backgroundColor,
              border: Border.all(
                color: widget.borderColor,
                width: widget.isReacted ? 1.5 : 1.0,
              ),
              borderRadius: BorderRadius.circular(16.0),
              boxShadow: widget.isReacted
                  ? [
                      BoxShadow(
                        color: theme.colorScheme.primary.withValues(alpha: 0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ]
                  : null,
            ),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

/// Modal hiển thị danh sách người react một emoji cụ thể
///
/// Khớp Angular: hiển thị reactors[] với fullName
/// Enhanced với slide animation và better UI
class ReactionDetailModal extends StatefulWidget {
  final String emojiCode;
  final List<String> reactorIds;

  final Map<String, String> reactorNameById;

  final Map<String, String?> reactorAvatarById;

  const ReactionDetailModal({
    Key? key,
    required this.emojiCode,
    required this.reactorIds,
    this.reactorNameById = const {},
    this.reactorAvatarById = const {},
  }) : super(key: key);

  @override
  State<ReactionDetailModal> createState() => _ReactionDetailModalState();

  /// Helper method để show modal
  static Future<void> show(
    BuildContext context, {
    required String emojiCode,
    required List<String> reactorIds,
    Map<String, String> reactorNameById = const {},
    Map<String, String?> reactorAvatarById = const {},
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ReactionDetailModal(
        emojiCode: emojiCode,
        reactorIds: reactorIds,
        reactorNameById: reactorNameById,
        reactorAvatarById: reactorAvatarById,
      ),
    );
  }
}

class _ReactionDetailModalState extends State<ReactionDetailModal>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic,
      ),
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _handleClose() async {
    await _animationController.reverse();
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final screenHeight = MediaQuery.of(context).size.height;

    return GestureDetector(
      onTap: _handleClose,
      child: Container(
        color: Colors.black.withValues(alpha: 0.5),
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: GestureDetector(
                onTap: () {}, // Prevent closing when tapping on modal content
                child: Container(
                  constraints: BoxConstraints(
                    maxHeight: screenHeight * 0.6,
                  ),
                  decoration: BoxDecoration(
                    color: theme.scaffoldBackgroundColor,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(24.0),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 16,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Drag handle
                      Container(
                        margin: const EdgeInsets.only(top: 12.0),
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: theme.dividerColor,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),

                      // Header
                      Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8.0),
                              decoration: BoxDecoration(
                                color:
                                    theme.colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(12.0),
                              ),
                              child: Text(
                                widget.emojiCode,
                                style: const TextStyle(fontSize: 28.0),
                              ),
                            ),
                            const SizedBox(width: 12.0),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Reactions',
                                    style: theme.textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  Text(
                                    '${widget.reactorIds.length} ${widget.reactorIds.length == 1 ? 'person' : 'people'}',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: theme.textTheme.bodySmall?.color,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close_rounded),
                              onPressed: _handleClose,
                              style: IconButton.styleFrom(
                                backgroundColor:
                                    theme.colorScheme.surfaceContainerHighest,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const Divider(height: 1),

                      // Danh sách reactors
                      Flexible(
                        child: widget.reactorIds.isEmpty
                            ? Padding(
                                padding: const EdgeInsets.all(32.0),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.sentiment_neutral_rounded,
                                      size: 48,
                                      color: theme.disabledColor,
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      l10n.noUsers,
                                      style:
                                          theme.textTheme.bodyLarge?.copyWith(
                                        color: theme.textTheme.bodySmall?.color,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : ListView.builder(
                                shrinkWrap: true,
                                padding: const EdgeInsets.only(bottom: 20.0),
                                itemCount: widget.reactorIds.length,
                                itemBuilder: (context, index) {
                                  final userId = widget.reactorIds[index];
                                  final name = _resolveDisplayName(
                                    userId,
                                    l10n.unknownUser,
                                  );
                                  final avatarUrl =
                                      widget.reactorAvatarById[userId];
                                  return TweenAnimationBuilder<double>(
                                    duration: Duration(
                                      milliseconds: 300 + (index * 50),
                                    ),
                                    curve: Curves.easeOutCubic,
                                    tween: Tween(begin: 0.0, end: 1.0),
                                    builder: (context, value, child) {
                                      return Transform.translate(
                                        offset: Offset(30 * (1 - value), 0),
                                        child: Opacity(
                                          opacity: value,
                                          child: child,
                                        ),
                                      );
                                    },
                                    child: ListTile(
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                        horizontal: 20.0,
                                        vertical: 4.0,
                                      ),
                                      leading: Hero(
                                        tag: 'reactor_avatar_$userId',
                                        child: (avatarUrl != null &&
                                                avatarUrl.trim().isNotEmpty)
                                            ? AppAvatar.network(
                                                imageUrl: avatarUrl.trim(),
                                                size: AvatarSize.medium,
                                              )
                                            : AppAvatar.initials(
                                                name: name.isNotEmpty
                                                    ? name
                                                    : '?',
                                                size: AvatarSize.medium,
                                                backgroundColor:
                                                    _getAvatarColor(
                                                  theme,
                                                  index,
                                                ),
                                                foregroundColor: Colors.white,
                                              ),
                                      ),
                                      title: Text(
                                        name,
                                        style:
                                            theme.textTheme.bodyLarge?.copyWith(
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      trailing: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12.0,
                                          vertical: 6.0,
                                        ),
                                        decoration: BoxDecoration(
                                          color: theme.colorScheme
                                              .surfaceContainerHighest,
                                          borderRadius:
                                              BorderRadius.circular(12.0),
                                        ),
                                        child: Text(
                                          widget.emojiCode,
                                          style:
                                              const TextStyle(fontSize: 16.0),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color _getAvatarColor(ThemeData theme, int index) {
    final colors = [
      theme.colorScheme.primary,
      theme.colorScheme.secondary,
      theme.colorScheme.tertiary,
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
    ];
    return colors[index % colors.length];
  }

  String _resolveDisplayName(String userId, String unknownUserLabel) {
    final mappedName = widget.reactorNameById[userId]?.trim();
    if (mappedName != null && mappedName.isNotEmpty && mappedName != userId) {
      return mappedName;
    }

    if (!_looksLikeOpaqueUserId(userId)) {
      return userId;
    }
    return unknownUserLabel;
  }

  bool _looksLikeOpaqueUserId(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return true;

    final uuidRegex = RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-5][0-9a-fA-F]{3}'
      r'-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$',
    );
    return uuidRegex.hasMatch(trimmed);
  }
}
