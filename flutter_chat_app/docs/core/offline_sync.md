# Hệ thống xử lý offline và đồng bộ hóa

## Tổng quan

Ứng dụng chat được thiết kế theo nguyên tắc **"Offline-First"**, cho phép người dùng sử dụng ứng dụng mà không cần kết nối internet liên tục. Dữ liệu được lưu trữ cục bộ và đồng bộ hóa với server khi có kết nối. Cách tiếp cận này mang lại nhiều lợi ích:

- **Trải nghiệm mượt mà**: Người dùng có thể xem và gửi tin nhắn ngay cả khi mất kết nối
- **Khả năng phục hồi**: Không bị mất dữ liệu khi mạng không ổn định
- **Tiết kiệm dữ liệu**: Chỉ đồng bộ những thay đổi, không tải lại toàn bộ dữ liệu
- **Hiệu suất tốt hơn**: Đọc/ghi dữ liệu cục bộ nhanh hơn nhiều so với network requests

## Các thành phần chính

### 1. MessageQueueService

Quản lý hàng đợi tin nhắn chờ gửi khi không có kết nối internet.

```dart
class MessageQueueService {
  /// Thêm tin nhắn vào hàng đợi
  Future<void> enqueueMessage(Message message);
  
  /// Lấy tất cả tin nhắn đang chờ gửi
  Future<List<Message>> getPendingMessages();
  
  /// Đánh dấu tin nhắn đã gửi thành công
  Future<void> markMessageAsSent(String messageId, String serverMessageId);
  
  /// Xử lý lỗi khi gửi tin nhắn
  Future<void> handleMessageError(String messageId, MessageError error);
}
```

### 2. ConnectivityService

Theo dõi trạng thái kết nối và thông báo cho các service khác.

```dart
class ConnectivityService {
  /// Stream để theo dõi trạng thái kết nối
  Stream<ConnectivityStatus> get connectivityStream;
  
  /// Kiểm tra có kết nối internet không
  Future<bool> isConnected();
  
  /// Đăng ký callback khi kết nối trở lại
  void registerOnConnectedCallback(Function callback);
  
  /// Hủy đăng ký callback
  void unregisterOnConnectedCallback(Function callback);
}
```

### 3. DatabaseService

Lưu trữ và quản lý dữ liệu cục bộ.

```dart
class DatabaseService {
  /// Lưu tin nhắn vào database cục bộ
  Future<void> saveMessage(Message message);
  
  /// Lấy tin nhắn từ database
  Future<List<Message>> getMessages(String chatId, {int limit, int offset});
  
  /// Lưu thông tin chat
  Future<void> saveChat(Chat chat);
  
  /// Lấy danh sách chat
  Future<List<Chat>> getChats();
  
  /// Cập nhật trạng thái tin nhắn
  Future<void> updateMessageStatus(String messageId, MessageStatus status);
}
```

### 4. SyncService

Đồng bộ hóa dữ liệu giữa thiết bị và server.

```dart
class SyncService {
  /// Đồng bộ tin nhắn chưa gửi
  Future<void> syncPendingMessages();
  
  /// Đồng bộ cập nhật từ server
  Future<void> syncUpdatesFromServer();
  
  /// Đồng bộ thông tin người dùng
  Future<void> syncUserData();
  
  /// Đánh dấu sync token mới nhất
  Future<void> updateLastSyncToken(String token);
}
```

## Quy trình xử lý tin nhắn

### 1. Gửi tin nhắn

```
┌───────────┐      ┌───────────┐     ┌───────────┐      ┌───────────┐
│  Người    │─────►│ Local DB  │────►│ Message   │─────►│   API     │
│  dùng     │      │ (Device)  │     │ Queue     │      │  Server   │
└───────────┘      └───────────┘     └───────────┘      └───────────┘
```

**Quy trình chi tiết**:

1. **Khởi tạo tin nhắn**:
   - Tạo một ID cục bộ duy nhất (UUID) cho tin nhắn
   - Đặt trạng thái ban đầu là `sending`
   - Lưu tin nhắn vào database cục bộ

