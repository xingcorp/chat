import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_chat_app/core/constants/app_icons.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/media/app_icon.dart';
import 'package:get_it/get_it.dart';
import 'package:flutter_chat_app/domain/services/file_download_state.dart';
import 'package:flutter_chat_app/domain/services/i_file_download_manager.dart';
import 'package:flutter_chat_app/domain/usecases/media/save_media_to_gallery_usecase.dart';
import 'package:flutter_chat_app/presentation/blocs/message/message_bloc.dart';
import 'package:flutter_chat_app/presentation/models/edited_image_result.dart';
import 'package:flutter_chat_app/presentation/screens/media/image_viewer_screen.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/feedback/app_snack_bar.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/media/app_chat_image_gallery.dart';
import 'package:flutter_chat_app/shared/domain/entities/chat_message.dart';
import 'package:flutter_chat_app/features/chat/presentation/widgets/chat/video_player_widget.dart';
import 'package:flutter_chat_app/l10n/l10n.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Widget hiển thị media gallery cho message attachments

///
/// Khớp với:
/// - Angular: urls[] array rendering per ChatMessageType
/// - stream_chat_flutter: gallery_attachment patterns
///
/// Features:
/// - Image grid: 1 = full width, 2 = 2 columns, 3+ = 2x2 grid + counter
/// - Video thumbnails với play icon
/// - Tap → fullscreen gallery với swipe
/// - Zoom/pinch support
/// - Optional ChatMessage for reactions and forwarding
class MediaGallery extends StatelessWidget {
  /// Danh sách attachments
  final List<MessageAttachment> attachments;

  /// Layout mode: grid hoặc list
  final MediaGalleryLayout layout;

  /// Optional ChatMessage for reactions and forwarding in fullscreen view
  final ChatMessage? message;

  /// Chat ID for forwarding
  final String? chatId;

  final bool isFromCurrentUser;

  final bool isOnPrimaryBackground;

  /// Callback when user edits an image and wants to send it
  final void Function(Uint8List editedBytes, String fileName)?
      onEditedImageSend;

  /// Side-channel progress notifier from [MessageBloc.uploadProgressNotifier].
  /// Key: attachment ID (e.g. "local_<clientId>_<index>"), Value: 0.0…1.0.
  /// When non-null, progress overlays use [ValueListenableBuilder] on this
  /// notifier instead of the static [MessageAttachment.uploadProgress] field,
  /// avoiding full BLoC state rebuilds on every progress tick.
  final ValueNotifier<Map<String, double>>? progressNotifier;

