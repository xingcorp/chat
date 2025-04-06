# Nguyên tắc Thiết kế UI/UX 

Tài liệu này mô tả các nguyên tắc thiết kế UI/UX được áp dụng trong ứng dụng Chat, đảm bảo giao diện nhất quán, trải nghiệm người dùng mượt mà, và accessibility cao.

## Design System

### Bảng màu

Ứng dụng sử dụng bảng màu sau để đảm bảo tính nhất quán và tuân thủ các nguyên tắc thiết kế Material Design:

```dart
class AppColors {
  // Màu chính
  static const primary = Color(0xFF4B6BFF);
  static const primaryDark = Color(0xFF3652CC);
  static const primaryLight = Color(0xFFE7EBFF);
  
  // Màu trung tính
  static const neutral100 = Color(0xFFF9FAFB);
  static const neutral200 = Color(0xFFF4F6F8);
  static const neutral300 = Color(0xFFDFE3E8);
  static const neutral400 = Color(0xFFC4CDD5);
  static const neutral500 = Color(0xFF919EAB);
  static const neutral600 = Color(0xFF637381);
  static const neutral700 = Color(0xFF454F5B);
  static const neutral800 = Color(0xFF212B36);
  static const neutral900 = Color(0xFF161C24);
  
  // Màu ngữ cảnh
  static const success = Color(0xFF0AC074);
  static const warning = Color(0xFFFFA113);
  static const error = Color(0xFFFF4842);
  static const info = Color(0xFF1890FF);
  
  // Màu gradient
  static const gradientStart = Color(0xFF4B6BFF);
  static const gradientEnd = Color(0xFF6B8BFF);
  
  // Màu tin nhắn
  static const messageBubbleOwn = Color(0xFF4B6BFF);
  static const messageBubbleOther = Color(0xFFF4F6F8);
  static const messageBubbleSpecial = Color(0xFFF3F4FF);
  
  // Màu Dark Mode
  static const darkBackground = Color(0xFF121212);
  static const darkSurface = Color(0xFF1E1E1E);
}
```

### Typography

Hệ thống typography được định nghĩa rõ ràng để đảm bảo tính đọc được và hiệu quả trên tất cả các màn hình:

```dart
class AppTypography {
  static const fontFamily = 'Inter';
  
  // Heading
  static const TextStyle h1 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 32,
    fontWeight: FontWeight.bold,
    height: 1.25,
    letterSpacing: -0.5,
  );
  
  static const TextStyle h2 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 24,
    fontWeight: FontWeight.bold,
    height: 1.35,
    letterSpacing: -0.25,
  );
  
  static const TextStyle h3 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 1.4,
    letterSpacing: -0.15,
  );
  
  // Body text
  static const TextStyle bodyLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.normal,
    height: 1.5,
  );
  
  static const TextStyle bodyMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.normal,
    height: 1.5,
  );
  
  static const TextStyle bodySmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.normal,
    height: 1.5,
  );
  
  // Button text
  static const TextStyle buttonLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.5,
    letterSpacing: 0.5,
  );
  
  static const TextStyle buttonMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1.5,
    letterSpacing: 0.25,
  );
  
  // Caption
  static const TextStyle caption = TextStyle(
    fontFamily: fontFamily,
    fontSize: 11,
    fontWeight: FontWeight.normal,
    height: 1.5,
    letterSpacing: 0.4,
  );
}
```

### Spacing

Hệ thống spacing giúp duy trì nhất quán trong bố cục và hiển thị:

