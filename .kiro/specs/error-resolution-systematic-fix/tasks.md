# Implementation Plan: Error Resolution Systematic Fix

## Overview

This plan systematically fixes 742 compilation errors in the Flutter chat app through 7 phased approaches. Each phase addresses a specific error category in dependency order, with validation checkpoints to ensure incremental progress. The implementation follows clean architecture principles and maintains all project patterns (BaseBloc, BaseState, design system).

## Tasks

- [-] 1. Phase 1: Foundation - Fix Missing Files and Imports (~80 errors)
  - [x] 1.1 Add dartz package to pubspec.yaml
    - Add `dartz: ^0.10.1` to dependencies section
    - Run `flutter pub get`
    - _Requirements: 2.3_
  
  - [x] 1.2 Create missing MediaCache service
    - Create `lib/core/services/media_cache.dart`
    - Implement MediaCache class with @singleton annotation
    - Implement CachedMedia data class
    - Add Logger dependency
    - _Requirements: 2.1_
  
  - [x] 1.3 Resolve ChatType and ContentType ambiguous imports
    - Audit all files using ChatType and ContentType
    - Consolidate definitions in domain layer
    - Update data layer to import from domain
    - Use qualified imports where consolidation not possible
    - _Requirements: 2.2, 2.5_
  
  - [x] 1.4 Fix all "Target of URI doesn't exist" errors
    - Run `flutter analyze` and extract all missing import errors
    - For each missing file, either restore or refactor dependency
    - Verify all imports resolve correctly
    - _Requirements: 2.1, 2.4_
  
  - [ ] 1.5 Checkpoint - Verify import errors resolved
    - Run `flutter analyze` and count remaining errors
    - Expected: Import errors reduced to 0
    - Expected: Total errors reduced by ~80
    - Commit changes: "Phase 1: Fixed missing files and imports"
    - _Requirements: 2.4, 2.5_

- [ ] 2. Phase 2: Type System - Fix Type Definitions and Signatures (~150 errors)
  - [ ] 2.1 Create missing ChatRemoteDataSource
    - Create `lib/data/datasources/chat_remote_datasource.dart`
    - Define abstract class with required methods
    - Implement ChatRemoteDataSourceImpl with @LazySingleton
    - Add ApiClient and Logger dependencies
    - _Requirements: 3.2_
  
  - [ ] 2.2 Fix PersistentBottomSheetController type parameters
    - Search for all PersistentBottomSheetController usages
    - Add `<void>` type parameter to each usage
    - Verify no type parameter errors remain
    - _Requirements: 3.1_
  
  - [ ] 2.3 Fix method override signatures
    - Run `flutter analyze` and extract all override errors
    - For each invalid override, match parent signature exactly
    - Update return types and parameter types as needed
    - _Requirements: 3.3_
  
  - [ ] 2.4 Fix return type mismatches
    - Extract all "type mismatch" errors from analyzer
    - Correct return types or returned values
    - Ensure Future types are properly awaited
    - _Requirements: 3.4_
  
  - [ ] 2.5 Create any other missing class definitions
    - Identify all "Undefined class" errors
    - Create missing classes or remove references
    - Ensure all classes follow project patterns
    - _Requirements: 3.2_
  
  - [ ] 2.6 Checkpoint - Verify type errors resolved
    - Run `flutter analyze` and count remaining errors
    - Expected: Type errors reduced significantly
    - Expected: Total errors reduced by ~150
    - Commit changes: "Phase 2: Fixed type system issues"
    - _Requirements: 3.5_

- [ ] 3. Phase 3: Constructors - Fix Constructor and Parameter Issues (~200 errors)
  - [ ] 3.1 Fix missing required parameters
    - Extract all "Missing required argument" errors
    - Add missing parameters to constructor calls
    - Ensure parameters are available in scope
    - _Requirements: 4.1_
  
  - [ ] 3.2 Fix undefined named parameters
    - Extract all "Undefined named parameter" errors
    - Either add parameter to constructor or remove usage
    - Update all affected constructor calls
    - _Requirements: 4.2_
  
  - [ ] 3.3 Fix const constructor issues
    - Extract all const constructor errors
    - Either remove const or make super constructor const
    - Ensure all initialized fields are final and const
    - _Requirements: 4.3_
  
  - [ ] 3.4 Fix extra positional arguments
    - Extract all "Too many positional arguments" errors
    - Remove extra arguments or add parameters
    - Verify constructor signatures match calls
    - _Requirements: 4.4_
  
  - [ ] 3.5 Checkpoint - Verify constructor errors resolved
    - Run `flutter analyze` and count remaining errors
    - Expected: Constructor errors reduced to 0
    - Expected: Total errors reduced by ~200
    - Commit changes: "Phase 3: Fixed constructor and parameter issues"
    - _Requirements: 4.5_

