library;

/// **APP FILE UPLOADER**
///
/// File upload component with drag-and-drop, progress tracking, and validation.
/// Extends [BaseStatefulWidget] for lifecycle management.
///
/// **Features**:
/// - Drag-and-drop support (web/desktop)
/// - File picker integration
/// - Upload progress indicator
/// - Multiple file upload
/// - File type validation
/// - Size limit validation
/// - Preview thumbnails
/// - Remove uploaded files
/// - Retry failed uploads
/// - Dark mode support
/// - Accessibility labels
///
/// **Architecture**: Clean Architecture + Design System
/// **Pattern**: Stateful widget with upload management
///
/// **Usage**:
/// ```dart
/// AppFileUploader(
///   onFilesSelected: (files) async {
///     for (final file in files) {
///       await _uploadFile(file);
///     }
///   },
///   allowedTypes: [FileType.image, FileType.document],
///   maxFileSize: 10 * 1024 * 1024, // 10MB
///   maxFiles: 5,
/// )
/// ```

import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_app/core/base/base_widget.dart';
import 'package:flutter_chat_app/core/constants/app_dimens.dart';
import 'package:flutter_chat_app/l10n/l10n.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/media/media_enums.dart';

/// Uploaded file information
class UploadedFile {
  /// File name
  final String name;

  /// File size in bytes
  final int size;

  /// File type
  final FileType type;

  /// File path (mobile/desktop)
  final String? path;

  /// File bytes (web)
  final Uint8List? bytes;

  /// Upload status
  final FileUploadStatus status;

  /// Upload progress (0.0 to 1.0)
  final double progress;

  /// Error message if upload failed
  final String? error;

  /// Thumbnail URL or path
  final String? thumbnailUrl;

  const UploadedFile({
    required this.name,
    required this.size,
    required this.type,
    this.path,
    this.bytes,
    this.status = FileUploadStatus.pending,
    this.progress = 0.0,
    this.error,
    this.thumbnailUrl,
  });

  /// Copy with updated fields
  UploadedFile copyWith({
    String? name,
    int? size,
    FileType? type,
    String? path,
    Uint8List? bytes,
    FileUploadStatus? status,
    double? progress,
    String? error,
    String? thumbnailUrl,
  }) {
    return UploadedFile(
      name: name ?? this.name,
      size: size ?? this.size,
      type: type ?? this.type,
      path: path ?? this.path,
      bytes: bytes ?? this.bytes,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      error: error ?? this.error,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
    );
  }

  /// Get formatted file size
  String get formattedSize {
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
    if (size < 1024 * 1024 * 1024) {
      return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(size / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}

/// App File Uploader widget
class AppFileUploader extends BaseStatefulWidget {
  const AppFileUploader({
    super.key,
    required this.onFilesSelected,
    this.allowedTypes = const [
      FileType.image,
      FileType.video,
      FileType.audio,
      FileType.document,
    ],
    this.maxFileSize = 25 * 1024 * 1024, // 25MB default
    this.maxFiles = 10,
    this.allowMultiple = true,
    this.showPreview = true,
    this.enableDragDrop = true,
    this.uploadedFiles = const [],
    this.onFileRemoved,
    this.onRetry,
    this.height = 200.0,
  });

  /// Callback when files are selected
  final Future<void> Function(List<UploadedFile> files) onFilesSelected;

  /// Allowed file types
  final List<FileType> allowedTypes;

  /// Maximum file size in bytes
  final int maxFileSize;

  /// Maximum number of files
  final int maxFiles;

  /// Whether to allow multiple file selection
  final bool allowMultiple;

  /// Whether to show file previews
  final bool showPreview;

  /// Whether to enable drag and drop (web/desktop)
  final bool enableDragDrop;

  /// Currently uploaded files
  final List<UploadedFile> uploadedFiles;

  /// Callback when file is removed
  final void Function(UploadedFile file)? onFileRemoved;

  /// Callback to retry failed upload
  final Future<void> Function(UploadedFile file)? onRetry;

  /// Upload area height
  final double height;

  @override
  AppFileUploaderState createState() => AppFileUploaderState();
}

class AppFileUploaderState extends BaseState<AppFileUploader> {
  bool _isDragging = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = context.l10n;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Upload area
        _buildUploadArea(theme, isDark, l10n),

        // Uploaded files list
        if (widget.uploadedFiles.isNotEmpty && widget.showPreview) ...[
          SizedBox(height: AppDimens.spaceMedium),
          _buildFilesList(theme, isDark, l10n),
        ],
      ],
    );
  }

