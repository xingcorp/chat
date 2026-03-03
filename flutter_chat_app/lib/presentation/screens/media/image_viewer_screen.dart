import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:get_it/get_it.dart';
import 'package:flutter_chat_app/core/constants/app_dimens.dart';
import 'package:flutter_chat_app/core/services/animation_service.dart';
import 'package:flutter_chat_app/core/services/image_editor_service.dart';
import 'package:flutter_chat_app/domain/usecases/media/save_media_to_gallery_usecase.dart';
import 'package:flutter_chat_app/shared/domain/entities/chat_message.dart'
    as domain;
import 'package:flutter_chat_app/features/chat/presentation/widgets/chat/reaction_bar.dart';
import 'package:flutter_chat_app/features/chat/presentation/widgets/chat/emoji_picker_widget.dart';
import 'package:flutter_chat_app/features/chat/presentation/widgets/chat/forward_message_sheet.dart';
import 'package:flutter_chat_app/features/chat/presentation/models/message_ui_state.dart';
import 'package:flutter_chat_app/core/services/current_user_provider.dart';
import 'package:flutter_chat_app/l10n/l10n.dart';
import 'package:flutter_chat_app/presentation/models/edited_image_result.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/feedback/app_snack_bar.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_chat_app/presentation/blocs/message/message_bloc.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';

class ImageViewerItem {
  final String imageUrl;
  final String heroTag;
  final String? title;

  const ImageViewerItem({
    required this.imageUrl,
    required this.heroTag,
    this.title,
  });
}

/// Màn hình xem hình ảnh với khả năng zoom và phóng to
/// Supports reactions and forwarding when ChatMessage is provided
class ImageViewerScreen extends StatefulWidget {
  final List<ImageViewerItem> images;

  final int initialIndex;

  /// Tiêu đề
  final String? title;

  /// Optional ChatMessage for reaction/forward support
  final domain.ChatMessage? message;

  /// Chat ID for forwarding
  final String? chatId;

  ImageViewerScreen({
    Key? key,
    required this.imageUrl,
    required this.heroTag,
    this.title,
    this.message,
    this.chatId,
  })  : images = <ImageViewerItem>[
          ImageViewerItem(
            imageUrl: imageUrl,
            heroTag: heroTag,
            title: title,
          ),
        ],
        initialIndex = 0,
        super(key: key);

  ImageViewerScreen.gallery({
    Key? key,
    required this.images,
    this.initialIndex = 0,
    this.title,
    this.message,
    this.chatId,
  })  : assert(images.isNotEmpty),
        assert(initialIndex >= 0),
        assert(initialIndex < images.length),
        imageUrl = '',
        heroTag = '',
        super(key: key);

  /// Legacy params kept for backward compatibility.
  final String imageUrl;
  final String heroTag;

  List<ImageViewerItem> get effectiveImages {
    if (images.isNotEmpty) return images;
    return <ImageViewerItem>[
      ImageViewerItem(
        imageUrl: imageUrl,
        heroTag: heroTag,
        title: title,
      ),
    ];
  }

  int get safeInitialIndex {
    final maxIndex = effectiveImages.length - 1;
    if (initialIndex < 0) return 0;
    if (initialIndex > maxIndex) return maxIndex;
    return initialIndex;
  }

  @override
  State<ImageViewerScreen> createState() => _ImageViewerScreenState();
}

