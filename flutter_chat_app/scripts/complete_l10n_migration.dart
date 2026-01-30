#!/usr/bin/env dart

/// Complete l10n migration script
/// Handles remaining hardcoded strings and complex cases

import 'dart:io';

void main() {
  print('🌍 Completing l10n migration...');
  
  // Advanced replacements for complex cases
  final Map<String, String> advancedReplacements = {
    // Vietnamese strings with context
    "'Tên nhóm'": "context.l10n.groupName",
    "'Thành viên'": "context.l10n.members",
    "'Thêm thành viên'": "context.l10n.addMembers",
    "'Tìm kiếm'": "context.l10n.search",
    "'Tắt thông báo'": "context.l10n.muteNotifications",
    "'Xem thông tin'": "context.l10n.viewInfo",
    
    // Common UI patterns
    "'Không có tin nhắn nào'": "context.l10n.noMessages",
    "'Đang nhập...'": "context.l10n.typing",
    "'Đã xem'": "context.l10n.seen",
    "'Đã gửi'": "context.l10n.sent",
    "'Đang gửi...'": "context.l10n.sending",
    
    // Error messages
    "'Không thể tải tin nhắn'": "context.l10n.cannotLoadMessages",
    "'Mất kết nối'": "context.l10n.connectionLost",
    "'Đang kết nối lại...'": "context.l10n.reconnecting",
    
    // Time-related
    "'vừa xong'": "context.l10n.justNow",
    "'phút trước'": "context.l10n.minutesAgo",
    "'giờ trước'": "context.l10n.hoursAgo",
    
    // English equivalents
    "'Group Name'": "context.l10n.groupName",
    "'Members'": "context.l10n.members",
    "'Add Members'": "context.l10n.addMembers",
    "'Search'": "context.l10n.search",
    "'Mute Notifications'": "context.l10n.muteNotifications",
    "'View Info'": "context.l10n.viewInfo",
    "'No messages'": "context.l10n.noMessages",
    "'Typing...'": "context.l10n.typing",
    "'Seen'": "context.l10n.seen",
    "'Sent'": "context.l10n.sent",
    "'Sending...'": "context.l10n.sending",
    "'Cannot load messages'": "context.l10n.cannotLoadMessages",
    "'Connection lost'": "context.l10n.connectionLost",
    "'Reconnecting...'": "context.l10n.reconnecting",
    "'Just now'": "context.l10n.justNow",
    "'minutes ago'": "context.l10n.minutesAgo",
    "'hours ago'": "context.l10n.hoursAgo",
  };
  
  // Files to process (remaining ones)
  final List<String> remainingFiles = [
    'lib/presentation/widgets/chat/chat_bubble.dart',
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
    'lib/main_desktop.dart',
    'lib/main_web.dart',
    'lib/main_mobile.dart',
  ];
  
  int filesProcessed = 0;
  int replacementsMade = 0;
  
  for (final filePath in remainingFiles) {
    final file = File(filePath);
    if (!file.existsSync()) {
      print('⚠️  File not found: $filePath');
      continue;
    }
    
    String content = file.readAsStringSync();
    String originalContent = content;
    
    // Add l10n import if not present and file contains Text widgets
    if (content.contains('Text(') && 
        !content.contains("import 'package:flutter_chat_app/l10n/l10n.dart';") &&
        !content.contains('context.l10n')) {
      
      // Find the right place to add import
      if (content.contains("import 'package:flutter/material.dart';")) {
        content = content.replaceFirst(
          "import 'package:flutter/material.dart';",
          "import 'package:flutter/material.dart';\nimport 'package:flutter_chat_app/l10n/l10n.dart';",
        );
      }
    }
    
    // Apply advanced replacements
    for (final entry in advancedReplacements.entries) {
      if (content.contains(entry.key)) {
        content = content.replaceAll(entry.key, entry.value);
        replacementsMade++;
      }
    }
    
    // Handle special patterns
    content = _handleSpecialPatterns(content);
    
    // Remove const from Text widgets that now use context.l10n
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
      print('✅ Processed: $filePath');
    }
  }
  
  print('\n🎉 Advanced migration completed!');
  print('📊 Files processed: $filesProcessed');
  print('🔄 Replacements made: $replacementsMade');
  print('\n📝 Next steps:');
  print('1. Run: flutter gen-l10n');
  print('2. Add missing l10n keys to ARB files');
  print('3. Test language switching');
  print('4. Verify all UI strings are localized');
}

String _handleSpecialPatterns(String content) {
  // Handle member count patterns like "5 thành viên"
  content = content.replaceAllMapped(
    RegExp(r"'\$\{(\w+)\} thành viên'"),
    (match) => "context.l10n.memberCount(${match.group(1)})",
  );
  
  // Handle chat title patterns like "Chat \$chatId"
  content = content.replaceAllMapped(
    RegExp(r"'Chat \$\{?(\w+)\}?'"),
    (match) => "context.l10n.chatTitle(${match.group(1)})",
  );
  
  // Handle time patterns
  content = content.replaceAllMapped(
    RegExp(r"'\$\{(\w+)\} phút trước'"),
    (match) => "context.l10n.minutesAgo(${match.group(1)})",
  );
  
  content = content.replaceAllMapped(
    RegExp(r"'\$\{(\w+)\} giờ trước'"),
    (match) => "context.l10n.hoursAgo(${match.group(1)})",
  );
  
  return content;
}