2. **Kiểm tra kết nối**:
   - Nếu **có kết nối**: Gửi tin nhắn ngay đến server
   - Nếu **không có kết nối**: Đưa vào MessageQueue để gửi sau

3. **Xử lý phản hồi từ server**:
   - **Thành công**: Cập nhật ID và trạng thái tin nhắn trong DB
   - **Thất bại**: Giữ trong hàng đợi và thử lại sau

### 2. Nhận tin nhắn

Có hai cách nhận tin nhắn:

1. **Push Notification** (khi ứng dụng ở background/foreground):
   - Nhận notification từ FCM/APNS
   - Lưu tin nhắn vào database cục bộ
   - Cập nhật UI nếu đang ở foreground

2. **Long Polling/WebSocket** (khi ứng dụng active):
   - Duy trì kết nối WebSocket hoặc Long Polling
   - Nhận tin nhắn theo thời gian thực
   - Lưu vào database và cập nhật UI

### 3. Đồng bộ hóa khi có kết nối trở lại

```
┌───────────┐     ┌────────────┐     ┌────────────┐    ┌────────────┐
│ Kết nối   │────►│   Sync     │────►│ Message    │───►│    API     │
│ trở lại   │     │  Service   │     │  Queue     │    │   Server   │
└───────────┘     └────────────┘     └────────────┘    └────────────┘
                         │                                    │
                         ▼                                    ▼
                  ┌────────────┐                      ┌────────────┐
                  │ Local DB   │◄─────────────────────┤ Cập nhật   │
                  │ (Device)   │                      │ từ server  │
                  └────────────┘                      └────────────┘
```

**Quy trình đồng bộ**:

1. **Phát hiện kết nối trở lại**:
   - `ConnectivityService` phát hiện và thông báo

2. **Gửi tin nhắn chưa gửi**:
   - Lấy tin nhắn từ `MessageQueue`
   - Gửi lần lượt lên server
   - Cập nhật trạng thái trong DB cục bộ

3. **Lấy cập nhật từ server**:
   - Gửi `lastSyncToken` để lấy dữ liệu mới
   - Cập nhật chat, tin nhắn, trạng thái đọc

## Xử lý xung đột

### 1. Chiến lược xử lý xung đột

Ứng dụng sử dụng chiến lược xử lý xung đột dựa trên ba nguyên tắc:

1. **Timestamp-based Resolution**:
   - Mỗi thay đổi có timestamp riêng
   - Khi xung đột, ưu tiên thay đổi gần nhất

2. **Unique ID Consistency**:
   - Mỗi entity có ID duy nhất không đổi
   - ID cục bộ được ánh xạ với ID server

3. **Server Authority**:
   - Server là nguồn đáng tin cậy cuối cùng
   - Trong trường hợp không thể giải quyết, ưu tiên dữ liệu server

### 2. Ví dụ xử lý xung đột

**Tình huống**: Người dùng cập nhật tên nhóm chat khi offline, nhưng người khác cũng thay đổi khi họ online.

**Xử lý**:
1. Lưu thời gian thay đổi cục bộ
2. Khi đồng bộ, gửi timestamp cùng với dữ liệu
3. Server so sánh timestamp
4. Nếu thay đổi cục bộ mới hơn, áp dụng; nếu không, lấy dữ liệu từ server
5. Thông báo cho người dùng nếu có xung đột được giải quyết

## Cấu trúc dữ liệu offline

### 1. Schema cục bộ

Ứng dụng sử dụng **SQLite** (thông qua package `sqflite` hoặc `drift`) để lưu trữ dữ liệu:

