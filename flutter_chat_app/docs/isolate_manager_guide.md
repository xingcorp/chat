# Hướng dẫn sử dụng IsolateManager

## Giới thiệu

`IsolateManager` là một công cụ mạnh mẽ giúp xử lý các tác vụ nặng trong background mà không làm đơ UI chính. Phiên bản cải tiến này hỗ trợ:

- Tự phục hồi isolate khi bị lỗi
- Báo cáo tiến độ theo thời gian thực
- Hủy tác vụ đang chạy
- Tự động chuyển tác vụ lỗi về main thread
- Tối ưu hóa truyền dữ liệu lớn
- Tự động điều chỉnh số lượng isolate dựa trên thiết bị

## Cách sử dụng

### 1. Khởi tạo IsolateManager

```dart
final isolateManager = getIt<IsolateManager>();
await isolateManager.initialize();
```

### 2. Xử lý tác vụ cơ bản

```dart
final result = await isolateManager.processInBackground(
  taskType: IsolateTaskType.dataProcessing,
  data: yourData,
  params: {
    'key1': 'value1',
    'key2': 'value2',
  },
);

if (result.isSuccess) {
  // Xử lý kết quả thành công
  print('Kết quả: ${result.result}');
} else {
  // Xử lý lỗi
  print('Lỗi: ${result.error}');
}
```

### 3. Báo cáo tiến độ

```dart
// Tạo controller để theo dõi tiến độ
final progressController = StreamController<IsolateProgress>();

// Lắng nghe cập nhật tiến độ
progressController.stream.listen((progress) {
  print('Tiến độ: ${progress.progress * 100}%');
  print('Trạng thái: ${progress.message}');
  
  // Cập nhật UI
  setState(() {
    _progress = progress.progress;
    _statusMessage = progress.message ?? 'Đang xử lý...';
  });
});

// Xử lý với báo cáo tiến độ
final result = await isolateManager.processInBackground(
  taskType: IsolateTaskType.imageProcessing,
  data: imageData,
  params: params,
  progressController: progressController,
);

// Đừng quên đóng controller khi hoàn thành
await progressController.close();
```

### 4. Hủy tác vụ đang chạy

```dart
// Xử lý với ID tác vụ để có thể hủy sau này
final taskId = 'custom_task_id_${DateTime.now().millisecondsSinceEpoch}';

// Bắt đầu xử lý với khả năng hủy bỏ
final futureResult = isolateManager.processInBackground(
  taskType: IsolateTaskType.fileOperation,
  taskId: taskId,
  data: largeData,
  enableCancellation: true, // Bật khả năng hủy bỏ
);

// Nếu muốn hủy tác vụ
bool cancelled = await isolateManager.cancelTask(taskId);
if (cancelled) {
  print('Đã hủy tác vụ thành công');
} else {
  print('Không thể hủy tác vụ');
}
```

### 5. Xác định ưu tiên cho tác vụ

```dart
// Tác vụ quan trọng, cần xử lý ngay
final criticalResult = await isolateManager.processInBackground(
  taskType: IsolateTaskType.cryptoOperation,
  data: sensitiveData,
  params: cryptoParams,
  priority: TaskPriority.critical, // Ưu tiên cao nhất
);

// Tác vụ ít quan trọng, có thể đợi
final lowPriorityResult = await isolateManager.processInBackground(
  taskType: IsolateTaskType.textProcessing,
  data: textData,
  params: processingParams,
  priority: TaskPriority.low, // Ưu tiên thấp
);
```

### 6. Xử lý dữ liệu lớn

IsolateManager tự động tối ưu hóa việc truyền dữ liệu lớn giữa các isolate. Để tận dụng tính năng này, hãy truyền dữ liệu dưới dạng `Uint8List` cho các mảng byte lớn như hình ảnh, âm thanh, tệp.

```dart
final bytes = await file.readAsBytes();
final result = await isolateManager.processInBackground(
  taskType: IsolateTaskType.imageProcessing,
  data: bytes, // Uint8List sẽ được tối ưu khi truyền
  params: imageParams,
);
```

## Các loại tác vụ hỗ trợ

- **IsolateTaskType.imageProcessing**: Xử lý hình ảnh (nén, resize, filter)
- **IsolateTaskType.fileOperation**: Các thao tác với tệp (copy, move, delete)
- **IsolateTaskType.dataProcessing**: Xử lý dữ liệu tổng quát
- **IsolateTaskType.cryptoOperation**: Mã hóa/giải mã
- **IsolateTaskType.searchOperation**: Tìm kiếm
- **IsolateTaskType.textProcessing**: Xử lý văn bản
- **IsolateTaskType.aiProcessing**: Xử lý AI/ML cục bộ
- **IsolateTaskType.fuzzySearch**: Tìm kiếm mờ
- **IsolateTaskType.custom**: Các tác vụ tùy chỉnh khác

## Các mức ưu tiên

- **TaskPriority.critical**: Ưu tiên cao nhất, có thể chạy trên main thread nếu isolate bận
- **TaskPriority.high**: Ưu tiên cao nhưng không khẩn cấp
- **TaskPriority.medium**: Ưu tiên mặc định
- **TaskPriority.low**: Ưu tiên thấp, có thể đợi tác vụ khác hoàn thành

## Xử lý lỗi

IsolateManager tự động phục hồi sau lỗi mà không cần can thiệp. Trong trường hợp xảy ra lỗi trong khi xử lý, `result.isSuccess` sẽ là `false` và `result.error` sẽ chứa thông tin lỗi.

## Quản lý tài nguyên

Khi không còn sử dụng nữa, hãy giải phóng tài nguyên:

```dart
@override
void dispose() {
  // Nếu bạn đã tạo StreamController cho tiến độ
  progressController.close();
  
  super.dispose();
}
```

IsolateManager sẽ được quản lý bởi DI container (GetIt) và được giải phóng khi ứng dụng kết thúc.

## Thực hành tốt

1. **Sử dụng isolate cho các tác vụ nặng**: Xử lý hình ảnh, mã hóa, phân tích dữ liệu lớn
2. **Cung cấp báo cáo tiến độ**: Giúp người dùng biết ứng dụng đang hoạt động
3. **Xác định ưu tiên phù hợp**: Không đánh dấu mọi thứ là "critical"
4. **Cho phép hủy tác vụ dài**: Trao quyền cho người dùng kiểm soát
5. **Xử lý lỗi gracefully**: Luôn kiểm tra `result.isSuccess` trước khi sử dụng kết quả

## Ví dụ hoàn chỉnh

Xem `lib/core/utils/isolate_manager_demo.dart` để xem ví dụ về cách triển khai đầy đủ các tính năng của IsolateManager, bao gồm báo cáo tiến độ và hủy tác vụ. 