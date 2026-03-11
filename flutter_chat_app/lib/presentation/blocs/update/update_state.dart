import 'package:flutter_chat_app/domain/entities/app_update_info.dart';
import 'package:flutter_chat_app/presentation/blocs/base/base_state.dart';

/// States for the [UpdateBloc].
abstract class UpdateState extends BaseState {
  const UpdateState();
}

/// No update activity — initial/idle state.
class UpdateIdle extends UpdateState {
  const UpdateIdle();

  @override
  List<Object?> get props => [];
}

/// Checking for updates (GitHub API call in progress).
class UpdateChecking extends UpdateState {
  const UpdateChecking({this.isManual = false});

  /// Whether this was a manual check (shows loading indicator in UI).
  final bool isManual;

  @override
  List<Object?> get props => [isManual];
}

/// A newer version is available.
class UpdateAvailable extends UpdateState {
  const UpdateAvailable({required this.updateInfo});

  final AppUpdateInfo updateInfo;

  @override
  List<Object?> get props => [updateInfo];
}

/// Download is in progress.
class UpdateDownloading extends UpdateState {
  const UpdateDownloading({
    required this.updateInfo,
    required this.progress,
    required this.receivedBytes,
    required this.totalBytes,
  });

  final AppUpdateInfo updateInfo;

  /// 0.0 to 1.0
  final double progress;
  final int receivedBytes;
  final int totalBytes;

  @override
  List<Object?> get props => [updateInfo, progress, receivedBytes, totalBytes];
}

/// Download completed and verified — ready to install.
class UpdateReadyToInstall extends UpdateState {
  const UpdateReadyToInstall({
    required this.updateInfo,
    required this.installerPath,
  });

  final AppUpdateInfo updateInfo;
  final String installerPath;

  @override
  List<Object?> get props => [updateInfo, installerPath];
}

/// Installer is being launched — app will exit shortly.
class UpdateInstalling extends UpdateState {
  const UpdateInstalling();

  @override
  List<Object?> get props => [];
}

/// An error occurred during any update step.
class UpdateError extends UpdateState {
  const UpdateError({
    required this.message,
    this.canRetry = true,
  });

  final String message;
  final bool canRetry;

  @override
  List<Object?> get props => [message, canRetry];
}

/// Manual check completed — no update available.
class UpdateNotAvailable extends UpdateState {
  const UpdateNotAvailable();

  @override
  List<Object?> get props => [];
}
