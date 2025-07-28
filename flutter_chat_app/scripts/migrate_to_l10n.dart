#!/usr/bin/env dart

/// Script to migrate hardcoded strings to l10n
/// Usage: dart scripts/migrate_to_l10n.dart

import 'dart:io';

void main() {
  print('🌍 Starting l10n migration...');
  
  // Common hardcoded strings to replace
  final Map<String, String> commonReplacements = {
    // Vietnamese strings
    "'Đang tải...'": "context.l10n.loading",
    "'Lỗi'": "context.l10n.error",
    "'Thử lại'": "context.l10n.retry",
    "'Gửi'": "context.l10n.send",
    "'Hủy'": "context.l10n.cancel",
    "'Lưu'": "context.l10n.save",
    "'Xóa'": "context.l10n.delete",
    "'Đóng'": "context.l10n.close",
    "'OK'": "context.l10n.ok",
    "'Trực tuyến'": "context.l10n.online",
    "'Ngoại tuyến'": "context.l10n.offline",
    "'Hôm nay'": "context.l10n.today",
    "'Hôm qua'": "context.l10n.yesterday",
    "'Tin nhắn mới'": "context.l10n.newMessage",
    "'Nhập tin nhắn...'": "context.l10n.typeMessage",
    "'Chưa có tin nhắn'": "context.l10n.noMessages",
    
    // English strings
    "'Loading...'": "context.l10n.loading",
    "'Error'": "context.l10n.error",
    "'Retry'": "context.l10n.retry",
    "'Send'": "context.l10n.send",
    "'Cancel'": "context.l10n.cancel",
    "'Save'": "context.l10n.save",
    "'Delete'": "context.l10n.delete",
    "'Close'": "context.l10n.close",
    "'OK'": "context.l10n.ok",
    "'Online'": "context.l10n.online",
    "'Offline'": "context.l10n.offline",
    "'Today'": "context.l10n.today",
    "'Yesterday'": "context.l10n.yesterday",
    "'New Message'": "context.l10n.newMessage",
    "'Type a message...'": "context.l10n.typeMessage",
    "'No messages'": "context.l10n.noMessages",
  };
  
  // Files to process
  final List<String> targetFiles = [
    'lib/presentation/pages/auth/register_page.dart',
    'lib/presentation/pages/auth/forgot_password_page.dart',
    'lib/presentation/pages/chat/chat_details_page.dart',
    'lib/presentation/pages/chat/chat_list_page.dart',
    'lib/presentation/pages/error_page.dart',
    'lib/presentation/pages/splash_page.dart',
    'lib/presentation/widgets/chat/chat_input.dart',
    'lib/presentation/widgets/chat/typing_indicator.dart',
    'lib/presentation/widgets/connection_status_widget.dart',
    'lib/presentation/widgets/error/error_recovery_widget.dart',
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
    
    // Add l10n import if not present
    if (!content.contains("import 'package:flutter_chat_app/l10n/l10n.dart';") &&
        !content.contains('context.l10n')) {
      content = content.replaceFirst(
        "import 'package:flutter/material.dart';",
        "import 'package:flutter/material.dart';\nimport 'package:flutter_chat_app/l10n/l10n.dart';",
      );
    }
    
    // Apply replacements
    for (final entry in commonReplacements.entries) {
      if (content.contains(entry.key)) {
        content = content.replaceAll(entry.key, entry.value);
        replacementsMade++;
      }
    }
    
    // Remove const from Text widgets that now use context.l10n
    content = content.replaceAllMapped(
      RegExp(r'const Text\(\s*context\.l10n\.[^)]+\)'),
      (match) => match.group(0)!.replaceFirst('const ', ''),
    );
    
    if (content != originalContent) {
      file.writeAsStringSync(content);
      filesProcessed++;
      print('✅ Processed: $filePath');
    }
  }
  
  print('\n🎉 Migration completed!');
  print('📊 Files processed: $filesProcessed');
  print('🔄 Replacements made: $replacementsMade');
  print('\n📝 Next steps:');
  print('1. Run: flutter gen-l10n');
  print('2. Check for any missing l10n keys');
  print('3. Test the app in both languages');
}
