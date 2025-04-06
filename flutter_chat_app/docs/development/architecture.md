# Kiến trúc ứng dụng chat

## Tổng quan

Ứng dụng Flutter Chat được thiết kế theo nguyên tắc Clean Architecture, tập trung vào hiệu suất cao, trải nghiệm người dùng mượt mà và hoạt động ổn định trong các điều kiện mạng khác nhau. Kiến trúc này giúp code dễ bảo trì, mở rộng và kiểm thử.

## Các lớp kiến trúc

### 1. Presentation Layer

Lớp này chứa toàn bộ UI, các màn hình, widget và quản lý state:

- **Screens**: Các màn hình chính của ứng dụng
  - `/lib/presentation/screens/`
  - Ví dụ: ChatListScreen, ChatDetailScreen, MediaGalleryScreen
  
- **Widgets**: Các thành phần UI có thể tái sử dụng
  - `/lib/presentation/widgets/`
  - Được tổ chức thành các nhóm: common, chat, media
  
- **State Management**: Sử dụng Flutter Bloc
  - `/lib/presentation/blocs/`
  - Tách biệt logic UI và business logic

### 2. Domain Layer

Lớp này chứa các business rules và logic cốt lõi:

- **Entities**: Các đối tượng miền
  - `/lib/domain/entities/`
  - Ví dụ: Chat, Message, User
  
- **Repositories (Interface)**: Định nghĩa cách tương tác với dữ liệu
  - `/lib/domain/repositories/`
  - Tạo ra các contract cho các repository
  
- **Use Cases**: Xử lý logic nghiệp vụ
  - `/lib/domain/usecases/`
  - Ví dụ: SendMessageUseCase, FetchChatsUseCase

### 3. Data Layer

Lớp này chịu trách nhiệm cho việc truy xuất và lưu trữ dữ liệu:

- **Repositories (Implementation)**: Thực hiện các interface đã định nghĩa
  - `/lib/data/repositories/`
  - Xử lý logic truy xuất dữ liệu từ nhiều nguồn
  
- **Data Sources**: Nguồn dữ liệu cụ thể
  - `/lib/data/datasources/`
  - Remote: API clients (GraphQL, REST)
  - Local: Database, SharedPreferences, Hive
  
- **Models**: Đối tượng dữ liệu
  - `/lib/data/models/`
  - Các lớp chuyển đổi dữ liệu từ JSON sang entities và ngược lại

### 4. Core Layer

Lớp này chứa các utilities và services dùng chung:

- **Services**: Các dịch vụ nền
  - `/lib/core/services/`
  - AnimationService, DeviceCapabilityService, ConnectivityService
  
- **Utils**: Các tiện ích và hàm hỗ trợ
  - `/lib/core/utils/`
  - Formatters, Constants, Extensions
  
- **DI (Dependency Injection)**: Cung cấp dependencies
  - `/lib/core/di/`
  - Sử dụng GetIt làm service locator

## Luồng dữ liệu

1. **User Input**: Người dùng tương tác với UI (Screen/Widget)
2. **UI Event**: UI gửi event đến Bloc
3. **Business Logic**: Bloc gọi Use Case tương ứng
4. **Repository Call**: Use Case gọi đến Repository
5. **Data Source Access**: Repository truy xuất dữ liệu từ Local/Remote Data Source
6. **Response Flow**: Dữ liệu đi ngược lại qua Repository -> Use Case -> Bloc -> UI

```
┌─────────────┐    ┌─────────┐    ┌────────────┐    ┌────────────┐    ┌────────────┐
│     UI      │───►│   Bloc  │───►│  Use Case  │───►│ Repository │───►│ Data Source│
└─────────────┘    └─────────┘    └────────────┘    └────────────┘    └────────────┘
       ▲                ▲               ▲                ▲                   │
       │                │               │                │                   │
       └────────────────┴───────────────┴────────────────┴───────────────────┘
                                  Dữ liệu phản hồi
```

## Nguyên tắc offline-first

Ứng dụng được thiết kế theo nguyên tắc offline-first:

1. **Lưu trữ cục bộ**: Tất cả dữ liệu được lưu cục bộ trước khi đồng bộ với server
2. **Message Queue**: Tin nhắn được đưa vào hàng đợi khi không có kết nối
3. **Đồng bộ hóa tự động**: Tự động đồng bộ khi có kết nối internet
4. **Phát hiện xung đột**: Giải quyết xung đột dữ liệu thông qua timestamps và IDs

## Tối ưu hiệu năng

Ứng dụng áp dụng các chiến lược tối ưu hiệu năng:

1. **Lazy loading**: Chỉ tải dữ liệu cần thiết
2. **Pagination**: Phân trang dữ liệu lớn như danh sách chat và tin nhắn
3. **Caching**: Cache hình ảnh và dữ liệu
4. **Adaptive animations**: Điều chỉnh độ phức tạp animation dựa trên khả năng thiết bị
5. **Efficient list rendering**: Sử dụng ListView.builder và tái sử dụng widgets

## Dependency Injection

Ứng dụng sử dụng pattern Dependency Injection để giảm sự phụ thuộc giữa các components:

```dart
// Đăng ký services
GetIt.I.registerSingleton<DeviceCapabilityService>(DeviceCapabilityService());
GetIt.I.registerSingleton<AnimationService>(AnimationService(GetIt.I<DeviceCapabilityService>()));

// Sử dụng service
final animationService = GetIt.I<AnimationService>();
```

## Xử lý lỗi

Ứng dụng xử lý lỗi theo các lớp:

1. **Data Layer**: Chuyển đổi lỗi mạng/database thành exceptions cụ thể
2. **Domain Layer**: Xử lý business exceptions
3. **Presentation Layer**: Hiển thị thông báo lỗi thân thiện cho người dùng

## Mở rộng trong tương lai

Kiến trúc này hỗ trợ mở rộng dễ dàng:

1. **Thêm features mới**: Tạo các use cases và repositories mới
2. **Đổi API backend**: Chỉ thay đổi ở Data Sources, không ảnh hưởng đến phần còn lại
3. **Thay đổi UI**: Presentation Layer có thể được redesign mà không ảnh hưởng đến business logic 