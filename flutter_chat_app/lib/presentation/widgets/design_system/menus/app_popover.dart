import 'package:flutter/material.dart';
import 'package:flutter_chat_app/core/base/base_widget.dart';
import 'package:flutter_chat_app/core/constants/app_dimens.dart';
import 'package:flutter_chat_app/core/theme/app_colors.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/menus/menu_enums.dart';

/// **APP POPOVER**
///
/// Floating popover component with interactive content anchored to a widget.
/// Extends [BaseStatefulWidget] for lifecycle management.
///
/// **Features**:
/// - Interactive content support
/// - Dismissible backdrop
/// - Positioning relative to anchor
/// - Show/hide animation
/// - Smart edge detection
/// - Dark mode support
/// - Accessibility labels
///
/// **Usage**:
/// ```dart
/// // Simple popover
/// AppPopover(
///   content: Column(
///     mainAxisSize: MainAxisSize.min,
///     children: [
///       ListTile(
///         leading: Icon(Icons.edit),
///         title: Text(context.l10n.edit),
///         onTap: () => _handleEdit(),
///       ),
///       ListTile(
///         leading: Icon(Icons.delete),
///         title: Text(context.l10n.delete),
///         onTap: () => _handleDelete(),
///       ),
///     ],
///   ),
///   child: IconButton(
///     icon: Icon(Icons.more_vert),
///     onPressed: () {},
///   ),
/// )
///
/// // Custom positioning
/// AppPopover(
///   content: Container(
///     padding: EdgeInsets.all(AppDimens.paddingMedium),
///     child: Text('Custom content'),
///   ),
///   position: PopoverPosition.bottomRight,
///   width: 300,
///   child: ElevatedButton(
///     onPressed: () {},
///     child: Text('Show Popover'),
///   ),
/// )
///
/// // Programmatic control
/// final controller = AppPopoverController();
/// AppPopover(
///   controller: controller,
///   content: MyCustomWidget(),
///   child: MyTriggerWidget(),
/// )
/// // Later: controller.show() or controller.hide()
/// ```
class AppPopover extends BaseStatefulWidget {
  const AppPopover({
    super.key,
    required this.content,
    required this.child,
    this.controller,
    this.position = PopoverPosition.auto,
    this.width,
    this.height,
    this.backgroundColor,
    this.elevation = AppDimens.elevationMedium,
    this.borderRadius = AppDimens.radiusMedium,
    this.padding,
    this.margin,
    this.barrierDismissible = true,
    this.barrierColor,
    this.animationDuration = const Duration(milliseconds: 200),
    this.onShow,
    this.onDismiss,
  });

  /// Content widget to display in popover
  final Widget content;

  /// Child widget that triggers the popover
  final Widget child;

  /// Optional controller for programmatic control
  final AppPopoverController? controller;

  /// Preferred popover position
  final PopoverPosition position;

  /// Fixed width (if null, uses content width)
  final double? width;

  /// Fixed height (if null, uses content height)
  final double? height;

  /// Background color
  final Color? backgroundColor;

  /// Shadow elevation
  final double elevation;

  /// Border radius
  final double borderRadius;

  /// Content padding
  final EdgeInsets? padding;

  /// Margin from anchor
  final EdgeInsets? margin;

  /// Whether tapping outside dismisses popover
  final bool barrierDismissible;

  /// Barrier color (backdrop)
  final Color? barrierColor;

  /// Animation duration
  final Duration animationDuration;

  /// Callback when popover is shown
  final VoidCallback? onShow;

  /// Callback when popover is dismissed
  final VoidCallback? onDismiss;

  @override
  State<AppPopover> createState() => _AppPopoverState();
}

