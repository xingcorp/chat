import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_chat_app/core/base/base_widget.dart';
import 'package:flutter_chat_app/core/constants/app_dimens.dart';
import 'package:flutter_chat_app/core/theme/app_colors.dart';
import 'package:flutter_chat_app/core/theme/app_text_styles.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/menus/menu_enums.dart';

/// **APP TOOLTIP**
///
/// Enhanced tooltip component with rich content support and smart positioning.
/// Extends [BaseStatefulWidget] for lifecycle management.
///
/// **Features**:
/// - Hover and long-press triggers
/// - Smart positioning (top, bottom, left, right, auto)
/// - Rich content support (not just text)
/// - Configurable delay before showing
/// - Arrow pointer to target
/// - Dismiss on tap outside
/// - Dark mode support
/// - Accessibility labels
///
/// **Usage**:
/// ```dart
/// // Simple text tooltip
/// AppTooltip(
///   message: context.l10n.tapToView,
///   child: IconButton(
///     icon: Icon(Icons.info),
///     onPressed: () {},
///   ),
/// )
///
/// // Rich content tooltip
/// AppTooltip.rich(
///   content: Column(
///     mainAxisSize: MainAxisSize.min,
///     children: [
///       Text('Title', style: TextStyle(fontWeight: FontWeight.bold)),
///       SizedBox(height: AppDimens.spaceSmall),
///       Text('Description text'),
///     ],
///   ),
///   position: TooltipPosition.bottom,
///   child: Icon(Icons.help),
/// )
///
/// // Custom delay
/// AppTooltip(
///   message: context.l10n.longPressForOptions,
///   showDelay: Duration(milliseconds: 500),
///   child: MessageBubble(),
/// )
/// ```
class AppTooltip extends BaseStatefulWidget {
  const AppTooltip({
    super.key,
    this.message,
    this.content,
    required this.child,
    this.position = TooltipPosition.auto,
    this.showDelay = const Duration(milliseconds: 300),
    this.hideDelay = const Duration(milliseconds: 100),
    this.showArrow = true,
    this.backgroundColor,
    this.textStyle,
    this.padding,
    this.margin,
    this.maxWidth = 200.0,
    this.enableHover = true,
    this.enableLongPress = true,
  }) : assert(
          message != null || content != null,
          'Either message or content must be provided',
        );

  /// Simple text message (for basic tooltips)
  final String? message;

  /// Rich content widget (for advanced tooltips)
  final Widget? content;

  /// Child widget that triggers the tooltip
  final Widget child;

  /// Preferred tooltip position
  final TooltipPosition position;

  /// Delay before showing tooltip
  final Duration showDelay;

  /// Delay before hiding tooltip
  final Duration hideDelay;

  /// Whether to show arrow pointer
  final bool showArrow;

  /// Background color (defaults to theme-based)
  final Color? backgroundColor;

  /// Text style for message
  final TextStyle? textStyle;

  /// Content padding
  final EdgeInsets? padding;

  /// Margin from target
  final EdgeInsets? margin;

  /// Maximum width of tooltip
  final double maxWidth;

  /// Enable hover trigger (desktop/web)
  final bool enableHover;

  /// Enable long-press trigger (mobile)
  final bool enableLongPress;

  /// Factory constructor for rich content tooltip
  factory AppTooltip.rich({
    Key? key,
    required Widget content,
    required Widget child,
    TooltipPosition position = TooltipPosition.auto,
    Duration showDelay = const Duration(milliseconds: 300),
    Duration hideDelay = const Duration(milliseconds: 100),
    bool showArrow = true,
    Color? backgroundColor,
    EdgeInsets? padding,
    EdgeInsets? margin,
    double maxWidth = 200.0,
    bool enableHover = true,
    bool enableLongPress = true,
  }) {
    return AppTooltip(
      key: key,
      content: content,
      child: child,
      position: position,
      showDelay: showDelay,
      hideDelay: hideDelay,
      showArrow: showArrow,
      backgroundColor: backgroundColor,
      padding: padding,
      margin: margin,
      maxWidth: maxWidth,
      enableHover: enableHover,
      enableLongPress: enableLongPress,
    );
  }

