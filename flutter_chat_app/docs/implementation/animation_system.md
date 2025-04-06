# Hệ thống Animation

## Tổng quan

Ứng dụng chat sử dụng hệ thống animation thích nghi, tự động điều chỉnh độ phức tạp animation dựa trên khả năng thiết bị. Mục tiêu là cung cấp trải nghiệm người dùng mượt mà trên mọi thiết bị mà không ảnh hưởng đến hiệu suất. Thiết kế này được lấy cảm hứng từ các ứng dụng nhắn tin phổ biến như WhatsApp, Messenger, Telegram.

## Kiến trúc Animation

### 1. Đánh giá và phân loại thiết bị

Hệ thống dựa trên `DeviceCapabilityService` để đánh giá hiệu năng thiết bị thông qua các tiêu chí:

- **Đo FPS**: Chạy animation test và đo lường frame rate
- **Thông tin phần cứng**: Phiên bản OS, RAM, model thiết bị
- **Điểm benchmark**: Tổng hợp các yếu tố trên thành điểm đánh giá thiết bị

Từ đó thiết bị được phân loại thành 3 cấp độ:

```dart
/// Các cấp độ animation hiệu ứng
enum AnimationLevel {
  /// Mức độ thấp: ít animation nhất, ưu tiên hiệu suất
  low,
  
  /// Mức độ trung bình: cân bằng giữa hiệu ứng và hiệu suất
  medium,
  
  /// Mức độ cao: đầy đủ hiệu ứng, giả định thiết bị mạnh
  high,
}
```

### 2. Cấu hình Animation

`AnimationService` quản lý tất cả cấu hình animation trong ứng dụng:

```dart
class AnimationConfig {
  /// Thời gian animation mặc định
  final Duration defaultDuration;
  
  /// Thời gian animation dài
  final Duration longDuration;
  
  /// Thời gian animation nhanh
  final Duration fastDuration;
  
  /// Có sử dụng Hero animation không
  final bool useHeroAnimations;
  
  /// Có sử dụng chuyển trang nâng cao không
  final bool useExtendedTransitions;
  
  /// Có sử dụng micro-animations không
  final bool useMicroAnimations;
  
  /// Có sử dụng hiệu ứng nâng cao không
  final bool useAdvancedEffects;
  
  /// Chất lượng filter cho hình ảnh
  final FilterQuality imageFilterQuality;
  
  /// Curve mặc định cho animation
  final Curve defaultCurve;
}
```

Mỗi cấp độ thiết bị có một cấu hình animation khác nhau:

- **Low**: Tối giản animation, ưu tiên hiệu suất
  - Thời gian animation ngắn
  - Không sử dụng Hero animations
  - Không dùng page transitions phức tạp
  - FilterQuality thấp cho hình ảnh

- **Medium**: Cân bằng giữa hiệu ứng và hiệu suất
  - Thời gian animation trung bình
  - Có sử dụng Hero animations
  - Dùng page transitions cơ bản
  - FilterQuality trung bình

- **High**: Đầy đủ hiệu ứng
  - Thời gian animation dài hơn
  - Đầy đủ Hero animations
  - Page transitions phức tạp
  - FilterQuality cao
  - Haptic feedback và các hiệu ứng nâng cao

## Các loại animation

### 1. Shared Element Transitions (Hero)

Hero animation cho phép các thành phần UI được chia sẻ giữa các màn hình, tạo ra trải nghiệm chuyển tiếp mượt mà.

```dart
// Sử dụng HeroAvatar trong danh sách chat
HeroAvatar(
  id: chat.id,
  imageUrl: chat.avatarUrl,
  displayName: chat.name,
  size: 40,
)

// Cùng HeroAvatar trong màn hình chi tiết
HeroAvatar(
  id: chat.id,
  imageUrl: chat.avatarUrl,
  displayName: chat.name,
  size: 36,
)
```

Các thành phần hỗ trợ Hero animation:
- **HeroAvatar**: Avatar có animation khi chuyển màn hình
- **Hero wrapper cho text**: Title với animation

### 2. Page Transitions

Cung cấp các loại chuyển trang với hiệu ứng mượt mà:

