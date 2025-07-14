---
type: "always_apply"
description: "Comprehensive file length management with automated enforcement and refactoring guidelines"
---

# File Length Management Rules - Enterprise Messaging App

**Type**: Always  
**Description**: Comprehensive file length limitations with automated enforcement, refactoring guidelines, and maintainability standards for Flutter messaging app

## File Length Standards

### Maximum File Length Thresholds
```dart
class FileLengthStandards {
  // Standard file length limits (lines of code)
  static const Map<FileType, FileLengthLimit> limits = {
    FileType.entity: FileLengthLimit(
      warning: 150,
      error: 200,
      description: 'Domain entities should be simple and focused',
    ),
    FileType.repository: FileLengthLimit(
      warning: 200,
      error: 300,
      description: 'Repository interfaces should be concise',
    ),
    FileType.repositoryImpl: FileLengthLimit(
      warning: 300,
      error: 400,
      description: 'Repository implementations with error handling',
    ),
    FileType.useCase: FileLengthLimit(
      warning: 100,
      error: 150,
      description: 'Use cases should have single responsibility',
    ),
    FileType.bloc: FileLengthLimit(
      warning: 250,
      error: 350,
      description: 'BLoC classes with event/state handling',
    ),
    FileType.widget: FileLengthLimit(
      warning: 200,
      error: 300,
      description: 'UI widgets should be focused and reusable',
    ),
    FileType.screen: FileLengthLimit(
      warning: 300,
      error: 400,
      description: 'Screen widgets with complex layouts',
    ),
    FileType.service: FileLengthLimit(
      warning: 250,
      error: 350,
      description: 'Service classes with multiple operations',
    ),
    FileType.dataSource: FileLengthLimit(
      warning: 200,
      error: 300,
      description: 'Data source implementations',
    ),
    FileType.model: FileLengthLimit(
      warning: 150,
      error: 200,
      description: 'Data models with serialization',
    ),
    FileType.test: FileLengthLimit(
      warning: 400,
      error: 500,
      description: 'Test files with comprehensive coverage',
    ),
    FileType.constants: FileLengthLimit(
      warning: 100,
      error: 150,
      description: 'Constants and configuration files',
    ),
  };
  
  // Special exceptions for specific file types
  static const Map<String, FileLengthLimit> exceptions = {
    'generated_files': FileLengthLimit(
      warning: 1000,
      error: 2000,
      description: 'Auto-generated files (*.g.dart, *.freezed.dart)',
    ),
    'legacy_migration': FileLengthLimit(
      warning: 600,
      error: 800,
      description: 'Legacy files during migration period',
    ),
    'complex_algorithms': FileLengthLimit(
      warning: 400,
      error: 500,
      description: 'Complex algorithms with detailed documentation',
    ),
  };
}
```

### File Type Detection
```dart
class FileTypeDetector {
  static FileType detectFileType(String filePath, String content) {
    final fileName = path.basename(filePath);
    final directory = path.dirname(filePath);
    
    // Generated files
    if (fileName.endsWith('.g.dart') || 
        fileName.endsWith('.freezed.dart') ||
        fileName.endsWith('.gr.dart')) {
      return FileType.generated;
    }
    
    // Test files
    if (filePath.contains('/test/') || fileName.endsWith('_test.dart')) {
      return FileType.test;
    }
    
    // Domain layer
    if (directory.contains('/domain/entities/')) {
      return FileType.entity;
    }
    if (directory.contains('/domain/repositories/')) {
      return FileType.repository;
    }
    if (directory.contains('/domain/usecases/') || fileName.endsWith('_usecase.dart')) {
      return FileType.useCase;
    }
    
    // Data layer
    if (directory.contains('/data/repositories/') || fileName.endsWith('_repository_impl.dart')) {
      return FileType.repositoryImpl;
    }
    if (directory.contains('/data/datasources/') || fileName.endsWith('_data_source.dart')) {
      return FileType.dataSource;
    }
    if (directory.contains('/data/models/') || fileName.endsWith('_model.dart')) {
      return FileType.model;
    }
    
    // Presentation layer
    if (fileName.endsWith('_bloc.dart') || fileName.endsWith('_cubit.dart')) {
      return FileType.bloc;
    }
    if (directory.contains('/presentation/screens/') || fileName.endsWith('_screen.dart') || fileName.endsWith('_page.dart')) {
      return FileType.screen;
    }
    if (directory.contains('/presentation/widgets/') || _isWidgetFile(content)) {
      return FileType.widget;
    }
    
    // Core/Services
    if (directory.contains('/core/services/') || fileName.endsWith('_service.dart')) {
      return FileType.service;
    }
    if (fileName.contains('constants') || fileName.contains('config')) {
      return FileType.constants;
    }
    
    return FileType.general;
  }
  
  static bool _isWidgetFile(String content) {
    return content.contains('extends StatelessWidget') ||
           content.contains('extends StatefulWidget') ||
           content.contains('extends ConsumerWidget');
  }
}
```

