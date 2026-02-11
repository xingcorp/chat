import 'package:flutter/foundation.dart' show debugPrint, kDebugMode, kReleaseMode;
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:flutter_chat_app/core/config/flavor_config.dart';

/// Handles dotenv loading and environment variable validation.
class EnvValidator {
  EnvValidator._();

  /// Loads the `.env` file matching the current flavor.
  ///
  /// Returns the file name that was loaded (e.g. `.env.staging`).
  static Future<String> loadDotenvForFlavor() async {
    final fileName = FlavorConfig.instance.isProduction
        ? '.env.production'
        : '.env.staging';
    await dotenv.load(fileName: fileName);
    return fileName;
  }

  /// Validates that all required keys are present and not placeholder values.
  ///
  /// In release mode, throws [StateError] on failure.
  /// In debug mode, prints a warning instead.
  static void validateDotenvConfiguration(String envFileName) {
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
