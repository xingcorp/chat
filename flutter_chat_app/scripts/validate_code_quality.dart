#!/usr/bin/env dart

/// **CODE QUALITY VALIDATION SCRIPT**
///
/// Professional validation script for enterprise Flutter development:
/// - Automated hardcoded value detection
/// - Code similarity analysis
/// - Architecture compliance checking
/// - Development rules enforcement
///
/// **Usage:** dart run scripts/validate_code_quality.dart

import 'dart:io';
import 'dart:convert';

void main(List<String> arguments) async {
  print('🔍 Flutter Chat App - Code Quality Validation');
  print('=' * 60);

  final validator = CodeQualityValidator();
  final results = await validator.runAllValidations();

  validator.printResults(results);

  // Exit with error code if validation fails
  if (results.hasErrors) {
    exit(1);
  }

  print('\n✅ All validations passed! Code quality is excellent.');
  exit(0);
}

/// **Code Quality Validator**
class CodeQualityValidator {
  /// **Run All Validations**
  Future<ValidationResults> runAllValidations() async {
    final results = ValidationResults();

    print('\n📋 Running validation checks...\n');

    // 1. Check for hardcoded values
    print('1️⃣  Checking for hardcoded values...');
    final hardcodedResults = await _checkHardcodedValues();
    results.addResults('Hardcoded Values', hardcodedResults);

    // 2. Check for duplicate code patterns
    print('2️⃣  Checking for duplicate code patterns...');
    final duplicateResults = await _checkDuplicatePatterns();
    results.addResults('Duplicate Patterns', duplicateResults);

    // 3. Check architecture compliance
    print('3️⃣  Checking architecture compliance...');
    final architectureResults = await _checkArchitectureCompliance();
    results.addResults('Architecture Compliance', architectureResults);

    // 4. Check constant usage
    print('4️⃣  Checking constant usage...');
    final constantResults = await _checkConstantUsage();
    results.addResults('Constant Usage', constantResults);

    // 5. Check reusable component usage
    print('5️⃣  Checking reusable component usage...');
    final reusabilityResults = await _checkReusabilityCompliance();
    results.addResults('Reusability Compliance', reusabilityResults);

    return results;
  }

  /// **Check for Hardcoded Values**
  Future<List<ValidationIssue>> _checkHardcodedValues() async {
    final issues = <ValidationIssue>[];
    final libDir = Directory('lib');

    if (!libDir.existsSync()) {
      return [ValidationIssue(
        type: IssueType.error,
        message: 'lib directory not found',
        file: '',
        line: 0,
      )];
    }

    await for (final entity in libDir.list(recursive: true)) {
      if (entity is File && entity.path.endsWith('.dart')) {
        final content = await entity.readAsString();
        final lines = content.split('\n');

        for (int i = 0; i < lines.length; i++) {
          final line = lines[i];
          final lineNumber = i + 1;

          // Skip comments and imports
          if (line.trim().startsWith('//') || 
              line.trim().startsWith('import') ||
              line.trim().startsWith('export') ||
              line.trim().startsWith('part ')) {
            continue;
          }

          // Check for hardcoded colors
          final colorMatches = RegExp(r'Color\(0x[A-Fa-f0-9]{8}\)').allMatches(line);
          for (final match in colorMatches) {
            if (!_isInConstantsFile(entity.path)) {
              issues.add(ValidationIssue(
                type: IssueType.error,
                message: 'Hardcoded color found: ${match.group(0)}. Use AppColors constants instead.',
                file: entity.path,
                line: lineNumber,
              ));
            }
          }

          // Check for hardcoded dimensions
          final dimensionMatches = RegExp(r'\b\d+\.0?\s*(?=\s*[,\)])').allMatches(line);
          for (final match in dimensionMatches) {
            final value = match.group(0)?.trim();
            if (value != null && 
                double.tryParse(value) != null && 
                double.parse(value) > 1.0 &&
                !_isInConstantsFile(entity.path) &&
                !line.contains('AppDimensions') &&
                !line.contains('MediaQuery')) {
              issues.add(ValidationIssue(
                type: IssueType.warning,
                message: 'Potential hardcoded dimension: $value. Consider using AppDimensions constants.',
                file: entity.path,
                line: lineNumber,
              ));
            }
          }

          // Check for hardcoded strings (longer than 3 characters)
          final stringMatches = RegExp(r"'[^']{4,}'|" r'"[^"]{4,}"').allMatches(line);
          for (final match in stringMatches) {
            if (!_isInConstantsFile(entity.path) &&
                !line.contains('import') &&
                !line.contains('part') &&
                !line.contains('assert') &&
                !line.contains('throw') &&
                !_isTestFile(entity.path)) {
              issues.add(ValidationIssue(
                type: IssueType.info,
                message: 'Potential hardcoded string: ${match.group(0)}. Consider extracting to constants.',
                file: entity.path,
                line: lineNumber,
              ));
            }
          }
        }
      }
    }

    return issues;
  }

