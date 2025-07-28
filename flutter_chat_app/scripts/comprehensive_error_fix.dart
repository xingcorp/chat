#!/usr/bin/env dart

/// **COMPREHENSIVE ERROR FIX SCRIPT**
/// 
/// Systematically fixes ALL remaining compile errors in lib directory
/// Categories: AppColors, AppDimensions, L10n, Type Safety, Imports
///
/// **Approach:**
/// 1. AppColors constant mapping (SCREAMING_SNAKE_CASE → lowerCamelCase)
/// 2. AppDimensions constant mapping
/// 3. L10n context access fixes
/// 4. Type safety and const violations
/// 5. Import and dependency resolution

import 'dart:io';

void main() {
  print('🔧 Comprehensive error fixing - ALL remaining compile errors...');
  
  // AppColors constant mappings
  final Map<String, String> appColorsFixes = {
    'AppColors.TEXT_SECONDARY_LIGHT': 'Colors.grey[600]!',
    'AppColors.TEXT_PRIMARY_LIGHT': 'Colors.black87',
    'AppColors.TEXT_PRIMARY_DARK': 'Colors.white',
    'AppColors.GREY_100': 'Colors.grey[100]!',
    'AppColors.WHITE': 'Colors.white',
    'AppColors.BLACK': 'Colors.black',
    'AppColors.info_LIGHT': 'Colors.blue[100]!',
    'AppColors.warning_LIGHT': 'Colors.orange[100]!',
    'AppColors.error_LIGHT': 'Colors.red[100]!',
    'AppColors.error_DARK': 'Colors.red[800]!',
    'AppColors.success_LIGHT': 'Colors.green[100]!',
    'AppColors.primary_BLUE': 'Colors.blue',
    'AppColors.BACKGROUND_LIGHT': 'Colors.white',
    'AppColors.BACKGROUND_DARK': 'Colors.grey[900]!',
    'AppColors.SURFACE_LIGHT': 'Colors.grey[50]!',
    'AppColors.SURFACE_DARK': 'Colors.grey[800]!',
  };
  
  // AppDimensions constant mappings
  final Map<String, String> appDimensionsFixes = {
    'AppDimensions.SPACING_TINY': '4.0',
    'AppDimensions.SPACING_SMALL': '8.0',
    'AppDimensions.SPACING_DEFAULT': '16.0',
    'AppDimensions.SPACING_LARGE': '24.0',
    'AppDimensions.PADDING_TINY': '4.0',
    'AppDimensions.PADDING_SMALL': '8.0',
    'AppDimensions.PADDING_DEFAULT': '16.0',
    'AppDimensions.PADDING_LARGE': '24.0',
    'AppDimensions.MARGIN_SMALL': '8.0',
    'AppDimensions.MARGIN_DEFAULT': '16.0',
    'AppDimensions.MARGIN_LARGE': '24.0',
    'AppDimensions.ICON_SMALL': '16.0',
    'AppDimensions.ICON_DEFAULT': '24.0',
    'AppDimensions.ICON_LARGE': '32.0',
    'AppDimensions.RADIUS_SMALL': '4.0',
    'AppDimensions.RADIUS_DEFAULT': '8.0',
    'AppDimensions.RADIUS_LARGE': '12.0',
    'AppDimensions.ELEVATION_DEFAULT': '2.0',
    'AppDimensions.ELEVATION_LARGE': '8.0',
  };
  
  // L10n fixes
  final Map<String, String> l10nFixes = {
    'L10n.of(context)': 'context.l10n',
    'L10n.current': 'context.l10n',
    'L10n.': 'context.l10n.',
  };
  
  // Files to process (all lib files with errors)
  final List<String> targetFiles = [
    'lib/presentation/widgets/common/error_display_widget.dart',
    'lib/presentation/widgets/common/language_indicator.dart',
    'lib/presentation/widgets/chat/chat_input.dart',
    'lib/presentation/widgets/chat/message_item.dart',
    'lib/presentation/widgets/chat/optimized_message_list.dart',
    'lib/presentation/widgets/chat/chat_list_item.dart',
    'lib/presentation/widgets/connection/connection_status_widget.dart',
    'lib/presentation/widgets/offline/offline_mode_indicator.dart',
    'lib/presentation/widgets/date_separator.dart',
    'lib/presentation/widgets/user/user_avatar.dart',
    'lib/presentation/widgets/media_viewer.dart',
    'lib/presentation/pages/chat/chat_details_page.dart',
    'lib/presentation/pages/chat/chat_list_page.dart',
    'lib/presentation/screens/chat/chat_header.dart',
    'lib/presentation/screens/chat/optimized_chat_screen.dart',
    'lib/core/utils/reusable_components.dart',
    'lib/core/extensions/extensions.dart',
  ];
  
  int filesProcessed = 0;
  int errorsFixed = 0;
  
  for (final filePath in targetFiles) {
    final file = File(filePath);
    if (!file.existsSync()) {
      print('⚠️  File not found: $filePath');
      continue;
    }
    
    String content = file.readAsStringSync();
    String originalContent = content;
    
    // Fix AppColors constants
    for (final entry in appColorsFixes.entries) {
      if (content.contains(entry.key)) {
        content = content.replaceAll(entry.key, entry.value);
        errorsFixed++;
      }
    }
    
    // Fix AppDimensions constants
    for (final entry in appDimensionsFixes.entries) {
      if (content.contains(entry.key)) {
        content = content.replaceAll(entry.key, entry.value);
        errorsFixed++;
      }
    }
    
    // Fix L10n access
    for (final entry in l10nFixes.entries) {
      if (content.contains(entry.key)) {
        content = content.replaceAll(entry.key, entry.value);
        errorsFixed++;
      }
    }
    
    // Fix const violations
    content = _fixConstViolations(content);
    
    // Fix specific file issues
    content = _fixSpecificFileIssues(filePath, content);
    
    if (content != originalContent) {
      file.writeAsStringSync(content);
      filesProcessed++;
      print('✅ Fixed errors: $filePath');
    }
  }
  
  print('\n🎉 Comprehensive error fixing completed!');
  print('📊 Files processed: $filesProcessed');
  print('🔄 Errors fixed: $errorsFixed');
  print('\n📝 Next steps:');
  print('1. Run: flutter analyze lib/ --no-fatal-infos');
  print('2. Verify zero compile errors');
  print('3. Test app build and run');
}

