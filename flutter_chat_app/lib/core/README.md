# Kiến trúc Ứng dụng Chat Hiệu năng cao

## Giới thiệu

Ứng dụng chat này được thiết kế dựa trên các nguyên tắc Clean Architecture và SOLID, đảm bảo tính mô-đun, khả năng mở rộng và dễ bảo trì. Kiến trúc này giúp tối ưu hiệu suất, xử lý trải nghiệm mượt mà và hỗ trợ scale tương tự như các ứng dụng lớn như WhatsApp, Messenger, Zalo và Telegram.

## Cấu trúc thư mục

Cấu trúc thư mục được tổ chức theo các tầng của Clean Architecture:

```
lib/
├── core/                  # Thành phần cốt lõi và tiện ích dùng chung
│   ├── base/              # Các lớp cơ sở (base classes)
│   ├── constants/         # Hằng số dùng chung
│   ├── di/                # Dependency Injection
│   ├── error/             # Xử lý lỗi
│   ├── extensions/        # Mở rộng chức năng cho các lớp mặc định
│   ├── network/           # Xử lý mạng
│   ├── services/          # Các dịch vụ chung
│   ├── storage/           # Lưu trữ local
│   ├── theme/             # Theme và style
│   └── utils/             # Các tiện ích
├── data/                  # Tầng dữ liệu
│   ├── datasources/       # Nguồn dữ liệu (remote và local)
│   ├── models/            # Các DTO (Data Transfer Objects)
│   └── repositories/      # Triển khai Repository
├── domain/                # Tầng domain chứa business logic
│   ├── entities/          # Các đối tượng thực thể
│   ├── repositories/      # Interface của Repository
│   └── usecases/          # Các trường hợp sử dụng
├── presentation/          # Tầng trình bày
│   ├── blocs/             # Quản lý trạng thái với BLoC pattern
│   ├── pages/             # Các trang màn hình
│   ├── widgets/           # Các widget dùng chung
│   └── animations/        # Các animation
├── di/                    # Service Locator và Dependency Injection
├── features/              # Các tính năng được module hóa
└── config/                # Cấu hình ứng dụng
```

## Các lớp cơ sở (Base Classes)

### 1. Widgets

- `BaseStatefulWidget`: Lớp cơ sở cho tất cả các StatefulWidget, tích hợp các tính năng tối ưu hiệu suất.
- `BaseState`: Lớp cơ sở cho State của StatefulWidget, cung cấp các tiện ích như safeSetState, logging và xử lý vòng đời.
- `BaseStatelessWidget`: Lớp cơ sở cho tất cả các StatelessWidget, tích hợp logging và tối ưu build.

### 2. Data Layer

- `BaseModel`: Lớp cơ sở cho tất cả các model trong tầng presentation.
- `BaseEntity`: Lớp cơ sở cho tất cả các entity trong tầng domain.
- `BaseDto`: Lớp cơ sở cho tất cả các DTO trong tầng data.
- `BaseRepository`: Lớp cơ sở cung cấp các chiến lược xử lý dữ liệu (online-first, offline-first, cache-only, remote-only).

### 3. Business Logic

- `UseCase`: Lớp cơ sở cho các use case theo Clean Architecture.
- `NoParamsUseCase`: Lớp cơ sở cho use case không cần tham số.
- `StreamUseCase`: Lớp cơ sở cho use case cung cấp dữ liệu dạng Stream.

### 4. Error Handling

- `Failure`: Lớp cơ sở cho tất cả các lỗi trong ứng dụng.
- Các lớp con như `ServerFailure`, `ConnectionFailure`, `CacheFailure`... xử lý các loại lỗi cụ thể.

## Tối ưu hiệu suất

1. **Memory Management**:
   - Sử dụng weak references cho cache
   - Tự động dispose resources
   - Tối ưu hóa vòng đời widget

2. **Rendering Optimization**:
   - Sử dụng const constructors
   - RepaintBoundary cho các widget phức tạp
   - Lazy loading và pagination

3. **Network & Data**:
   - Offline-first architecture
   - Caching with time-to-live (TTL)
   - Compression cho request/response
   - Websocket cho realtime

4. **Animation**:
   - Hardware accelerated animations
   - Staggered animations
   - Preemptive loading

## Hướng dẫn sử dụng

### Tạo mới một Widget

```dart
class MyWidget extends BaseStatefulWidget {
  const MyWidget({Key? key}) : super(key: key);

  @override
  MyWidgetState createState() => MyWidgetState();
}

class MyWidgetState extends BaseState<MyWidget> {
  @override
  Widget buildContent(BuildContext context) {
    return Container(...);
  }
}
```

### Tạo Repository mới

```dart
class ChatRepositoryImpl extends BaseRepository implements ChatRepository {
  final ChatRemoteDataSource remoteDataSource;
  final ChatLocalDataSource localDataSource;

  ChatRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required NetworkInfo networkInfo,
  }) : super(networkInfo: networkInfo);

  @override
  Future<Either<Failure, List<Message>>> getMessages(String chatId) {
    return executeOfflineFirst(
      remoteDataSource: () => remoteDataSource.getMessages(chatId),
      localDataSource: () => localDataSource.getMessages(chatId),
      cacheData: (data) => localDataSource.cacheMessages(chatId, data),
    );
  }
}
```

### Tạo UseCase mới

```dart
class GetMessages implements UseCase<List<Message>, String> {
  final ChatRepository repository;

  GetMessages(this.repository);

  @override
  Future<Either<Failure, List<Message>>> call(String chatId) {
    return repository.getMessages(chatId);
  }
}
```

## Các chiến lược tối ưu

1. **Message Loading:**
   - Tải tin nhắn mới nhất trước tiên
   - Lazy loading khi cuộn lên
   - Hợp nhất các tin nhắn đang chờ xử lý

2. **Media Handling:**
   - Tối ưu hóa hình ảnh trước khi gửi
   - Hiển thị thumbnail trước khi tải
   - Background uploading
   - Xử lý Media trong isolate

3. **UI Responsiveness:**
   - Thread chuyên dụng cho các tính toán nặng
   - Debounce cho input người dùng 
   - Throttle cho các event thường xuyên

4. **Real-time Processing:**
   - Websocket cho tin nhắn real-time
   - Message queueing và retry logic
   - Optimistic UI updates

## Best practices

1. Tất cả business logic nên nằm trong tầng domain
2. Sử dụng dependency injection cho tất cả các dependency
3. Sử dụng các extension để tránh code trùng lặp
4. Luôn sử dụng constants thay vì hard-coded values
5. Luôn xử lý lỗi và các edge case
6. Áp dụng tiện ích caching cho tất cả requests
7. Tách biệt UI và logic nghiệp vụ 