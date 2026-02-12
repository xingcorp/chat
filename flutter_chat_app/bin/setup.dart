#!/usr/bin/env dart
// ignore_for_file: avoid_print

/// Flutter Chat App Setup Script
///
/// This script helps set up the environment configuration for flutter_chat_app.
/// It copies the appropriate .env file from the package to the host app.
///
/// Usage:
///   dart run flutter_chat_app:setup                    # Copy .env.staging to .env
///   dart run flutter_chat_app:setup --env production   # Copy .env.production to .env
///   dart run flutter_chat_app:setup --interactive      # Interactively configure .env
///   dart run flutter_chat_app:setup --force            # Overwrite existing .env

import 'dart:io';

void main(List<String> args) async {
  final config = _parseArgs(args);

  print('');
  print('╔══════════════════════════════════════════════════════════════╗');
  print('║           Flutter Chat App - Environment Setup              ║');
  print('╚══════════════════════════════════════════════════════════════╝');
  print('');

  final packagePath = _findPackagePath();
  if (packagePath == null) {
    print('❌ Error: Could not find flutter_chat_app package.');
    print('   Make sure you are running this from your project root.');
    exit(1);
  }

  print('📦 Found package at: $packagePath');
  print('');

  // Source file based on environment
  final sourceFileName = config.environment == 'production'
      ? '.env.production'
      : '.env.staging';
  final sourceFile = File('$packagePath/$sourceFileName');

  // Target file in package directory
  final targetFile = File('$packagePath/.env');

  // Check if source exists
  if (!sourceFile.existsSync()) {
    print('❌ Error: $sourceFileName not found in flutter_chat_app package.');
    exit(1);
  }

  // Check if target already exists
  if (targetFile.existsSync() && !config.force) {
    print('ℹ️  File .env already exists.');
    print('   Use --force to overwrite.');
    exit(0);
  }

  if (config.interactive) {
    await _runInteractiveSetup(sourceFile, targetFile, config.environment);
  } else {
    _copyEnvFile(sourceFile, targetFile, sourceFileName);
  }

  print('');
  print('✅ Setup complete!');
  print('');
  print('📝 Created .env from $sourceFileName');
  print('');
  print('Next steps:');
  print('  1. Review .env and update any values if needed');
  print('  2. Run your app: flutter run');
  print('');
}

/// Parse command line arguments
_SetupConfig _parseArgs(List<String> args) {
  bool interactive = false;
  bool force = false;
  String environment = 'staging'; // Default to staging

  for (int i = 0; i < args.length; i++) {
    switch (args[i]) {
      case '--interactive':
      case '-i':
        interactive = true;
        break;
      case '--force':
      case '-f':
        force = true;
        break;
      case '--env':
      case '-e':
        if (i + 1 < args.length) {
          environment = args[++i];
          if (environment != 'staging' && environment != 'production') {
            print('❌ Error: Invalid environment "$environment".');
            print('   Valid options: staging, production');
            exit(1);
          }
        }
        break;
      case '--help':
      case '-h':
        _printHelp();
        exit(0);
    }
  }

  return _SetupConfig(
    interactive: interactive,
    force: force,
    environment: environment,
  );
}

void _printHelp() {
  print('''
Flutter Chat App Setup Script

This script creates the .env file required for standalone app mode.
When using flutter_chat_app as a package, you don't need .env -
configuration is passed via ChatConfig instead.

Usage:
  dart run flutter_chat_app:setup [options]

Options:
  -i, --interactive    Interactively configure environment variables
  -f, --force          Overwrite existing .env file
  -e, --env <name>     Source environment (staging, production)
                       Default: staging
  -h, --help           Show this help message

Examples:
  dart run flutter_chat_app:setup
    → Creates .env from .env.staging (default)

  dart run flutter_chat_app:setup --env production
    → Creates .env from .env.production

  dart run flutter_chat_app:setup --interactive
    → Prompts for key configuration values

  dart run flutter_chat_app:setup --env production --force
    → Overwrites existing .env with production config
''');
}

/// Find the flutter_chat_app package path
String? _findPackagePath() {
  // Check if running from within the package
  if (File('pubspec.yaml').existsSync()) {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    if (pubspec.contains('name: flutter_chat_app')) {
      return '.';
    }
  }

  // Check common locations for the package
  final possiblePaths = [
    'packages/flutter_chat_app',
    'plugins/flutter_chat_app',
    'plugins/chat/flutter_chat_app',
    'modules/flutter_chat_app',
    '../flutter_chat_app',
    'flutter_chat_app',
  ];

  for (final path in possiblePaths) {
    if (File('$path/.env.staging').existsSync() ||
        File('$path/.env.production').existsSync()) {
      return path;
    }
  }

  // Try to find via .dart_tool/package_config.json
  final packageConfigFile = File('.dart_tool/package_config.json');
  if (packageConfigFile.existsSync()) {
    final content = packageConfigFile.readAsStringSync();
    final regex = RegExp(r'"name":\s*"flutter_chat_app"[^}]*"rootUri":\s*"([^"]*)"');
    final match = regex.firstMatch(content);
    if (match != null) {
      var path = match.group(1)!;
      // Convert file:// URI to path
      if (path.startsWith('file://')) {
        path = path.substring(7);
        // Handle Windows paths
        if (Platform.isWindows && path.startsWith('/')) {
          path = path.substring(1);
        }
      }
      // Handle relative paths
      if (path.startsWith('../')) {
        // Resolve relative to .dart_tool directory
        path = '.dart_tool/$path';
      }
      if (File('$path/.env.staging').existsSync() ||
          File('$path/.env.production').existsSync()) {
        return path;
      }
    }
  }

  return null;
}