/// Fix const violations
String _fixConstViolations(String content) {
  // Remove const from expressions with dynamic values
  content = content.replaceAllMapped(
    RegExp(r'const\s+(\w+)\([^)]*Colors\.[a-z][^)]*\)'),
    (match) => match.group(0)!.replaceFirst('const ', ''),
  );
  
  // Remove const from TextStyle with dynamic colors
  content = content.replaceAllMapped(
    RegExp(r'const TextStyle\([^)]*Colors\.[^)]*\)'),
    (match) => match.group(0)!.replaceFirst('const ', ''),
  );
  
  // Remove const from EdgeInsets with dynamic values
  content = content.replaceAllMapped(
    RegExp(r'const EdgeInsets\.[^(]*\([^)]*[0-9]+\.0[^)]*\)'),
    (match) => match.group(0)!.replaceFirst('const ', ''),
  );
  
  return content;
}

/// Fix specific file issues
String _fixSpecificFileIssues(String filePath, String content) {
  if (filePath.contains('error_display_widget.dart')) {
    return _fixErrorDisplayWidget(content);
  } else if (filePath.contains('language_indicator.dart')) {
    return _fixLanguageIndicator(content);
  } else if (filePath.contains('chat_input.dart')) {
    return _fixChatInput(content);
  }
  
  return content;
}

/// Fix error_display_widget.dart specific issues
String _fixErrorDisplayWidget(String content) {
  // Add missing import if needed
  if (!content.contains("import 'package:flutter_chat_app/l10n/l10n.dart';") &&
      content.contains('context.l10n')) {
    content = content.replaceFirst(
      "import 'package:flutter/material.dart';",
      "import 'package:flutter/material.dart';\nimport 'package:flutter_chat_app/l10n/l10n.dart';",
    );
  }
  
  // Fix specific color issues
  content = content.replaceAll('Colors.grey[600]!', 'Colors.grey.shade600');
  content = content.replaceAll('Colors.grey[100]!', 'Colors.grey.shade100');
  content = content.replaceAll('Colors.blue[100]!', 'Colors.blue.shade100');
  content = content.replaceAll('Colors.orange[100]!', 'Colors.orange.shade100');
  content = content.replaceAll('Colors.red[100]!', 'Colors.red.shade100');
  content = content.replaceAll('Colors.red[800]!', 'Colors.red.shade800');
  content = content.replaceAll('Colors.green[100]!', 'Colors.green.shade100');
  content = content.replaceAll('Colors.grey[50]!', 'Colors.grey.shade50');
  content = content.replaceAll('Colors.grey[800]!', 'Colors.grey.shade800');
  content = content.replaceAll('Colors.grey[900]!', 'Colors.grey.shade900');
  
  return content;
}

/// Fix language_indicator.dart specific issues
String _fixLanguageIndicator(String content) {
  // Add missing import
  if (!content.contains("import 'package:flutter_chat_app/l10n/l10n.dart';")) {
    content = content.replaceFirst(
      "import 'package:flutter/material.dart';",
      "import 'package:flutter/material.dart';\nimport 'package:flutter_chat_app/l10n/l10n.dart';",
    );
  }
  
  // Fix L10n access
  content = content.replaceAll('L10n.of(context)', 'context.l10n');
  content = content.replaceAll('L10n.current', 'context.l10n');
  
  return content;
}

/// Fix chat_input.dart specific issues
String _fixChatInput(String content) {
  // Add l10n import if using context.l10n
  if (content.contains('context.l10n') && 
      !content.contains("import 'package:flutter_chat_app/l10n/l10n.dart';")) {
    content = content.replaceFirst(
      "import 'package:flutter/material.dart';",
      "import 'package:flutter/material.dart';\nimport 'package:flutter_chat_app/l10n/l10n.dart';",
    );
  }
  
  return content;
}