  Widget _buildUploadArea(ThemeData theme, bool isDark, AppLocalizations l10n) {
    final canUploadMore = widget.uploadedFiles.length < widget.maxFiles;

    return GestureDetector(
      onTap: canUploadMore ? _pickFiles : null,
      child: DragTarget<List<File>>(
        onWillAcceptWithDetails: (details) =>
            widget.enableDragDrop && canUploadMore,
        onAcceptWithDetails: (details) {
          if (widget.enableDragDrop && canUploadMore) {
            _handleDroppedFiles(details.data);
          }
        },
        onMove: (details) {
          if (!_isDragging && widget.enableDragDrop && canUploadMore) {
            safeSetState(() => _isDragging = true);
          }
        },
        onLeave: (_) {
          if (_isDragging) {
            safeSetState(() => _isDragging = false);
          }
        },
        builder: (context, candidateData, rejectedData) {
          return Container(
            height: widget.height,
            decoration: BoxDecoration(
              color: _isDragging
                  ? (isDark ? Colors.grey[800] : Colors.grey[100])
                  : (isDark ? Colors.grey[900] : Colors.grey[50]),
              border: Border.all(
                color: _isDragging
                    ? theme.colorScheme.primary
                    : (isDark ? Colors.white24 : Colors.black12),
                width: _isDragging ? 2.0 : 1.0,
                style: BorderStyle.solid,
              ),
              borderRadius: BorderRadius.circular(AppDimens.radiusCard),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _isDragging ? Icons.file_download : Icons.cloud_upload,
                  size: AppDimens.iconLarge * 2,
                  color: _isDragging
                      ? theme.colorScheme.primary
                      : (isDark ? Colors.white54 : Colors.black54),
                ),
                SizedBox(height: AppDimens.spaceMedium),
                Text(
                  _isDragging
                      ? l10n.dropFilesHere
                      : (canUploadMore
                          ? l10n.dragDropOrClickToUpload
                          : l10n.maxFilesReached),
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: _isDragging
                        ? theme.colorScheme.primary
                        : (isDark ? Colors.white70 : Colors.black87),
                  ),
                  textAlign: TextAlign.center,
                ),
                if (canUploadMore) ...[
                  SizedBox(height: AppDimens.spaceSmall),
                  Text(
                    _getAllowedTypesText(l10n),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isDark ? Colors.white54 : Colors.black54,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: AppDimens.spaceSmall),
                  Text(
                    l10n.maxFileSize(_formatBytes(widget.maxFileSize)),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isDark ? Colors.white54 : Colors.black54,
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildFilesList(ThemeData theme, bool isDark, AppLocalizations l10n) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: widget.uploadedFiles.length,
      separatorBuilder: (context, index) =>
          SizedBox(height: AppDimens.spaceSmall),
      itemBuilder: (context, index) {
        final file = widget.uploadedFiles[index];
        return _buildFileItem(file, theme, isDark, l10n);
      },
    );
  }

  Widget _buildFileItem(
    UploadedFile file,
    ThemeData theme,
    bool isDark,
    AppLocalizations l10n,
  ) {
    return Container(
      padding: const EdgeInsets.all(AppDimens.paddingMedium),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.white,
        border: Border.all(
          color: isDark ? Colors.white12 : Colors.black12,
        ),
        borderRadius: BorderRadius.circular(AppDimens.radiusCard),
      ),
      child: Row(
        children: [
          // File icon or thumbnail
          _buildFileIcon(file, theme, isDark),
          SizedBox(width: AppDimens.spaceMedium),

          // File info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  file.name,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: AppDimens.spaceSmall),
                Text(
                  file.formattedSize,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isDark ? Colors.white54 : Colors.black54,
                  ),
                ),
                if (file.status.isInProgress) ...[
                  SizedBox(height: AppDimens.spaceSmall),
                  _buildProgressBar(file, theme),
                ],
                if (file.status.isFailed && file.error != null) ...[
                  SizedBox(height: AppDimens.spaceSmall),
                  Text(
                    file.error!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Actions
          _buildFileActions(file, theme, isDark, l10n),
        ],
      ),
    );
  }

  Widget _buildFileIcon(UploadedFile file, ThemeData theme, bool isDark) {
    if (file.thumbnailUrl != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(AppDimens.radiusSmall),
        child: Image.network(
          file.thumbnailUrl!,
          width: AppDimens.iconLarge * 2,
          height: AppDimens.iconLarge * 2,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) =>
              _buildDefaultFileIcon(file, theme, isDark),
        ),
      );
    }

    return _buildDefaultFileIcon(file, theme, isDark);
  }

  Widget _buildDefaultFileIcon(
    UploadedFile file,
    ThemeData theme,
    bool isDark,
  ) {
    IconData icon;
    Color color;

    switch (file.type) {
      case FileType.image:
        icon = Icons.image;
        color = Colors.blue;
        break;
      case FileType.video:
        icon = Icons.videocam;
        color = Colors.red;
        break;
      case FileType.audio:
        icon = Icons.audiotrack;
        color = Colors.purple;
        break;
      case FileType.document:
        icon = Icons.description;
        color = Colors.orange;
        break;
      case FileType.archive:
        icon = Icons.folder_zip;
        color = Colors.brown;
        break;
      case FileType.other:
        icon = Icons.insert_drive_file;
        color = Colors.grey;
        break;
    }

    return Container(
      width: AppDimens.iconLarge * 2,
      height: AppDimens.iconLarge * 2,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppDimens.radiusSmall),
      ),
      child: Icon(
        icon,
        size: AppDimens.iconLarge,
        color: color,
      ),
    );
  }