/// Copy source .env file to target
void _copyEnvFile(File source, File target, String sourceName) {
  print('📄 Copying $sourceName to .env...');

  // Read source and add header comment
  final content = source.readAsStringSync();
  final header = '''
# Generated by: dart run flutter_chat_app:setup
# Source: $sourceName
# Generated at: ${DateTime.now().toIso8601String()}
#
# To regenerate, run: dart run flutter_chat_app:setup --force
#
''';

  target.writeAsStringSync(header + content);
  print('   Done!');
}

/// Run interactive setup - allows customizing key values
Future<void> _runInteractiveSetup(
  File sourceFile,
  File targetFile,
  String environment,
) async {
  print('🔧 Interactive Setup Mode (base: $environment)');
  print('   Press Enter to keep default values');
  print('');

  // Read source file and parse
  final sourceContent = sourceFile.readAsStringSync();
  final lines = sourceContent.split('\n');
  final config = <String, String>{};
  final comments = <String, String>{};

  String? currentSection;

  for (final line in lines) {
    final trimmed = line.trim();

    // Track section comments
    if (trimmed.startsWith('# ') && trimmed.toUpperCase() == trimmed) {
      currentSection = trimmed;
      continue;
    }

    // Skip empty lines and comments
    if (trimmed.isEmpty || trimmed.startsWith('#')) continue;

    // Parse key=value
    final eqIndex = trimmed.indexOf('=');
    if (eqIndex > 0) {
      final key = trimmed.substring(0, eqIndex);
      final value = trimmed.substring(eqIndex + 1);
      config[key] = value;
      if (currentSection != null) {
        comments[key] = currentSection;
      }
    }
  }

  // Interactive prompts for key configurations
  print('─── API Configuration ───');
  config['API_BASE_URL'] = _prompt('API Base URL', config['API_BASE_URL'] ?? '');
  config['GRAPHQL_API_URL'] = _prompt('GraphQL API URL', config['GRAPHQL_API_URL'] ?? '');
  config['GRAPHQL_WS_URL'] = _prompt('GraphQL WS URL', config['GRAPHQL_WS_URL'] ?? '');
  config['SOCKET_URL'] = _prompt('Socket URL', config['SOCKET_URL'] ?? '');

  print('');
  print('─── Firebase Configuration ───');
  config['FIREBASE_PROJECT_ID'] = _prompt('Firebase Project ID', config['FIREBASE_PROJECT_ID'] ?? '');
  config['FIREBASE_API_KEY'] = _prompt('Firebase API Key', config['FIREBASE_API_KEY'] ?? '');

  print('');
  print('─── App Configuration ───');
  config['APP_NAME'] = _prompt('App Name', config['APP_NAME'] ?? '');
  config['ENVIRONMENT'] = _prompt('Environment', config['ENVIRONMENT'] ?? environment);

  // Rebuild the file with updated values
  final buffer = StringBuffer();
  buffer.writeln('# Generated by: dart run flutter_chat_app:setup --interactive');
  buffer.writeln('# Source: .env.$environment');
  buffer.writeln('# Generated at: ${DateTime.now().toIso8601String()}');
  buffer.writeln('#');
  buffer.writeln('# To regenerate, run: dart run flutter_chat_app:setup --force');
  buffer.writeln('');

  // Write all config preserving original structure
  for (final line in lines) {
    final trimmed = line.trim();

    // Preserve section headers
    if (trimmed.startsWith('#')) {
      buffer.writeln(line);
      continue;
    }

    // Preserve empty lines
    if (trimmed.isEmpty) {
      buffer.writeln('');
      continue;
    }

    // Update key=value with potentially modified value
    final eqIndex = trimmed.indexOf('=');
    if (eqIndex > 0) {
      final key = trimmed.substring(0, eqIndex);
      final value = config[key] ?? trimmed.substring(eqIndex + 1);
      buffer.writeln('$key=$value');
    }
  }

  print('');
  print('📄 Writing .env...');
  targetFile.writeAsStringSync(buffer.toString());
  print('   Done!');
}

/// Prompt for a string value
String _prompt(String label, String defaultValue) {
  final displayDefault = defaultValue.length > 50
      ? '${defaultValue.substring(0, 47)}...'
      : defaultValue;
  stdout.write('  $label [$displayDefault]: ');
  final input = stdin.readLineSync()?.trim() ?? '';
  return input.isEmpty ? defaultValue : input;
}

class _SetupConfig {
  final bool interactive;
  final bool force;
  final String environment;

  _SetupConfig({
    required this.interactive,
    required this.force,
    required this.environment,
  });
}
