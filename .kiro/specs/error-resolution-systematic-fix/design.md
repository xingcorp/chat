# Design Document

## Overview

This design provides a systematic approach to fixing 742 compilation errors in the Flutter chat app project. The errors are categorized into six main groups: Dependency Injection (DI), Missing Imports, Type System, Constructor/Parameter, Design System Widgets, and Test Files. The fix strategy follows a dependency-order approach, addressing foundational issues first (missing files, imports) before tackling dependent issues (DI, constructors, types).

The design prioritizes:
1. **Minimal disruption**: Fix errors without major refactoring
2. **Dependency order**: Fix root causes before symptoms
3. **Pattern compliance**: Maintain BaseBloc, BaseState, and design system patterns
4. **Incremental validation**: Test after each category fix
5. **Clean architecture**: Preserve layer separation

## Architecture

### Error Resolution Strategy

The fix process follows a phased approach based on error dependencies:

```
Phase 1: Foundation (Missing Files & Imports)
    ↓
Phase 2: Type System (Class Definitions & Signatures)
    ↓
Phase 3: Constructors & Parameters
    ↓
Phase 4: Dependency Injection Configuration
    ↓
Phase 5: Design System Widgets
    ↓
Phase 6: Test Files
    ↓
Phase 7: Verification & Validation
```

### Error Category Analysis

**Category 1: Dependency Injection (~100+ errors)**
- Root cause: Missing service implementations, incorrect parameter names
- Fix approach: Create missing services, update DI annotations, regenerate config
- Dependencies: Requires Phase 1-3 fixes first

**Category 2: Missing/Broken Imports (~80+ errors)**
- Root cause: Deleted files, missing packages, ambiguous imports
- Fix approach: Restore files or refactor dependencies, add packages, use qualified imports
- Dependencies: None (foundational)

**Category 3: Type System (~150+ errors)**
- Root cause: Undefined classes, incorrect type parameters, invalid overrides
- Fix approach: Create missing classes, fix type parameters, correct method signatures
- Dependencies: Requires Phase 1 fixes first

**Category 4: Constructor/Parameter (~200+ errors)**
- Root cause: Missing parameters, undefined named parameters, const issues
- Fix approach: Add parameters, update constructors, fix const correctness
- Dependencies: Requires Phase 2 fixes first

**Category 5: Design System Widgets (~150+ errors)**
- Root cause: New widgets with incomplete implementations, missing localization
- Fix approach: Complete widget implementations, add localization keys
- Dependencies: Requires Phase 1-3 fixes first

**Category 6: Test Files (~60+ errors)**
- Root cause: Broken test setup, missing mocks
- Fix approach: Fix test initialization, create mocks
- Dependencies: Requires Phase 1-5 fixes first

## Components and Interfaces

### 1. Missing File Restoration

**Files to Create/Restore:**

```dart
// lib/core/services/media_cache.dart
@singleton
class MediaCache {
  final Logger _logger;
  final Map<String, CachedMedia> _cache = {};
  
  MediaCache({required Logger logger}) : _logger = logger;
  
  Future<CachedMedia?> get(String key) async {
    return _cache[key];
  }
  
  Future<void> put(String key, CachedMedia media) async {
    _cache[key] = media;
    _logger.d('Cached media: $key');
  }
  
  Future<void> clear() async {
    _cache.clear();
    _logger.d('Cache cleared');
  }
}

class CachedMedia {
  final String url;
  final Uint8List data;
  final DateTime cachedAt;
  
  CachedMedia({
    required this.url,
    required this.data,
    required this.cachedAt,
  });
}
```

**Package Dependencies to Add:**

```yaml
# pubspec.yaml
dependencies:
  dartz: ^0.10.1  # For Either<Failure, T> pattern
```

### 2. Import Conflict Resolution

**Ambiguous Type Resolution:**

```dart
// For ChatType conflicts
// Option 1: Use qualified imports
import 'package:flutter_chat_app/domain/entities/chat.dart' as domain;
import 'package:flutter_chat_app/data/models/chat_model.dart' as data;

// Usage
domain.ChatType.direct
data.ChatType.direct

// Option 2: Consolidate definitions (preferred)
// Keep only domain/entities/chat.dart definition
// Update data models to import from domain
```

### 3. Type System Fixes

**PersistentBottomSheetController Fix:**

