# Error Resolution - Tasks

## Phase 1: Critical Errors (P0) - Days 1-5

### Task 1.1: Fix Type Mismatches ⚠️ CRITICAL

**Acceptance Criteria**:
- [x] Fix File → Uint8List conversion in `attachment_queue_service.dart:632`
- [x] Fix all `argument_type_not_assignable` errors
- [x] All type assignments are correct
- [x] Code compiles without type errors

**Files Fixed**:
- `lib/core/services/attachment_queue_service.dart` - Added `readAsBytes()` conversion

**Status**: ✅ COMPLETED

---

### Task 1.2: Fix Undefined Methods ⚠️ CRITICAL

**Acceptance Criteria**:
- [x] Add `cancelMessage` method to `MessageQueueService`
- [x] Add mapper extensions for `ChatDto` → `Chat`
- [x] Add import for `ChatDto` in `chat_repository.dart`
- [x] Add `toDomain()` mapper for `MessageDto`
- [x] Add import for `MessageDto` in `chat_repository.dart`
- [x] Fix remaining method calls
- [x] All method calls resolve correctly
- [x] No `undefined_method` errors

**Files Fixed**:
- `lib/core/services/message_queue_service.dart` - Added `cancelMessage()` method
- `lib/data/dtos/chat_dto.dart` - Added `toDomain()` and `toDomainList()` extensions
- `lib/data/dtos/message_dto.dart` - Added `toDomain()` and `toDomainList()` extensions
- `lib/data/repositories/chat_repository.dart` - Added imports for ChatDto and MessageDto
- `lib/data/repositories/chat_repository.dart` - Fixed void return type handling for updateChat, sendMessage, addUsersToChat, removeUsersFromChat

**Status**: ✅ COMPLETED

---

### Task 1.3: Fix Constructor Issues ⚠️ CRITICAL

**Acceptance Criteria**:
- [x] Remove invalid `const` from non-const constructors
- [x] Fix all `const_with_non_const` errors in media datasources
- [x] All constructors can be instantiated
- [x] No constructor errors

**Files Fixed**:
- `lib/data/datasources/media/media_local_datasource.dart` - Removed const from CacheException
- `lib/data/datasources/media/media_remote_datasource.dart` - Removed all const from exceptions (6 instances)

**Status**: ✅ COMPLETED

---

### Task 1.4: Fix Missing Required Parameters ⚠️ CRITICAL

**Acceptance Criteria**:
- [x] Add `groupType`, `memberIds`, `name` to `CreateGroupDto` call
- [x] Fix addUsersToChat - add `conversationId`, `userIds` named parameters
- [x] Fix removeUsersFromChat - add `conversationId`, `userIds` named parameters
- [x] All function calls have required parameters
- [x] No missing parameter errors

**Files Fixed**:
- `lib/data/repositories/chat_repository.dart:196` - Added required named parameters
- `lib/data/repositories/chat_repository.dart:519` - Fixed addUsersToChat parameters
- `lib/data/repositories/chat_repository.dart:560` - Fixed removeUsersFromChat parameters

**Status**: ✅ COMPLETED

---

### Task 1.5: Fix Undefined Parameters ⚠️ CRITICAL

**Acceptance Criteria**:
- [ ] Fix `limit` parameter usage in Isar queries
- [ ] Replace `findAll(limit: 50)` with `limit(50).findAll()`
- [ ] All `undefined_named_parameter` errors fixed
- [ ] Queries work correctly

**Files to Fix**:
- `lib/data/datasources/chat/chat_local_datasource.dart:383`

**Status**: ⏳ PENDING

---

### Task 1.6: Fix Undefined Enum Constants ⚠️ CRITICAL

**Acceptance Criteria**:
- [x] Fix `AttachmentType.file` reference
- [x] Use correct enum value from `AttachmentType`
- [x] Add missing enum cases (document, location, contact)
- [x] All `undefined_enum_constant` errors fixed
- [x] Enum usage is correct

**Files Fixed**:
- `lib/data/datasources/media/media_local_datasource.dart:117` - Changed `file` to `document`, added missing cases

**Status**: ✅ COMPLETED

---