class _ImageViewerScreenState extends State<ImageViewerScreen>
    with TickerProviderStateMixin {
  /// Lấy cấu hình animation
  final animationService = GetIt.I<AnimationService>();

  /// Controller cho animation
  late AnimationController _animationController;

  /// Animation cho background
  late Animation<Color?> _colorAnimation;

  /// Animation cho AppBar
  late Animation<double> _appBarOpacityAnimation;

  /// Animation cho bottom overlay
  late Animation<double> _bottomOverlayAnimation;

  late PageController _pageController;
  late ScrollController _thumbnailScrollController;
  late int _currentIndex;

  /// Có hiện UI không
  bool _showUI = true;

  List<ImageViewerItem> get _images => widget.effectiveImages;
  ImageViewerItem get _currentImage => _images[_currentIndex];

  static const double _thumbnailSize = 56.0;
  static const double _thumbnailSpacing = 8.0;

  @override
  void initState() {
    super.initState();

    // Cài đặt SystemUI cho trải nghiệm đắm chìm
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Colors.black,
      ),
    );

    // Thiết lập animation
    _animationController = AnimationController(
      vsync: this,
      duration: animationService.config.defaultDuration,
    );

    _colorAnimation = ColorTween(
      begin: Colors.black,
      end: Colors.black.withValues(alpha: 0.5),
    ).animate(_animationController);

    _appBarOpacityAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(_animationController);

    // Bottom overlay animation (slide up from bottom)
    _bottomOverlayAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    // Khởi tạo hiển thị UI
    _animationController.value = 0.0;

    _currentIndex = widget.safeInitialIndex;
    _pageController = PageController(initialPage: _currentIndex);
    _thumbnailScrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollThumbnailToCurrent(animate: false);
    });
  }

  @override
  void dispose() {
    // Reset SystemUI
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );

    _thumbnailScrollController.dispose();
    _pageController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _toggleUI() {
    setState(() {
      _showUI = !_showUI;
    });

    if (_showUI) {
      _animationController.reverse();
    } else {
      _animationController.forward();
    }
  }

  /// Resolve viewer filter quality with a floor to avoid blurry rendering.
  ///
  /// - Web/Desktop: force high quality for text-heavy screenshots.
  /// - Mobile: respect adaptive config but never go below medium.
  FilterQuality _resolveViewerFilterQuality(BuildContext context) {
    final configured = animationService.config.imageFilterQuality;
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= AppDimens.breakpointDesktop;

    if (kIsWeb || isDesktop) {
      return FilterQuality.high;
    }

    if (configured == FilterQuality.low || configured == FilterQuality.none) {
      return FilterQuality.medium;
    }

    return configured;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasMessage = widget.message != null;

    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(theme),
      body: GestureDetector(
        onTap: _toggleUI,
        behavior: HitTestBehavior.opaque,
        child: AnimatedBuilder(
          animation: _colorAnimation,
          builder: (context, child) {
            return Container(
              color: _colorAnimation.value,
              child: child,
            );
          },
          child: Stack(
            fit: StackFit.expand,
            children: [
              PhotoViewGallery.builder(
                pageController: _pageController,
                itemCount: _images.length,
                builder: (context, index) {
                  final image = _images[index];
                  return PhotoViewGalleryPageOptions(
                    imageProvider: CachedNetworkImageProvider(image.imageUrl),
                    initialScale: PhotoViewComputedScale.contained,
                    minScale: PhotoViewComputedScale.contained * 0.8,
                    maxScale: PhotoViewComputedScale.covered * 2.0,
                    filterQuality: _resolveViewerFilterQuality(context),
                    heroAttributes: image.heroTag.isNotEmpty
                        ? PhotoViewHeroAttributes(tag: image.heroTag)
                        : null,
                    scaleStateCycle: (currentState) {
                      if (currentState == PhotoViewScaleState.initial) {
                        return PhotoViewScaleState.covering;
                      }
                      return PhotoViewScaleState.initial;
                    },
                  );
                },
                onPageChanged: (index) {
                  setState(() {
                    _currentIndex = index;
                  });
                  _scrollThumbnailToCurrent();
                },
                scrollPhysics: const BouncingScrollPhysics(),
                backgroundDecoration: const BoxDecoration(
                  color: Colors.transparent,
                ),
                loadingBuilder: (context, event) {
                  if (event == null) {
                    return const SizedBox.shrink();
                  }

                  return Center(
                    child: CircularProgressIndicator(
                      value: event.expectedTotalBytes != null
                          ? event.cumulativeBytesLoaded /
                              event.expectedTotalBytes!
                          : null,
                      valueColor: AlwaysStoppedAnimation<Color>(
                          theme.colorScheme.primary),
                    ),
                  );
                },
              ),

              if (!hasMessage && _images.length > 1)
                _buildStandaloneThumbnailStrip(context),

              // Bottom overlay with forward/reaction bar (only if message provided)
              if (hasMessage) _buildBottomOverlay(context, theme),
            ],
          ),
        ),
      ),
    );
  }

  /// Tạo AppBar với animation và design system components
  PreferredSizeWidget _buildAppBar(ThemeData theme) {
    final topButtonStyle = IconButton.styleFrom(
      foregroundColor: Colors.white,
      backgroundColor: Colors.black.withValues(alpha: 0.45),
      minimumSize: const Size(40, 40),
      padding: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
    );

    return PreferredSize(
      preferredSize: const Size.fromHeight(kToolbarHeight),
      child: AnimatedBuilder(
        animation: _appBarOpacityAnimation,
        builder: (context, child) {
          return Opacity(
            opacity: _appBarOpacityAnimation.value,
            child: Theme(
              data: theme.copyWith(
                iconTheme: const IconThemeData(color: Colors.white),
                appBarTheme: const AppBarTheme(
                  iconTheme: IconThemeData(color: Colors.white),
                  actionsIconTheme: IconThemeData(color: Colors.white),
                  foregroundColor: Colors.white,
                ),
              ),
              child: AppBar(
                backgroundColor: Colors.black.withValues(alpha: 0.65),
                elevation: 0,
                foregroundColor: Colors.white,
                iconTheme: const IconThemeData(color: Colors.white),
                actionsIconTheme: const IconThemeData(color: Colors.white),
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                  tooltip: context.l10n.backOnline,
                  style: topButtonStyle,
                ),
                title: Text(
                  _images.length > 1
                      ? '${_currentIndex + 1} / ${_images.length}'
                      : (widget.title ??
                          _currentImage.title ??
                          context.l10n.imageMessage),
                  style: const TextStyle(color: Colors.white),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.white),
                    onPressed: _handleEdit,
                    tooltip: context.l10n.edit,
                    style: topButtonStyle,
                  ),
                  IconButton(
                    icon: const Icon(Icons.share, color: Colors.white),
                    onPressed: _handleShare,
                    tooltip: context.l10n.share,
                    style: topButtonStyle,
                  ),
                  IconButton(
                    icon: const Icon(Icons.download, color: Colors.white),
                    onPressed: _handleDownload,
                    tooltip: context.l10n.download,
                    style: topButtonStyle,
                  ),
                  PopupMenuButton<String>(
                    padding: EdgeInsets.zero,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.45),
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      child: const Icon(Icons.more_vert, color: Colors.white),
                    ),
                    onSelected: _handleMenuOption,
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            const Icon(Icons.edit, size: 20),
                            const SizedBox(width: 8),
                            Text(context.l10n.edit),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'info',
                        child: Text(context.l10n.imageMessage),
                      ),
                      PopupMenuItem(
                        value: 'save',
                        child: Text(context.l10n.download),
                      ),
                      if (widget.message != null)
                        PopupMenuItem(
                          value: 'forward',
                          child: Text(context.l10n.forward),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// Build bottom overlay with forward button and reaction bar
  Widget _buildBottomOverlay(BuildContext context, ThemeData theme) {
    final message = widget.message!;
    final groupedReactions = _groupReactions(
      message.reactions,
      unknownUserLabel: context.l10n.unknownUser,
    );

    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: AnimatedBuilder(
        animation: _bottomOverlayAnimation,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, 100 * (1.0 - _bottomOverlayAnimation.value)),
            child: Opacity(
              opacity: _bottomOverlayAnimation.value,
              child: child,
            ),
          );
        },
        child: Container(
          padding: EdgeInsets.only(
            left: 16.0,
            right: 16.0,
            top: 12.0,
            bottom: MediaQuery.of(context).padding.bottom + 12.0,
          ),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.6),
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(16.0)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_images.length > 1) ...[
                _buildThumbnailStrip(context),
                const SizedBox(height: 12.0),
              ],

              // Forward button row
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildActionButton(
                    icon: Icons.forward,
                    label: context.l10n.forward,
                    onTap: _handleForward,
                  ),
                  const SizedBox(width: 24.0),
                  _buildActionButton(
                    icon: Icons.emoji_emotions_outlined,
                    label: context.l10n.addReaction, // Using available key
                    onTap: () => _showReactionPicker(context),
                  ),
                ],
              ),

              // Reaction bar (if any reactions exist)
              if (groupedReactions.isNotEmpty) ...[
                const SizedBox(height: 12.0),
                ReactionBar(
                  groupedReactions: groupedReactions,
                  showAddButton: true,
                  onReactionTap: (
                    emojiCode,
                    reactorIds,
                    reactorNameById,
                    reactorAvatarById,
                  ) {
                    ReactionDetailModal.show(
                      context,
                      emojiCode: emojiCode,
                      reactorIds: reactorIds,
                      reactorNameById: reactorNameById,
                      reactorAvatarById: reactorAvatarById,
                    );
                  },
                  onReactionLongPress: (emojiCode, isCurrentlyReacted) {
                    if (isCurrentlyReacted && widget.message != null) {
                      context.read<MessageBloc>().add(
                            ToggleReaction(
                              messageId: widget.message!.id,
                              emojiCode: emojiCode,
                            ),
                          );
                    }
                  },
                  onAddReaction: () => _showReactionPicker(context),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStandaloneThumbnailStrip(BuildContext context) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: AnimatedBuilder(
        animation: _bottomOverlayAnimation,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, 100 * (1.0 - _bottomOverlayAnimation.value)),
            child: Opacity(
              opacity: _bottomOverlayAnimation.value,
              child: child,
            ),
          );
        },
        child: Container(
          padding: EdgeInsets.only(
            left: 12.0,
            right: 12.0,
            top: 10.0,
            bottom: MediaQuery.of(context).padding.bottom + 10.0,
          ),
          color: Colors.black.withValues(alpha: 0.45),
          child: _buildThumbnailStrip(context),
        ),
      ),
    );
  }

  Widget _buildThumbnailStrip(BuildContext context) {
    return SizedBox(
      height: _thumbnailSize,
      child: ListView.separated(
        controller: _thumbnailScrollController,
        scrollDirection: Axis.horizontal,
        itemCount: _images.length,
        separatorBuilder: (_, __) => const SizedBox(width: _thumbnailSpacing),
        itemBuilder: (context, index) {
          final image = _images[index];
          final isSelected = index == _currentIndex;

          return GestureDetector(
            onTap: () => _jumpToImage(index),
            child: AnimatedContainer(
              duration: animationService.config.fastDuration,
              width: _thumbnailSize,
              height: _thumbnailSize,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8.0),
                border: Border.all(
                  color: isSelected
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.4),
                  width: isSelected ? 2.0 : 1.0,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(7.0),
                child: CachedNetworkImage(
                  imageUrl: image.imageUrl,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: Colors.black26,
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: Colors.black26,
                    child: const Icon(
                      Icons.broken_image_outlined,
                      color: Colors.white70,
                      size: 18.0,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _jumpToImage(int index) async {
    if (index < 0 || index >= _images.length || index == _currentIndex) {
      return;
    }

    await _pageController.animateToPage(
      index,
      duration: animationService.config.fastDuration,
      curve: Curves.easeOutCubic,
    );
  }

  void _scrollThumbnailToCurrent({bool animate = true}) {
    if (!_thumbnailScrollController.hasClients || _images.length <= 1) {
      return;
    }

    final targetOffset =
        (_currentIndex * (_thumbnailSize + _thumbnailSpacing)) -
            ((_thumbnailScrollController.position.viewportDimension -
                    _thumbnailSize) /
                2);

    final clampedOffset = targetOffset.clamp(
      0.0,
      _thumbnailScrollController.position.maxScrollExtent,
    );

    if (animate) {
      _thumbnailScrollController.animateTo(
        clampedOffset,
        duration: animationService.config.fastDuration,
        curve: Curves.easeOutCubic,
      );
    } else {
      _thumbnailScrollController.jumpTo(clampedOffset);
    }
  }

  /// Build action button for bottom overlay
  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.0),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 24.0),
            const SizedBox(height: 4.0),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12.0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Group reactions by emoji code
  List<ReactionGroup> _groupReactions(
    List<domain.MessageReaction> reactions, {
    required String unknownUserLabel,
  }) {
    if (reactions.isEmpty) return const [];

    final currentUserInfo = _resolveCurrentUserInfo();
    final currentUserId = currentUserInfo.$1;
    final currentUserName = currentUserInfo.$2;
    final messageSender = widget.message?.sender;
    final messageSenderId = messageSender?.id.trim() ?? '';
    final messageSenderName = messageSender?.name.trim() ?? '';
    final groupedByCode = <String, List<String>>{};
    final nameByIdByCode = <String, Map<String, String>>{};

    for (final reaction in reactions) {
      final userId = reaction.userId.trim();
      if (userId.isEmpty) {
        continue;
      }

      groupedByCode.putIfAbsent(reaction.code, () => []).add(userId);
      nameByIdByCode.putIfAbsent(reaction.code, () => {})[userId] =
          _resolveReactorDisplayName(
        userId: userId,
        reactionName: reaction.userName,
        messageSenderId: messageSenderId,
        messageSenderName: messageSenderName,
        currentUserId: currentUserId,
        currentUserName: currentUserName,
        unknownUserLabel: unknownUserLabel,
      );
    }

    return groupedByCode.entries.map((entry) {
      return ReactionGroup(
        code: entry.key,
        reactorIds: entry.value,
        reactorNameById: nameByIdByCode[entry.key] ?? const {},
        reactorAvatarById: const {},
        isReactedByCurrentUser:
            currentUserId.isNotEmpty && entry.value.contains(currentUserId),
      );
    }).toList()
      ..sort((a, b) {
        if (a.isReactedByCurrentUser && !b.isReactedByCurrentUser) return -1;
        if (!a.isReactedByCurrentUser && b.isReactedByCurrentUser) return 1;
        return b.count.compareTo(a.count);
      });
  }

  (String, String?) _resolveCurrentUserInfo() {
    try {
      final provider = GetIt.I<CurrentUserProvider>();
      return (
        provider.currentUserId.trim(),
        provider.currentUser?.fullName?.trim(),
      );
    } catch (_) {
      return ('', null);
    }
  }

  String _resolveReactorDisplayName({
    required String userId,
    String? reactionName,
    required String messageSenderId,
    required String messageSenderName,
    required String currentUserId,
    String? currentUserName,
    required String unknownUserLabel,
  }) {
    final normalizedReactionName = reactionName?.trim();
    final normalizedCurrentUserName = currentUserName?.trim();

    if (normalizedReactionName != null &&
        normalizedReactionName.isNotEmpty &&
        normalizedReactionName != userId) {
      return normalizedReactionName;
    }
    if (userId == currentUserId &&
        normalizedCurrentUserName != null &&
        normalizedCurrentUserName.isNotEmpty) {
      return normalizedCurrentUserName;
    }
    if (userId == messageSenderId && messageSenderName.isNotEmpty) {
      return messageSenderName;
    }
    return unknownUserLabel;
  }

  /// Show reaction picker bottom sheet
  void _showReactionPicker(BuildContext context) {
    EmojiPickerBottomSheet.show(
      context,
      onEmojiSelected: (emoji) {
        if (widget.message != null) {
          context.read<MessageBloc>().add(
                ToggleReaction(
                  messageId: widget.message!.id,
                  emojiCode: emoji,
                ),
              );
        }
      },
    );
  }

  /// Handle share action
  void _handleShare() {
    // TODO: Implement share functionality
  }

  /// Handle download action
  Future<void> _handleDownload() async {
    final SaveMediaToGalleryUseCase saveMediaToGallery =
        GetIt.I<SaveMediaToGalleryUseCase>();

    final result = await saveMediaToGallery(
      SaveMediaToGalleryParams(
        url: _currentImage.imageUrl,
        mediaType: GalleryMediaType.image,
        mediaId: widget.message?.id,
      ),
    );

    if (!mounted) {
      return;
    }

    result.fold(
      (failure) => AppSnackBar.error(
        context: context,
        message: failure.userMessage,
      ),
      (_) => AppSnackBar.success(
        context: context,
        message: context.l10n.downloaded,
      ),
    );
  }

  /// Handle menu option selection
  void _handleMenuOption(String value) {
    switch (value) {
      case 'edit':
        _handleEdit();
        break;
      case 'info':
        // TODO: Show image info dialog
        break;
      case 'save':
        _handleDownload();
        break;
      case 'forward':
        _handleForward();
        break;
    }
  }

  /// Handle edit action - open image editor
  void _handleEdit() {
    final imageEditorService = GetIt.I<ImageEditorService>();

    imageEditorService.editNetworkImage(
      context,
      imageUrl: _currentImage.imageUrl,
      onComplete: (bytes) {
        if (!context.mounted) return;
        final fileName = 'edited_${DateTime.now().millisecondsSinceEpoch}.jpg';
        // Pop back to caller with edited bytes
        Navigator.of(context).pop(
          EditedImageResult(bytes: bytes, fileName: fileName),
        );
      },
    );
  }

  /// Handle forward action
  void _handleForward() {
    if (widget.message == null) return;

    showForwardMessageSheet(
      context,
      messages: [widget.message!],
      sourceChatId: widget.chatId,
    );
  }
}
