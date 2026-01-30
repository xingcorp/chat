#!/usr/bin/env dart

/// Script to automatically fix remaining compilation errors
/// 
/// This script analyzes flutter analyze output and applies fixes for:
/// 1. Ambiguous imports (ServerException, NetworkException)
/// 2. Missing methods (toDomain, map, etc.)
/// 3. Constructor issues (const, missing parameters)
/// 4. Type mismatches
/// 
/// Usage: dart run scripts/fix_remaining_errors.dart

import 'dart:io';

void main() async {
  print('🔧 Starting automatic error fixes...\n');
  
  // Run flutter analyze to get current errors
  print('📊 Analyzing current errors...');
  final result = await Process.run('flutter', ['analyze'], runInStdMode: true);
  final output = result.stdout.toString() + result.stderr.toString();
  
  // Count errors
  final errorLines = output.split('\n').where((line) => line.contains('error •')).toList();
  print('Found ${errorLines.length} errors\n');
  
  // Fix ambiguous imports
  await fixAmbiguousImports();
  
  // Fix missing toDomain methods
  await fixMissingToDomainMethods();
  
  // Fix const constructor issues
  await fixConstConstructorIssues();
  
  // Fix missing parameters
  await fixMissingParameters();
  
  print('\n✅ Automatic fixes completed!');
  print('Run "flutter analyze" to check remaining errors.');
}

Future<void> fixAmbiguousImports() async {
  print('🔧 Fixing ambiguous imports...');
  
  final files = [
    'lib/data/repositories/chat_repository.dart',
    'lib/data/repositories/message_repository.dart',
  ];
  
  for (final filePath in files) {
    final file = File(filePath);
    if (!file.existsSync()) continue;
    
    var content = await file.readAsString();
    
    // Add qualified imports for ambiguous types
    if (content.contains('import \'package:graphql_flutter/graphql_flutter.dart\'')) {
      // Use qualified import for our exceptions
      content = content.replaceAll(
        'import \'package:flutter_chat_app/core/error/exceptions.dart\';',
        'import \'package:flutter_chat_app/core/error/exceptions.dart\' as app_exceptions;',
      );
      
      // Replace usages
      content = content.replaceAll(
        RegExp(r'on ServerException catch'),
        'on app_exceptions.ServerException catch',
      );
      content = content.replaceAll(
        RegExp(r'on NetworkException catch'),
        'on app_exceptions.NetworkException catch',
      );
      content = content.replaceAll(
        RegExp(r'throw ServerException\('),
        'throw app_exceptions.ServerException(',
      );
      content = content.replaceAll(
        RegExp(r'throw NetworkException\('),
        'throw app_exceptions.NetworkException(',
      );
      
      await file.writeAsString(content);
      print('  ✓ Fixed $filePath');
    }
  }
}

Future<void> fixMissingToDomainMethods() async {
  print('🔧 Adding missing toDomain methods...');
  
  // This would require analyzing DTOs and adding toDomain methods
  // For now, we'll document what needs to be done
  print('  ℹ️  Manual fix required: Add toDomain() methods to DTOs');
}

Future<void> fixConstConstructorIssues() async {
  print('🔧 Fixing const constructor issues...');
  
  final files = [
    'lib/data/datasources/media/media_local_datasource.dart',
    'lib/data/datasources/media/media_remote_datasource.dart',
  ];
  
  for (final filePath in files) {
    final file = File(filePath);
    if (!file.existsSync()) continue;
    
    var content = await file.readAsString();
    
    // Remove const from non-const constructor calls
    content = content.replaceAll(
      RegExp(r'const ServerException\('),
      'ServerException(',
    );
    content = content.replaceAll(
      RegExp(r'const NetworkException\('),
      'NetworkException(',
    );
    content = content.replaceAll(
      RegExp(r'const CacheException\('),
      'CacheException(',
    );
    
    await file.writeAsString(content);
    print('  ✓ Fixed $filePath');
  }
}

Future<void> fixMissingParameters() async {
  print('🔧 Fixing missing parameters...');
  print('  ℹ️  Manual fix required: Review method calls with missing parameters');
}

