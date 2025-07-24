/// **CODE ANALYSIS HELPER - MANDATORY EXISTING CODE ANALYSIS**
///
/// Professional code analysis tools following enterprise standards:
/// - Search entire codebase for similar functionality
/// - Identify reusable patterns and components
/// - Prevent duplicate functionality creation
/// - Enforce code review standards
///
/// **Architecture:** Clean Architecture + Code Quality Tools

import 'dart:io';

/// **CODE ANALYSIS HELPER**
class CodeAnalysisHelper {
  // Private constructor to prevent instantiation
  CodeAnalysisHelper._();

  /// **Search Keywords in Codebase**
  /// 
  /// Comprehensive keyword search across the entire codebase
  /// 
  /// Usage:
  /// ```dart
  /// final results = await CodeAnalysisHelper.searchKeywords([
  ///   'authentication', 'login', 'auth'
  /// ]);
  /// ```
  static Future<List<SearchResult>> searchKeywords(
    List<String> keywords, {
    List<String> fileExtensions = const ['.dart'],
    List<String> excludeDirectories = const [
      'build',
      '.dart_tool',
      '.git',
      'node_modules'
    ],
  }) async {
    final results = <SearchResult>[];
    final projectRoot = Directory.current;

    await for (final entity in projectRoot.list(recursive: true)) {
      if (entity is File) {
        final path = entity.path;
        
        // Skip excluded directories
        if (excludeDirectories.any((dir) => path.contains('/$dir/'))) {
          continue;
        }

        // Check file extension
        if (!fileExtensions.any((ext) => path.endsWith(ext))) {
          continue;
        }

        try {
          final content = await entity.readAsString();
          final lines = content.split('\n');

          for (int i = 0; i < lines.length; i++) {
            final line = lines[i];
            for (final keyword in keywords) {
              if (line.toLowerCase().contains(keyword.toLowerCase())) {
                results.add(SearchResult(
                  filePath: path,
                  lineNumber: i + 1,
                  lineContent: line.trim(),
                  keyword: keyword,
                ));
              }
            }
          }
        } catch (e) {
          // Skip files that can't be read
          continue;
        }
      }
    }

    return results;
  }

  /// **Find Similar Functions**
  /// 
  /// Find functions with similar names or patterns
  /// 
  /// Usage:
  /// ```dart
  /// final functions = await CodeAnalysisHelper.findSimilarFunctions('login');
  /// ```
  static Future<List<FunctionMatch>> findSimilarFunctions(
    String functionPattern,
  ) async {
    final results = <FunctionMatch>[];
    final projectRoot = Directory.current;

    final functionRegex = RegExp(
      r'(?:Future<[^>]*>|[A-Za-z_][A-Za-z0-9_<>]*)\s+([A-Za-z_][A-Za-z0-9_]*)\s*\([^)]*\)\s*(?:async\s*)?{',
      multiLine: true,
    );

    await for (final entity in projectRoot.list(recursive: true)) {
      if (entity is File && entity.path.endsWith('.dart')) {
        try {
          final content = await entity.readAsString();
          final matches = functionRegex.allMatches(content);

          for (final match in matches) {
            final functionName = match.group(1) ?? '';
            if (functionName.toLowerCase().contains(functionPattern.toLowerCase())) {
              final lines = content.substring(0, match.start).split('\n');
              results.add(FunctionMatch(
                filePath: entity.path,
                functionName: functionName,
                lineNumber: lines.length,
                signature: match.group(0) ?? '',
              ));
            }
          }
        } catch (e) {
          continue;
        }
      }
    }

    return results;
  }