  @override
  State<AppTooltip> createState() => _AppTooltipState();
}

class _AppTooltipState extends BaseState<AppTooltip> {
  OverlayEntry? _overlayEntry;
  Timer? _showTimer;
  Timer? _hideTimer;
  bool _isShowing = false;

  @override
  void dispose() {
    _hideTooltip();
    _showTimer?.cancel();
    _hideTimer?.cancel();
    super.dispose();
  }

  void _scheduleShow() {
    _hideTimer?.cancel();
    if (_isShowing) return;

    _showTimer = Timer(widget.showDelay, () {
      _showTooltip();
    });
  }

  void _scheduleHide() {
    _showTimer?.cancel();
    if (!_isShowing) return;

    _hideTimer = Timer(widget.hideDelay, () {
      _hideTooltip();
    });
  }

  void _showTooltip() {
    if (_isShowing) return;

    final overlay = Overlay.of(context);
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final targetPosition = renderBox.localToGlobal(Offset.zero);
    final targetSize = renderBox.size;

    _overlayEntry = OverlayEntry(
      builder: (context) => _TooltipOverlay(
        targetPosition: targetPosition,
        targetSize: targetSize,
        message: widget.message,
        content: widget.content,
        position: widget.position,
        showArrow: widget.showArrow,
        backgroundColor: widget.backgroundColor,
        textStyle: widget.textStyle,
        padding: widget.padding,
        margin: widget.margin,
        maxWidth: widget.maxWidth,
        onDismiss: _hideTooltip,
      ),
    );

    overlay.insert(_overlayEntry!);
    safeSetState(() => _isShowing = true);
  }

  void _hideTooltip() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    if (mounted) {
      safeSetState(() => _isShowing = false);
    }
  }

  @override
  Widget buildContent(BuildContext context) {
    return MouseRegion(
      onEnter: widget.enableHover ? (_) => _scheduleShow() : null,
      onExit: widget.enableHover ? (_) => _scheduleHide() : null,
      child: GestureDetector(
        onLongPress: widget.enableLongPress ? _scheduleShow : null,
        onLongPressEnd: widget.enableLongPress ? (_) => _scheduleHide() : null,
        child: widget.child,
      ),
    );
  }
}

class _TooltipOverlay extends StatelessWidget {
  const _TooltipOverlay({
    required this.targetPosition,
    required this.targetSize,
    this.message,
    this.content,
    required this.position,
    required this.showArrow,
    this.backgroundColor,
    this.textStyle,
    this.padding,
    this.margin,
    required this.maxWidth,
    required this.onDismiss,
  });

  final Offset targetPosition;
  final Size targetSize;
  final String? message;
  final Widget? content;
  final TooltipPosition position;
  final bool showArrow;
  final Color? backgroundColor;
  final TextStyle? textStyle;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final double maxWidth;
  final VoidCallback onDismiss;

  static const double _arrowSize = 8.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final screenSize = MediaQuery.of(context).size;

    // Calculate optimal position
    final actualPosition = _calculatePosition(screenSize);

    // Calculate tooltip position
    final tooltipPosition = _calculateTooltipPosition(
      actualPosition,
      screenSize,
    );

    final bgColor = backgroundColor ??
        (isDark ? AppColors.surfaceDarkMode : AppColors.surface);