  const MediaGallery({
    Key? key,
    required this.attachments,
    this.layout = MediaGalleryLayout.grid,
    this.message,
    this.chatId,
    this.isFromCurrentUser = false,
    this.isOnPrimaryBackground = false,
    this.onEditedImageSend,
    this.progressNotifier,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (attachments.isEmpty) return const SizedBox.shrink();

    // Lọc attachments theo type
    final images = attachments.where(_isImageAttachment).toList();
    final videos = attachments.where(_isVideoAttachment).toList();
    final files = attachments
        .where((a) => !_isImageAttachment(a) && !_isVideoAttachment(a))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Image grid
        if (images.isNotEmpty) _buildImageGrid(context, images),

        // Video list
        if (videos.isNotEmpty) ...[
          if (images.isNotEmpty) const SizedBox(height: 8.0),
          _buildVideoList(context, videos),
        ],

        // File list
        if (files.isNotEmpty) ...[
          if (images.isNotEmpty || videos.isNotEmpty)
            const SizedBox(height: 8.0),
          _buildFileList(context, files),
        ],
      ],
    );
  }

  bool _isImageAttachment(MessageAttachment attachment) {
    final normalizedType = attachment.type.trim().toLowerCase();
    return normalizedType == 'image' || normalizedType.startsWith('image/');
  }

  bool _isVideoAttachment(MessageAttachment attachment) {
    final normalizedType = attachment.type.trim().toLowerCase();
    return normalizedType == 'video' || normalizedType.startsWith('video/');
  }

  /// Build image grid theo pattern design-system dùng chung.
  Widget _buildImageGrid(BuildContext context, List<MessageAttachment> images) {
    if (images.isEmpty) return const SizedBox.shrink();

    return AppChatImageGallery(
      images: images
          .map(
            (image) => AppChatImageGalleryItem(
              id: image.id,
              url: image.url,
              localPath: image.localPath,
              localBytes: image.localBytes,
              isUploading: image.isUploading,
              uploadProgress: image.uploadProgress ?? 0.0,
              originalWidth: image.originalWidth,
              originalHeight: image.originalHeight,
            ),
          )
          .toList(growable: false),
      onImageTap: (index) => _openFullscreenGallery(
        context,
        attachments: images,
        initialIndex: index,
      ),
      progressNotifier: progressNotifier,
    );
  }

  /// Build circular upload progress indicator (like WhatsApp/Telegram)
  Widget _buildUploadProgressIndicator(double progress) {
    final percentage = (progress * 100).toInt();

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.5),
        shape: BoxShape.circle,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 40,
            height: 40,
            child: CircularProgressIndicator(
              value: progress > 0 ? progress : null, // Indeterminate if 0
              strokeWidth: 3.0,
              backgroundColor: Colors.white.withValues(alpha: 0.3),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          if (progress > 0)
            Text(
              '$percentage%',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
        ],
      ),
    );
  }

  /// Builds a widget that reads live upload progress from [progressNotifier].
  ///
  /// If [progressNotifier] is available, wraps [builder] in a
  /// [ValueListenableBuilder] so only this tiny sub-tree rebuilds on every
  /// progress tick — the rest of the message list stays untouched.
  /// Falls back to the static [fallbackProgress] from the BLoC snapshot.
  Widget _buildLiveUploadProgress({
    required String attachmentId,
    required double fallbackProgress,
    required Widget Function(double progress) builder,
  }) {
    final notifier = progressNotifier;
    if (notifier == null) {
      return builder(fallbackProgress);
    }

    return ValueListenableBuilder<Map<String, double>>(
      valueListenable: notifier,
      builder: (_, progressMap, __) {
        final liveProgress = progressMap[attachmentId] ?? fallbackProgress;
        return builder(liveProgress);
      },
    );
  }

  /// Build video list
  Widget _buildVideoList(BuildContext context, List<MessageAttachment> videos) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: videos.map((video) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 4.0),
          child: _buildVideoTile(context, video),
        );
      }).toList(),
    );
  }

  /// Build single video tile
  Widget _buildVideoTile(BuildContext context, MessageAttachment video) {
    final isUploading = video.isUploading;

    if (!isUploading) {
      return VideoPlayerWidget(
        url: video.url,
        isFromCurrentUser: isFromCurrentUser,
      );
    }

    return Container(
      height: 180,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: Container(
              color: Colors.grey[850],
              alignment: Alignment.center,
              child: AppIcon.svg(
                AppIcons.video,
                color: Colors.white54,
                size: 48,
              ),
            ),
          ),
          Positioned.fill(
            child: Container(
              color: Colors.black.withValues(alpha: 0.4),
              child: Center(
                child: _buildLiveUploadProgress(
                  attachmentId: video.id,
                  fallbackProgress: video.uploadProgress ?? 0.0,
                  builder: _buildUploadProgressIndicator,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build file list
  Widget _buildFileList(BuildContext context, List<MessageAttachment> files) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: files.map((file) {
        return _buildFileTile(context, file);
      }).toList(),
    );
  }

  /// Build single file tile
  /// Supports upload progress indicator like image tiles
  Widget _buildFileTile(BuildContext context, MessageAttachment file) {
    final IFileDownloadManager downloadManager =
        GetIt.I<IFileDownloadManager>();
    final String downloadKey = _buildAttachmentDownloadKey(file);

    return StreamBuilder<FileDownloadState>(
      stream: downloadManager.watch(downloadKey),
      initialData: downloadManager.stateOf(downloadKey),
      builder: (context, snapshot) {
        final FileDownloadState downloadState = snapshot.data ??
            FileDownloadState.idle(
              downloadKey,
              sourceUrl: file.url,
              fileName: file.name,
            );

        return _buildFileTileContent(
          context: context,
          file: file,
          downloadState: downloadState,
          downloadManager: downloadManager,
          downloadKey: downloadKey,
        );
      },
    );
  }

  Widget _buildFileTileContent({
    required BuildContext context,
    required MessageAttachment file,
    required FileDownloadState downloadState,
    required IFileDownloadManager downloadManager,
    required String downloadKey,
  }) {
    final theme = Theme.of(context);
    final isUploading = file.isUploading;
    final isDownloading = downloadState.isInProgress;
    final isDownloaded = downloadState.status == FileDownloadStatus.completed;
    final isDownloadFailed = downloadState.status == FileDownloadStatus.failed;

    // Follow same pattern as ReplyPreview, LinkPreviewCard:
    // - on primary bubble -> use white/onPrimary colors
    // - isFromCurrentUser == false -> use theme neutral colors
    final tileBackgroundColor = isOnPrimaryBackground
        ? theme.colorScheme.onPrimary.withValues(alpha: 0.12)
        : theme.colorScheme.surfaceContainerHighest;

    final primaryIconColor = isOnPrimaryBackground
        ? theme.colorScheme.onPrimary.withValues(alpha: 0.9)
        : theme.colorScheme.primary;

    final titleTextStyle = isOnPrimaryBackground
        ? theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onPrimary,
          )
        : theme.textTheme.bodyMedium;

    final subTextColor = isOnPrimaryBackground
        ? theme.colorScheme.onPrimary.withValues(alpha: 0.8)
        : theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7);

    final downloadIconColor = isOnPrimaryBackground
        ? theme.colorScheme.onPrimary.withValues(alpha: 0.85)
        : theme.iconTheme.color?.withValues(alpha: 0.7);

    return GestureDetector(
      onTap: isUploading
          ? null // Disable tap during upload
          : () => _handleFileTileTap(
                context,
                file,
                downloadState: downloadState,
                downloadManager: downloadManager,
                downloadKey: downloadKey,
              ),
      child: Container(
        padding: const EdgeInsets.all(12.0),
        color: tileBackgroundColor,
        child: Row(
          children: [
            // File icon or upload progress indicator
            if (isUploading)
              _buildLiveUploadProgress(
                attachmentId: file.id,
                fallbackProgress: file.uploadProgress ?? 0.0,
                builder: _buildFileUploadProgressIndicator,
              )
            else if (isDownloading)
              _buildFileDownloadProgressIndicator(
                progress: downloadState.progress,
                color: primaryIconColor,
              )
            else if (isDownloaded)
              AppIcon.svg(
                AppIcons.checkCircle,
                color: theme.colorScheme.tertiary,
                size: 28,
              )
            else if (isDownloadFailed)
              AppIcon.svg(
                AppIcons.errorOutline,
                color: theme.colorScheme.error,
                size: 28,
              )
            else
              AppIcon.svg(
                _getFileIcon(file.type),
                color: primaryIconColor,
                size: 32,
              ),
            const SizedBox(width: 12.0),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    file.name.isNotEmpty ? file.name : 'File',
                    style: titleTextStyle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2.0),
                  if (isUploading)
                    // Show upload progress text (live from notifier)
                    _buildLiveUploadProgress(
                      attachmentId: file.id,
                      fallbackProgress: file.uploadProgress ?? 0.0,
                      builder: (progress) => Text(
                        'Uploading... ${(progress * 100).toInt()}%',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: primaryIconColor,
                        ),
                      ),
                    )
                  else if (isDownloading)
                    Text(
                      '${context.l10n.downloading} ${downloadState.progress}%',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: primaryIconColor,
                      ),
                    )
                  else if (isDownloaded)
                    Text(
                      context.l10n.downloaded,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: subTextColor,
                      ),
                    )
                  else if (isDownloadFailed)
                    Text(
                      context.l10n.downloadFailed,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.error,
                      ),
                    )
                  else if (file.size > 0)
                    Text(
                      _formatFileSize(file.size),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: subTextColor,
                      ),
                    ),
                ],
              ),
            ),
            if (!isUploading)
              AppIcon.svg(
                isDownloading
                    ? AppIcons.close
                    : isDownloaded
                        ? AppIcons.openInNew
                        : isDownloadFailed
                            ? AppIcons.refresh
                            : AppIcons.updateReady,
                color: downloadIconColor,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  /// Build circular upload progress indicator for file tiles
  Widget _buildFileUploadProgressIndicator(double progress) {
    final percentage = (progress * 100).toInt();

    return SizedBox(
      width: 32,
      height: 32,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: progress > 0 ? progress : null, // Indeterminate if 0
            strokeWidth: 2.5,
            backgroundColor: Colors.grey.withValues(alpha: 0.3),
          ),
          if (progress > 0)
            Text(
              '$percentage%',
              style: const TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.w600,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFileDownloadProgressIndicator({
    required int progress,
    required Color color,
  }) {
    return SizedBox(
      width: 32,
      height: 32,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: progress > 0 ? progress / 100 : null,
            strokeWidth: 2.5,
            backgroundColor: Colors.grey.withValues(alpha: 0.3),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
          if (progress > 0)
            Text(
              '$progress%',
              style: TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
        ],
      ),
    );
  }

  /// Get icon cho file type
  String _getFileIcon(String type) {
    switch (type.toLowerCase()) {
      case 'audio':
        return AppIcons.audioTrack;
      case 'location':
        return AppIcons.location;
      case 'doc':
        return AppIcons.file;
      case 'pdf':
        return AppIcons.filePdf;
      case 'file':
      default:
        return AppIcons.file;
    }
  }

  /// Format file size
  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  String _buildAttachmentDownloadKey(MessageAttachment attachment) {
    final String attachmentId = attachment.id.trim();
    if (attachmentId.isNotEmpty) {
      return 'attachment_$attachmentId';
    }

    final String url = attachment.url.trim();
    if (url.isNotEmpty) {
      return 'url_${url.hashCode}';
    }

    final int fallbackHash = Object.hash(
      attachment.name,
      attachment.type,
      attachment.size,
    );
    return 'attachment_fallback_$fallbackHash';
  }

  Future<void> _handleFileTileTap(
    BuildContext context,
    MessageAttachment attachment, {
    required FileDownloadState downloadState,
    required IFileDownloadManager downloadManager,
    required String downloadKey,
  }) async {
    final GalleryMediaType? mediaType = _isImageAttachment(attachment)
        ? GalleryMediaType.image
        : _isVideoAttachment(attachment)
            ? GalleryMediaType.video
            : null;

    if (mediaType != null) {
      await _saveAttachmentToGallery(
        context,
        attachment,
        mediaType: mediaType,
      );
      return;
    }

    if (downloadState.isInProgress) {
      final cancelResult = await downloadManager.cancelDownload(downloadKey);
      if (!context.mounted) {
        return;
      }

      cancelResult.fold(
        (failure) => AppSnackBar.error(
          context: context,
          message: failure.userMessage,
        ),
        (_) {},
      );
      return;
    }

    if (downloadState.canOpen) {
      final openResult = await downloadManager.openDownloadedFile(downloadKey);
      if (!context.mounted) {
        return;
      }

      openResult.fold(
        (failure) => AppSnackBar.error(
          context: context,
          message: failure.userMessage,
        ),
        (_) {},
      );
      return;
    }

    final result = await downloadManager.startDownload(
      key: downloadKey,
      url: attachment.url,
      fileName: attachment.name.isNotEmpty ? attachment.name : null,
    );

    if (!context.mounted) {
      return;
    }

    result.fold(
      (failure) => AppSnackBar.error(
        context: context,
        message: failure.userMessage,
      ),
      (_) => AppSnackBar.info(
        context: context,
        message: context.l10n.downloading,
      ),
    );
  }

  Future<void> _saveAttachmentToGallery(
    BuildContext context,
    MessageAttachment attachment, {
    required GalleryMediaType mediaType,
  }) async {
    final SaveMediaToGalleryUseCase saveMediaToGallery =
        GetIt.I<SaveMediaToGalleryUseCase>();
    final result = await saveMediaToGallery(
      SaveMediaToGalleryParams(
        url: attachment.url,
        mediaType: mediaType,
        mediaId: attachment.id,
      ),
    );

    if (!context.mounted) {
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

  /// Open fullscreen gallery
  Future<void> _openFullscreenGallery(
    BuildContext context, {
    required List<MessageAttachment> attachments,
    required int initialIndex,
  }) async {
    if (attachments.isEmpty ||
        initialIndex < 0 ||
        initialIndex >= attachments.length) {
      return;
    }

    MessageBloc? messageBloc;
    try {
      messageBloc = context.read<MessageBloc>();
    } catch (_) {
      messageBloc = null;
    }

    final result = await Navigator.push<EditedImageResult>(
      context,
      MaterialPageRoute(
        builder: (_) {
          final gallery = ImageViewerScreen.gallery(
            images: attachments
                .map(
                  (attachment) => ImageViewerItem(
                    imageUrl: attachment.url,
                    heroTag:
                        'chat_media_${message?.id ?? chatId ?? ''}_${attachment.id}',
                  ),
                )
                .toList(growable: false),
            initialIndex: initialIndex,
            message: message,
            chatId: chatId,
          );

          if (messageBloc != null) {
            return BlocProvider<MessageBloc>.value(
              value: messageBloc,
              child: gallery,
            );
          }

          return gallery;
        },
      ),
    );

    if (result != null && onEditedImageSend != null) {
      onEditedImageSend!(result.bytes, result.fileName);
    }
  }
}

/// Layout mode cho media gallery
enum MediaGalleryLayout {
  /// Grid layout (default)
  grid,

  /// List layout
  list,
}
