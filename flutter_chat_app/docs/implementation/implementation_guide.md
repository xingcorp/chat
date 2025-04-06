# Hướng dẫn triển khai

Tài liệu này cung cấp hướng dẫn chi tiết về cách triển khai các thành phần chính trong ứng dụng chat. Đây là tài liệu thực hành dành cho các developer mới tham gia dự án.

## Thiết lập môi trường

### 1. Cài đặt dependencies

Thêm các dependencies cần thiết vào file `pubspec.yaml`:

```yaml
dependencies:
  flutter:
    sdk: flutter
  
  # State management
  flutter_bloc: ^8.1.3
  get_it: ^7.6.0
  provider: ^6.0.5
  
  # UI components
  cached_network_image: ^3.2.3
  flutter_staggered_grid_view: ^0.6.2
  photo_view: ^0.14.0
  timeago: ^3.5.0
  
  # Device info & performance
  device_info_plus: ^8.2.2
  shared_preferences: ^2.2.0
  
  # Animation & UI utilities
  animations: ^2.0.7
  lottie: ^2.3.2
  
  # Network & data
  http: ^0.13.6
  connectivity_plus: ^3.0.6
  sqflite: ^2.2.8+4
  uuid: ^4.1.0
```

### 2. Thiết lập Dependency Injection

Tạo file `lib/core/di/injection.dart`:

```dart
import 'package:get_it/get_it.dart';
import 'package:flutter_chat_app/core/services/device_capability_service.dart';
import 'package:flutter_chat_app/core/services/animation_service.dart';
import 'package:flutter_chat_app/core/services/connectivity_service.dart';
import 'package:flutter_chat_app/core/services/sync_service.dart';
import 'package:flutter_chat_app/data/datasources/local/database_service.dart';
import 'package:flutter_chat_app/data/repositories/message_repository_impl.dart';
import 'package:flutter_chat_app/data/repositories/chat_repository_impl.dart';

final GetIt getIt = GetIt.instance;

Future<void> setupDependencies() async {
  // Core services
  _setupCoreServices();
  
  // Data sources
  _setupDataSources();
  
  // Repositories
  _setupRepositories();
  
  // Use cases
  _setupUseCases();
  
  // Blocs
  _setupBlocs();
}

void _setupCoreServices() {
  // Đăng ký DeviceCapabilityService
  final deviceCapabilityService = DeviceCapabilityService();
  getIt.registerSingleton<DeviceCapabilityService>(deviceCapabilityService);
  
  // Đăng ký AnimationService
  getIt.registerSingleton<AnimationService>(
    AnimationService(getIt<DeviceCapabilityService>()),
  );
  
  // Đăng ký ConnectivityService
  getIt.registerSingleton<ConnectivityService>(
    ConnectivityService(),
  );
  
  // Đăng ký SyncService
  getIt.registerSingleton<SyncService>(
    SyncService(
      getIt<ConnectivityService>(),
      getIt<DatabaseService>(),
    ),
  );
  
  // Khởi tạo và benchmark thiết bị
  deviceCapabilityService.initialize();
}

// ...
```

## Triển khai hệ thống animation

### 1. Tạo DeviceCapabilityService

File `lib/core/services/device_capability_service.dart`:

```dart
import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_info_plus/device_info_plus.dart';

enum AnimationLevel {
  low,
  medium,
  high,
}

class DeviceCapabilityService {
  // (Sao chép nội dung từ tài liệu animation_system.md)
  
  // Thực hiện:
  // 1. Đánh giá thiết bị
  // 2. Benchmark đơn giản
  // 3. Lưu trữ cấu hình
}
```

### 2. Triển khai AnimationService

File `lib/core/services/animation_service.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'package:flutter_chat_app/core/services/device_capability_service.dart';

class AnimationConfig {
  // Xem tài liệu animation_system.md
}

class AnimationService {
  // Triển khai các phương thức như trong animation_system.md
  
  // 1. Cấu hình animation theo cấp độ
  // 2. Tạo route với transition
  // 3. Cung cấp utility functions cho animations
}
```

### 3. Tạo HeroAvatar Widget

File `lib/presentation/widgets/common/hero_avatar.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:get_it/get_it.dart';
import 'package:flutter_chat_app/core/services/animation_service.dart';

class HeroAvatar extends StatelessWidget {
  // Triển khai widget:
  // 1. Kích hoạt/vô hiệu hóa hero animation dựa trên cấu hình
  // 2. Tối ưu hóa hình ảnh
  // 3. Xử lý placeholder và error
}
```

## Triển khai hệ thống Offline-First

### 1. Tạo ConnectivityService

File `lib/core/services/connectivity_service.dart`:

```dart
import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

enum ConnectivityStatus {
  connected,
  offline,
}

class ConnectivityService {
  // Triển khai service:
  // 1. Theo dõi thay đổi trạng thái mạng
  // 2. Thông báo khi có/mất kết nối
  // 3. Cung cấp API kiểm tra kết nối
}
```

### 2. Thiết lập Database

File `lib/data/datasources/local/database_service.dart`:

```dart
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseService {
  // Triển khai:
  // 1. Tạo/mở database
  // 2. Tạo các bảng
  // 3. Cung cấp API CRUD
}
```