    return Stack(
      children: [
        // Dismiss barrier
        Positioned.fill(
          child: GestureDetector(
            onTap: onDismiss,
            behavior: HitTestBehavior.translucent,
            child: Container(color: Colors.transparent),
          ),
        ),
        // Tooltip content
        Positioned(
          left: tooltipPosition.dx,
          top: tooltipPosition.dy,
          child: Material(
            color: Colors.transparent,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (showArrow && actualPosition == TooltipPosition.bottom)
                  _buildArrow(bgColor, isTop: true),
                Container(
                  constraints: BoxConstraints(maxWidth: maxWidth),
                  padding: padding ??
                      const EdgeInsets.symmetric(
                        horizontal: AppDimens.paddingMedium,
                        vertical: AppDimens.paddingSmall,
                      ),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(AppDimens.radiusSmall),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.shadow,
                        blurRadius: AppDimens.elevationMedium,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: content ??
                      Text(
                        message!,
                        style: textStyle ??
                            AppTextStyles.bodySmall.copyWith(
                              color: isDark
                                  ? AppColors.textPrimaryDarkMode
                                  : AppColors.textPrimary,
                            ),
                      ),
                ),
                if (showArrow && actualPosition == TooltipPosition.top)
                  _buildArrow(bgColor, isTop: false),
              ],
            ),
          ),
        ),
      ],
    );
  }

  TooltipPosition _calculatePosition(Size screenSize) {
    if (position != TooltipPosition.auto) return position;

    // Auto-detect best position based on available space
    final targetCenter = targetPosition + Offset(targetSize.width / 2, 0);
    final spaceAbove = targetPosition.dy;
    final spaceBelow = screenSize.height - (targetPosition.dy + targetSize.height);
    final spaceLeft = targetPosition.dx;
    final spaceRight = screenSize.width - (targetPosition.dx + targetSize.width);

    // Prefer top/bottom over left/right
    if (spaceAbove > spaceBelow && spaceAbove > 100) {
      return TooltipPosition.top;
    } else if (spaceBelow > 100) {
      return TooltipPosition.bottom;
    } else if (spaceRight > spaceLeft && spaceRight > 150) {
      return TooltipPosition.right;
    } else if (spaceLeft > 150) {
      return TooltipPosition.left;
    }

    // Default to bottom if no good position
    return TooltipPosition.bottom;
  }

  Offset _calculateTooltipPosition(
    TooltipPosition actualPosition,
    Size screenSize,
  ) {
    final marginValue = margin ?? const EdgeInsets.all(AppDimens.spaceSmall);
    double dx = 0;
    double dy = 0;

    switch (actualPosition) {
      case TooltipPosition.top:
        dx = targetPosition.dx + (targetSize.width / 2) - (maxWidth / 2);
        dy = targetPosition.dy - marginValue.top - 50; // Approximate height
        break;
      case TooltipPosition.bottom:
        dx = targetPosition.dx + (targetSize.width / 2) - (maxWidth / 2);
        dy = targetPosition.dy + targetSize.height + marginValue.bottom;
        break;
      case TooltipPosition.left:
        dx = targetPosition.dx - maxWidth - marginValue.left;
        dy = targetPosition.dy + (targetSize.height / 2) - 25; // Approximate height
        break;
      case TooltipPosition.right:
        dx = targetPosition.dx + targetSize.width + marginValue.right;
        dy = targetPosition.dy + (targetSize.height / 2) - 25; // Approximate height
        break;
      case TooltipPosition.auto:
        // Should not reach here
        dx = targetPosition.dx;
        dy = targetPosition.dy + targetSize.height + marginValue.bottom;
        break;
    }

    // Ensure tooltip stays within screen bounds
    dx = dx.clamp(AppDimens.paddingSmall, screenSize.width - maxWidth - AppDimens.paddingSmall);
    dy = dy.clamp(AppDimens.paddingSmall, screenSize.height - 100); // Approximate max height

    return Offset(dx, dy);
  }

  Widget _buildArrow(Color color, {required bool isTop}) {
    return Align(
      alignment: Alignment.center,
      child: CustomPaint(
        size: const Size(_arrowSize * 2, _arrowSize),
        painter: _ArrowPainter(
          color: color,
          isTop: isTop,
        ),
      ),
    );
  }
}

class _ArrowPainter extends CustomPainter {
  const _ArrowPainter({
    required this.color,
    required this.isTop,
  });

  final Color color;
  final bool isTop;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();

    if (isTop) {
      // Arrow pointing up
      path.moveTo(size.width / 2, 0);
      path.lineTo(0, size.height);
      path.lineTo(size.width, size.height);
    } else {
      // Arrow pointing down
      path.moveTo(0, 0);
      path.lineTo(size.width, 0);
      path.lineTo(size.width / 2, size.height);
    }

    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_ArrowPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.isTop != isTop;
  }
}