## Automated File Length Validation

### Pre-commit Hook Integration
```bash
#!/bin/bash
# .augment/scripts/file-length-validator.sh

echo "📏 Checking file length compliance..."

# Find all Dart files excluding generated files
dart_files=$(find lib test -name "*.dart" ! -name "*.g.dart" ! -name "*.freezed.dart" ! -name "*.gr.dart")

violations=()
warnings=()

for file in $dart_files; do
    line_count=$(wc -l < "$file")
    
    # Run Dart file length analyzer
    result=$(dart run file_length_analyzer "$file" "$line_count")
    
    if [[ $result == ERROR:* ]]; then
        violations+=("$result")
    elif [[ $result == WARNING:* ]]; then
        warnings+=("$result")
    fi
done

# Report warnings
if [ ${#warnings[@]} -gt 0 ]; then
    echo "⚠️  File length warnings:"
    for warning in "${warnings[@]}"; do
        echo "  $warning"
    done
fi

# Report violations and fail if any
if [ ${#violations[@]} -gt 0 ]; then
    echo "❌ File length violations found:"
    for violation in "${violations[@]}"; do
        echo "  $violation"
    done
    echo ""
    echo "Please refactor large files before committing."
    echo "See .augment/rules/core/file_length_management.md for guidelines."
    exit 1
fi

echo "✅ All files comply with length standards"
```

### Dart Analyzer Implementation
```dart
// tools/file_length_analyzer.dart
import 'dart:io';
import 'package:path/path.dart' as path;

class FileLengthAnalyzer {
  static Future<void> main(List<String> args) async {
    if (args.length != 2) {
      print('Usage: dart run file_length_analyzer <file_path> <line_count>');
      exit(1);
    }
    
    final filePath = args[0];
    final lineCount = int.parse(args[1]);
    
    final result = await analyzeFile(filePath, lineCount);
    print(result.message);
    
    if (result.isError) {
      exit(1);
    }
  }
  
  static Future<AnalysisResult> analyzeFile(String filePath, int lineCount) async {
    final content = await File(filePath).readAsString();
    final fileType = FileTypeDetector.detectFileType(filePath, content);
    
    // Check for exceptions first
    final exception = _checkExceptions(filePath, content);
    if (exception != null) {
      return _validateAgainstLimit(filePath, lineCount, exception, fileType);
    }
    
    // Use standard limits
    final limit = FileLengthStandards.limits[fileType] ?? 
                  FileLengthStandards.limits[FileType.general]!;
    
    return _validateAgainstLimit(filePath, lineCount, limit, fileType);
  }
  
  static AnalysisResult _validateAgainstLimit(
    String filePath,
    int lineCount,
    FileLengthLimit limit,
    FileType fileType,
  ) {
    if (lineCount > limit.error) {
      return AnalysisResult.error(
        'ERROR: $filePath ($lineCount lines) exceeds maximum ${limit.error} lines for ${fileType.name}. ${limit.description}',
      );
    } else if (lineCount > limit.warning) {
      return AnalysisResult.warning(
        'WARNING: $filePath ($lineCount lines) exceeds recommended ${limit.warning} lines for ${fileType.name}. Consider refactoring.',
      );
    }
    
    return AnalysisResult.success('$filePath: OK ($lineCount lines)');
  }
  
  static FileLengthLimit? _checkExceptions(String filePath, String content) {
    // Generated files
    if (filePath.endsWith('.g.dart') || 
        filePath.endsWith('.freezed.dart') ||
        filePath.endsWith('.gr.dart')) {
      return FileLengthStandards.exceptions['generated_files'];
    }
    
    // Legacy migration files (temporary)
    if (content.contains('// TODO: Refactor during migration') ||
        content.contains('// LEGACY:')) {
      return FileLengthStandards.exceptions['legacy_migration'];
    }
    
    // Complex algorithms with extensive documentation
    if (_hasComplexAlgorithm(content)) {
      return FileLengthStandards.exceptions['complex_algorithms'];
    }
    
    return null;
  }
  
  static bool _hasComplexAlgorithm(String content) {
    final algorithmIndicators = [
      'encryption',
      'compression',
      'sorting algorithm',
      'search algorithm',
      'mathematical computation',
      'complex calculation',
    ];
    
    final commentLines = content
        .split('\n')
        .where((line) => line.trim().startsWith('//') || line.trim().startsWith('*'))
        .length;
    
    // If more than 30% of file is comments and contains algorithm indicators
    final totalLines = content.split('\n').length;
    final commentRatio = commentLines / totalLines;
    
    return commentRatio > 0.3 && 
           algorithmIndicators.any((indicator) => 
               content.toLowerCase().contains(indicator));
  }
}
```