```dart
// Bảng Chats
final chatTable = Table(
  'chats',
  columns: [
    IntColumn('id', autoIncrement: true, primaryKey: true),
    TextColumn('server_id'),
    TextColumn('name'),
    TextColumn('avatar_url'),
    IntColumn('last_message_time'),
    IntColumn('sync_status'),
    TextColumn('sync_token'),
  ],
);

// Bảng Messages
final messageTable = Table(
  'messages',
  columns: [
    IntColumn('id', autoIncrement: true, primaryKey: true),
    TextColumn('local_id'),
    TextColumn('server_id'),
    TextColumn('chat_id'),
    TextColumn('sender_id'),
    TextColumn('content'),
    IntColumn('timestamp'),
    IntColumn('status'),
    IntColumn('sync_status'),
  ],
);
```

### 2. Flags đồng bộ

Mỗi entity có cờ đánh dấu trạng thái đồng bộ:

```dart
enum SyncStatus {
  /// Đã đồng bộ đầy đủ với server
  synced,
  
  /// Chưa đồng bộ với server
  pendingSync,
  
  /// Đang cố gắng đồng bộ
  syncing,
  
  /// Xung đột cần giải quyết
  conflict,
  
  /// Lỗi khi đồng bộ
  error,
}
```

## Tối ưu hiệu suất

### 1. Đồng bộ chọn lọc

Không đồng bộ tất cả dữ liệu cùng lúc:

- **Ưu tiên đồng bộ chat đang mở**: Đảm bảo dữ liệu mới nhất cho chat người dùng đang xem
- **Batching**: Gộp nhiều thay đổi nhỏ thành một request lớn
- **Differential Sync**: Chỉ gửi những thay đổi, không gửi toàn bộ dữ liệu

### 2. Chiến lược nén dữ liệu

Giảm kích thước dữ liệu đồng bộ:

- **JSON Minification**: Giảm kích thước JSON bằng cách loại bỏ khoảng trắng và dùng tên trường ngắn
- **Nén Binary**: Sử dụng gzip hoặc các thuật toán nén khác
- **Delta Encoding**: Chỉ gửi phần khác biệt giữa phiên bản cũ và mới

### 3. Kiểm soát hàng đợi

Quản lý hàng đợi tin nhắn hiệu quả:

- **Retry với backoff**: Tăng thời gian giữa các lần thử lại
- **Batch Processing**: Xử lý nhiều tin nhắn trong một request
- **Priority Queue**: Tin nhắn quan trọng được gửi trước

## Kiểm thử

### 1. Kịch bản kiểm thử

- **Mất kết nối khi đang gửi tin nhắn**
- **Xung đột khi nhiều thiết bị cùng sửa dữ liệu**
- **Đồng bộ với lượng lớn dữ liệu**
- **Mất kết nối trong thời gian dài**
- **Kết nối không ổn định (lúc có lúc không)**

### 2. Công cụ kiểm thử

- **Network Link Conditioner**: Mô phỏng các điều kiện mạng khác nhau
- **Charles Proxy**: Giám sát và can thiệp vào request/response
- **Flutter integration tests**: Kiểm thử end-to-end với điều kiện mạng khác nhau

## Triển khai trong dự án

### 1. Cấu trúc thư mục

```
/lib
  /core
    /services
      connectivity_service.dart
      sync_service.dart
  /data
    /datasources
      /local
        database_helper.dart
        message_dao.dart
        chat_dao.dart
      /remote
        api_client.dart
    /repositories
      message_repository_impl.dart
      chat_repository_impl.dart
  /domain
    /entities
      sync_status.dart
    /repositories
      message_repository.dart
      chat_repository.dart
    /usecases
      send_message_usecase.dart
      sync_data_usecase.dart
```

### 2. Tích hợp với UI

UI hiển thị trạng thái đồng bộ:

- **Chỉ báo gửi tin nhắn**: Đang gửi, đã gửi, đã nhận, đã đọc
- **Trạng thái kết nối**: Hiển thị thông báo khi offline
- **Badge đồng bộ**: Hiển thị số lượng thay đổi chưa đồng bộ

### 3. Xử lý lỗi

- **Retry Mechanism**: Tự động thử lại khi thất bại
- **Conflict Resolution UI**: Giao diện cho người dùng giải quyết xung đột
- **Error Reporting**: Gửi báo cáo lỗi để phân tích 