  /// **Check for Duplicate Code Patterns**
  Future<List<ValidationIssue>> _checkDuplicatePatterns() async {
    final issues = <ValidationIssue>[];
    
    // Check for duplicate function signatures
    final functionPatterns = <String, List<String>>{};
    final libDir = Directory('lib');

    await for (final entity in libDir.list(recursive: true)) {
      if (entity is File && entity.path.endsWith('.dart')) {
        final content = await entity.readAsString();
        final functionRegex = RegExp(
          r'(?:Future<[^>]*>|[A-Za-z_][A-Za-z0-9_<>]*)\s+([A-Za-z_][A-Za-z0-9_]*)\s*\([^)]*\)',
          multiLine: true,
        );

        final matches = functionRegex.allMatches(content);
        for (final match in matches) {
          final functionName = match.group(1) ?? '';
          if (functionName.isNotEmpty) {
            functionPatterns.putIfAbsent(functionName, () => []).add(entity.path);
          }
        }
      }
    }

    // Report duplicate function names
    functionPatterns.forEach((functionName, files) {
      if (files.length > 1 && !_isCommonFunctionName(functionName)) {
        issues.add(ValidationIssue(
          type: IssueType.warning,
          message: 'Duplicate function name "$functionName" found in ${files.length} files. Consider consolidating.',
          file: files.join(', '),
          line: 0,
        ));
      }
    });

    return issues;
  }

  /// **Check Architecture Compliance**
  Future<List<ValidationIssue>> _checkArchitectureCompliance() async {
    final issues = <ValidationIssue>[];
    final libDir = Directory('lib');

    await for (final entity in libDir.list(recursive: true)) {
      if (entity is File && entity.path.endsWith('.dart')) {
        final content = await entity.readAsString();
        final relativePath = entity.path.replaceFirst('lib/', '');

        // Check layer violations
        if (relativePath.startsWith('domain/')) {
          // Domain layer should not import from data or presentation
          if (content.contains("import 'package:flutter_chat_app/data/") ||
              content.contains("import 'package:flutter_chat_app/presentation/")) {
            issues.add(ValidationIssue(
              type: IssueType.error,
              message: 'Domain layer violation: Domain should not depend on Data or Presentation layers.',
              file: entity.path,
              line: 0,
            ));
          }
        }

        if (relativePath.startsWith('data/')) {
          // Data layer should not import from presentation
          if (content.contains("import 'package:flutter_chat_app/presentation/")) {
            issues.add(ValidationIssue(
              type: IssueType.error,
              message: 'Data layer violation: Data should not depend on Presentation layer.',
              file: entity.path,
              line: 0,
            ));
          }
        }

        // Check for proper error handling pattern
        if (content.contains('Either<') && !content.contains('Failure')) {
          issues.add(ValidationIssue(
            type: IssueType.warning,
            message: 'Either pattern used without Failure type. Use Either<Failure, T> pattern.',
            file: entity.path,
            line: 0,
          ));
        }
      }
    }

    return issues;
  }

