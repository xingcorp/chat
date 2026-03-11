/// Constants for the auto-update system.
abstract class UpdateConstants {
  /// GitHub Releases API endpoint
  static const String githubApiBaseUrl = 'https://api.github.com';

  /// GitHub repository owner (public repo — no auth needed)
  static const String githubOwner = 'xingcorp';

  /// GitHub repository name
  static const String githubRepo = 'chat';

  /// Fallback JSON endpoint (for future use if GitHub API is unavailable)
  static const String fallbackUpdateUrl =
      'https://updates.oxii.chat/latest.json';

  /// How often to auto-check (4 hours)
  static const Duration checkInterval = Duration(hours: 4);

  /// 'Remind me later' snooze duration (24 hours)
  static const Duration remindLaterDuration = Duration(hours: 24);

  /// Delay before first auto-check after startup (30 seconds)
  static const Duration initialCheckDelay = Duration(seconds: 30);

  /// SharedPreferences keys
  static const String prefSkippedVersion = 'update_skipped_version';
  static const String prefLastCheckTimestamp = 'update_last_check';
  static const String prefRemindLaterTimestamp = 'update_remind_later';

  /// Platform-specific asset name patterns in GitHub Releases
  static const String windowsAssetPattern = '.exe';
  static const String macosAssetPattern = '.dmg';

  /// Checksum file suffix (e.g., 'OXIIChat-2.1.0-setup.exe.sha256')
  static const String checksumSuffix = '.sha256';

  /// Download subdirectory name inside system temp
  static const String downloadSubDir = 'oxii_chat_updates';
}