  /// **Find Similar Classes**
  /// 
  /// Find classes with similar names or patterns
  /// 
  /// Usage:
  /// ```dart
  /// final classes = await CodeAnalysisHelper.findSimilarClasses('Repository');
  /// ```
  static Future<List<ClassMatch>> findSimilarClasses(
    String classPattern,
  ) async {
    final results = <ClassMatch>[];
    final projectRoot = Directory.current;

    final classRegex = RegExp(
      r'(?:abstract\s+)?class\s+([A-Za-z_][A-Za-z0-9_]*)',
      multiLine: true,
    );

    await for (final entity in projectRoot.list(recursive: true)) {
      if (entity is File && entity.path.endsWith('.dart')) {
        try {
          final content = await entity.readAsString();
          final matches = classRegex.allMatches(content);

          for (final match in matches) {
            final className = match.group(1) ?? '';
            if (className.toLowerCase().contains(classPattern.toLowerCase())) {
              final lines = content.substring(0, match.start).split('\n');
              results.add(ClassMatch(
                filePath: entity.path,
                className: className,
                lineNumber: lines.length,
                isAbstract: match.group(0)?.contains('abstract') ?? false,
              ));
            }
          }
        } catch (e) {
          continue;
        }
      }
    }

    return results;
  }

  /// **Find Hardcoded Values**
  /// 
  /// Find hardcoded strings, numbers, and colors in the codebase
  /// 
  /// Usage:
  /// ```dart
  /// final hardcoded = await CodeAnalysisHelper.findHardcodedValues();
  /// ```
  static Future<List<HardcodedValue>> findHardcodedValues() async {
    final results = <HardcodedValue>[];
    final projectRoot = Directory.current;

    // Patterns for hardcoded values
    final patterns = {
      'string': RegExp(r"'[^']{3,}'|\"[^\"]{3,}\""),
      'number': RegExp(r'\b\d+\.?\d*\b'),
      'color': RegExp(r'Color\(0x[A-Fa-f0-9]{8}\)'),
      'dimension': RegExp(r'\b\d+\.?\d*\s*(?:px|dp|sp)\b'),
    };

    await for (final entity in projectRoot.list(recursive: true)) {
      if (entity is File && entity.path.endsWith('.dart')) {
        try {
          final content = await entity.readAsString();
          final lines = content.split('\n');

          for (int i = 0; i < lines.length; i++) {
            final line = lines[i];
            
            // Skip comments and imports
            if (line.trim().startsWith('//') || 
                line.trim().startsWith('import') ||
                line.trim().startsWith('export')) {
              continue;
            }

            for (final entry in patterns.entries) {
              final matches = entry.value.allMatches(line);
              for (final match in matches) {
                results.add(HardcodedValue(
                  filePath: entity.path,
                  lineNumber: i + 1,
                  lineContent: line.trim(),
                  value: match.group(0) ?? '',
                  type: entry.key,
                ));
              }
            }
          }
        } catch (e) {
          continue;
        }
      }
    }

    return results;
  }

  /// **Generate Analysis Report**
  /// 
  /// Generate comprehensive analysis report
  /// 
  /// Usage:
  /// ```dart
  /// final report = await CodeAnalysisHelper.generateAnalysisReport([
  ///   'authentication', 'message', 'chat'
  /// ]);
  /// ```
  static Future<AnalysisReport> generateAnalysisReport(
    List<String> keywords,
  ) async {
    final searchResults = await searchKeywords(keywords);
    final hardcodedValues = await findHardcodedValues();
    
    final functionMatches = <FunctionMatch>[];
    final classMatches = <ClassMatch>[];
    
    for (final keyword in keywords) {
      functionMatches.addAll(await findSimilarFunctions(keyword));
      classMatches.addAll(await findSimilarClasses(keyword));
    }

    return AnalysisReport(
      keywords: keywords,
      searchResults: searchResults,
      functionMatches: functionMatches,
      classMatches: classMatches,
      hardcodedValues: hardcodedValues,
      generatedAt: DateTime.now(),
    );
  }