### 3. Triển khai MessageQueueService

File `lib/core/services/message_queue_service.dart`:

```dart
import 'package:flutter_chat_app/domain/entities/message.dart';
import 'package:flutter_chat_app/data/datasources/local/database_service.dart';

class MessageQueueService {
  // Triển khai:
  // 1. Quản lý hàng đợi tin nhắn
  // 2. Xử lý backoff và retry
  // 3. Ưu tiên tin nhắn
}
```

### 4. Triển khai SyncService

File `lib/core/services/sync_service.dart`:

```dart
import 'package:flutter_chat_app/core/services/connectivity_service.dart';
import 'package:flutter_chat_app/data/datasources/local/database_service.dart';

class SyncService {
  // Triển khai:
  // 1. Đồng bộ hóa dữ liệu
  // 2. Xử lý xung đột
  // 3. Quản lý sync token
}
```

## Tích hợp vào Repository

### 1. Triển khai MessageRepository

File `lib/data/repositories/message_repository_impl.dart`:

```dart
import 'package:flutter_chat_app/domain/repositories/message_repository.dart';
import 'package:flutter_chat_app/domain/entities/message.dart';
import 'package:flutter_chat_app/core/services/message_queue_service.dart';
import 'package:flutter_chat_app/core/services/connectivity_service.dart';
import 'package:flutter_chat_app/data/datasources/local/database_service.dart';
import 'package:flutter_chat_app/data/datasources/remote/api_client.dart';

class MessageRepositoryImpl implements MessageRepository {
  final MessageQueueService _messageQueueService;
  final ConnectivityService _connectivityService;
  final DatabaseService _databaseService;
  final ApiClient _apiClient;
  
  // Triển khai:
  // 1. Gửi tin nhắn offline-first
  // 2. Lấy tin nhắn từ local trước
  // 3. Đồng bộ với server khi có kết nối
}
```

## Hiển thị trong UI

### 1. Hiển thị trạng thái tin nhắn

File `lib/presentation/widgets/chat/message_item.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_chat_app/domain/entities/message.dart';
import 'package:get_it/get_it.dart';
import 'package:flutter_chat_app/core/services/animation_service.dart';

class MessageItem extends StatelessWidget {
  final Message message;
  
  const MessageItem({Key? key, required this.message}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    // Hiển thị:
    // 1. Nội dung tin nhắn
    // 2. Chỉ báo trạng thái (đang gửi, đã gửi, đã nhận, đã đọc)
    // 3. Animation chuyển trạng thái
  }
  
  Widget _buildStatusIndicator() {
    // Hiển thị chỉ báo phù hợp với trạng thái tin nhắn
  }
}
```

### 2. Hiển thị trạng thái kết nối

File `lib/presentation/widgets/common/connection_status_bar.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_chat_app/presentation/blocs/connectivity/connectivity_bloc.dart';

class ConnectionStatusBar extends StatelessWidget {
  // Hiển thị thanh trạng thái kết nối phía trên màn hình
  // Animation fade in/out khi thay đổi trạng thái
}
```

## Kiểm thử

### 1. Unit Tests cho Offline Sync

File `test/core/services/sync_service_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:flutter_chat_app/core/services/sync_service.dart';

// Kiểm thử:
// 1. Đồng bộ khi có kết nối
// 2. Xử lý xung đột
// 3. Quản lý sync token
```

### 2. Device Capability Tests

File `test/core/services/device_capability_service_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:flutter_chat_app/core/services/device_capability_service.dart';

// Kiểm thử:
// 1. Đánh giá thiết bị
// 2. Lưu trữ cấu hình
// 3. Thay đổi cấp độ animation
```

## Triển khai từng bước

### Bước 1: Core Services

1. Triển khai `DeviceCapabilityService`
2. Triển khai `AnimationService`
3. Triển khai `ConnectivityService`
4. Thiết lập Dependency Injection

### Bước 2: Data Layer

1. Thiết lập `DatabaseService`
2. Triển khai `MessageQueueService`
3. Triển khai `SyncService`
4. Xây dựng các Repository

### Bước 3: UI Layer

1. Tạo các widget tái sử dụng (`HeroAvatar`, `TypingIndicator`)
2. Tích hợp animation vào màn hình chat
3. Hiển thị trạng thái kết nối và đồng bộ
4. Tối ưu hiệu suất

## Lưu ý quan trọng

1. **Luôn test trên thiết bị thật**: Đặc biệt là thiết bị cấu hình thấp
2. **Tránh quá nhiều đồng bộ**: Chỉ đồng bộ khi cần thiết
3. **Kiểm soát kích thước database**: Đừng lưu quá nhiều tin nhắn offline
4. **Xử lý lỗi toàn diện**: Đảm bảo UX mượt mà ngay cả khi có lỗi

## Tài liệu tham khảo

- [Animation System](./animation_system.md)
- [Offline Sync](./offline_sync.md)
- [Architecture](./architecture.md)
- [Flutter Hero Animation](https://flutter.dev/docs/development/ui/animations/hero-animations)
- [SQLite trong Flutter](https://flutter.dev/docs/cookbook/persistence/sqlite) 