class _AppPopoverState extends BaseState<AppPopover>
    with SingleTickerProviderStateMixin {
  OverlayEntry? _overlayEntry;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  bool _isShowing = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );

    _scaleAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    );

    _opacityAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );

    widget.controller?._attach(this);
  }

  @override
  void dispose() {
    _hidePopover();
    _animationController.dispose();
    widget.controller?._detach();
    super.dispose();
  }

  void _togglePopover() {
    if (_isShowing) {
      _hidePopover();
    } else {
      _showPopover();
    }
  }

  void _showPopover() {
    if (_isShowing) return;

    final overlay = Overlay.of(context);
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final targetPosition = renderBox.localToGlobal(Offset.zero);
    final targetSize = renderBox.size;

    _overlayEntry = OverlayEntry(
      builder: (context) => _PopoverOverlay(
        targetPosition: targetPosition,
        targetSize: targetSize,
        content: widget.content,
        position: widget.position,
        width: widget.width,
        height: widget.height,
        backgroundColor: widget.backgroundColor,
        elevation: widget.elevation,
        borderRadius: widget.borderRadius,
        padding: widget.padding,
        margin: widget.margin,
        barrierDismissible: widget.barrierDismissible,
        barrierColor: widget.barrierColor,
        scaleAnimation: _scaleAnimation,
        opacityAnimation: _opacityAnimation,
        onDismiss: _hidePopover,
      ),
    );

    overlay.insert(_overlayEntry!);
    _animationController.forward();
    safeSetState(() => _isShowing = true);
    widget.onShow?.call();
  }

  Future<void> _hidePopover() async {
    if (!_isShowing) return;

    await _animationController.reverse();
    _overlayEntry?.remove();
    _overlayEntry = null;
    if (mounted) {
      safeSetState(() => _isShowing = false);
      widget.onDismiss?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _togglePopover,
      child: widget.child,
    );
  }
}

class _PopoverOverlay extends StatelessWidget {
  const _PopoverOverlay({
    required this.targetPosition,
    required this.targetSize,
    required this.content,
    required this.position,
    this.width,
    this.height,
    this.backgroundColor,
    required this.elevation,
    required this.borderRadius,
    this.padding,
    this.margin,
    required this.barrierDismissible,
    this.barrierColor,
    required this.scaleAnimation,
    required this.opacityAnimation,
    required this.onDismiss,
  });

  final Offset targetPosition;
  final Size targetSize;
  final Widget content;
  final PopoverPosition position;
  final double? width;
  final double? height;
  final Color? backgroundColor;
  final double elevation;
  final double borderRadius;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final bool barrierDismissible;
  final Color? barrierColor;
  final Animation<double> scaleAnimation;
  final Animation<double> opacityAnimation;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final screenSize = MediaQuery.of(context).size;

    // Calculate optimal position
    final actualPosition = _calculatePosition(screenSize);

    // Calculate popover position
    final popoverPosition = _calculatePopoverPosition(
      actualPosition,
      screenSize,
    );

    final bgColor = backgroundColor ??
        (isDark ? AppColors.surfaceDarkMode : AppColors.surface);

