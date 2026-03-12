import 'dart:io';

import 'package:flutter/foundation.dart' show debugPrint, kDebugMode, kIsWeb, kReleaseMode;
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:flutter_chat_app/core/config/flavor_config.dart';

/// Handles dotenv loading and environment variable validation.
class EnvValidator {
  EnvValidator._();

  /// Loads the `.env` file matching the current flavor.
  ///
  /// Tries loading from the filesystem first (standalone mode).
  /// Falls back to asset bundle if file not found.
  /// Silently succeeds with empty env if neither source exists
  /// (package mode provides config via [ChatConfig]).
  ///
  /// Returns the file name that was loaded (e.g. `.env.staging`).
  static Future<String> loadDotenvForFlavor() async {
    final fileName = FlavorConfig.instance.isProduction
        ? '.env.production'
        : '.env.staging';
    try {
      if (!kIsWeb) {
        final file = File(fileName);
        if (file.existsSync()) {
          dotenv.testLoad(fileInput: file.readAsStringSync());
          return fileName;
        }
      }
      // Try loading from asset bundle (works when listed in pubspec.yaml assets)
      await dotenv.load(fileName: fileName);
    } catch (e) {
      // In package mode, .env files are not bundled — config comes from
      // ChatConfig. Silently continue with empty env.
      if (kDebugMode) {
        debugPrint(
          'EnvValidator: Could not load $fileName ($e). '
          'This is expected in package mode.',
        );
      }
    }
    return fileName;
  }

  /// Validates that all required keys are present and not placeholder values.
  ///
  /// In release mode, throws [StateError] on failure.
  /// In debug mode, prints a warning instead.
  /// Silently returns if dotenv was never loaded (e.g. no .env file bundled;
  /// the DI layer will fall back to [FlavorConfig] URLs).
  static void validateDotenvConfiguration(String envFileName) {
    // If dotenv failed to load (missing .env file), skip validation.
    // The DI layer in injection.dart will fall back to FlavorConfig URLs.
    if (!dotenv.isInitialized) {
      if (kDebugMode) {
        debugPrint(
          'EnvValidator: dotenv not initialized, skipping validation. '
          'DI will use FlavorConfig URLs as fallback.',
        );
      }
      return;
    }

    final requiredKeys = <String>[
      'GRAPHQL_API_URL',
      'GRAPHQL_WS_URL',
      'SOCKET_URL',
    ];

    final missingKeys = <String>[];
    for (final key in requiredKeys) {
      final value = (dotenv.env[key] ?? '').trim();
      if (value.isEmpty) {
        missingKeys.add(key);
      }
    }

    if (missingKeys.isNotEmpty) {
      final message =
          'Missing required environment keys in $envFileName: ${missingKeys.join(', ')}';
      if (kReleaseMode) {
        throw StateError(message);
      }
      if (kDebugMode) {
        debugPrint(message);
      }
    }

    final placeholderKeys = <String>[];
    for (final key in requiredKeys) {
      final value = (dotenv.env[key] ?? '').trim();
      if (value.isNotEmpty && _looksLikePlaceholderUrl(value)) {
        placeholderKeys.add(key);
      }
    }

    if (placeholderKeys.isNotEmpty) {
      final message =
          'Placeholder environment values detected in $envFileName: ${placeholderKeys.join(', ')}';
      if (kReleaseMode) {
        throw StateError(message);
      }
      if (kDebugMode) {
        debugPrint(message);
      }
    }
  }

  static bool _looksLikePlaceholderUrl(String value) {
    final lower = value.toLowerCase();
    return lower.contains('example.com') ||
        lower.contains('localhost') ||
        lower.contains('enterprise-chat.com');
  }
}
