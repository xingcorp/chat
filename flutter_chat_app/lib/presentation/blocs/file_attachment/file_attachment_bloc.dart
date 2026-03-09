import 'dart:async';
import 'dart:typed_data';

import 'package:cross_file/cross_file.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_chat_app/core/constants/app_constants.dart';
import 'package:flutter_chat_app/core/utils/logger.dart';
import 'package:flutter_chat_app/data/services/file_validation_service.dart';
import 'package:flutter_chat_app/domain/entities/pending_file.dart';
import 'package:flutter_chat_app/domain/usecases/file/upload_attachment_usecase.dart';
import 'package:flutter_chat_app/domain/usecases/file/validate_file_usecase.dart';
import 'package:flutter_chat_app/shared/domain/entities/attachment.dart';
import 'package:injectable/injectable.dart';
import 'package:uuid/uuid.dart';

part 'file_attachment_event.dart';
part 'file_attachment_state.dart';

/// Information about a file picked via the file picker
class PickedFileInfo {
  /// File path on disk (null on web)
  final String? path;

  /// File bytes in memory (for web)
  final Uint8List? bytes;

  /// Original file name
  final String name;

  /// File size in bytes
  final int size;

  /// MIME type
  final String? mimeType;

  const PickedFileInfo({
    this.path,
    this.bytes,
    required this.name,
    required this.size,
    this.mimeType,
  });
}