```dart
class AppSpacing {
  // Space values based on 4-point grid
  static const double xxxs = 2;
  static const double xxs = 4;
  static const double xs = 8;
  static const double s = 12;
  static const double m = 16;
  static const double l = 24;
  static const double xl = 32;
  static const double xxl = 40;
  static const double xxxl = 48;
  
  // Padding constants
  static const EdgeInsets screenPadding = EdgeInsets.symmetric(
    horizontal: m,
    vertical: m,
  );
  
  static const EdgeInsets cardPadding = EdgeInsets.all(m);
  
  static const EdgeInsets listItemPadding = EdgeInsets.symmetric(
    horizontal: m,
    vertical: s,
  );
  
  // Border radius
  static const double radiusSmall = 4;
  static const double radiusMedium = 8;
  static const double radiusLarge = 12;
  static const double radiusExtraLarge = 20;
  
  // Standard border radiuses
  static final BorderRadius borderRadiusSmall = BorderRadius.circular(radiusSmall);
  static final BorderRadius borderRadiusMedium = BorderRadius.circular(radiusMedium);
  static final BorderRadius borderRadiusLarge = BorderRadius.circular(radiusLarge);
  static final BorderRadius borderRadiusExtraLarge = BorderRadius.circular(radiusExtraLarge);
}
```

### Elevation và Shadow

Định nghĩa shadow để biểu thị độ nâng của các thành phần:

```dart
class AppShadows {
  static List<BoxShadow> get small => [
    BoxShadow(
      color: Colors.black.withOpacity(0.05),
      offset: const Offset(0, 1),
      blurRadius: 2,
    ),
  ];
  
  static List<BoxShadow> get medium => [
    BoxShadow(
      color: Colors.black.withOpacity(0.08),
      offset: const Offset(0, 2),
      blurRadius: 8,
      spreadRadius: 1,
    ),
  ];
  
  static List<BoxShadow> get large => [
    BoxShadow(
      color: Colors.black.withOpacity(0.12),
      offset: const Offset(0, 4),
      blurRadius: 16,
      spreadRadius: 2,
    ),
  ];
  
  static List<BoxShadow> get messageOwn => [
    BoxShadow(
      color: AppColors.primary.withOpacity(0.2),
      offset: const Offset(0, 2),
      blurRadius: 4,
    ),
  ];
  
  static List<BoxShadow> get messageOther => [
    BoxShadow(
      color: Colors.black.withOpacity(0.05),
      offset: const Offset(0, 1),
      blurRadius: 2,
    ),
  ];
}
```

## Component Library

### Common Widgets

Các widget dùng chung xuyên suốt ứng dụng:

```dart
class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final ButtonSize size;
  final ButtonVariant variant;
  final bool isLoading;
  final bool isFullWidth;
  final IconData? icon;
  
  const AppButton({
    Key? key,
    required this.label,
    required this.onPressed,
    this.size = ButtonSize.medium,
    this.variant = ButtonVariant.filled,
    this.isLoading = false,
    this.isFullWidth = false,
    this.icon,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return _buildButton();
  }
  
  Widget _buildButton() {
    final deviceCapability = GetIt.instance<DeviceCapabilityService>();
    final shouldUseSimpleAnimations = !deviceCapability.canUseComplexAnimations;
    
    // Xác định style dựa trên variant, size, isFullWidth
    final style = _getButtonStyle();
    final textStyle = _getTextStyle();
    final height = _getHeight();
    final width = isFullWidth ? double.infinity : null;
    
    return SizedBox(
      height: height,
      width: width,
      child: shouldUseSimpleAnimations
          ? _buildSimpleButton(style, textStyle)
          : _buildAnimatedButton(style, textStyle),
    );
  }
  
  // Implementations for _buildSimpleButton, _buildAnimatedButton...
}

enum ButtonSize { small, medium, large }
enum ButtonVariant { filled, outlined, text }
```

### Chat-specific Components

Các thành phần dành riêng cho ứng dụng chat:

```dart
class MessageBubble extends StatelessWidget {
  final Message message;
  final bool isOwn;
  final bool showSenderInfo;
  final bool isLastInGroup;
  final VoidCallback? onLongPress;
  
  const MessageBubble({
    Key? key,
    required this.message,
    required this.isOwn,
    this.showSenderInfo = false,
    this.isLastInGroup = false,
    this.onLongPress,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: onLongPress,
      child: Align(
        alignment: isOwn ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin: EdgeInsets.only(
            left: isOwn ? AppSpacing.xl : 0,
            right: isOwn ? 0 : AppSpacing.xl,
            bottom: isLastInGroup ? AppSpacing.s : AppSpacing.xxs,
          ),
          padding: EdgeInsets.all(AppSpacing.s),
          decoration: BoxDecoration(
            color: isOwn ? AppColors.messageBubbleOwn : AppColors.messageBubbleOther,
            borderRadius: _getBorderRadius(),
            boxShadow: isOwn ? AppShadows.messageOwn : AppShadows.messageOther,
          ),
          child: _buildMessageContent(),
        ),
      ),
    );
  }
  
  BorderRadius _getBorderRadius() {
    const radius = AppSpacing.radiusLarge;
    
    if (isOwn) {
      return BorderRadius.only(
        topLeft: Radius.circular(radius),
        topRight: isLastInGroup ? Radius.circular(radius) : Radius.circular(AppSpacing.radiusSmall),
        bottomLeft: Radius.circular(radius),
        bottomRight: Radius.circular(AppSpacing.radiusSmall),
      );
    } else {
      return BorderRadius.only(
        topLeft: isLastInGroup ? Radius.circular(radius) : Radius.circular(AppSpacing.radiusSmall),
        topRight: Radius.circular(radius),
        bottomLeft: Radius.circular(AppSpacing.radiusSmall),
        bottomRight: Radius.circular(radius),
      );
    }
  }
  
  Widget _buildMessageContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showSenderInfo && !isOwn) _buildSenderInfo(),
        _buildMessageBody(),
        _buildMessageFooter(),
      ],
    );
  }
  
  // Implementations for _buildSenderInfo, _buildMessageBody, _buildMessageFooter...
}
```

### Input Components

Các thành phần input với validate và error handling:

```dart
class AppTextField extends StatelessWidget {
  final String label;
  final String? hint;
  final String? errorText;
  final TextEditingController controller;
  final FocusNode? focusNode;
  final bool obscureText;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onSubmitted;
  final IconData? prefixIcon;
  final Widget? suffix;
  final int? maxLength;
  final int maxLines;
  
  const AppTextField({
    Key? key,
    required this.label,
    this.hint,
    this.errorText,
    required this.controller,
    this.focusNode,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.next,
    this.onChanged,
    this.onSubmitted,
    this.prefixIcon,
    this.suffix,
    this.maxLength,
    this.maxLines = 1,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.bodyMedium.copyWith(
            fontWeight: FontWeight.w500,
            color: AppColors.neutral700,
          ),
        ),
        SizedBox(height: AppSpacing.xxs),
        TextField(
          controller: controller,
          focusNode: focusNode,
          obscureText: obscureText,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          maxLength: maxLength,
          maxLines: maxLines,
          style: AppTypography.bodyLarge,
          onChanged: onChanged,
          onSubmitted: (_) => onSubmitted?.call(),
          decoration: InputDecoration(
            hintText: hint,
            errorText: errorText,
            prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
            suffix: suffix,
            border: OutlineInputBorder(
              borderRadius: AppSpacing.borderRadiusMedium,
              borderSide: BorderSide(color: AppColors.neutral300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: AppSpacing.borderRadiusMedium,
              borderSide: BorderSide(color: AppColors.neutral300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: AppSpacing.borderRadiusMedium,
              borderSide: BorderSide(color: AppColors.primary, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: AppSpacing.borderRadiusMedium,
              borderSide: BorderSide(color: AppColors.error),
            ),
            filled: true,
            fillColor: AppColors.neutral100,
            contentPadding: EdgeInsets.symmetric(
              horizontal: AppSpacing.m,
              vertical: AppSpacing.s,
            ),
          ),
        ),
      ],
    );
  }
}
```

## Layout Patterns

### Responsive Design