- [ ] 4. Phase 4: Dependency Injection - Fix DI Configuration (~100 errors)
  - [ ] 4.1 Fix InvalidType errors in injection.config.dart
    - Review lines 217, 322, 447, 448 in injection.config.dart
    - Identify source classes causing InvalidType
    - Fix source class annotations and constructors
    - _Requirements: 1.1_
  
  - [ ] 4.2 Add missing service dependencies
    - Audit all @injectable classes for missing dependencies
    - Add localDataSource, remoteDataSource parameters where needed
    - Add logger, mediaCache, performanceMonitor where needed
    - Ensure all dependencies are registered in DI
    - _Requirements: 1.2, 1.3_
  
  - [ ] 4.3 Regenerate DI configuration
    - Run `dart run build_runner clean`
    - Run `dart run build_runner build --delete-conflicting-outputs`
    - Verify no build errors
    - Verify injection.config.dart has no InvalidType errors
    - _Requirements: 1.1, 1.4_
  
  - [ ] 4.4 Test DI initialization
    - Create test to verify all services can be resolved
    - Test app initialization without DI exceptions
    - Verify all repositories and use cases are registered
    - _Requirements: 1.5_
  
  - [ ] 4.5 Checkpoint - Verify DI errors resolved
    - Run `flutter analyze` and count remaining errors
    - Expected: DI errors reduced to 0
    - Expected: Total errors reduced by ~100
    - Commit changes: "Phase 4: Fixed dependency injection configuration"
    - _Requirements: 1.1, 1.4, 1.5_

- [ ] 5. Phase 5: Design System - Fix Widget Issues (~150 errors)
  - [ ] 5.1 Fix AppRichTextEditor undefined parameters
    - Add placeholder, initialValue, onChanged parameters
    - Ensure all parameters have correct types
    - Follow BaseStatefulWidget pattern
    - _Requirements: 5.1_
  
  - [ ] 5.2 Fix AppOTPInput undefined parameters
    - Add length, onCompleted, onChanged parameters
    - Implement OTP input logic
    - Follow design system patterns
    - _Requirements: 5.1_
  
  - [ ] 5.3 Fix AppTagInput undefined parameters
    - Add tags, onTagAdded, onTagRemoved parameters
    - Implement tag management logic
    - Follow design system patterns
    - _Requirements: 5.1_
  
  - [ ] 5.4 Fix AppMentionInput undefined parameters
    - Add mentions, onMentionAdded parameters
    - Implement mention detection logic
    - Follow design system patterns
    - _Requirements: 5.1_
  
  - [ ] 5.5 Fix AppMultiSelect undefined parameters
    - Add options, selectedValues, onChanged parameters
    - Implement multi-selection logic
    - Follow design system patterns
    - _Requirements: 5.1_
  
  - [ ] 5.6 Fix AppAutoComplete undefined parameters
    - Add suggestions, onSelected, onChanged parameters
    - Implement autocomplete logic
    - Follow design system patterns
    - _Requirements: 5.1_
  
  - [ ] 5.7 Fix AppEmojiPicker undefined parameters
    - Add onEmojiSelected, categories parameters
    - Implement emoji selection logic
    - Follow design system patterns
    - _Requirements: 5.1_
  
  - [ ] 5.8 Fix AppImageGallery undefined parameters
    - Add images, onImageTap, onImageLongPress parameters
    - Implement gallery display logic
    - Follow design system patterns
    - _Requirements: 5.1_
  
  - [ ] 5.9 Fix AppFileUploader undefined parameters
    - Add onFileSelected, allowedExtensions, maxSize parameters
    - Implement file upload logic
    - Follow design system patterns
    - _Requirements: 5.1_
  
  - [ ] 5.10 Fix AppVideoPlayer undefined parameters
    - Add videoUrl, autoPlay, controls parameters
    - Implement video playback logic
    - Follow design system patterns
    - _Requirements: 5.1_
  
  - [ ] 5.11 Fix AppAudioPlayer undefined parameters
    - Add audioUrl, autoPlay, showWaveform parameters
    - Implement audio playback logic
    - Follow design system patterns
    - _Requirements: 5.1_
  
  - [ ] 5.12 Fix AppCalendar undefined parameters
    - Add selectedDate, onDateSelected, events parameters
    - Implement calendar display logic
    - Follow design system patterns
    - _Requirements: 5.1_
  
  - [ ] 5.13 Fix AppDataTable undefined parameters
    - Add columns, rows, onSort, onRowTap parameters
    - Implement data table logic
    - Follow design system patterns
    - _Requirements: 5.1_
  
  - [ ] 5.14 Add missing localization keys
    - Review all new widgets for hardcoded strings
    - Add keys to flutter_chat_app/assets/translations/en.json
    - Add keys to flutter_chat_app/assets/translations/vi.json
    - Update widgets to use localization
    - _Requirements: 5.2_
  
  - [ ] 5.15 Fix widget type mismatches
    - Extract all type mismatch errors in design system widgets
    - Correct parameter types in constructors
    - Ensure ValueChanged, VoidCallback types are correct
    - _Requirements: 5.3_
  
  - [ ] 5.16 Verify App* naming convention
    - Audit all design system widgets for naming
    - Ensure all start with "App" prefix
    - Rename any non-compliant widgets
    - _Requirements: 5.4_
  
  - [ ] 5.17 Checkpoint - Verify widget errors resolved
    - Run `flutter analyze` and count remaining errors
    - Expected: Design system widget errors reduced to 0
    - Expected: Total errors reduced by ~150
    - Commit changes: "Phase 5: Fixed design system widget issues"
    - _Requirements: 5.5_

