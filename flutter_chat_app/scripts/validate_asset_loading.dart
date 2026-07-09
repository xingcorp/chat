#!/usr/bin/env dart

/// **ASSET LOADING GUARD**
///
/// Enforces the single-choke-point rule for bundled assets so the chat module
/// renders correctly in BOTH deployment modes (standalone app + embedded
/// package). See `lib/core/config/app_environment.dart`.
///
/// ## Why this guard exists
///
/// Bundled assets resolve differently per mode:
/// - standalone: assets live at the bare path (`assets/icons/...`).
/// - package:    assets live under `packages/flutter_chat_app/assets/...` and
///               MUST be qualified with `package: 'flutter_chat_app'`.
///
/// A raw `Image.asset(...)` / `SvgPicture.asset(...)` / `AssetImage(...)` that
/// forgets the conditional package resolves to nothing in package mode
/// (transparent icons) while looking perfectly fine in standalone — so it
/// slips through local runs and PR review, and only breaks in the host app.
///
/// The fix: every bundled asset goes through a design-system choke-point
/// (`AppIcon`, `AppImage`, `AppAvatar`, `AppReactionEmoji`) that passes
/// `AppEnvironment.assetPackage`. This guard bans the raw loaders everywhere
/// EXCEPT inside `lib/presentation/widgets/design_system/media/`, where those
/// choke-points are implemented.
///
/// **Usage:** dart run scripts/validate_asset_loading.dart

import 'dart:io';

/// Directory holding the sanctioned asset choke-points. Raw loaders are allowed
/// here (and nowhere else).
const String _allowedDir = 'lib/presentation/widgets/design_system/media';

/// Raw asset-loading calls that must not appear outside [_allowedDir].
final List<RegExp> _bannedPatterns = <RegExp>[
  RegExp(r'\bImage\.asset\s*\('),
  RegExp(r'\bSvgPicture\.asset\s*\('),
  RegExp(r'\bAssetImage\s*\('),
];

void main(List<String> arguments) async {
  stdout.writeln('🔍 Asset loading guard (dual-mode package: resolution)');
  stdout.writeln('=' * 60);

  final libDir = Directory('lib');
  if (!libDir.existsSync()) {
    stderr.writeln('❌ Run from the flutter_chat_app root (no lib/ found).');
    exit(2);
  }

  final normalizedAllowed = _allowedDir.replaceAll('\\', '/');
  final violations = <String>[];

  final dartFiles = libDir
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'));

  for (final file in dartFiles) {
    final relative = file.path.replaceAll('\\', '/');

    // Skip the sanctioned choke-point implementations.
    if (relative.contains(normalizedAllowed)) continue;

    final lines = file.readAsLinesSync();
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];

      // Ignore comments and doc references.
      final trimmed = line.trimLeft();
      if (trimmed.startsWith('//') || trimmed.startsWith('*') ||
          trimmed.startsWith('///')) {
        continue;
      }

      for (final pattern in _bannedPatterns) {
        if (pattern.hasMatch(line)) {
          violations.add('$relative:${i + 1}: ${line.trim()}');
          break;
        }
      }
    }
  }

  if (violations.isEmpty) {
    stdout.writeln('\n✅ No raw asset loaders outside $_allowedDir.');
    stdout.writeln('   All bundled assets go through a design-system '
        'choke-point.');
    exit(0);
  }

  stderr.writeln('\n❌ Found ${violations.length} raw asset loader(s) outside '
      '$_allowedDir:\n');
  for (final v in violations) {
    stderr.writeln('  $v');
  }
  stderr.writeln('\nFix: render bundled assets via AppIcon / AppImage / '
      'AppAvatar / AppReactionEmoji, which pass AppEnvironment.assetPackage.');
  stderr.writeln('If you are adding a new choke-point, put it under '
      '$_allowedDir/.');
  exit(1);
}