Hướng dẫn responsive design để đảm bảo ứng dụng hoạt động tốt trên mọi kích thước màn hình:

```dart
class ResponsiveLayout extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;
  
  const ResponsiveLayout({
    Key? key,
    required this.mobile,
    this.tablet,
    this.desktop,
  }) : super(key: key);
  
  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < 650;
  
  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= 650 &&
      MediaQuery.of(context).size.width < 1100;
  
  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= 1100;
  
  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    
    if (size.width >= 1100 && desktop != null) {
      return desktop!;
    } else if (size.width >= 650 && tablet != null) {
      return tablet!;
    } else {
      return mobile;
    }
  }
}
```

### Split View Layout

Bố cục tách view cho tablet và desktop:

```dart
class SplitViewLayout extends StatelessWidget {
  final Widget master;
  final Widget detail;
  final double masterWidthFraction;
  
  const SplitViewLayout({
    Key? key,
    required this.master,
    required this.detail,
    this.masterWidthFraction = 0.35,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      mobile: master, // On mobile, show only master view with navigator
      tablet: _buildSplitView(context, masterWidthFraction),
      desktop: _buildSplitView(context, masterWidthFraction * 0.8), // Thinner master on desktop
    );
  }
  
  Widget _buildSplitView(BuildContext context, double widthFraction) {
    return Row(
      children: [
        SizedBox(
          width: MediaQuery.of(context).size.width * widthFraction,
          child: master,
        ),
        Container(
          width: 1,
          color: AppColors.neutral300,
        ),
        Expanded(
          child: detail,
        ),
      ],
    );
  }
}
```

## Adaptive Features

### Dark Mode Support

```dart
class AppTheme {
  static ThemeData getLightTheme() {
    return ThemeData(
      brightness: Brightness.light,
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: AppColors.neutral100,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: AppColors.neutral800),
        titleTextStyle: AppTypography.h3.copyWith(color: AppColors.neutral800),
      ),
      // Other theme properties...
    );
  }
  
  static ThemeData getDarkTheme() {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: AppColors.darkBackground,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.darkSurface,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: Colors.white),
        titleTextStyle: AppTypography.h3.copyWith(color: Colors.white),
      ),
      // Dark theme properties...
    );
  }
}
```

### Dynamic Text Size

```dart
class DynamicTextSize {
  static double getScaledFontSize(BuildContext context, double fontSize) {
    final textScaleFactor = MediaQuery.of(context).textScaleFactor;
    
    // Restrict scaling to reasonable limits to prevent layout issues
    final scaleFactor = textScaleFactor.clamp(0.8, 1.3);
    
    return fontSize * scaleFactor;
  }
  
  static TextStyle getScaledTextStyle(BuildContext context, TextStyle style) {
    return style.copyWith(
      fontSize: getScaledFontSize(context, style.fontSize ?? 14),
    );
  }
}
```

## Animations

### Animation Guidelines

Các nguyên tắc animation để đảm bảo UI mượt mà và thân thiện với người dùng:

1. **Phát vụ hóa** (Servility) - Animation phục vụ mục đích UX, không làm mất tập trung
2. **Nhất quán** (Consistency) - Animation nhất quán trong toàn ứng dụng
3. **Hiệu quả** (Efficiency) - Animation ngắn gọn, không gây chậm trễ
4. **Phản hồi** (Responsiveness) - Animation phản hồi tức thì với tương tác của người dùng

```dart
class AnimationConstants {
  // Thời gian cho các loại animation
  static const Duration shortDuration = Duration(milliseconds: 150);
  static const Duration normalDuration = Duration(milliseconds: 250);
  static const Duration longDuration = Duration(milliseconds: 350);
  
  // Các curves thường dùng
  static const Curve defaultCurve = Curves.fastOutSlowIn;
  static const Curve emphasizedCurve = Curves.easeOutCubic;
  static const Curve entranceCurve = Curves.easeOut;
  static const Curve exitCurve = Curves.easeIn;
  
  // Offset cho slide animation
  static const Offset slideInFromBottomOffset = Offset(0.0, 0.2);
  static const Offset slideInFromRightOffset = Offset(0.2, 0.0);
  static const Offset slideInFromLeftOffset = Offset(-0.2, 0.0);
  
  // Scale factors
  static const double defaultScaleStart = 0.95;
  
  // Opacity values
  static const double defaultOpacityStart = 0.0;
  static const double mediumOpacityStart = 0.3;
}
```