  Widget _buildProgressBar(UploadedFile file, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LinearProgressIndicator(
          value: file.progress,
          backgroundColor: theme.colorScheme.surfaceContainerHighest,
          valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
        ),
        SizedBox(height: AppDimens.spaceSmall),
        Text(
          '${(file.progress * 100).toInt()}%',
          style: theme.textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _buildFileActions(
    UploadedFile file,
    ThemeData theme,
    bool isDark,
    AppLocalizations l10n,
  ) {
    if (file.status.isFailed && widget.onRetry != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => widget.onRetry!(file),
            tooltip: l10n.retry,
            iconSize: AppDimens.iconMedium,
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => widget.onFileRemoved?.call(file),
            tooltip: l10n.remove,
            iconSize: AppDimens.iconMedium,
          ),
        ],
      );
    }

    if (file.status.isComplete || file.status.isInProgress) {
      return IconButton(
        icon: const Icon(Icons.close),
        onPressed: file.status.isInProgress
            ? null
            : () => widget.onFileRemoved?.call(file),
        tooltip: l10n.remove,
        iconSize: AppDimens.iconMedium,
      );
    }

    return const SizedBox.shrink();
  }

  Future<void> _pickFiles() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: _getAllowedExtensions(),
        allowMultiple: widget.allowMultiple,
        withData: kIsWeb,
      );

      if (result != null) {
        final files = result.files.map((file) {
          final fileType = _getFileType(file.extension ?? '');
          return UploadedFile(
            name: file.name,
            size: file.size,
            type: fileType,
            path: file.path,
            bytes: file.bytes,
          );
        }).toList();

        await _validateAndUploadFiles(files);
      }
    } catch (e) {
      // Handle error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.errorPickingFiles),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _handleDroppedFiles(List<File> files) async {
    final uploadedFiles = files.map((file) {
      final extension = file.path.split('.').last.toLowerCase();
      final fileType = _getFileType(extension);
      return UploadedFile(
        name: file.path.split('/').last,
        size: file.lengthSync(),
        type: fileType,
        path: file.path,
      );
    }).toList();

    await _validateAndUploadFiles(uploadedFiles);
  }

  Future<void> _validateAndUploadFiles(List<UploadedFile> files) async {
    final validFiles = <UploadedFile>[];
    final errors = <String>[];

    for (final file in files) {
      // Check file count
      if (widget.uploadedFiles.length + validFiles.length >= widget.maxFiles) {
        errors.add(context.l10n.maxFilesReached);
        break;
      }

      // Check file size
      if (file.size > widget.maxFileSize) {
        errors.add(
          context.l10n.fileTooLarge(
            file.name,
            _formatBytes(widget.maxFileSize),
          ),
        );
        continue;
      }

      // Check file type
      if (!widget.allowedTypes.contains(file.type)) {
        errors.add(context.l10n.fileTypeNotAllowed(file.name));
        continue;
      }

      validFiles.add(file);
    }

    // Show errors if any
    if (errors.isNotEmpty && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errors.join('\n')),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }

    // Upload valid files
    if (validFiles.isNotEmpty) {
      await widget.onFilesSelected(validFiles);
    }
  }

  List<String> _getAllowedExtensions() {
    final extensions = <String>{};
    for (final type in widget.allowedTypes) {
      extensions.addAll(type.extensions);
    }
    return extensions.toList();
  }

  FileType _getFileType(String extension) {
    final ext = extension.toLowerCase();
    for (final type in FileType.values) {
      if (type.extensions.contains(ext)) {
        return type;
      }
    }
    return FileType.other;
  }

  String _getAllowedTypesText(AppLocalizations l10n) {
    final types = widget.allowedTypes.map((t) => t.displayName).join(', ');
    return l10n.allowedFileTypes(types);
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}