/// Manages file attachments for the chat input.
///
/// Handles drag & drop, clipboard paste, and file picker inputs.
/// Validates files, manages upload lifecycle, and provides
/// completed attachments for message send.
///
/// **Data flow:**
/// ```
/// User Action (Drop / Paste / Pick)
///   → FileAttachmentBloc.add(event)
///     → Validate (size, type, count)
///     → Create PendingFile entries
///     → Auto-start upload
///     → Update progress per file
///   → User hits Send
///     → state.completedAttachments → MessageQueueBloc
///     → FileAttachmentBloc.add(AllFilesCleared)
/// ```
@injectable
class FileAttachmentBloc
    extends Bloc<FileAttachmentEvent, FileAttachmentState> {
  final ValidateFileUseCase _validateFileUseCase;
  final UploadAttachmentUseCase _uploadAttachmentUseCase;
  final FileValidationService _fileValidationService;
  final AppLogger _logger;

  static const _uuid = Uuid();

  FileAttachmentBloc({
    required ValidateFileUseCase validateFileUseCase,
    required UploadAttachmentUseCase uploadAttachmentUseCase,
    required FileValidationService fileValidationService,
    required AppLogger logger,
  })  : _validateFileUseCase = validateFileUseCase,
        _uploadAttachmentUseCase = uploadAttachmentUseCase,
        _fileValidationService = fileValidationService,
        _logger = logger,
        super(const FileAttachmentState()) {
    on<FilesDropped>(_onFilesDropped);
    on<ImagePasted>(_onImagePasted);
    on<FilesPicked>(_onFilesPicked);
    on<FileRemoved>(_onFileRemoved);
    on<UploadRetried>(_onUploadRetried);
    on<UploadCancelled>(_onUploadCancelled);
    on<UploadProgressUpdated>(_onUploadProgressUpdated);
    on<UploadCompleted>(_onUploadCompleted);
    on<UploadFailed>(_onUploadFailed);
    on<AllFilesCleared>(_onAllCleared);
  }

  // ═══════════════════════════════════════════
  // Event Handlers
  // ═══════════════════════════════════════════

  /// Handle files dropped from OS drag & drop
  Future<void> _onFilesDropped(
    FilesDropped event,
    Emitter<FileAttachmentState> emit,
  ) async {
    _logger.info('FileAttachmentBloc: Files dropped', {
      'count': event.files.length,
    });

    for (final xFile in event.files) {
      final fileSize = await xFile.length();
      final fileName = xFile.name;
      final mimeType = xFile.mimeType ?? 'application/octet-stream';

      // Read bytes (needed for web, also useful for preview)
      Uint8List? bytes;
      String? filePath;

      try {
        filePath = xFile.path.isNotEmpty ? xFile.path : null;
      } catch (_) {
        filePath = null;
      }

      // On web, path is empty — read bytes instead
      if (filePath == null || filePath.isEmpty) {
        try {
          bytes = await xFile.readAsBytes();
        } catch (e) {
          _logger.warning(
            'FileAttachmentBloc: Failed to read bytes for ${xFile.name}',
            {'error': e.toString()},
          );
          continue;
        }
      }

      await _addFile(
        emit: emit,
        fileName: fileName,
        fileSize: fileSize,
        mimeType: mimeType,
        filePath: filePath,
        bytes: bytes,
      );
    }
  }

  /// Handle image pasted from clipboard
  Future<void> _onImagePasted(
    ImagePasted event,
    Emitter<FileAttachmentState> emit,
  ) async {
    _logger.info('FileAttachmentBloc: Image pasted', {
      'fileName': event.fileName,
      'size': event.bytes.length,
    });

    await _addFile(
      emit: emit,
      fileName: event.fileName,
      fileSize: event.bytes.length,
      mimeType: 'image/png',
      bytes: event.bytes,
    );
  }

  /// Handle files selected via file picker
  Future<void> _onFilesPicked(
    FilesPicked event,
    Emitter<FileAttachmentState> emit,
  ) async {
    _logger.info('FileAttachmentBloc: Files picked', {
      'count': event.files.length,
    });

    for (final file in event.files) {
      await _addFile(
        emit: emit,
        fileName: file.name,
        fileSize: file.size,
        mimeType: file.mimeType ?? 'application/octet-stream',
        filePath: file.path,
        bytes: file.bytes,
      );
    }
  }

  /// Handle file removal
  Future<void> _onFileRemoved(
    FileRemoved event,
    Emitter<FileAttachmentState> emit,
  ) async {
    _logger.info('FileAttachmentBloc: File removed', {
      'localId': event.localId,
    });

    final updated = state.pendingFiles
        .where((f) => f.localId != event.localId)
        .toList();

    emit(state.copyWith(pendingFiles: updated, clearError: true));
  }

  /// Handle upload retry for a failed file
  Future<void> _onUploadRetried(
    UploadRetried event,
    Emitter<FileAttachmentState> emit,
  ) async {
    _logger.info('FileAttachmentBloc: Upload retried', {
      'localId': event.localId,
    });

    final index = state.pendingFiles
        .indexWhere((f) => f.localId == event.localId);
    if (index == -1) return;

    final file = state.pendingFiles[index];
    if (file.status != PendingFileStatus.failed) return;

    // Reset status to pending
    final updatedFile = file.copyWith(
      status: PendingFileStatus.pending,
      uploadProgress: 0.0,
      errorMessage: null,
    );

    final updatedList = List<PendingFile>.from(state.pendingFiles);
    updatedList[index] = updatedFile;
    emit(state.copyWith(pendingFiles: updatedList, clearError: true));

    // Restart upload
    _startUpload(updatedFile);
  }

  /// Handle upload cancellation
  Future<void> _onUploadCancelled(
    UploadCancelled event,
    Emitter<FileAttachmentState> emit,
  ) async {
    _logger.info('FileAttachmentBloc: Upload cancelled', {
      'localId': event.localId,
    });

    final updated = state.pendingFiles.map((f) {
      if (f.localId == event.localId) {
        return f.copyWith(status: PendingFileStatus.cancelled);
      }
      return f;
    }).toList();

    emit(state.copyWith(pendingFiles: updated));
  }

  /// Handle upload progress update (internal event)
  Future<void> _onUploadProgressUpdated(
    UploadProgressUpdated event,
    Emitter<FileAttachmentState> emit,
  ) async {
    final updated = state.pendingFiles.map((f) {
      if (f.localId == event.localId) {
        return f.copyWith(
          status: PendingFileStatus.uploading,
          uploadProgress: event.progress,
        );
      }
      return f;
    }).toList();

    emit(state.copyWith(pendingFiles: updated));
  }

  /// Handle upload completion (internal event)
  Future<void> _onUploadCompleted(
    UploadCompleted event,
    Emitter<FileAttachmentState> emit,
  ) async {
    _logger.info('FileAttachmentBloc: Upload completed', {
      'localId': event.localId,
      'url': event.url,
    });

    final updated = state.pendingFiles.map((f) {
      if (f.localId == event.localId) {
        return f.copyWith(
          status: PendingFileStatus.completed,
          uploadProgress: 1.0,
          uploadedUrl: event.url,
          uploadId: event.uploadId,
        );
      }
      return f;
    }).toList();

    emit(state.copyWith(pendingFiles: updated));
  }

  /// Handle upload failure (internal event)
  Future<void> _onUploadFailed(
    UploadFailed event,
    Emitter<FileAttachmentState> emit,
  ) async {
    _logger.warning('FileAttachmentBloc: Upload failed', {
      'localId': event.localId,
      'error': event.error,
    });

    final updated = state.pendingFiles.map((f) {
      if (f.localId == event.localId) {
        return f.copyWith(
          status: PendingFileStatus.failed,
          errorMessage: event.error,
        );
      }
      return f;
    }).toList();

    emit(state.copyWith(
      pendingFiles: updated,
      lastError: event.error,
      lastErrorCode: 'upload_failed',
    ));
  }

  /// Handle clear all files
  Future<void> _onAllCleared(
    AllFilesCleared event,
    Emitter<FileAttachmentState> emit,
  ) async {
    _logger.info('FileAttachmentBloc: All files cleared');

    emit(const FileAttachmentState());
  }

  // ═══════════════════════════════════════════
  // Private Helpers
  // ═══════════════════════════════════════════

  /// Validate and add a file to the pending queue, then start upload
  Future<void> _addFile({
    required Emitter<FileAttachmentState> emit,
    required String fileName,
    required int fileSize,
    required String mimeType,
    String? filePath,
    Uint8List? bytes,
  }) async {
    // Validate the file
    final validationResult = await _validateFileUseCase.call(
      ValidateFileParams(
        fileName: fileName,
        fileSize: fileSize,
        mimeType: mimeType,
        currentAttachmentCount: state.pendingFiles.length,
      ),
    );

    final isValid = validationResult.fold(
      (failure) {
        _logger.warning(
          'FileAttachmentBloc: File validation failed',
          {'fileName': fileName, 'error': failure.message},
        );
        emit(state.copyWith(
          lastError: failure.message,
          lastErrorCode: failure.code,
        ));
        return false;
      },
      (_) => true,
    );

    if (!isValid) return;

    // Detect attachment type
    final attachmentType = _fileValidationService.detectType(fileName, mimeType);

    // Create PendingFile
    final pendingFile = PendingFile(
      localId: _uuid.v4(),
      fileName: fileName,
      fileSize: fileSize,
      mimeType: mimeType,
      type: attachmentType,
      localPath: filePath,
      bytes: bytes,
      status: PendingFileStatus.pending,
      addedAt: DateTime.now(),
    );

    // Add to state
    final updatedList = [...state.pendingFiles, pendingFile];
    emit(state.copyWith(pendingFiles: updatedList, clearError: true));

    // Start upload
    _startUpload(pendingFile);
  }

  /// Start uploading a file (fire-and-forget, progress via internal events)
  void _startUpload(PendingFile file) {
    // Update status to uploading
    add(UploadProgressUpdated(localId: file.localId, progress: 0.0));

    _uploadAttachmentUseCase
        .call(UploadAttachmentParams(
          localId: file.localId,
          filePath: file.localPath,
          bytes: file.bytes,
          fileName: file.fileName,
          mimeType: file.mimeType,
          onProgress: (progress) {
            // Only emit progress events if bloc is still open
            if (!isClosed) {
              add(UploadProgressUpdated(
                localId: file.localId,
                progress: progress,
              ));
            }
          },
        ))
        .then((result) {
      if (isClosed) return;

      result.fold(
        (failure) {
          add(UploadFailed(
            localId: file.localId,
            error: failure.message,
          ));
        },
        (uploadResult) {
          add(UploadCompleted(
            localId: file.localId,
            url: uploadResult.url,
            uploadId: uploadResult.id,
          ));
        },
      );
    });
  }

  @override
  Future<void> close() {
    _logger.info('FileAttachmentBloc: Closing');
    return super.close();
  }
}