```dart
// Before (error)
PersistentBottomSheetController controller;

// After (fixed)
PersistentBottomSheetController<void> controller;
```

**Missing Class Implementations:**

```dart
// lib/data/datasources/chat_remote_datasource.dart
abstract class ChatRemoteDataSource {
  Future<List<ChatModel>> getChats(String userId);
  Future<ChatModel> createChat(CreateChatRequest request);
  Future<void> deleteChat(String chatId);
}

@LazySingleton(as: ChatRemoteDataSource)
class ChatRemoteDataSourceImpl implements ChatRemoteDataSource {
  final ApiClient _apiClient;
  final Logger _logger;
  
  ChatRemoteDataSourceImpl({
    required ApiClient apiClient,
    required Logger logger,
  }) : _apiClient = apiClient,
       _logger = logger;
  
  @override
  Future<List<ChatModel>> getChats(String userId) async {
    try {
      final response = await _apiClient.get('/chats?userId=$userId');
      return (response.data as List)
          .map((json) => ChatModel.fromJson(json))
          .toList();
    } catch (e) {
      _logger.e('Failed to get chats', error: e);
      throw ServerException(message: 'Failed to get chats');
    }
  }
  
  @override
  Future<ChatModel> createChat(CreateChatRequest request) async {
    try {
      final response = await _apiClient.post('/chats', data: request.toJson());
      return ChatModel.fromJson(response.data);
    } catch (e) {
      _logger.e('Failed to create chat', error: e);
      throw ServerException(message: 'Failed to create chat');
    }
  }
  
  @override
  Future<void> deleteChat(String chatId) async {
    try {
      await _apiClient.delete('/chats/$chatId');
    } catch (e) {
      _logger.e('Failed to delete chat', error: e);
      throw ServerException(message: 'Failed to delete chat');
    }
  }
}
```

### 4. Constructor Parameter Fixes

**Pattern for Missing Parameters:**

```dart
// Before (error)
@injectable
class MessageService {
  MessageService({
    required MessageRepository repository,
    // Missing: logger parameter
  });
}

// After (fixed)
@injectable
class MessageService {
  final MessageRepository _repository;
  final Logger _logger;
  
  MessageService({
    required MessageRepository repository,
    required Logger logger,
  }) : _repository = repository,
       _logger = logger;
}
```

**Pattern for Undefined Named Parameters:**

```dart
// Before (error)
MediaService(
  mediaCache: mediaCache,  // Undefined parameter
  logger: logger,
)

// After (fixed)
// Option 1: Add parameter to constructor
class MediaService {
  final MediaCache _mediaCache;
  
  MediaService({
    required MediaCache mediaCache,
    required Logger logger,
  }) : _mediaCache = mediaCache;
}

// Option 2: Remove if not needed
MediaService(
  logger: logger,
)
```

### 5. Dependency Injection Configuration

**DI Registration Pattern:**

```dart
// lib/core/di/injection.dart
@InjectableInit(
  initializerName: 'init',
  preferRelativeImports: true,
  asExtension: true,
)
void configureDependencies() => getIt.init();

// Service registration
@singleton
class MediaCache { }

@LazySingleton(as: IMessageRepository)
class MessageRepositoryImpl implements IMessageRepository { }

@injectable
class GetMessages {
  final IMessageRepository _repository;
  
  GetMessages({required IMessageRepository repository})
      : _repository = repository;
}
```

**Regeneration Command:**

```bash
dart run build_runner build --delete-conflicting-outputs
```

### 6. Design System Widget Fixes

**Widget Parameter Addition Pattern:**

```dart
// Before (error)
AppRichTextEditor(
  placeholder: 'Enter text',  // Undefined parameter
)

// After (fixed)
class AppRichTextEditor extends BaseStatefulWidget {
  final String? placeholder;
  final String? initialValue;
  final ValueChanged<String>? onChanged;
  
  const AppRichTextEditor({
    super.key,
    this.placeholder,
    this.initialValue,
    this.onChanged,
  });
  
  @override
  AppRichTextEditorState createState() => AppRichTextEditorState();
}
```

**Localization Addition Pattern:**