```dart
// Tạo route với animation
Navigator.push(
  context,
  animationService.createRoute(
    builder: (context) => DetailScreen(),
    transitionType: PageTransitionType.fadeAndSlideFromRight,
  ),
);
```

Các loại transition:
- `fadeAndSlideFromRight`: Fade + Slide từ phải sang
- `fadeAndSlideFromLeft`: Fade + Slide từ trái sang
- `fadeAndSlideFromBottom`: Fade + Slide từ dưới lên
- `fade`: Chỉ có hiệu ứng mờ dần
- `scale`: Hiệu ứng phóng to
- `none`: Không có hiệu ứng

### 3. Micro-animations

Các animation nhỏ trong UI để tăng trải nghiệm người dùng:

```dart
// Wrap widget với animation fade
animationService.wrapWithFadeAnimation(
  child: myWidget,
  visible: isVisible,
)
```

Ví dụ micro-animations:
- **TypingIndicator**: Chỉ báo người dùng đang nhập
- **Message status**: Trạng thái tin nhắn (đã gửi, đã nhận, đã đọc)
- **Button feedback**: Phản hồi khi nhấn nút

### 4. Image animations

Các animation liên quan đến hình ảnh:

- **ImageViewerScreen**: Xem hình ảnh full-screen với zoom, pan
- **MediaGalleryScreen**: Danh sách hình ảnh dạng lưới với Hero transition

## Tối ưu hóa Animation

### 1. Thích nghi với điều kiện hệ thống

Hệ thống tự động giảm độ phức tạp animation trong một số trường hợp:

- **Chế độ tiết kiệm pin**: Khi thiết bị ở chế độ tiết kiệm pin
- **Hiệu năng thấp**: Trên thiết bị cấu hình yếu
- **Lag phát hiện**: Khi phát hiện frame rate thấp

```dart
// Đặt chế độ tiết kiệm pin
animationService.setLowPowerMode(isLowPower);
```

### 2. Chiến lược phân cấp animation

Animation được phân loại theo mức độ ưu tiên:

1. **Cần thiết**: Animation luôn được kích hoạt (loading indicator)
2. **Quan trọng**: Animation cho UX chính (page transitions)
3. **Tùy chọn**: Animation bổ sung (micro-animations)

Khi hiệu năng giảm, hệ thống sẽ vô hiệu hóa animation theo thứ tự ưu tiên từ thấp đến cao.

### 3. Hiệu suất với các danh sách dài

Khi hiển thị danh sách dài, các chiến lược được áp dụng:

- **Lazy loading hero**: Chỉ kích hoạt hero animation cho các mục trong viewport
- **Simplified animation**: Đơn giản hóa animation khi scroll nhanh

## Tích hợp vào dự án

### 1. Sử dụng AnimationService

Mọi animation nên sử dụng cấu hình từ AnimationService:

```dart
// Lấy service
final animationService = GetIt.I<AnimationService>();

// Sử dụng cấu hình
final duration = animationService.config.defaultDuration;
final curve = animationService.config.defaultCurve;
```

### 2. Điều kiện hóa animation

Luôn kiểm tra điều kiện trước khi áp dụng animation phức tạp:

```dart
// Kiểm tra khả năng thiết bị trước khi dùng animation phức tạp
if (animationService.config.useHeroAnimations) {
  // Dùng Hero animation
} else {
  // Fallback không dùng animation
}
```

### 3. Testing animation

Phương pháp kiểm thử animation:

- **Test trên thiết bị thật**: Đặc biệt là thiết bị cấu hình thấp
- **Test đa cấp độ**: Kiểm tra với 3 cấp độ animation
- **Performance profiling**: Sử dụng Flutter DevTools để phân tích hiệu suất

## Các vấn đề thường gặp

1. **Flickering với Hero**: Đảm bảo sử dụng Material trong Hero cho text
2. **Jank khi Hero lớn**: Giảm kích thước/độ phức tạp của widget dùng Hero
3. **Trễ khi tải hình ảnh**: Sử dụng placeholder và pre-loading
4. **Lỗi Hero tag trùng**: Đảm bảo hero tag luôn duy nhất 