### Animation Components

Các widget animation tái sử dụng:

```dart
class FadeInSlideWidget extends StatefulWidget {
  final Widget child;
  final Duration delay;
  final Duration duration;
  final Offset offset;
  
  const FadeInSlideWidget({
    Key? key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = AnimationConstants.normalDuration,
    this.offset = AnimationConstants.slideInFromBottomOffset,
  }) : super(key: key);
  
  @override
  State<FadeInSlideWidget> createState() => _FadeInSlideWidgetState();
}

class _FadeInSlideWidgetState extends State<FadeInSlideWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;
  late Animation<Offset> _slideAnimation;
  
  @override
  void initState() {
    super.initState();
    
    final deviceCapability = GetIt.instance<DeviceCapabilityService>();
    
    // Nếu thiết bị không đủ khả năng, chỉ sử dụng fade animation đơn giản
    final useSimpleAnimation = deviceCapability.animationLevel == AnimationLevel.low;
    
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    
    _opacityAnimation = Tween<double>(
      begin: AnimationConstants.defaultOpacityStart,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: AnimationConstants.entranceCurve,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: useSimpleAnimation ? Offset.zero : widget.offset,
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: AnimationConstants.entranceCurve,
    ));
    
    if (widget.delay == Duration.zero) {
      _controller.forward();
    } else {
      Future.delayed(widget.delay, () {
        if (mounted) _controller.forward();
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacityAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: widget.child,
      ),
    );
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
```

## Accessibility

### Nguyên tắc Accessibility

Các nguyên tắc accessibility để đảm bảo ứng dụng có thể sử dụng bởi mọi người:

1. **Text Scaling** - Hỗ trợ text scaling để người dùng có thể điều chỉnh kích thước chữ
2. **Screen Reader Support** - Cung cấp mô tả accessibility cho các widget tương tác
3. **Color Contrast** - Đảm bảo tỷ lệ tương phản màu đủ cao (WCAG AA)
4. **Focus Indicators** - Cung cấp focus indicator rõ ràng cho keyboard navigation

```dart
class AccessibleWidget extends StatelessWidget {
  final Widget child;
  final String label;
  final String? hint;
  final VoidCallback? onTap;
  
  const AccessibleWidget({
    Key? key,
    required this.child,
    required this.label,
    this.hint,
    this.onTap,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      hint: hint,
      button: onTap != null,
      child: ExcludeSemantics(
        child: onTap != null
            ? GestureDetector(
                onTap: onTap,
                child: child,
              )
            : child,
      ),
    );
  }
}
```

### High Contrast Mode

```dart
class HighContrastTheme {
  static ThemeData getHighContrastTheme() {
    return ThemeData(
      brightness: Brightness.light,
      primaryColor: Colors.black,
      accentColor: Colors.white,
      scaffoldBackgroundColor: Colors.white,
      textTheme: TextTheme(
        headline1: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        // Other text styles with high contrast
      ),
      // Other theme properties for high contrast
    );
  }
}
```

## Best Practices

### UI Optimization

1. **Performance Optimization**
   - Sử dụng `const` constructor khi có thể
   - Áp dụng `RepaintBoundary` cho các widget phức tạp
   - Tối ưu rebuild bằng cách tách các widget thành các phần nhỏ hơn

2. **Usability Principles**
   - Đảm bảo kích thước touch target tối thiểu 44x44px
   - Cung cấp visual feedback cho mọi tương tác
   - Đặt các UI control quan trọng trong vùng dễ với tới của ngón tay cái

