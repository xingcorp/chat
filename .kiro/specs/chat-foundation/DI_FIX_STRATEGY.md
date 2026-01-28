# Dependency Injection Fix Strategy

## 🎯 Phân Tích Vấn Đề (Root Cause Analysis)

### Vấn Đề Chính:
1. **UseCases và BLoCs đã được đánh dấu `@injectable`** ✅
2. **Dependencies (injectable, injectable_generator, build_runner) đã có trong pubspec.yaml** ✅
3. **NHƯNG: `configureDependencies()` chưa được gọi trong `enterprise_injection.dart`** ❌
4. **File `.config.dart` chưa được generate bởi build_runner** ❌
5. **`enterprise_app_initializer.dart` manually register với wrong parameters** ❌

### Hậu Quả:
- ChatBloc constructor cần 10 params nhưng chỉ nhận 4
- MessageBloc constructor cần 8 params nhưng không nhận gì
- Tất cả @injectable annotations bị ignore
- 200+ errors trong flutter analyze

## 🔧 Giải Pháp Đã Thực Hiện

### Bước 1: Thêm Injectable Configuration ✅
```dart
// lib/core/di/enterprise_injection.dart

import 'package:injectable/injectable.dart';
import 'enterprise_injection.config.dart';

@InjectableInit(
  initializerName: 'configureDependencies',
  preferRelativeImports: true,
  asExtension: false,
)
class EnterpriseDI {
  // ...
}
```

### Bước 2: Register External Dependencies Trước ✅
```dart
static Future<void> initialize() async {
  // STEP 0: Register external dependencies first
  if (!serviceLocator.isRegistered<Logger>()) {
    serviceLocator.registerSingleton<Logger>(_logger);
  }
  
  if (!serviceLocator.isRegistered<SharedPreferences>()) {
    final sharedPreferences = await SharedPreferences.getInstance();
    serviceLocator.registerSingleton<SharedPreferences>(sharedPreferences);
  }
  
  if (!serviceLocator.isRegistered<Connectivity>()) {
    serviceLocator.registerSingleton<Connectivity>(Connectivity());
  }
  
  // STEP 1: Configure auto-generated dependencies
  configureDependencies(serviceLocator);
  
  // STEP 2: Initialize manual dependencies
  await _initializeFoundation();
  // ...
}
```

### Bước 3: Tạo build.yaml để exclude test files ✅
```yaml
# flutter_chat_app/build.yaml
targets:
  $default:
    builders:
      injectable_generator:injectable_builder:
        generate_for:
          - lib/**
```

## ⚠️ Vấn Đề Còn Lại

### 1. SystemResourceMonitor Duplicate Registration
**Lỗi:**
```
SystemResourceMonitor [SystemResourceMonitor] envs: []  scope: null 
is registered more than once under the same environment or in the same scope
```

**Nguyên nhân:**
- Class được đánh dấu `@singleton` trong `system_resources.dart`
- Có thể bị import/register nhiều lần

**Giải pháp:**
- Option A: Comment out `@singleton` và manually register
- Option B: Tìm và xóa duplicate registration
- Option C: Sử dụng `@Environment` để tách biệt registrations

### 2. Missing Dependencies
Các class sau cần dependencies chưa được register:
- `CacheSyncStrategy` - cần cho ChatBloc, MessageBloc
- `MediaCacheManager` - cần cho ChatBloc, MessageBloc
- `ConnectivityAnalyzerService` - cần cho ConnectionBloc
- `AuthRemoteDataSource` - cần cho AuthRepositoryImpl
- `UserLocalDataSource` - cần cho AuthRepositoryImpl
- `NetworkInfo` - cần cho nhiều repositories
- `UserRepository` - cần cho UserBloc

**Giải pháp:**
Thêm `@injectable` hoặc `@singleton` cho các class này.

### 3. Test Files Syntax Errors
Test files có syntax errors ngăn build_runner chạy.

**Giải pháp:**
- Đã tạo `build.yaml` để exclude test files
- Cần fix test files sau khi DI hoạt động

## 📋 Các Bước Tiếp Theo (Theo Thứ Tự Ưu Tiên)

### Priority 1: Fix SystemResourceMonitor Duplicate
```bash
# Option A: Comment out @singleton
# File: lib/core/utils/system_resources.dart
# Line 97: @singleton -> // @singleton

# Then manually register in enterprise_injection.dart
serviceLocator.registerSingleton<SystemResourceMonitor>(
  SystemResourceMonitor()..initialize(),
);
```

### Priority 2: Register Missing Dependencies
```dart
// Add @injectable to these classes:
// - lib/core/cache/cache_sync_strategy.dart
// - lib/core/cache/media_cache_manager.dart
// - lib/core/services/connectivity_analyzer_service.dart
// - lib/data/datasources/auth/auth_remote_datasource.dart
// - lib/data/datasources/user/user_local_datasource.dart
// - lib/core/network/network_info.dart
// - lib/domain/repositories/user_repository.dart
```

### Priority 3: Run Build Runner
```bash
cd flutter_chat_app
dart run build_runner build --delete-conflicting-outputs
```

### Priority 4: Verify Generated Config
```bash
# Check if file exists
ls -la lib/core/di/enterprise_injection.config.dart

# Verify it contains configureDependencies function
grep "configureDependencies" lib/core/di/enterprise_injection.config.dart
```

### Priority 5: Test DI Initialization
```bash
# Run app and check logs
flutter run

# Look for these log messages:
# ✅ External dependencies registered
# ✅ Auto-generated dependencies configured
# ✅ Enterprise DI initialized successfully
```

### Priority 6: Fix UI Errors
Sau khi DI hoạt động, fix các lỗi UI:
- Chat entity properties (`imgUrl` → `avatarUrl`, add `lastMessage`, `lastMessageAt`)
- MessageEvent/MessageState methods
- getIt imports in UI files

### Priority 7: Fix Test Files
- Fix syntax errors in test files
- Update test mocks
- Run tests

## 🎯 Expected Outcome

Sau khi hoàn thành:
1. ✅ `configureDependencies()` được gọi thành công
2. ✅ Tất cả UseCases và BLoCs được auto-register
3. ✅ ChatBloc nhận đủ 10 dependencies
4. ✅ MessageBloc nhận đủ 8 dependencies
5. ✅ Errors giảm từ 200+ xuống <50
6. ✅ App có thể compile và chạy
7. ✅ Clean Architecture được maintain

## 📝 Notes

- **KHÔNG XÓA** `enterprise_app_initializer.dart` - có thể có code khác đang sử dụng
- **KHÔNG PHÁ VỠ** existing manual registrations - chỉ comment out duplicates
- **ƯU TIÊN** injectable auto-generation over manual registration
- **KIỂM TRA** performance sau khi DI hoạt động (target: <500ms initialization)

---

**Created**: 2025-01-28  
**Author**: Senior Flutter Architect  
**Status**: IN PROGRESS