  /// **Check Constant Usage**
  Future<List<ValidationIssue>> _checkConstantUsage() async {
    final issues = <ValidationIssue>[];
    
    // Check if constant files exist
    final constantFiles = [
      'lib/core/constants/app_constants.dart',
      'lib/core/constants/app_colors.dart',
      'lib/core/constants/app_dimensions.dart',
    ];

    for (final filePath in constantFiles) {
      final file = File(filePath);
      if (!file.existsSync()) {
        issues.add(ValidationIssue(
          type: IssueType.error,
          message: 'Required constant file missing: $filePath',
          file: filePath,
          line: 0,
        ));
      }
    }

    return issues;
  }

  /// **Check Reusability Compliance**
  Future<List<ValidationIssue>> _checkReusabilityCompliance() async {
    final issues = <ValidationIssue>[];
    
    // Check if reusable components file exists
    final reusableFile = File('lib/core/utils/reusable_components.dart');
    if (!reusableFile.existsSync()) {
      issues.add(ValidationIssue(
        type: IssueType.warning,
        message: 'Reusable components file not found. Create lib/core/utils/reusable_components.dart',
        file: 'lib/core/utils/reusable_components.dart',
        line: 0,
      ));
    }

    return issues;
  }

  /// **Print Results**
  void printResults(ValidationResults results) {
    print('\n📊 Validation Results:');
    print('=' * 60);

    for (final category in results.categories.keys) {
      final categoryIssues = results.categories[category]!;
      final errorCount = categoryIssues.where((i) => i.type == IssueType.error).length;
      final warningCount = categoryIssues.where((i) => i.type == IssueType.warning).length;
      final infoCount = categoryIssues.where((i) => i.type == IssueType.info).length;

      print('\n📋 $category:');
      print('   Errors: $errorCount, Warnings: $warningCount, Info: $infoCount');

      if (categoryIssues.isNotEmpty) {
        for (final issue in categoryIssues.take(5)) {
          final icon = issue.type == IssueType.error ? '❌' : 
                       issue.type == IssueType.warning ? '⚠️' : 'ℹ️';
          print('   $icon ${issue.message}');
          if (issue.file.isNotEmpty && issue.line > 0) {
            print('      📁 ${issue.file}:${issue.line}');
          }
        }
        
        if (categoryIssues.length > 5) {
          print('   ... and ${categoryIssues.length - 5} more issues');
        }
      }
    }

    print('\n📈 Summary:');
    print('   Total Errors: ${results.totalErrors}');
    print('   Total Warnings: ${results.totalWarnings}');
    print('   Total Info: ${results.totalInfo}');
  }

  /// **Helper Methods**
  bool _isInConstantsFile(String filePath) {
    return filePath.contains('/constants/') || filePath.contains('constants.dart');
  }

  bool _isTestFile(String filePath) {
    return filePath.contains('/test/') || filePath.endsWith('_test.dart');
  }

  bool _isCommonFunctionName(String functionName) {
    const commonNames = [
      'build', 'dispose', 'initState', 'didChangeDependencies',
      'toString', 'hashCode', 'operator', 'call', 'main'
    ];
    return commonNames.contains(functionName);
  }
}

/// **Validation Results**
class ValidationResults {
  final Map<String, List<ValidationIssue>> categories = {};

  void addResults(String category, List<ValidationIssue> issues) {
    categories[category] = issues;
  }

  bool get hasErrors => categories.values
      .expand((issues) => issues)
      .any((issue) => issue.type == IssueType.error);

  int get totalErrors => categories.values
      .expand((issues) => issues)
      .where((issue) => issue.type == IssueType.error)
      .length;

  int get totalWarnings => categories.values
      .expand((issues) => issues)
      .where((issue) => issue.type == IssueType.warning)
      .length;

  int get totalInfo => categories.values
      .expand((issues) => issues)
      .where((issue) => issue.type == IssueType.info)
      .length;
}

/// **Validation Issue**
class ValidationIssue {
  final IssueType type;
  final String message;
  final String file;
  final int line;

  const ValidationIssue({
    required this.type,
    required this.message,
    required this.file,
    required this.line,
  });
}

/// **Issue Type**
enum IssueType {
  error,
  warning,
  info,
}