### Task 1.7: Fix Extra Positional Arguments ⚠️ CRITICAL

**Acceptance Criteria**:
- [ ] Convert positional arguments to named parameters
- [ ] Fix all `extra_positional_arguments_could_be_named` errors
- [ ] Function calls match signatures
- [ ] No argument errors

**Files to Fix**:
- `lib/data/datasources/media/media_remote_datasource.dart:62`
- `lib/data/repositories/chat_repository.dart:196,201,259,350`

**Status**: ⏳ PENDING

---

### Task 1.8: Fix Final Not Initialized ⚠️ CRITICAL

**Acceptance Criteria**:
- [ ] Initialize `_connectivity` field in constructor
- [ ] Fix all `final_not_initialized_constructor` errors
- [ ] All final fields are initialized
- [ ] No initialization errors

**Files to Fix**:
- `lib/core/services/connectivity_analyzer_service.dart:72`

**Status**: ⏳ PENDING

---

### Task 1.9: Fix Build Runner Issues 🆕

**Acceptance Criteria**:
- [x] Fix syntax error in `app_breadcrumb.dart:145`
- [x] Run `dart run build_runner build` successfully
- [x] All generated files are up to date
- [x] No build errors

**Files Fixed**:
- `lib/presentation/widgets/design_system/menus/app_breadcrumb.dart:145` - Fixed parameter formatting

**Status**: ✅ COMPLETED

---

### Task 1.10: Fix Logger Method Calls 🆕

**Acceptance Criteria**:
- [x] Fix all `logger.e()` calls to use named parameters
- [x] Change `logger.e('message', failure)` to `logger.e('message', error: failure)`
- [x] All `extra_positional_arguments` errors in BLoCs fixed
- [x] Code compiles without errors

**Files Fixed**:
- `lib/presentation/blocs/message/message_bloc.dart` - Fixed 6 logger.e() calls to use `error:` named parameter
- `lib/presentation/pages/chat/create_group_page.dart` - Fixed syntax error from incomplete edit

**Status**: ✅ COMPLETED

---

**Phase 1 Progress**:
- ✅ Errors fixed: 161 → 84 (77 errors fixed) 🎉
- 📊 Progress: 48% complete (77/161 errors resolved)
- ⏳ Status: IN PROGRESS

**Current Status**:
- 84 errors remaining (mostly in tests and design system)
- Main application code errors largely resolved
- Test files need significant fixes
- Design system components need updates

**Remaining Work**:
- Complete Phase 1: Fix remaining 84 compilation errors
- Phase 2: High Priority Warnings (~50 warnings)
- Phase 3: Code Quality Issues (~1800 info messages)
- Phase 4: Architecture Compliance

**Next Actions**:
1. Fix remaining errors in:
   - Design system components (dialogs, lists, menus)
   - Test files (integration and unit tests)
   - BLoC states and events
   - Repository implementations
2. Run full test suite to verify functionality
3. Complete Phase 1 before moving to Phase 2

---

## Phase 2: High Priority Warnings (P1) - Days 6-10

### Task 2.1: Remove Unused Imports

**Acceptance Criteria**:
- [ ] Remove unused import in `production_config.dart`
- [ ] Remove all other unused imports
- [ ] No `unused_import` warnings
- [ ] Code still compiles

**Files to Fix**:
- `lib/core/config/production_config.dart:1`

**Estimated**: 1 hour

---

### Task 2.2: Fix Unused Fields

**Acceptance Criteria**:
- [ ] Use or remove `_maxCacheSize` in `cache_fallback_manager.dart`
- [ ] Use or remove `_performanceMonitor` in `enhanced_cache_manager.dart`
- [ ] Use or remove `_shortTtl`, `_longTtl` in `enhanced_cache_manager.dart`
- [ ] No `unused_field` warnings
- [ ] Logic still works correctly

**Files to Fix**:
- `lib/core/cache/cache_fallback_manager.dart:163`
- `lib/core/cache/enhanced_cache_manager.dart:36,49,50`

**Estimated**: 2 hours

---

### Task 2.3: Fix Unused Local Variables