  /// **Print Analysis Report**
  /// 
  /// Print formatted analysis report to console
  static void printAnalysisReport(AnalysisReport report) {
    print('\n' + '=' * 80);
    print('CODE ANALYSIS REPORT');
    print('Generated at: ${report.generatedAt}');
    print('Keywords: ${report.keywords.join(', ')}');
    print('=' * 80);

    print('\n📋 SEARCH RESULTS (${report.searchResults.length} found):');
    for (final result in report.searchResults.take(10)) {
      print('  ${result.filePath}:${result.lineNumber} - ${result.keyword}');
      print('    ${result.lineContent}');
    }

    print('\n🔧 SIMILAR FUNCTIONS (${report.functionMatches.length} found):');
    for (final match in report.functionMatches.take(10)) {
      print('  ${match.filePath}:${match.lineNumber} - ${match.functionName}');
    }

    print('\n📦 SIMILAR CLASSES (${report.classMatches.length} found):');
    for (final match in report.classMatches.take(10)) {
      print('  ${match.filePath}:${match.lineNumber} - ${match.className}');
    }

    print('\n⚠️  HARDCODED VALUES (${report.hardcodedValues.length} found):');
    for (final value in report.hardcodedValues.take(10)) {
      print('  ${value.filePath}:${value.lineNumber} - ${value.type}: ${value.value}');
    }

    print('\n' + '=' * 80);
  }
}

/// **Search Result Model**
class SearchResult {
  final String filePath;
  final int lineNumber;
  final String lineContent;
  final String keyword;

  const SearchResult({
    required this.filePath,
    required this.lineNumber,
    required this.lineContent,
    required this.keyword,
  });

  @override
  String toString() {
    return '$filePath:$lineNumber - $keyword: $lineContent';
  }
}

/// **Function Match Model**
class FunctionMatch {
  final String filePath;
  final String functionName;
  final int lineNumber;
  final String signature;

  const FunctionMatch({
    required this.filePath,
    required this.functionName,
    required this.lineNumber,
    required this.signature,
  });

  @override
  String toString() {
    return '$filePath:$lineNumber - $functionName';
  }
}

/// **Class Match Model**
class ClassMatch {
  final String filePath;
  final String className;
  final int lineNumber;
  final bool isAbstract;

  const ClassMatch({
    required this.filePath,
    required this.className,
    required this.lineNumber,
    required this.isAbstract,
  });

  @override
  String toString() {
    return '$filePath:$lineNumber - ${isAbstract ? 'abstract ' : ''}$className';
  }
}

/// **Hardcoded Value Model**
class HardcodedValue {
  final String filePath;
  final int lineNumber;
  final String lineContent;
  final String value;
  final String type;

  const HardcodedValue({
    required this.filePath,
    required this.lineNumber,
    required this.lineContent,
    required this.value,
    required this.type,
  });

  @override
  String toString() {
    return '$filePath:$lineNumber - $type: $value';
  }
}

/// **Analysis Report Model**
class AnalysisReport {
  final List<String> keywords;
  final List<SearchResult> searchResults;
  final List<FunctionMatch> functionMatches;
  final List<ClassMatch> classMatches;
  final List<HardcodedValue> hardcodedValues;
  final DateTime generatedAt;

  const AnalysisReport({
    required this.keywords,
    required this.searchResults,
    required this.functionMatches,
    required this.classMatches,
    required this.hardcodedValues,
    required this.generatedAt,
  });

  /// **Get Summary**
  String get summary {
    return '''
Analysis Summary:
- Keywords searched: ${keywords.length}
- Search results: ${searchResults.length}
- Similar functions: ${functionMatches.length}
- Similar classes: ${classMatches.length}
- Hardcoded values: ${hardcodedValues.length}
''';
  }
}

/// **Usage Examples:**
/// 
/// ```dart
/// // Before implementing new authentication feature
/// void main() async {
///   final report = await CodeAnalysisHelper.generateAnalysisReport([
///     'auth', 'login', 'authentication', 'user', 'token'
///   ]);
///   
///   CodeAnalysisHelper.printAnalysisReport(report);
///   
///   // Review results before implementing
///   if (report.functionMatches.isNotEmpty) {
///     print('⚠️  Similar functions found! Review before implementing:');
///     for (final match in report.functionMatches) {
///       print('  - ${match.functionName} in ${match.filePath}');
///     }
///   }
/// }
/// ```