- [ ] 6. Phase 6: Tests - Fix Test File Issues (~60 errors)
  - [ ] 6.1 Fix chat_flow_integration_test.dart setup
    - Fix test initialization code
    - Setup GetIt for testing
    - Create proper test fixtures
    - _Requirements: 6.1_
  
  - [ ] 6.2 Create missing mock implementations
    - Create MockAuthRepository
    - Create MockChatRepository
    - Create MockMessageRepository
    - Create any other needed mocks
    - _Requirements: 6.2_
  
  - [ ] 6.3 Fix test import paths
    - Update all broken test imports
    - Ensure test files can access src files
    - Fix relative vs package imports
    - _Requirements: 6.3_
  
  - [ ] 6.4 Verify test compilation
    - Run `flutter test --no-test-assets`
    - Ensure all test files compile
    - Fix any remaining test errors
    - _Requirements: 6.4_
  
  - [ ] 6.5 Checkpoint - Verify test errors resolved
    - Run `flutter analyze` on test files
    - Expected: Test file errors reduced to 0
    - Expected: Total errors reduced by ~60
    - Commit changes: "Phase 6: Fixed test file issues"
    - _Requirements: 6.4_

- [ ] 7. Phase 7: Verification - Comprehensive Validation
  - [ ] 7.1 Run full static analysis
    - Run `flutter analyze`
    - Verify 0 errors reported
    - Verify 0 critical warnings
    - _Requirements: 7.1_
  
  - [ ] 7.2 Test build process
    - Run `flutter build apk --debug`
    - Verify build completes successfully
    - Check build time is reasonable
    - _Requirements: 7.2_
  
  - [ ] 7.3 Test app launch
    - Launch app on emulator/device
    - Verify no runtime exceptions during startup
    - Check app initializes within 2 seconds
    - _Requirements: 7.3_
  
  - [ ] 7.4 Test navigation and UI
    - Navigate to all major screens
    - Verify all screens render without errors
    - Test design system components display correctly
    - _Requirements: 7.4_
  
  - [ ] 7.5 Run unit tests
    - Run `flutter test test/unit/`
    - Verify all unit tests pass
    - Check test coverage is maintained
    - _Requirements: 6.5_
  
  - [ ] 7.6 Run integration tests
    - Run `flutter test test/integration/`
    - Verify all integration tests pass
    - Test DI initialization
    - _Requirements: 7.5_
  
  - [ ] 7.7 Run property-based tests
    - **Property 1: DI Registration Completeness**
    - **Validates: Requirements 1.2**
    - Run with 100+ iterations
    - Verify all @injectable classes resolve from DI
  
  - [ ] 7.8 Run property-based tests for build success
    - **Property 2: Build Process Success**
    - **Validates: Requirements 1.4, 6.4, 7.2**
    - Test build_runner, flutter build, flutter test commands
  
  - [ ] 7.9 Run property-based tests for type correctness
    - **Property 3: Type Parameter Correctness**
    - **Property 4: Method Override Correctness**
    - **Validates: Requirements 3.1, 3.3**
    - Verify all generic types have parameters
    - Verify all overrides match parent signatures
  
  - [ ] 7.10 Run property-based tests for constructor correctness
    - **Property 5: Constructor Parameter Completeness**
    - **Property 6: Const Constructor Correctness**
    - **Validates: Requirements 4.1, 4.3**
    - Verify all constructor calls have required parameters
    - Verify all const constructors are valid
  
  - [ ] 7.11 Run property-based tests for widget compliance
    - **Property 7: Design System Widget Parameter Completeness**
    - **Property 8: Localization Key Completeness**
    - **Property 9: Design System Naming Convention**
    - **Validates: Requirements 5.1, 5.2, 5.4**
    - Verify all widget parameters are defined
    - Verify all l10n keys exist in both ARB files
    - Verify all design system widgets use App* prefix
  
  - [ ] 7.12 Run property-based tests for test compliance
    - **Property 10: Test File Compilation**
    - **Property 11: Mock Implementation Completeness**
    - **Validates: Requirements 6.1, 6.2**
    - Verify all test files compile
    - Verify all mocked interfaces have Mock* classes
  
  - [ ] 7.13 Run property-based tests for pattern compliance
    - **Property 12: BLoC Pattern Compliance**
    - **Property 13: State Pattern Compliance**
    - **Property 14: Widget Base Class Compliance**
    - **Property 15: Localization Usage Compliance**
    - **Property 16: Clean Architecture Compliance**
    - **Validates: Requirements 8.1, 8.2, 8.3, 8.4, 8.5**
    - Verify all BLoCs extend BaseBloc
    - Verify all States extend BaseState with @freezed
    - Verify all widgets extend base classes
    - Verify all UI text uses context.l10n
    - Verify domain layer has no Flutter imports
  
  - [ ] 7.14 Run comprehensive analyzer property test
    - **Property 17: Zero Analyzer Errors**
    - **Validates: Requirements 2.4, 2.5, 3.5, 4.5, 5.5, 7.1**
    - Run flutter analyze
    - Verify 0 errors, 0 critical warnings
  
  - [ ] 7.15 Final checkpoint - Project fully fixed
    - Document final error count: 0
    - Document total errors fixed: 742
    - Create summary of changes
    - Commit changes: "Phase 7: Verification complete - All 742 errors fixed"
    - _Requirements: 7.1, 7.2, 7.3, 7.4, 7.5_