```json
// flutter_chat_app/assets/translations/en.json
{
  "richTextEditorPlaceholder": "Enter text...",
  "otpInputLabel": "Enter OTP",
  "tagInputPlaceholder": "Add tags...",
  "mentionInputPlaceholder": "Type @ to mention..."
}

// flutter_chat_app/assets/translations/vi.json
{
  "richTextEditorPlaceholder": "Nhập văn bản...",
  "otpInputLabel": "Nhập mã OTP",
  "tagInputPlaceholder": "Thêm thẻ...",
  "mentionInputPlaceholder": "Gõ @ để nhắc đến..."
}
```

### 7. Test File Fixes

**Test Setup Pattern:**

```dart
// test/integration/chat_flow_integration_test.dart
void main() {
  late MockAuthRepository mockAuthRepo;
  late MockChatRepository mockChatRepo;
  late MockMessageRepository mockMessageRepo;
  
  setUp(() {
    mockAuthRepo = MockAuthRepository();
    mockChatRepo = MockChatRepository();
    mockMessageRepo = MockMessageRepository();
    
    // Setup GetIt for testing
    getIt.reset();
    getIt.registerSingleton<IAuthRepository>(mockAuthRepo);
    getIt.registerSingleton<IChatRepository>(mockChatRepo);
    getIt.registerSingleton<IMessageRepository>(mockMessageRepo);
  });
  
  tearDown(() {
    getIt.reset();
  });
  
  testWidgets('Chat flow integration test', (tester) async {
    // Test implementation
  });
}
```

**Mock Creation Pattern:**

```dart
// test/mocks/mock_repositories.dart
class MockAuthRepository extends Mock implements IAuthRepository {}
class MockChatRepository extends Mock implements IChatRepository {}
class MockMessageRepository extends Mock implements IMessageRepository {}
```

## Data Models

### Error Tracking Model

```dart
class ErrorCategory {
  final String name;
  final int count;
  final List<String> sampleErrors;
  final ErrorPriority priority;
  final List<String> dependencies;
  
  ErrorCategory({
    required this.name,
    required this.count,
    required this.sampleErrors,
    required this.priority,
    required this.dependencies,
  });
}

enum ErrorPriority {
  critical,  // Blocks all other fixes
  high,      // Blocks many other fixes
  medium,    // Blocks some fixes
  low,       // Independent fixes
}

class FixPhase {
  final int phaseNumber;
  final String name;
  final List<ErrorCategory> categories;
  final String description;
  final List<String> successCriteria;
  
  FixPhase({
    required this.phaseNumber,
    required this.name,
    required this.categories,
    required this.description,
    required this.successCriteria,
  });
}
```

### Fix Progress Tracking

```dart
class FixProgress {
  final int totalErrors;
  final int fixedErrors;
  final int remainingErrors;
  final Map<String, int> errorsByCategory;
  final String currentPhase;
  
  FixProgress({
    required this.totalErrors,
    required this.fixedErrors,
    required this.remainingErrors,
    required this.errorsByCategory,
    required this.currentPhase,
  });
  
  double get percentComplete => (fixedErrors / totalErrors) * 100;
}
```

## Correctness Properties

*A property is a characteristic or behavior that should hold true across all valid executions of a system—essentially, a formal statement about what the system should do. Properties serve as the bridge between human-readable specifications and machine-verifiable correctness guarantees.*


### Property 1: DI Registration Completeness
*For any* @injectable or @singleton annotated class, all constructor parameters should be satisfied by registered dependencies in the DI container.
**Validates: Requirements 1.2**

### Property 2: Build Process Success
*For any* build command (dart run build_runner, flutter build, flutter test), the command should complete successfully without compilation errors.
**Validates: Requirements 1.4, 6.4, 7.2**

### Property 3: Type Parameter Correctness
*For any* usage of generic types (like PersistentBottomSheetController), the correct type parameter should be provided.
**Validates: Requirements 3.1**

### Property 4: Method Override Correctness
*For any* method marked with @override, the method signature should exactly match the parent class or interface signature.
**Validates: Requirements 3.3**

### Property 5: Constructor Parameter Completeness
*For any* constructor invocation, all required parameters should be provided and no undefined named parameters should be used.
**Validates: Requirements 4.1**

### Property 6: Const Constructor Correctness
*For any* const constructor, it should only invoke const super constructors and initialize only final fields with const values.
**Validates: Requirements 4.3**

### Property 7: Design System Widget Parameter Completeness
*For any* design system widget (App* prefixed), all named parameters used in widget instantiation should be defined in the widget's constructor.
**Validates: Requirements 5.1**

