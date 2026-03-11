import 'dart:io';

import 'package:flutter_chat_app/core/utils/logger.dart';

/// Platform-specific logic to launch the downloaded installer and exit the app.
class UpdateInstallerService {
  /// Launch the downloaded installer and exit the current app process.
  ///
  /// **Windows**: Runs the Inno Setup .exe with /SILENT flag.
  ///   The installer handles closing the running app, upgrading, and restarting.
  ///
  /// **macOS**: Opens the .dmg file using `open` command. The user
  ///   drags the new app to Applications (or .pkg runs automatically).
  Future<void> launchInstallerAndExit(String installerPath) async {
    LogUtils.i('UpdateInstallerService', 'Launching installer: $installerPath');

    if (Platform.isWindows) {
      await _launchWindowsInstaller(installerPath);
    } else if (Platform.isMacOS) {
      await _launchMacOsInstaller(installerPath);
    } else {
      throw UnsupportedError(
        'Auto-update is not supported on ${Platform.operatingSystem}',
      );
    }

    // Give the installer a moment to start, then exit the app
    await Future<void>.delayed(const Duration(seconds: 1));
    exit(0);
  }

  Future<void> _launchWindowsInstaller(String installerPath) async {
    // Inno Setup flags:
    // /SILENT — minimal UI (shows progress bar only)
    // /CLOSEAPPLICATIONS — closes running app before install
    // /RESTARTAPPLICATIONS — restarts app after install
    // /NORESTART — don't restart Windows itself
    await Process.start(
      installerPath,
      [
        '/SILENT',
        '/CLOSEAPPLICATIONS',
        '/RESTARTAPPLICATIONS',
        '/NORESTART',
      ],
      mode: ProcessStartMode.detached,
    );
  }

  Future<void> _launchMacOsInstaller(String installerPath) async {
    if (installerPath.endsWith('.dmg')) {
      // Open the DMG — Finder will mount it and show the drag-to-install window
      await Process.start(
        'open',
        [installerPath],
        mode: ProcessStartMode.detached,
      );
    } else if (installerPath.endsWith('.pkg')) {
      // Open the .pkg installer
      await Process.start(
        'open',
        [installerPath],
        mode: ProcessStartMode.detached,
      );
    }
  }
}