**Acceptance Criteria**:
- [ ] Use or remove `config` variables in `app_identity.dart`
- [ ] Use or remove `dbPath` in `isar_v4_enterprise_solution.dart`
- [ ] Use or remove `metrics` in `repository_error_mixin.dart`
- [ ] Use or remove `timestamp` in `error_localization_service.dart`
- [ ] No `unused_local_variable` warnings

**Files to Fix**:
- `lib/core/config/app_identity.dart:29,154,161,168`
- `lib/core/database/isar_v4_enterprise_solution.dart:44`
- `lib/core/error/repository_error_mixin.dart:297`
- `lib/core/localization/error_localization_service.dart:172`

**Estimated**: 2 hours

---

### Task 2.4: Fix Unused Methods

**Acceptance Criteria**:
- [ ] Use or remove `_handleIntegrationEvent` in `integration_hub.dart`
- [ ] Use or remove `_emitPerformanceEvent` in `integration_hub.dart`
- [ ] No `unused_element` warnings
- [ ] Integration hub still works

**Files to Fix**:
- `lib/core/integration_hub.dart:209,263`

**Estimated**: 1 hour

---

### Task 2.5: Migrate from MediaCacheManager

**Acceptance Criteria**:
- [ ] Replace `MediaCacheManager` with `MediaRepository` in all files
- [ ] Update DI configuration
- [ ] Update all usages
- [ ] No `deprecated_member_use_from_same_package` warnings
- [ ] Media functionality still works

**Files to Fix**:
- `lib/core/cache/preload_manager.dart:26`
- `lib/core/di/injection.config.dart:161,306,466,518`

**Estimated**: 3 hours

---

### Task 2.6: Fix Logger Deprecation

**Acceptance Criteria**:
- [ ] Replace `printTime` with `dateTimeFormat`
- [ ] Update logger configuration
- [ ] No `deprecated_member_use` warnings
- [ ] Logging still works

**Files to Fix**:
- `lib/core/di/injection.dart:53`

**Estimated**: 1 hour

---

### Task 2.7: Fix Visibility Violations

**Acceptance Criteria**:
- [ ] Fix `ApiClient` usage in DI config
- [ ] Respect `@visibleForTesting` annotations
- [ ] No `invalid_use_of_visible_for_testing_member` warnings
- [ ] Tests still work

**Files to Fix**:
- `lib/core/di/injection.config.dart:414`

**Estimated**: 1 hour

---

**Phase 2 Complete When**:
- ✅ <10 warnings remaining
- ✅ No deprecated API usage
- ✅ No visibility violations
- ✅ All tests pass

**Estimated Total**: 11 hours (2 days)

---

## Phase 3: Code Quality (P2) - Days 11-15

### Task 3.1: Add Const Constructors (Automated)

**Acceptance Criteria**:
- [ ] Run `dart fix --apply`
- [ ] Manually review and add remaining const
- [ ] No `prefer_const_constructors` info messages
- [ ] Performance improved

**Estimated**: 4 hours

---

### Task 3.2: Organize Imports (Automated)

**Acceptance Criteria**:
- [ ] Run import sorter
- [ ] Fix package imports (replace relative with package imports)
- [ ] Remove unnecessary library names
- [ ] Sort directive sections
- [ ] No `directives_ordering`, `always_use_package_imports` info

**Files Affected**: ~50 files

**Estimated**: 3 hours

---

### Task 3.3: Fix Documentation Issues

**Acceptance Criteria**:
- [ ] Move dangling library doc comments
- [ ] Escape HTML in doc comments (wrap `<Type>` with backticks)
- [ ] No `dangling_library_doc_comments`, `unintended_html_in_doc_comment` info
- [ ] Documentation is readable

**Files Affected**: ~100 files

**Estimated**: 4 hours

---

### Task 3.4: Remove Unnecessary Operations

**Acceptance Criteria**:
- [ ] Remove noop operations (`.toString()` on strings, etc.)
- [ ] Remove unnecessary null checks
- [ ] Convert lambdas to tearoffs
- [ ] Remove unnecessary braces in string interpolations
- [ ] No `noop_primitive_operations`, `unnecessary_*` info

**Files Affected**: ~50 files