### Property 8: Localization Key Completeness
*For any* context.l10n.* reference in the codebase, the corresponding key should exist in both app_en.arb and app_vi.arb files.
**Validates: Requirements 5.2**

### Property 9: Design System Naming Convention
*For any* custom widget in the presentation/widgets/design_system folder, the class name should start with "App" prefix.
**Validates: Requirements 5.4**

### Property 10: Test File Compilation
*For any* test file in the test/ directory, the file should compile without errors and have valid test setup code.
**Validates: Requirements 6.1**

### Property 11: Mock Implementation Completeness
*For any* interface used in tests, a corresponding Mock* class should exist if the interface is mocked in any test.
**Validates: Requirements 6.2**

### Property 12: BLoC Pattern Compliance
*For any* class with name ending in "Bloc", it should extend BaseBloc<Event, State> and not extend Bloc directly.
**Validates: Requirements 8.1**

### Property 13: State Pattern Compliance
*For any* class with name ending in "State", it should extend BaseState and have the @freezed annotation.
**Validates: Requirements 8.2**

### Property 14: Widget Base Class Compliance
*For any* custom widget class (excluding design system widgets), it should extend either BaseStatefulWidget or BaseStatelessWidget, not StatefulWidget or StatelessWidget directly.
**Validates: Requirements 8.3**

### Property 15: Localization Usage Compliance
*For any* user-facing text in widget code, it should use context.l10n.* for localization rather than hardcoded strings (excluding technical keys and debug logs).
**Validates: Requirements 8.4**