3. **Visual Consistency**
   - Tuân thủ grid system 4px
   - Đảm bảo vertical rhythm trong layout
   - Giữ nhất quán khoảng cách và alignment

### UX Patterns

1. **Error Handling**
   - Sử dụng inline validation
   - Hiển thị lỗi gần với nguồn lỗi
   - Cung cấp hướng dẫn cụ thể để khắc phục lỗi

```dart
class ValidationUtils {
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email không được để trống';
    }
    
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Email không đúng định dạng';
    }
    
    return null;
  }
  
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Mật khẩu không được để trống';
    }
    
    if (value.length < 8) {
      return 'Mật khẩu phải có ít nhất 8 ký tự';
    }
    
    return null;
  }
  
  static String? validateNonEmpty(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName không được để trống';
    }
    
    return null;
  }
}
```

2. **Empty States**
   - Cung cấp empty state có ích
   - Hướng dẫn người dùng thực hiện hành động tiếp theo
   - Sử dụng hình ảnh minh họa để làm rõ context

```dart
class EmptyStateWidget extends StatelessWidget {
  final String title;
  final String message;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;
  
  const EmptyStateWidget({
    Key? key,
    required this.title,
    required this.message,
    required this.icon,
    this.actionLabel,
    this.onAction,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.l),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 64,
              color: AppColors.neutral400,
            ),
            SizedBox(height: AppSpacing.m),
            Text(
              title,
              style: AppTypography.h3,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: AppSpacing.xs),
            Text(
              message,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.neutral600,
              ),
              textAlign: TextAlign.center,
            ),
            if (actionLabel != null) ...[
              SizedBox(height: AppSpacing.l),
              AppButton(
                label: actionLabel!,
                onPressed: onAction!,
                variant: ButtonVariant.outlined,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
```

3. **Loading States**
   - Sử dụng skeleton loading thay vì spinner khi có thể
   - Hiển thị progress indicator cho các thao tác dài
   - Đảm bảo UI không bị block khi loading

```dart
class SkeletonLoading extends StatelessWidget {
  final double width;
  final double height;
  final BorderRadius borderRadius;
  
  const SkeletonLoading({
    Key? key,
    required this.width,
    required this.height,
    this.borderRadius = const BorderRadius.all(Radius.circular(4)),
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Shimmer.fromColors(
      baseColor: isDarkMode 
          ? Colors.grey[800]! 
          : Colors.grey[300]!,
      highlightColor: isDarkMode 
          ? Colors.grey[700]! 
          : Colors.grey[100]!,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: borderRadius,
        ),
      ),
    );
  }
}
```

## Design Checklist

Sử dụng checklist này để đảm bảo UI/UX chất lượng cao:

- [ ] **Nhất quán** - UI sử dụng các thành phần từ design system
- [ ] **Responsive** - UI hoạt động tốt trên tất cả kích thước màn hình
- [ ] **Accessible** - UI tuân thủ WCAG 2.1 AA guidelines
- [ ] **Hiệu quả** - UI mượt mà, không có jank hay lag
- [ ] **Dark mode** - UI hoạt động tốt trong cả light và dark mode
- [ ] **Empty states** - Có empty states có ích cho tất cả views
- [ ] **Error states** - Thông báo lỗi rõ ràng và hữu ích
- [ ] **Loading states** - Loading indicators phù hợp và không làm gián đoạn
- [ ] **Animation** - Animation phù hợp, mượt mà và có mục đích

## Tham khảo

- [Material Design Guidelines](https://material.io/design)
- [Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/)
- [WCAG 2.1 Guidelines](https://www.w3.org/TR/WCAG21/)
- [Flutter Accessibility Guide](https://flutter.dev/docs/development/accessibility-and-localization/accessibility)
- [Flutter ResponsiveFramework](https://pub.dev/packages/responsive_framework) 