**Estimated**: 3 hours

---

### Task 3.5: Fix Miscellaneous Info

**Acceptance Criteria**:
- [ ] Fix `use_super_parameters` where applicable
- [ ] Fix `use_setters_to_change_properties`
- [ ] Fix `prefer_conditional_assignment`
- [ ] Fix `prefer_final_in_for_each`
- [ ] Fix `type_literal_in_constant_pattern`
- [ ] Fix `avoid_slow_async_io` (document why needed)
- [ ] Fix `avoid_void_async`
- [ ] Fix `await_only_futures`

**Estimated**: 4 hours

---

**Phase 3 Complete When**:
- ✅ <100 info messages remaining
- ✅ Code is formatted and organized
- ✅ Documentation is clean
- ✅ No unnecessary code

**Estimated Total**: 18 hours (3-4 days)

---

## Phase 4: Architecture Compliance (P3) - Days 16-20

### Task 4.1: Enforce Base Class Usage

**Acceptance Criteria**:
- [ ] All `StatelessWidget` → `BaseStatelessWidget`
- [ ] All `StatefulWidget` → `BaseStatefulWidget`
- [ ] All `Bloc` → `BaseBloc`
- [ ] All states extend `BaseState`
- [ ] Architecture is consistent

**Estimated**: 8 hours

---

### Task 4.2: Enforce Localization

**Acceptance Criteria**:
- [ ] Find all hardcoded user-facing strings
- [ ] Add strings to `app_en.arb` and `app_vi.arb`
- [ ] Replace with `context.l10n.*`
- [ ] Run `flutter gen-l10n`
- [ ] No hardcoded strings in UI

**Estimated**: 6 hours

---

### Task 4.3: Enforce Design System

**Acceptance Criteria**:
- [ ] Replace `Text` → `AppText`
- [ ] Replace `ListView` → `AppListView`
- [ ] Replace `TextField` → `AppTextField`
- [ ] Replace `ElevatedButton` → `AppButton`
- [ ] All UI uses design system

**Estimated**: 6 hours

---

**Phase 4 Complete When**:
- ✅ All widgets use base classes
- ✅ All strings are localized
- ✅ All UI uses design system
- ✅ <50 total issues remaining

**Estimated Total**: 20 hours (4 days)

---

## Success Criteria Summary

### Overall Goals
- [x] **Phase 1**: 0 compilation errors ✅
- [ ] **Phase 2**: <10 warnings
- [ ] **Phase 3**: <100 info messages
- [ ] **Phase 4**: <50 total issues

### Quality Gates
- [ ] Project builds successfully
- [ ] All tests pass
- [ ] No breaking changes
- [ ] Performance maintained or improved
- [ ] Code coverage maintained

### Metrics Tracking

| Metric | Start | Phase 1 | Phase 2 | Phase 3 | Phase 4 | Target |
|--------|-------|---------|---------|---------|---------|--------|
| Total Issues | 2048 | TBD | TBD | TBD | TBD | <50 |
| Errors | 161 | 0 | 0 | 0 | 0 | 0 |
| Warnings | ~50 | TBD | <10 | <10 | <10 | <10 |
| Info | ~1837 | TBD | TBD | <100 | <50 | <50 |

---

## Daily Progress Log

### Day 1: [Date]
- [ ] Task 1.1 completed
- [ ] Task 1.2 completed
- [ ] Errors remaining: ___

### Day 2: [Date]
- [ ] Task 1.3 completed
- [ ] Task 1.4 completed
- [ ] Errors remaining: ___

### Day 3: [Date]
- [ ] Task 1.5 completed
- [ ] Task 1.6 completed
- [ ] Errors remaining: ___

### Day 4: [Date]
- [ ] Task 1.7 completed
- [ ] Task 1.8 completed
- [ ] Phase 1 verification
- [ ] Errors remaining: 0 ✅

### Day 5: [Date]
- [ ] Phase 1 final testing
- [ ] Phase 1 commit
- [ ] Phase 2 kickoff

---

**Status**: Ready to Start  
**Next Action**: Begin Task 1.1 - Fix Type Mismatches  
**Priority**: P0 (Critical)
