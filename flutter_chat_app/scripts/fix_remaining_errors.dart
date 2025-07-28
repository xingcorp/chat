#!/usr/bin/env dart

/// Fix remaining errors in lib directory
/// Systematic approach to resolve all critical errors

import 'dart:io';

void main() {
  print('🔧 Fixing remaining errors in lib directory...');
  
  // Common error fixes
  final Map<String, String> errorFixes = {
    // Import fixes
    "import 'package:flutter_chat_app/core/constants/app_colors.dart';": 
        "import 'package:flutter_chat_app/core/theme/app_colors.dart';",
    
    // AppColors constant fixes
    'AppColors.TEXT_PRIMARY_LIGHT': 'AppColors.textPrimary',
    'AppColors.TEXT_PRIMARY_DARK': 'AppColors.textPrimaryDarkMode',
    'AppColors.BACKGROUND_LIGHT': 'AppColors.backgroundLight',
    'AppColors.BACKGROUND_DARK': 'AppColors.backgroundDark',
    'AppColors.SURFACE_LIGHT': 'AppColors.surfaceLight',
    'AppColors.SURFACE_DARK': 'AppColors.surfaceDark',
    'AppColors.PRIMARY': 'AppColors.primary',
    'AppColors.SECONDARY': 'AppColors.secondary',
    'AppColors.ERROR': 'AppColors.error',
    'AppColors.SUCCESS': 'AppColors.success',
    'AppColors.WARNING': 'AppColors.warning',
    'AppColors.INFO': 'AppColors.info',
    
    // AppDimensions constant fixes
    'AppDimensions.PADDING_DEFAULT': 'AppDimensions.paddingDefault',
    'AppDimensions.PADDING_LARGE': 'AppDimensions.paddingLarge',
    'AppDimensions.PADDING_SMALL': 'AppDimensions.paddingSmall',
    'AppDimensions.MARGIN_DEFAULT': 'AppDimensions.marginDefault',
    'AppDimensions.SPACING_DEFAULT': 'AppDimensions.spacingDefault',
    'AppDimensions.ICON_DEFAULT': 'AppDimensions.iconDefault',
    'AppDimensions.ICON_LARGE': 'AppDimensions.iconLarge',
    'AppDimensions.RADIUS_DEFAULT': 'AppDimensions.radiusDefault',
    'AppDimensions.ELEVATION_DEFAULT': 'AppDimensions.elevationDefault',
    
    // Remove const from dynamic expressions
    'const TextStyle(color: AppColors.': 'TextStyle(color: AppColors.',
    'const Text(context.l10n.': 'Text(context.l10n.',
  };
  
  // Files to process
  final List<String> targetFiles = [
    'lib/presentation/widgets/chat/chat_input.dart',
    'lib/presentation/widgets/common/error_display_widget.dart',
    'lib/presentation/widgets/common/loading_widget.dart',
    'lib/presentation/widgets/common/message_bubble.dart',
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
  int replacementsMade = 0;
  
  for (final filePath in targetFiles) {
    final file = File(filePath);
    if (!file.existsSync()) {
      print('⚠️  File not found: $filePath');
      continue;
    }
    
    String content = file.readAsStringSync();
    String originalContent = content;
    
    // Apply error fixes
    for (final entry in errorFixes.entries) {
      if (content.contains(entry.key)) {
        content = content.replaceAll(entry.key, entry.value);
        replacementsMade++;
      }
    }
    
    // Handle context access in chat_input.dart
    if (filePath.contains('chat_input.dart')) {
      content = _fixChatInputContext(content);
    }
    
    // Handle error_display_widget.dart specific issues
    if (filePath.contains('error_display_widget.dart')) {
      content = _fixErrorDisplayWidget(content);
    }
    
    if (content != originalContent) {
      file.writeAsStringSync(content);
      filesProcessed++;
      print('✅ Fixed: $filePath');
    }
  }
  
  print('\n🎉 Error fixing completed!');
  print('📊 Files processed: $filesProcessed');
  print('🔄 Replacements made: $replacementsMade');
  print('\n📝 Next steps:');
  print('1. Run: flutter analyze lib/');
  print('2. Check remaining errors');
  print('3. Fix any remaining issues manually');
}

String _fixChatInputContext(String content) {
  // Fix context access in chat_input.dart
  // This is a placeholder - specific fixes would go here
  return content;
}

String _fixErrorDisplayWidget(String content) {
  // Fix error_display_widget.dart specific issues
  content = content.replaceAll(
    'const TextStyle(color: AppColors.textPrimary)',
    'TextStyle(color: AppColors.textPrimary)',
  );
  
  content = content.replaceAll(
    'const TextStyle(color: AppColors.error)',
    'TextStyle(color: AppColors.error)',
  );
  
  return content;
}
