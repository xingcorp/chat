import 'package:equatable/equatable.dart';
import 'package:flutter_chat_app/domain/entities/app_update_info.dart';

/// Events for the [UpdateBloc].
abstract class UpdateEvent extends Equatable {
  const UpdateEvent();

  @override
  List<Object?> get props => [];
}

/// Trigger a check for updates (manual or automatic).
class CheckForUpdateRequested extends UpdateEvent {
  const CheckForUpdateRequested({this.isManual = false});

  /// Whether this was manually triggered by the user (shows UI feedback).
  final bool isManual;

  @override
  List<Object?> get props => [isManual];
}

/// User wants to start downloading the update.
class DownloadUpdateRequested extends UpdateEvent {
  const DownloadUpdateRequested({required this.updateInfo});

  final AppUpdateInfo updateInfo;

  @override
  List<Object?> get props => [updateInfo];
}

/// Internal event: download progress updated.
class DownloadProgressUpdated extends UpdateEvent {
  const DownloadProgressUpdated({
    required this.receivedBytes,
    required this.totalBytes,
  });

  final int receivedBytes;
  final int totalBytes;

  @override
  List<Object?> get props => [receivedBytes, totalBytes];
}

/// User wants to cancel the ongoing download.
class CancelDownloadRequested extends UpdateEvent {
  const CancelDownloadRequested();
}

/// User wants to install the downloaded update (restart app).
class InstallUpdateRequested extends UpdateEvent {
  const InstallUpdateRequested({required this.installerPath});

  final String installerPath;

  @override
  List<Object?> get props => [installerPath];
}

/// User chose to skip this version.
class SkipVersionRequested extends UpdateEvent {
  const SkipVersionRequested({required this.version});

  final String version;

  @override
  List<Object?> get props => [version];
}

/// User chose 'Remind me later'.
class RemindLaterRequested extends UpdateEvent {
  const RemindLaterRequested();
}

/// Dismiss the update notification banner/dialog.
class UpdateDismissed extends UpdateEvent {
  const UpdateDismissed();
}
