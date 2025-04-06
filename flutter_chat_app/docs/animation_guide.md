# Hướng dẫn sử dụng Hero Animation và Shared Element Transitions

## Tổng quan

Tài liệu này mô tả cách triển khai và tối ưu hóa hiệu ứng **Hero Animation** và **Shared Element Transitions** trong ứng dụng Flutter Chat. Mục tiêu là tạo ra trải nghiệm người dùng mượt mà, đồng thời đảm bảo hiệu suất trên các thiết bị có cấu hình khác nhau.

## Kiến trúc Animation

### 1. Hệ thống Đánh giá Thiết bị

Ứng dụng sử dụng `DeviceCapabilityService` để đánh giá khả năng của thiết bị và tự động điều chỉnh độ phức tạp của animation:

```dart
// Lấy cấp độ animation phù hợp với thiết bị
final animationLevel = GetIt.I<DeviceCapabilityService>().currentLevel;
```

Có 3 cấp độ animation:
- **Low**: Ít hiệu ứng, ưu tiên hiệu suất
- **Medium**: Cân bằng giữa hiệu ứng và hiệu suất
- **High**: Đầy đủ hiệu ứng, giả định thiết bị mạnh

### 2. Cấu hình Animation

`AnimationService` quản lý tất cả cấu hình animation trong ứng dụng:

```dart
// Lấy service
final animationService = GetIt.I<AnimationService>();

// Sử dụng các giá trị cấu hình
final duration = animationService.config.defaultDuration;
final curve = animationService.config.defaultCurve;
```

### 3. Page Transitions

`AnimationService` cung cấp phương thức để tạo route transition tùy chỉnh:

```dart
Navigator.push(
  context,
  animationService.createRoute(
    builder: (context) => DetailScreen(id: id),
    transitionType: PageTransitionType.fadeAndSlideFromRight,
  ),
);
```

Các loại transition có sẵn:
- `fadeAndSlideFromRight`: Fade + Slide từ phải qua
- `fadeAndSlideFromLeft`: Fade + Slide từ trái qua
- `fadeAndSlideFromBottom`: Fade + Slide từ dưới lên
- `fade`: Chỉ có hiệu ứng mờ dần
- `scale`: Hiệu ứng phóng to
- `none`: Không có hiệu ứng

## Hero Animation

### Nguyên tắc thiết kế

1. **Tag duy nhất**: Mỗi hero animation cần một tag duy nhất
2. **Nhất quán**: Cả widget nguồn và đích phải sử dụng cùng một tag
3. **Tối ưu kích thước**: Đảm bảo kích thước hình ảnh phù hợp

### Triển khai

#### 1. Sử dụng HeroAvatar

Để hiển thị avatar với hero animation:

```dart
HeroAvatar(
  id: chat.id,
  imageUrl: chat.avatarUrl,
  displayName: chat.name,
  size: 40,
)
```

HeroAvatar có các tham số:
- `id`: ID duy nhất (dùng để tạo hero tag)
- `imageUrl`: URL ảnh đại diện
- `displayName`: Tên hiển thị khi không có hình
- `size`: Kích thước avatar
- `hasBorder`: Có viền hay không
- `borderColor`: Màu viền
- `borderWidth`: Độ dày viền

#### 2. Sử dụng trong Danh sách Chat

```dart
Widget _buildChatItem(Chat chat) {
  return ListTile(
    leading: HeroAvatar(
      id: chat.id,
      imageUrl: chat.avatarUrl,
      displayName: chat.name,
      size: 40,
    ),
    title: Hero(
      tag: 'chat_name_${chat.id}',
      child: Material(
        color: Colors.transparent,
        child: Text(chat.name),
      ),
    ),
    // ...
  );
}
```

#### 3. Sử dụng trong Chi tiết Chat

```dart
Widget _buildChatHeader(Chat chat) {
  return AppBar(
    leading: BackButton(),
    title: Row(
      children: [
        HeroAvatar(
          id: chat.id,
          imageUrl: chat.avatarUrl,
          displayName: chat.name,
          size: 36,
        ),
        SizedBox(width: 12),
        Hero(
          tag: 'chat_name_${chat.id}',
          child: Material(
            color: Colors.transparent,
            child: Text(chat.name),
          ),
        ),
      ],
    ),
  );
}
```

#### 4. Xem Hình ảnh Full-screen

```dart
void _openImage(BuildContext context, String url, String id) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => ImageViewerScreen(
        imageUrl: url,
        heroTag: 'image_$id',
      ),
    ),
  );
}

// Hiển thị ảnh với Hero tag
Hero(
  tag: 'image_$id',
  child: Image.network(url),
)
```

### Tối ưu hóa

1. **Bật/tắt theo thiết bị**: Hero animation sẽ bị vô hiệu hóa trên thiết bị yếu

```dart
// Kiểm tra trước khi sử dụng Hero
final useHero = animationService.config.useHeroAnimations;

return useHero
    ? Hero(tag: 'avatar_$id', child: avatarWidget)
    : avatarWidget;
```

2. **Chất lượng hình ảnh**: Điều chỉnh chất lượng hình ảnh theo khả năng thiết bị

```dart
CachedNetworkImage(
  imageUrl: imageUrl,
  filterQuality: animationService.config.imageFilterQuality,
)
```

3. **Microanimations**: Bật/tắt các hiệu ứng nhỏ dựa trên cấu hình

```dart
// Kiểm tra trước khi sử dụng microcanimations
if (animationService.config.useMicroAnimations) {
  return AnimatedOpacity(
    opacity: isVisible ? 1.0 : 0.0,
    duration: animationService.config.fastDuration,
    child: widget,
  );
} else {
  return isVisible ? widget : SizedBox.shrink();
}
```

## Thành phần khác

### 1. TypingIndicator

Widget hiển thị chỉ báo đang nhập văn bản:

```dart
TypingIndicatorWithFade(
  isTyping: isUserTyping,
  displayName: user.name,
)
```

### 2. MediaGalleryScreen

Màn hình dạng lưới hiển thị ảnh/videos với Hero animation:

```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => MediaGalleryScreen(
      chatId: chatId,
      title: 'Hình ảnh',
    ),
  ),
);
```

### 3. ImageViewerScreen

Màn hình xem hình ảnh với khả năng phóng to, zoom và Hero animation:

```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => ImageViewerScreen(
      imageUrl: url,
      heroTag: heroTag,
      title: title,
    ),
  ),
);
```

## Sự cố thường gặp

1. **Flickering**: Đảm bảo sử dụng `Material` widget bên trong Hero nếu có text
2. **Lỗi tag trùng lặp**: Luôn đảm bảo tag là duy nhất
3. **Hiệu suất kém**: Giảm độ phức tạp animation trên thiết bị yếu
4. **Layout Shifts**: Đảm bảo kích thước của widget Hero giống nhau ở màn hình nguồn và đích

## Tham khảo

- [Flutter Hero Animation](https://flutter.dev/docs/development/ui/animations/hero-animations)
- [Optimizing Performance](https://flutter.dev/docs/perf/rendering/shader) 