## Refactoring Guidelines

### When to Refactor
```dart
class RefactoringTriggers {
  static const Map<String, RefactoringStrategy> strategies = {
    'large_widget': RefactoringStrategy(
      trigger: 'Widget file > 300 lines',
      actions: [
        'Extract child widgets into separate files',
        'Create reusable component widgets',
        'Split complex build methods',
        'Use composition over large inheritance',
      ],
      example: '''
// Before: Large widget file (400+ lines)
class ChatScreen extends StatefulWidget {
  // Massive build method with nested widgets
}

// After: Refactored into smaller components
class ChatScreen extends StatefulWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ChatAppBar(),
      body: ChatMessageList(),
      bottomSheet: MessageInputArea(),
    );
  }
}

// Separate files:
// - chat_app_bar.dart
// - chat_message_list.dart  
// - message_input_area.dart
      ''',
    ),
    
    'large_bloc': RefactoringStrategy(
      trigger: 'BLoC file > 350 lines',
      actions: [
        'Split events into logical groups',
        'Extract complex event handlers',
        'Create separate BLoCs for different concerns',
        'Use composition with multiple smaller BLoCs',
      ],
      example: '''
// Before: Large BLoC handling everything
class ChatBloc extends Bloc<ChatEvent, ChatState> {
  // Handles messages, typing, file upload, etc.
}

// After: Split into focused BLoCs
class MessageBloc extends Bloc<MessageEvent, MessageState> {
  // Only handles message operations
}

class TypingBloc extends Bloc<TypingEvent, TypingState> {
  // Only handles typing indicators
}

class FileUploadBloc extends Bloc<FileUploadEvent, FileUploadState> {
  // Only handles file uploads
}
      ''',
    ),
    
    'large_repository': RefactoringStrategy(
      trigger: 'Repository implementation > 400 lines',
      actions: [
        'Split into multiple repositories by domain',
        'Extract common operations to base class',
        'Create separate data sources',
        'Use composition with helper services',
      ],
      example: '''
// Before: Large repository
class ChatRepositoryImpl implements ChatRepository {
  // Handles messages, users, conversations, files, etc.
}

// After: Split by domain
class MessageRepositoryImpl implements MessageRepository {
  // Only message operations
}

class ConversationRepositoryImpl implements ConversationRepository {
  // Only conversation operations
}

class FileRepositoryImpl implements FileRepository {
  // Only file operations
}
      ''',
    ),
  };
}
```