## Success Criteria Summary

**Phase 1 Complete When:**
- All missing files created or dependencies refactored
- dartz package added to pubspec.yaml
- All import errors resolved (0 "Target of URI doesn't exist" errors)
- All ambiguous import errors resolved
- Error count reduced by ~80

**Phase 2 Complete When:**
- All missing classes created (ChatRemoteDataSource, etc.)
- All type parameter errors fixed
- All method override errors fixed
- All return type mismatches fixed
- Error count reduced by ~150

**Phase 3 Complete When:**
- All missing required parameters added
- All undefined named parameters fixed
- All const constructor issues resolved
- All extra argument errors fixed
- Error count reduced by ~200

**Phase 4 Complete When:**
- All InvalidType errors in injection.config.dart resolved
- All service dependencies properly configured
- DI configuration regenerates without errors
- App initializes without DI exceptions
- Error count reduced by ~100

**Phase 5 Complete When:**
- All design system widget parameters defined
- All localization keys added to en.json and vi.json
- All widget type mismatches fixed
- All widgets follow App* naming convention
- Error count reduced by ~150

**Phase 6 Complete When:**
- All test files compile without errors
- All necessary mocks created
- All test imports fixed
- `flutter test` runs without compilation errors
- Error count reduced by ~60

**Phase 7 Complete When:**
- `flutter analyze` reports 0 errors
- `flutter build apk --debug` succeeds
- App launches without runtime exceptions
- All screens render correctly
- All tests pass (unit, integration, property-based)
- Total error count: 0 (down from 742)

## Notes

- All tasks including property-based tests are required for comprehensive validation
- Each phase includes a checkpoint to verify progress before moving to next phase
- Commit after each successful phase for rollback capability
- If a phase fails, rollback and reassess approach
- Property tests validate universal correctness properties with 100+ iterations
- Unit tests validate specific examples and edge cases
- Both testing approaches are complementary for comprehensive coverage
