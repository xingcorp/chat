import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_chat_app/core/constants/update_constants.dart';
import 'package:flutter_chat_app/core/utils/logger.dart';
import 'package:flutter_chat_app/domain/repositories/i_update_repository.dart';
import 'package:flutter_chat_app/presentation/blocs/update/update_event.dart';
import 'package:flutter_chat_app/presentation/blocs/update/update_state.dart';

/// BLoC managing the app auto-update lifecycle.
///
/// **State machine:**
/// ```
/// Idle → Checking → UpdateAvailable → Downloading → ReadyToInstall → Installing
///                ↘ UpdateNotAvailable → Idle
///                ↘ Error (with retry)
/// ```
///
/// **Timer logic:**
/// - First check: 30s after creation
/// - Periodic: every 4 hours
/// - Respects 'remind later' and 'skipped version' preferences
class UpdateBloc extends Bloc<UpdateEvent, UpdateState> {
  UpdateBloc({
    required IUpdateRepository updateRepository,
  })  : _updateRepository = updateRepository,
        super(const UpdateIdle()) {
    // Register event handlers
    on<CheckForUpdateRequested>(_onCheckForUpdate);
    on<DownloadUpdateRequested>(_onDownloadUpdate);
    on<DownloadProgressUpdated>(_onDownloadProgress);
    on<CancelDownloadRequested>(_onCancelDownload);
    on<InstallUpdateRequested>(_onInstallUpdate);
    on<SkipVersionRequested>(_onSkipVersion);
    on<RemindLaterRequested>(_onRemindLater);
    on<UpdateDismissed>(_onDismissed);

    // Schedule initial check after delay
    _initialDelayTimer = Timer(UpdateConstants.initialCheckDelay, () {
      add(const CheckForUpdateRequested());
    });
  }

  final IUpdateRepository _updateRepository;
  Timer? _initialDelayTimer;
  Timer? _periodicCheckTimer;

  // ═══════════════════════════════════════════
  // Event Handlers
  // ═══════════════════════════════════════════

  Future<void> _onCheckForUpdate(
    CheckForUpdateRequested event,
    Emitter<UpdateState> emit,
  ) async {
    emit(UpdateChecking(isManual: event.isManual));

    final result = await _updateRepository.checkForUpdate(
      isManual: event.isManual,
    );

    result.fold(
      (failure) {
        LogUtils.w('UpdateBloc', 'Check failed: ${failure.message}');
        if (event.isManual) {
          emit(UpdateError(message: failure.userMessage));
        } else {
          // Silent fail for auto-check — go back to idle
          emit(const UpdateIdle());
        }
      },
      (updateInfo) {
        if (updateInfo != null) {
          emit(UpdateAvailable(updateInfo: updateInfo));
        } else {
          if (event.isManual) {
            emit(const UpdateNotAvailable());
            // Return to idle after 3 seconds
            Future.delayed(const Duration(seconds: 3), () {
              if (!isClosed && state is UpdateNotAvailable) {
                add(const UpdateDismissed());
              }
            });
          } else {
            emit(const UpdateIdle());
          }
        }
      },
    );

    // Schedule next periodic check
    _scheduleNextCheck();
  }

  Future<void> _onDownloadUpdate(
    DownloadUpdateRequested event,
    Emitter<UpdateState> emit,
  ) async {
    emit(UpdateDownloading(
      updateInfo: event.updateInfo,
      progress: 0,
      receivedBytes: 0,
      totalBytes: event.updateInfo.fileSizeBytes,
    ));

    final result = await _updateRepository.downloadUpdate(
      updateInfo: event.updateInfo,
      onProgress: (received, total) {
        add(DownloadProgressUpdated(
          receivedBytes: received,
          totalBytes: total > 0 ? total : event.updateInfo.fileSizeBytes,
        ));
      },
    );

    result.fold(
      (failure) {
        if (failure.code == 'cancelled') {
          emit(UpdateAvailable(updateInfo: event.updateInfo));
        } else {
          emit(UpdateError(message: failure.userMessage));
        }
      },
      (filePath) async {
        // Verify checksum if available
        if (event.updateInfo.sha256Checksum.isNotEmpty) {
          final verifyResult = await _updateRepository.verifyDownload(
            filePath: filePath,
            expectedChecksum: event.updateInfo.sha256Checksum,
          );

          verifyResult.fold(
            (failure) {
              emit(UpdateError(
                message: failure.userMessage,
                canRetry: true,
              ));
            },
            (isValid) {
              if (isValid) {
                emit(UpdateReadyToInstall(
                  updateInfo: event.updateInfo,
                  installerPath: filePath,
                ));
              } else {
                emit(const UpdateError(
                  message: 'File verification failed. Please try again.',
                  canRetry: true,
                ));
              }
            },
          );
        } else {
          // No checksum — skip verification
          emit(UpdateReadyToInstall(
            updateInfo: event.updateInfo,
            installerPath: filePath,
          ));
        }
      },
    );
  }

  void _onDownloadProgress(
    DownloadProgressUpdated event,
    Emitter<UpdateState> emit,
  ) {
    final currentState = state;
    if (currentState is UpdateDownloading) {
      final total = event.totalBytes > 0
          ? event.totalBytes
          : currentState.totalBytes;
      final progress = total > 0 ? event.receivedBytes / total : 0.0;

      emit(UpdateDownloading(
        updateInfo: currentState.updateInfo,
        progress: progress.clamp(0.0, 1.0),
        receivedBytes: event.receivedBytes,
        totalBytes: total,
      ));
    }
  }

  Future<void> _onCancelDownload(
    CancelDownloadRequested event,
    Emitter<UpdateState> emit,
  ) async {
    await _updateRepository.cancelDownload();
    // State will be updated when downloadUpdate returns with 'cancelled' failure
  }

  Future<void> _onInstallUpdate(
    InstallUpdateRequested event,
    Emitter<UpdateState> emit,
  ) async {
    emit(const UpdateInstalling());

    final result = await _updateRepository.installUpdate(
      installerPath: event.installerPath,
    );

    result.fold(
      (failure) {
        emit(UpdateError(message: failure.userMessage, canRetry: false));
      },
      (_) {
        // App will exit — this code likely won't execute
      },
    );
  }

  Future<void> _onSkipVersion(
    SkipVersionRequested event,
    Emitter<UpdateState> emit,
  ) async {
    await _updateRepository.skipVersion(event.version);
    emit(const UpdateIdle());
  }

  Future<void> _onRemindLater(
    RemindLaterRequested event,
    Emitter<UpdateState> emit,
  ) async {
    final remindAt = DateTime.now().add(UpdateConstants.remindLaterDuration);
    await _updateRepository.setRemindLaterTimestamp(remindAt);
    emit(const UpdateIdle());
  }

  void _onDismissed(
    UpdateDismissed event,
    Emitter<UpdateState> emit,
  ) {
    emit(const UpdateIdle());
  }

  // ═══════════════════════════════════════════
  // Periodic check scheduling
  // ═══════════════════════════════════════════

  void _scheduleNextCheck() {
    _periodicCheckTimer?.cancel();
    _periodicCheckTimer = Timer(UpdateConstants.checkInterval, () {
      if (!isClosed) {
        add(const CheckForUpdateRequested());
      }
    });
  }

  @override
  Future<void> close() {
    _initialDelayTimer?.cancel();
    _periodicCheckTimer?.cancel();
    return super.close();
  }
}
