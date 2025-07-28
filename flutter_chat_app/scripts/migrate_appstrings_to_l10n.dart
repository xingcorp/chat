#!/usr/bin/env dart

/// Migrate AppStrings to context.l10n
/// Final step in l10n migration

import 'dart:io';

void main() {
  print('🔄 Migrating AppStrings to context.l10n...');
  
  // AppStrings to l10n mappings
  final Map<String, String> appStringsToL10n = {
    'AppStrings.replyMessage': 'context.l10n.reply',
    'AppStrings.forwardMessage': 'context.l10n.forward',
    'AppStrings.deleteMessage': 'context.l10n.delete',
    'AppStrings.confirmDelete': 'context.l10n.confirmDelete',
    'AppStrings.cancel': 'context.l10n.cancel',
    'AppStrings.delete': 'context.l10n.delete',
    'AppStrings.retry': 'context.l10n.retry',
    'AppStrings.chats': 'context.l10n.chats',
    'AppStrings.online': 'context.l10n.online',
    'AppStrings.offline': 'context.l10n.offline',
    'AppStrings.typeMessage': 'context.l10n.typeMessage',
    'AppStrings.send': 'context.l10n.send',
    'AppStrings.loading': 'context.l10n.loading',
    'AppStrings.error': 'context.l10n.errorOccurred',
    'AppStrings.noMessages': 'context.l10n.noMessages',
    'AppStrings.today': 'context.l10n.today',
    'AppStrings.yesterday': 'context.l10n.yesterday',
    'AppStrings.login': 'context.l10n.login',
    'AppStrings.register': 'context.l10n.register',
    'AppStrings.forgotPassword': 'context.l10n.forgotPassword',
    'AppStrings.username': 'context.l10n.username',
    'AppStrings.password': 'context.l10n.password',
    'AppStrings.email': 'context.l10n.email',
  };
  
  // Find all Dart files in presentation layer
  final presentationDir = Directory('lib/presentation');
  final dartFiles = presentationDir
      .listSync(recursive: true)
      .where((entity) => entity is File && entity.path.endsWith('.dart'))
      .cast<File>()
      .toList();
  
  int filesProcessed = 0;
  int replacementsMade = 0;
  
  for (final file in dartFiles) {
    String content = file.readAsStringSync();
    String originalContent = content;
    
    // Replace AppStrings with context.l10n
    for (final entry in appStringsToL10n.entries) {
      if (content.contains(entry.key)) {
        content = content.replaceAll(entry.key, entry.value);
        replacementsMade++;
      }
    }
    
    // Add l10n import if needed and remove AppStrings import
    if (content.contains('context.l10n') && 
        !content.contains("import 'package:flutter_chat_app/l10n/l10n.dart';")) {
      
      if (content.contains("import 'package:flutter/material.dart';")) {
        content = content.replaceFirst(
          "import 'package:flutter/material.dart';",
          "import 'package:flutter/material.dart';\nimport 'package:flutter_chat_app/l10n/l10n.dart';",
        );
      }
    }
    
    // Remove AppStrings import if no longer needed
    if (!content.contains('AppStrings.') && 
        content.contains("import 'package:flutter_chat_app/core/localization/app_strings.dart';")) {
      content = content.replaceAll(
        "import 'package:flutter_chat_app/core/localization/app_strings.dart';\n",
        "",
      );
    }
    
    // Remove const from Text widgets using context.l10n
    content = content.replaceAllMapped(
      RegExp(r'const Text\(\s*context\.l10n\.[^)]+\)'),
      (match) => match.group(0)!.replaceFirst('const ', ''),
    );
    
    // Remove const from widgets containing context.l10n
    content = content.replaceAllMapped(
      RegExp(r'const (\w+)\([^)]*context\.l10n[^)]*\)'),
      (match) => match.group(0)!.replaceFirst('const ', ''),
    );
    
    if (content != originalContent) {
      file.writeAsStringSync(content);
      filesProcessed++;
      print('✅ Migrated: ${file.path}');
    }
  }
  
  print('\n🎉 AppStrings to L10n migration completed!');
  print('📊 Files processed: $filesProcessed');
  print('🔄 Replacements made: $replacementsMade');
  
  // Check remaining hardcoded strings
  _checkRemainingStrings();
}

void _checkRemainingStrings() {
  print('\n🔍 Checking remaining hardcoded strings...');
  
  final result = Process.runSync(
    'grep',
    ['-r', 'Text(', 'lib/presentation/', '--include=*.dart'],
  );
  
  if (result.exitCode == 0) {
    final lines = result.stdout.toString().split('\n');
    final hardcodedLines = lines
        .where((line) => line.isNotEmpty)
        .where((line) => !line.contains('context.l10n'))
        .where((line) => !line.contains('L10n.'))
        .where((line) => !line.contains('// Dynamic content'))
        .where((line) => !line.contains('contact['))
        .where((line) => !line.contains('message['))
        .where((line) => !line.contains('\${'))
        .toList();
    
    print('📊 Remaining hardcoded Text widgets: ${hardcodedLines.length}');
    
    if (hardcodedLines.length <= 20) {
      print('\n🎯 Remaining items:');
      for (final line in hardcodedLines.take(10)) {
        print('  • ${line.trim()}');
      }
      if (hardcodedLines.length > 10) {
        print('  ... and ${hardcodedLines.length - 10} more');
      }
    }
    
    if (hardcodedLines.length < 50) {
      print('\n✅ Great progress! Most strings are now localized.');
    }
  }
}