    return Stack(
      children: [
        // Barrier
        Positioned.fill(
          child: GestureDetector(
            onTap: barrierDismissible ? onDismiss : null,
            behavior: HitTestBehavior.translucent,
            child: Container(
              color: barrierColor ??
                  (isDark
                      ? Colors.black.withValues(alpha: 0.3)
                      : Colors.black.withValues(alpha: 0.2)),
            ),
          ),
        ),
        // Popover content
        Positioned(
          left: popoverPosition.dx,
          top: popoverPosition.dy,
          child: AnimatedBuilder(
            animation: scaleAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: scaleAnimation.value,
                alignment: _getScaleAlignment(actualPosition),
                child: Opacity(
                  opacity: opacityAnimation.value,
                  child: child,
                ),
              );
            },
            child: Material(
              color: Colors.transparent,
              child: Container(
                width: width,
                height: height,
                padding: padding ??
                    const EdgeInsets.all(AppDimens.paddingMedium),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(borderRadius),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.shadow,
                      blurRadius: elevation,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: content,
              ),
            ),
          ),
        ),
      ],
    );
  }

  PopoverPosition _calculatePosition(Size screenSize) {
    if (position != PopoverPosition.auto) return position;

    // Auto-detect best position based on available space
    final spaceAbove = targetPosition.dy;
    final spaceBelow = screenSize.height - (targetPosition.dy + targetSize.height);
    final spaceLeft = targetPosition.dx;
    final spaceRight = screenSize.width - (targetPosition.dx + targetSize.width);

    // Determine vertical position
    final preferBottom = spaceBelow > spaceAbove;

    // Determine horizontal position
    if (spaceRight > 200) {
      return preferBottom ? PopoverPosition.bottomRight : PopoverPosition.topRight;
    } else if (spaceLeft > 200) {
      return preferBottom ? PopoverPosition.bottomLeft : PopoverPosition.topLeft;
    } else {
      return preferBottom ? PopoverPosition.bottom : PopoverPosition.top;
    }
  }

  Offset _calculatePopoverPosition(
    PopoverPosition actualPosition,
    Size screenSize,
  ) {
    final marginValue = margin ?? const EdgeInsets.all(AppDimens.spaceSmall);
    final popoverWidth = width ?? 200.0; // Default width
    final popoverHeight = height ?? 150.0; // Default height

    double dx = 0;
    double dy = 0;

    switch (actualPosition) {
      case PopoverPosition.top:
        dx = targetPosition.dx + (targetSize.width / 2) - (popoverWidth / 2);
        dy = targetPosition.dy - popoverHeight - marginValue.top;
        break;
      case PopoverPosition.topLeft:
        dx = targetPosition.dx;
        dy = targetPosition.dy - popoverHeight - marginValue.top;
        break;
      case PopoverPosition.topRight:
        dx = targetPosition.dx + targetSize.width - popoverWidth;
        dy = targetPosition.dy - popoverHeight - marginValue.top;
        break;
      case PopoverPosition.bottom:
        dx = targetPosition.dx + (targetSize.width / 2) - (popoverWidth / 2);
        dy = targetPosition.dy + targetSize.height + marginValue.bottom;
        break;
      case PopoverPosition.bottomLeft:
        dx = targetPosition.dx;
        dy = targetPosition.dy + targetSize.height + marginValue.bottom;
        break;
      case PopoverPosition.bottomRight:
        dx = targetPosition.dx + targetSize.width - popoverWidth;
        dy = targetPosition.dy + targetSize.height + marginValue.bottom;
        break;
      case PopoverPosition.left:
        dx = targetPosition.dx - popoverWidth - marginValue.left;
        dy = targetPosition.dy + (targetSize.height / 2) - (popoverHeight / 2);
        break;
      case PopoverPosition.right:
        dx = targetPosition.dx + targetSize.width + marginValue.right;
        dy = targetPosition.dy + (targetSize.height / 2) - (popoverHeight / 2);
        break;
      case PopoverPosition.auto:
        // Should not reach here
        dx = targetPosition.dx;
        dy = targetPosition.dy + targetSize.height + marginValue.bottom;
        break;
    }

    // Ensure popover stays within screen bounds
    dx = dx.clamp(
      AppDimens.paddingSmall,
      screenSize.width - popoverWidth - AppDimens.paddingSmall,
    );
    dy = dy.clamp(
      AppDimens.paddingSmall,
      screenSize.height - popoverHeight - AppDimens.paddingSmall,
    );

    return Offset(dx, dy);
  }

  Alignment _getScaleAlignment(PopoverPosition actualPosition) {
    switch (actualPosition) {
      case PopoverPosition.top:
      case PopoverPosition.topLeft:
      case PopoverPosition.topRight:
        return Alignment.bottomCenter;
      case PopoverPosition.bottom:
      case PopoverPosition.bottomLeft:
      case PopoverPosition.bottomRight:
        return Alignment.topCenter;
      case PopoverPosition.left:
        return Alignment.centerRight;
      case PopoverPosition.right:
        return Alignment.centerLeft;
      case PopoverPosition.auto:
        return Alignment.topCenter;
    }
  }
}

/// Controller for programmatic control of AppPopover
class AppPopoverController {
  _AppPopoverState? _state;

  void _attach(_AppPopoverState state) {
    _state = state;
  }

  void _detach() {
    _state = null;
  }

  /// Show the popover
  void show() {
    _state?._showPopover();
  }

  /// Hide the popover
  void hide() {
    _state?._hidePopover();
  }

  /// Toggle the popover visibility
  void toggle() {
    _state?._togglePopover();
  }

  /// Check if popover is currently showing
  bool get isShowing => _state?._isShowing ?? false;
}
