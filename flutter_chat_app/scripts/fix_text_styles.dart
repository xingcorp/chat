#!/usr/bin/env dart

/// Script to fix AppTextStyles getter/method pattern violations
/// 
/// Getters (no parameters): bodyLarge, bodyMedium, bodySmall, labelSmall, etc.
/// Methods (with parameters): bodyMediumCustom(), heading1(), etc.

import 'dart:io';

void main() async {
  final libDir = Directory('lib');
  final dartFiles = libDir
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))
      .toList();

  int filesModified = 0;
  int replacements = 0;

  // Getters that should NOT have (context) parameter
  final getters = [
    'bodyLarge',
    'bodyMedium',
    'bodySmall',
    'labelLarge',
    'labelMedium',
    'labelSmall',
    'displayLarge',
    'displayMedium',
    'displaySmall',
    'headlineLarge',
    'headlineMedium',
    'headlineSmall',
    'titleLarge',
    'titleMedium',
    'titleSmall',
  ];

  for (final file in dartFiles) {
    final content = await file.readAsString();
    var modified = content;
    bool changed = false;

    for (final getter in getters) {
      // Pattern: AppTextStyles.bodyMedium(context)
      final pattern = RegExp('AppTextStyles\\.$getter\\(context\\)');
      if (pattern.hasMatch(modified)) {
        modified = modified.replaceAll(pattern, 'AppTextStyles.$getter');
        changed = true;
        replacements++;
      }
    }

    if (changed) {
      await file.writeAsString(modified);
      filesModified++;
      print('✓ Fixed: ${file.path}');
    }
  }

  print('\n✅ Complete!');
  print('Files modified: $filesModified');
  print('Total replacements: $replacements');
}
