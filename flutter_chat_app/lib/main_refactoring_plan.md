be done **before** adding new features to prevent technical debt accumulation.
 Poor maintainability

### After (~100 lines main.dart)
- ✅ Clear separation of concerns
- ✅ Easy to understand
- ✅ Testable components
- ✅ Follows architecture
- ✅ Maintainable
- ✅ Reusable components

---

## Estimated Impact

- **Main.dart**: 694 → ~100 lines (85% reduction)
- **New files**: 5 focused files
- **Average file size**: ~130 lines
- **Maintainability**: Significantly improved
- **Testability**: Much easier
- **Reusability**: Components can be reused

---

## Priority: HIGH

This refactoring should `
- [ ] Replace Flutter widgets with design system
- [ ] Replace `GetIt.I` with `getIt`

### Step 8: Update Imports
- [ ] Update all import paths
- [ ] Remove unused imports
- [ ] Organize imports by category

### Step 9: Testing
- [ ] Verify app starts correctly
- [ ] Test all platforms (web, mobile, desktop)
- [ ] Verify all features work
- [ ] Run `flutter analyze`

---

## Benefits

### Before (694 lines)
- ❌ Hard to understand
- ❌ Mixed responsibilities
- ❌ Difficult to test
- ❌ Architecture violations
- ❌
- [ ] Create `app.dart`
- [ ] Extend `BaseStatelessWidget`
- [ ] Move `MyApp` logic
- [ ] Use proper base classes

### Step 6: Simplify main.dart
- [ ] Keep only entry point logic
- [ ] Use `AppInitializer`
- [ ] Target: <100 lines
- [ ] Clean imports

### Step 7: Fix Architecture Violations
- [ ] Replace all `StatelessWidget` with `BaseStatelessWidget`
- [ ] Replace all `StatefulWidget` with `BaseStatefulWidget`
- [ ] Replace `debugPrint()` with `AppLogger`
- [ ] Replace hardcoded strings with `context.l10n

### Step 5: Create ChatApp Widget 2: Create PlatformInitializer
- [ ] Create `platform_initializer.dart`
- [ ] Move `_initializeWebServices()`
- [ ] Move `_initializeMobileServices()`
- [ ] Move `_initializeDesktopServices()`

### Step 3: Extract IsarTestScreen
- [ ] Create `isar_test_screen.dart`
- [ ] Extend `BaseStatefulWidget`
- [ ] Use design system components
- [ ] Add localization

### Step 4: Extract HomeScreen
- [ ] Create `home_screen.dart`
- [ ] Extend `BaseStatefulWidget`
- [ ] Use design system components
- [ ] Add localizationove initialization logic from `runMainApp()`
- [ ] Add proper error handling
- [ ] Use `AppLogger` instead of `debugPrint()`

### Step
}
```

---

## New File Structure

```
lib/
├── main.dart (~100 lines)
├── core/
│   └── initialization/
│       ├── app_initializer.dart (~150 lines)
│       └── platform_initializer.dart (~100 lines)
├── presentation/
│   ├── app.dart (~150 lines)
│   └── pages/
│       ├── home/
│       │   └── home_screen.dart (~100 lines)
│       └── debug/
│           └── isar_test_screen.dart (~150 lines)
```

---

## Implementation Steps

### Step 1: Create AppInitializer
- [ ] Create `app_initializer.dart`
- [ ] Mrace,
        reason: 'unhandled_error',
      );
    },
  );er(logger: getIt<AppLogger>());
  await initializer.initialize();
  
  // Get dependencies
  final sharedPreferences = await SharedPreferences.getInstance();
  
  // Run app with error handling
  runZonedGuarded(
    () => runApp(
      ScreenUtilInit(
        designSize: const Size(375, 812),
        builder: (context, child) => ChatApp(
          sharedPreferences: sharedPreferences,
        ),
      ),
    ),
    (error, stackTrace) {
      getIt<CrashReporter>().recordError(
        error,
        stackT
Future<void> runMainApp() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize app
  final initializer = AppInitializonst ChatApp({
    super.key,
    required this.sharedPreferences,
  });
  
  @override
  Widget buildContent(BuildContext context) {
    return MultiBlocProvider(
      providers: _buildBlocProviders(),
      child: _buildMaterialApp(),
    );
  }
}
```

### Phase 5: Simplify Main Entry Point

**Update**: `lib/main.dart` (target: <100 lines)
```dart
/// Main entry point
Future<void> main() async {
  if (!FlavorConfig.isInitialized) {
    FlavorConfig.initializeFromEnvironment();
  }
  await runMainApp();
}
e_screen.dart`
```dart
/// Main home screen with bottom navigation
class HomeScreen extends BaseStatefulWidget {
  const HomeScreen({super.key});
  
  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends BaseState<HomeScreen> {
  // Move home screen logic here
}
```

### Phase 4: Create App Root Widget

**Create**: `lib/presentation/app.dart`
```dart
/// Root application widget
class ChatApp extends BaseStatelessWidget {
  final SharedPreferences sharedPreferences;
  
  ce Screen

**Create**: `lib/presentation/pages/home/hom all test screen logic here
}
```

### Phase 3: Extract Hom async { }
  static Future<void> initializeMobile() async { }
  static Future<void> initializeDesktop() async { }
}
```

### Phase 2: Extract Test Screen

**Create**: `lib/presentation/pages/debug/isar_test_screen.dart`
```dart
/// Test screen for Isar database (debug only)
class IsarTestScreen extends BaseStatefulWidget {
  const IsarTestScreen({super.key});
  
  @override
  IsarTestScreenState createState() => IsarTestScreenState();
}

class IsarTestScreenState extends BaseState<IsarTestScreen> {
  // Move
    await _initializePlatformServices();
  }
  
  Future<void> _initializeFlutter() async { }
  Future<void> _initializeFirebase() async { }
  Future<void> _initializeEnvironment() async { }
  Future<void> _initializeDependencies() async { }
  Future<void> _initializePlatformServices() async { }
}
```

**Create**: `lib/core/initialization/platform_initializer.dart`
```dart
/// Platform-specific initialization
class PlatformInitializer {
  static Future<void> initializeWeb()nitialization Logic

**Create**: `lib/core/initialization/app_initializer.dart`
```dart
/// Handles all app initialization logic
class AppInitializer {
  final AppLogger _logger;
  
  AppInitializer({required AppLogger logger}) : _logger = logger;
  
  Future<void> initialize() async {
    await _initializeFlutter();
    await _initializeFirebase();
    await _initializeEnvironment();
    await _initializeDependencies();94 lines (CRITICAL)
- **Target**: <400 lines per file
- **Current**: 694 lines
- **Action**: Split into multiple files

### 2. Architecture Violations
- Missing base class usage
- No logger integration
- Hardcoded strings
- Direct widget usage

### 3. Mixed Responsibilities
- App initialization
- Service setup
- UI screens
- Test utilities

---

## Refactoring Strategy

### Phase 1: Split I# Main.dart Refactoring Plan

## Current Issues

### 1. File Size: 6