#!/usr/bin/env dart

/// **COMPREHENSIVE IMPORT & DEPENDENCY FIX SCRIPT**
/// 
/// Systematically fixes all import and dependency issues
/// to make the Flutter chat app runnable
///
/// **Features:**
/// - Remove unused imports
/// - Fix missing dependencies
/// - Resolve import conflicts
/// - Add missing package imports
/// - Clean up redundant imports

import 'dart:io';

void main() {
  print('🔧 Fixing imports and dependencies systematically...');
  
  // Common import fixes
  final Map<String, List<String>> importFixes = {
    // Remove unused imports
    'unused_imports': [
      "import 'package:flutter_chat_app/l10n/l10n.dart';",
      "import 'package:flutter_screenutil/flutter_screenutil.dart';",
      "import 'package:flutter_chat_app/core/theme/app_colors.dart';",
      "import 'package:flutter/services.dart';",
      "import 'package:dartz/dartz.dart';",
    ],
    
    // Add missing imports
    'missing_imports': [
      "import 'package:injectable/injectable.dart';",
      "import 'package:logger/logger.dart';",
      "import 'package:rxdart/rxdart.dart';",
      "import 'package:socket_io_client/socket_io_client.dart' as io;",
      "import 'package:web_socket_channel/web_socket_channel.dart';",
    ],
  };
  
  // Files to process
  final List<String> targetFiles = [
    'lib/presentation/widgets/chat/chat_input.dart',
    'lib/presentation/blocs/realtime/realtime_message_bloc.dart',
    'lib/core/services/unified_websocket_service.dart',
    'lib/presentation/widgets/common/error_display_widget.dart',
    'lib/presentation/widgets/chat/message_item.dart',
    'lib/presentation/widgets/chat/optimized_message_list.dart',
    'lib/presentation/widgets/chat/chat_list_item.dart',
    'lib/presentation/widgets/connection/connection_status_widget.dart',
    'lib/presentation/widgets/offline/offline_mode_indicator.dart',
    'lib/presentation/widgets/date_separator.dart',
    'lib/presentation/widgets/user/user_avatar.dart',
    'lib/presentation/widgets/common/language_indicator.dart',
    'lib/presentation/widgets/media_viewer.dart',
    'lib/core/utils/reusable_components.dart',
    'lib/core/extensions/extensions.dart',
  ];
  
  int filesProcessed = 0;
  int importsFixed = 0;
  
  for (final filePath in targetFiles) {
    final file = File(filePath);
    if (!file.existsSync()) {
      print('⚠️  File not found: $filePath');
      continue;
    }
    
    String content = file.readAsStringSync();
    String originalContent = content;
    
    // Remove unused imports
    for (final unusedImport in importFixes['unused_imports']!) {
      if (content.contains(unusedImport)) {
        // Check if the import is actually used
        final importName = _extractImportName(unusedImport);
        if (importName != null && !_isImportUsed(content, importName)) {
          content = content.replaceAll('$unusedImport\n', '');
          importsFixed++;
          print('  ❌ Removed unused import: $importName');
        }
      }
    }
    
    // Fix specific file issues
    content = _fixSpecificFileIssues(filePath, content);
    
    if (content != originalContent) {
      file.writeAsStringSync(content);
      filesProcessed++;
      print('✅ Fixed imports: $filePath');
    }
  }
  
  // Fix pubspec.yaml dependencies
  _fixPubspecDependencies();
  
  print('\n🎉 Import and dependency fixing completed!');
  print('📊 Files processed: $filesProcessed');
  print('🔄 Imports fixed: $importsFixed');
  print('\n📝 Next steps:');
  print('1. Run: flutter pub get');
  print('2. Run: flutter analyze lib/');
  print('3. Check remaining errors');
}

/// Extract import name from import statement
String? _extractImportName(String importStatement) {
  final regex = RegExp(r"import\s+'package:([^/]+)/");
  final match = regex.firstMatch(importStatement);
  return match?.group(1);
}

/// Check if import is actually used in the file
bool _isImportUsed(String content, String importName) {
  // Simple heuristic - check if package name appears in code
  final lines = content.split('\n');
  for (final line in lines) {
    if (line.trim().startsWith('import ')) continue;
    if (line.contains(importName)) return true;
  }
  return false;
}

/// Fix specific file issues
String _fixSpecificFileIssues(String filePath, String content) {
  if (filePath.contains('chat_input.dart')) {
    return _fixChatInputFile(content);
  } else if (filePath.contains('realtime_message_bloc.dart')) {
    return _fixRealtimeMessageBlocFile(content);
  } else if (filePath.contains('unified_websocket_service.dart')) {
    return _fixUnifiedWebSocketServiceFile(content);
  }
  
  return content;
}

/// Fix chat_input.dart specific issues
String _fixChatInputFile(String content) {
  // Remove unused imports
  content = content.replaceAll("import 'package:flutter_chat_app/l10n/l10n.dart';\n", '');
  content = content.replaceAll("import 'package:flutter_screenutil/flutter_screenutil.dart';\n", '');
  content = content.replaceAll("import 'package:flutter/services.dart';\n", '');
  content = content.replaceAll("import 'package:flutter_chat_app/core/theme/app_colors.dart';\n", '');
  
  return content;
}

/// Fix realtime_message_bloc.dart specific issues
String _fixRealtimeMessageBlocFile(String content) {
  // Ensure proper imports
  if (!content.contains("import 'package:equatable/equatable.dart';")) {
    content = content.replaceFirst(
      "import 'package:bloc/bloc.dart';",
      "import 'package:bloc/bloc.dart';\nimport 'package:equatable/equatable.dart';",
    );
  }
  
  return content;
}

/// Fix unified_websocket_service.dart specific issues
String _fixUnifiedWebSocketServiceFile(String content) {
  // Ensure proper imports for network info
  if (!content.contains("import '../network/network_info.dart';")) {
    content = content.replaceFirst(
      "import '../constants/app_constants.dart';",
      "import '../constants/app_constants.dart';\nimport '../network/network_info.dart';",
    );
  }
  
  return content;
}

/// Fix pubspec.yaml dependencies
void _fixPubspecDependencies() {
  final pubspecFile = File('pubspec.yaml');
  if (!pubspecFile.existsSync()) {
    print('⚠️  pubspec.yaml not found');
    return;
  }
  
  String content = pubspecFile.readAsStringSync();
  
  // Ensure required dependencies
  final requiredDeps = [
    'bloc: ^8.1.2',
    'equatable: ^2.0.5',
    'injectable: ^2.3.2',
    'logger: ^2.0.2+1',
    'rxdart: ^0.27.7',
    'socket_io_client: ^2.0.3+1',
    'web_socket_channel: ^2.4.0',
  ];
  
  bool modified = false;
  for (final dep in requiredDeps) {
    final packageName = dep.split(':')[0];
    if (!content.contains('$packageName:')) {
      // Add dependency
      final dependenciesIndex = content.indexOf('dependencies:');
      if (dependenciesIndex != -1) {
        final insertIndex = content.indexOf('\n', dependenciesIndex) + 1;
        content = content.substring(0, insertIndex) + 
                 '  $dep\n' + 
                 content.substring(insertIndex);
        modified = true;
        print('  ➕ Added dependency: $packageName');
      }
    }
  }
  
  if (modified) {
    pubspecFile.writeAsStringSync(content);
    print('✅ Updated pubspec.yaml dependencies');
  }
}