### Automated Refactoring Suggestions
```dart
class RefactoringSuggestionGenerator {
  static List<RefactoringSuggestion> generateSuggestions(
    String filePath,
    String content,
    int lineCount,
    FileType fileType,
  ) {
    final suggestions = <RefactoringSuggestion>[];
    
    // Analyze file structure
    final analysis = _analyzeFileStructure(content);
    
    switch (fileType) {
      case FileType.widget:
        suggestions.addAll(_generateWidgetSuggestions(analysis, lineCount));
        break;
      case FileType.bloc:
        suggestions.addAll(_generateBlocSuggestions(analysis, lineCount));
        break;
      case FileType.repositoryImpl:
        suggestions.addAll(_generateRepositorySuggestions(analysis, lineCount));
        break;
      case FileType.service:
        suggestions.addAll(_generateServiceSuggestions(analysis, lineCount));
        break;
      default:
        suggestions.addAll(_generateGeneralSuggestions(analysis, lineCount));
    }
    
    return suggestions;
  }
  
  static List<RefactoringSuggestion> _generateWidgetSuggestions(
    FileStructureAnalysis analysis,
    int lineCount,
  ) {
    final suggestions = <RefactoringSuggestion>[];
    
    if (analysis.buildMethodLines > 100) {
      suggestions.add(RefactoringSuggestion(
        type: SuggestionType.extractMethod,
        description: 'Extract large build method into smaller widget methods',
        priority: Priority.high,
        estimatedReduction: analysis.buildMethodLines * 0.6,
      ));
    }
    
    if (analysis.nestedWidgetDepth > 5) {
      suggestions.add(RefactoringSuggestion(
        type: SuggestionType.extractWidget,
        description: 'Extract deeply nested widgets into separate components',
        priority: Priority.medium,
        estimatedReduction: lineCount * 0.4,
      ));
    }
    
    if (analysis.duplicatedWidgetPatterns > 3) {
      suggestions.add(RefactoringSuggestion(
        type: SuggestionType.createReusableComponent,
        description: 'Create reusable components for repeated widget patterns',
        priority: Priority.medium,
        estimatedReduction: lineCount * 0.3,
      ));
    }
    
    return suggestions;
  }
}
```

## CI/CD Integration

### GitHub Actions Workflow
```yaml
# .github/workflows/file-length-check.yml
name: File Length Validation

on:
  pull_request:
    paths:
      - 'lib/**/*.dart'
      - 'test/**/*.dart'

jobs:
  file-length-check:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Setup Dart
        uses: dart-lang/setup-dart@v1

      - name: Install dependencies
        run: dart pub get

      - name: Run file length validation
        run: |
          chmod +x .augment/scripts/file-length-validator.sh
          .augment/scripts/file-length-validator.sh

      - name: Generate refactoring report
        if: failure()
        run: |
          dart run tools/refactoring_report_generator.dart > file-length-report.md

      - name: Comment PR with refactoring suggestions
        if: failure()
        uses: actions/github-script@v6
        with:
          script: |
            const fs = require('fs');
            const report = fs.readFileSync('file-length-report.md', 'utf8');

            github.rest.issues.createComment({
              issue_number: context.issue.number,
              owner: context.repo.owner,
              repo: context.repo.repo,
              body: `## 📏 File Length Violations Found\n\n${report}`
            });
```

### IDE Integration
```json
// .vscode/settings.json
{
  "augment.rules.fileLength": {
    "enableValidation": true,
    "showWarnings": true,
    "showRefactoringSuggestions": true,
    "autoGenerateReport": true
  },
  "augment.fileLength.limits": {
    "widget": 300,
    "bloc": 350,
    "repository": 400,
    "useCase": 150,
    "entity": 200
  }
}
```

## Team Guidelines

### Best Practices for File Length Management
```markdown
## File Length Best Practices

### 1. Proactive File Management
- Monitor file length during development
- Refactor early when approaching warning thresholds
- Use IDE plugins for real-time length monitoring
- Regular code reviews focusing on file size

### 2. Refactoring Strategies
- **Extract Method**: Break large methods into smaller ones
- **Extract Class**: Split large classes by responsibility
- **Extract Widget**: Create reusable UI components
- **Composition**: Use composition over inheritance

### 3. Team Workflow
- Pre-commit hooks prevent oversized files
- Code review checklist includes file length
- Regular refactoring sessions for large files
- Documentation of refactoring decisions

### 4. Exception Handling
- Document reasons for exceptions
- Set time limits for temporary exceptions
- Regular review of exception files
- Migration plans for legacy large files
```
```