### Property 16: Clean Architecture Compliance
*For any* file in the lib/domain/ directory, it should not import Flutter packages (package:flutter/*) or infrastructure packages (http, isar, etc.).
**Validates: Requirements 8.5**

### Property 17: Zero Analyzer Errors
*After all fixes are applied*, running `flutter analyze` should report zero errors, zero warnings for critical issues, and all code should pass static analysis.
**Validates: Requirements 2.4, 2.5, 3.5, 4.5, 5.5, 7.1**

## Error Handling

### Error Detection Strategy

**Automated Error Detection:**
```bash
# Run analyzer to get all errors
flutter analyze > analysis_output.txt 2>&1

# Count errors by category
grep "error •" analysis_output.txt | wc -l

# Extract specific error types
grep "Undefined name" analysis_output.txt
grep "The argument type" analysis_output.txt
grep "Missing required argument" analysis_output.txt
```

**Error Categorization Script:**
```dart
// tools/categorize_errors.dart
void main() {
  final analysisOutput = File('analysis_output.txt').readAsStringSync();
  final errors = analysisOutput.split('\n')
      .where((line) => line.contains('error •'))
      .toList();
  
  final categories = {
    'DI': 0,
    'Import': 0,
    'Type': 0,
    'Constructor': 0,
    'Widget': 0,
    'Test': 0,
  };
  
  for (final error in errors) {
    if (error.contains('InvalidType') || error.contains('injection.config')) {
      categories['DI'] = categories['DI']! + 1;
    } else if (error.contains("Target of URI doesn't exist")) {
      categories['Import'] = categories['Import']! + 1;
    } else if (error.contains('Undefined class') || error.contains('type mismatch')) {
      categories['Type'] = categories['Type']! + 1;
    } else if (error.contains('Missing required argument') || error.contains('Undefined named parameter')) {
      categories['Constructor'] = categories['Constructor']! + 1;
    } else if (error.contains('design_system')) {
      categories['Widget'] = categories['Widget']! + 1;
    } else if (error.contains('test/')) {
      categories['Test'] = categories['Test']! + 1;
    }
  }
  
  print('Error Categories:');
  categories.forEach((category, count) {
    print('  $category: $count errors');
  });
}
```

### Fix Validation Strategy

**Per-Phase Validation:**
```bash
# After each phase, run validation
flutter analyze --no-fatal-infos

# Check specific error reduction
# Expected: Phase 1 should reduce import errors to 0
# Expected: Phase 2 should reduce type errors significantly
# Expected: Phase 3 should reduce constructor errors significantly
# Expected: Phase 4 should reduce DI errors to 0
```

**Incremental Testing:**
```bash
# After Phase 1-3: Try to generate DI config
dart run build_runner build --delete-conflicting-outputs

# After Phase 4: Try to compile
flutter build apk --debug --no-tree-shake-icons

# After Phase 5: Run widget tests
flutter test test/presentation/widgets/

# After Phase 6: Run all tests
flutter test
```

### Rollback Strategy

**Git-based Rollback:**
```bash
# Commit after each successful phase
git add .
git commit -m "Phase X: [Phase Name] - Fixed Y errors"

# If phase fails, rollback
git reset --hard HEAD~1
```

**Error Tracking:**
```dart
// Track errors before and after each phase
class PhaseResult {
  final int phaseNumber;
  final int errorsBefore;
  final int errorsAfter;
  final int errorsFixed;
  final Duration duration;
  final bool success;
  
  PhaseResult({
    required this.phaseNumber,
    required this.errorsBefore,
    required this.errorsAfter,
    required this.duration,
    required this.success,
  }) : errorsFixed = errorsBefore - errorsAfter;
}
```

## Testing Strategy

### Dual Testing Approach

This spec uses both **unit tests** and **property-based tests** to ensure comprehensive coverage:

- **Unit tests**: Verify specific examples, edge cases, and error conditions
- **Property tests**: Verify universal properties across all inputs
- Both are complementary and necessary for comprehensive coverage

### Unit Testing Strategy

**Focus Areas:**
1. **Specific error fixes**: Test that specific known errors are resolved
2. **Edge cases**: Test boundary conditions (empty constructors, single parameter, many parameters)
3. **Integration points**: Test that fixed components work together
4. **Regression prevention**: Test that fixes don't break existing functionality

**Example Unit Tests:**

```dart
// test/fixes/di_fixes_test.dart
void main() {
  group('DI Configuration Fixes', () {
    test('MediaCache service is registered', () {
      configureDependencies();
      expect(() => getIt<MediaCache>(), returnsNormally);
    });
    
    test('ChatRemoteDataSource is registered', () {
      configureDependencies();
      expect(() => getIt<ChatRemoteDataSource>(), returnsNormally);
    });
    
    test('All repositories have required dependencies', () {
      configureDependencies();
      final authRepo = getIt<IAuthRepository>();
      expect(authRepo, isNotNull);
    });
  });
  
  group('Import Fixes', () {
    test('dartz package is available', () {
      // This test will fail to compile if dartz is not in pubspec.yaml
      final Either<String, int> result = Right(42);
      expect(result.isRight(), true);
    });
    
    test('MediaCache class exists and is importable', () {
      final cache = MediaCache(logger: getIt<Logger>());
      expect(cache, isNotNull);
    });
  });
  
  group('Type System Fixes', () {
    test('PersistentBottomSheetController has type parameter', () {
      // This test verifies the type compiles correctly
      PersistentBottomSheetController<void>? controller;
      expect(controller, isNull); // Just checking it compiles
    });
  });
}
```

### Property-Based Testing Strategy

**Configuration:**
- Minimum 100 iterations per property test
- Each property test references its design document property
- Tag format: **Feature: error-resolution-systematic-fix, Property {number}: {property_text}**

**Property Test Examples:**

```dart
// test/properties/di_properties_test.dart
import 'package:test/test.dart';
import 'package:flutter_chat_app/core/di/injection.dart';

void main() {
  group('Property 1: DI Registration Completeness', () {
    test('All @injectable classes can be resolved from DI container', () {
      // Feature: error-resolution-systematic-fix, Property 1: DI Registration Completeness
      
      configureDependencies();
      
      // Get all @injectable classes via reflection or manual list
      final injectableClasses = [
        MediaCache,
        ChatRemoteDataSource,
        MessageService,
        // ... add all @injectable classes
      ];
      
      for (final classType in injectableClasses) {
        expect(
          () => getIt.get(classType),
          returnsNormally,
          reason: '$classType should be resolvable from DI container',
        );
      }
    });
  });
  
  group('Property 12: BLoC Pattern Compliance', () {
    test('All *Bloc classes extend BaseBloc', () {
      // Feature: error-resolution-systematic-fix, Property 12: BLoC Pattern Compliance
      
      // This would require reflection or code generation to get all Bloc classes
      // For now, manually list all Blocs
      final blocClasses = [
        AuthBloc,
        ChatBloc,
        MessageBloc,
        // ... add all Bloc classes
      ];
      
      for (final blocClass in blocClasses) {
        final instance = getIt.get(blocClass);
        expect(
          instance,
          isA<BaseBloc>(),
          reason: '$blocClass should extend BaseBloc',
        );
      }
    });
  });
  
  group('Property 16: Clean Architecture Compliance', () {
    test('Domain layer files do not import Flutter packages', () {
      // Feature: error-resolution-systematic-fix, Property 16: Clean Architecture Compliance
      
      final domainFiles = Directory('lib/domain')
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'))
          .toList();
      
      for (final file in domainFiles) {
        final content = file.readAsStringSync();
        final hasFlutterImport = content.contains("import 'package:flutter/");
        final hasInfraImport = content.contains("import 'package:http/") ||
                                content.contains("import 'package:isar/");
        
        expect(
          hasFlutterImport,
          false,
          reason: '${file.path} should not import Flutter packages',
        );
        expect(
          hasInfraImport,
          false,
          reason: '${file.path} should not import infrastructure packages',
        );
      }
    });
  });
}
```

### Integration Testing Strategy

**Post-Fix Integration Tests:**

```dart
// test/integration/post_fix_integration_test.dart
void main() {
  testWidgets('App launches without DI errors', (tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();
    
    // Verify no exceptions were thrown during initialization
    expect(tester.takeException(), isNull);
  });
  
  testWidgets('Navigation works after fixes', (tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();
    
    // Navigate to different screens
    await tester.tap(find.byIcon(Icons.chat));
    await tester.pumpAndSettle();
    expect(find.byType(ChatListPage), findsOneWidget);
    
    await tester.tap(find.byIcon(Icons.person));
    await tester.pumpAndSettle();
    expect(find.byType(ProfilePage), findsOneWidget);
  });
  
  testWidgets('Design system widgets render correctly', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Column(
          children: [
            AppText('Test'),
            AppButton(label: 'Button', onPressed: () {}),
            AppTextField(label: 'Input'),
          ],
        ),
      ),
    ));
    
    await tester.pumpAndSettle();
    expect(find.byType(AppText), findsOneWidget);
    expect(find.byType(AppButton), findsOneWidget);
    expect(find.byType(AppTextField), findsOneWidget);
  });
}
```

### Validation Checklist

**After Each Phase:**
- [ ] Run `flutter analyze` and verify error count decreased
- [ ] Run `dart run build_runner build` if DI-related changes
- [ ] Commit changes with descriptive message
- [ ] Document errors fixed and errors remaining

**After All Phases:**
- [ ] Run `flutter analyze` - expect 0 errors
- [ ] Run `flutter test` - expect all tests pass
- [ ] Run `flutter build apk --debug` - expect successful build
- [ ] Launch app and verify no runtime exceptions
- [ ] Navigate through all major screens
- [ ] Verify design system components render correctly
- [ ] Run property-based tests (100+ iterations each)
- [ ] Check test coverage is maintained or improved

### Performance Validation

**Build Time Tracking:**
```bash
# Measure build time before fixes
time flutter build apk --debug

# Measure build time after fixes
time flutter build apk --debug

# Expected: Build time should not increase significantly
```

**App Startup Tracking:**
```dart
// Measure app startup time
void main() {
  final startTime = DateTime.now();
  
  runApp(const MyApp());
  
  WidgetsBinding.instance.addPostFrameCallback((_) {
    final endTime = DateTime.now();
    final duration = endTime.difference(startTime);
    print('App startup time: ${duration.inMilliseconds}ms');
    // Expected: < 2000ms
  });
}
```

## Summary

This design provides a systematic, phased approach to fixing 742 compilation errors:

1. **Phase 1 (Foundation)**: Fix missing files and imports - establishes the foundation
2. **Phase 2 (Types)**: Fix type system issues - enables correct type checking
3. **Phase 3 (Constructors)**: Fix constructor and parameter issues - enables object instantiation
4. **Phase 4 (DI)**: Fix dependency injection - enables service resolution
5. **Phase 5 (Widgets)**: Fix design system widgets - enables UI rendering
6. **Phase 6 (Tests)**: Fix test files - enables automated testing
7. **Phase 7 (Verification)**: Comprehensive validation - ensures everything works

Each phase builds on the previous, following dependency order. The design maintains clean architecture, follows project patterns (BaseBloc, BaseState, design system), and includes comprehensive testing strategy with both unit tests and property-based tests.

The fix process is incremental, validated at each step, and includes rollback capability. Success is measured by zero analyzer errors, successful builds, and working application functionality.
