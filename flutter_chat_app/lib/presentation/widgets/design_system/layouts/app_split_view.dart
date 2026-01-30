import 'package:flutter/material.dart';
import 'package:flutter_chat_app/core/base/base_widget.dart';
import 'package:flutter_chat_app/core/constants/app_dimens.dart';
import 'package:flutter_chat_app/core/theme/app_colors.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/layouts/layout_enums.dart';

/// APP SPLIT VIEW
///
/// Master-detail layout with resizable divider.
/// Adapts to screen size: side-by-side on desktop, separate screens on mobile.
class AppSplitView extends BaseStatefulWidget {
  const AppSplitView({
    super.key,
    required this.master,
    required this.detail,
    this.initialMasterWidth = 300,
    this.minMasterWidth = 200,
    this.maxMasterWidth = 500,
    this.dividerWidth = 8,
    this.showDivider = true,
    this.masterCollapsible = true,
    this.persistDividerPosition = false,
    this.storageKey = 'split_view_divider',
  });

  final WidgetBuilder master;
  final WidgetBuilder detail;
  final double initialMasterWidth;
  final double minMasterWidth;
  final double maxMasterWidth;
  final double dividerWidth;
  final bool showDivider;
  final bool masterCollapsible;
  final bool persistDividerPosition;
  final String storageKey;

  @override
  AppSplitViewState createState() => AppSplitViewState();
}

class AppSplitViewState extends BaseState<AppSplitView> {
  late double _masterWidth;
  bool _isMasterCollapsed = false;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    _masterWidth = widget.initialMasterWidth;
    _loadDividerPosition();
  }

  Future<void> _loadDividerPosition() async {
    if (!widget.persistDividerPosition) return;
    // Note: SharedPreferences integration can be added when needed
    // Example: final prefs = await SharedPreferences.getInstance();
    // _masterWidth = prefs.getDouble(widget.storageKey) ?? widget.initialMasterWidth;
  }

  Future<void> _saveDividerPosition() async {
    if (!widget.persistDividerPosition) return;
    // Note: SharedPreferences integration can be added when needed
    // Example: final prefs = await SharedPreferences.getInstance();
    // await prefs.setDouble(widget.storageKey, _masterWidth);
  }

  void _onDragUpdate(DragUpdateDetails details) {
    safeSetState(() {
      _masterWidth = (_masterWidth + details.delta.dx)
          .clamp(widget.minMasterWidth, widget.maxMasterWidth);
    });
  }

  void _onDragEnd(DragEndDetails details) {
    safeSetState(() {
      _isDragging = false;
    });
    _saveDividerPosition();
  }

  void toggleMasterPanel() {
    safeSetState(() {
      _isMasterCollapsed = !_isMasterCollapsed;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final layoutType = LayoutType.fromWidth(MediaQuery.of(context).size.width);

    if (layoutType.isMobile) {
      return _buildMobileLayout(context);
    }

    return _buildDesktopLayout(context, isDark);
  }

  Widget _buildMobileLayout(BuildContext context) {
    return Navigator(
      onGenerateRoute: (settings) {
        return MaterialPageRoute(
          builder: (context) => widget.master(context),
        );
      },
    );
  }

  Widget _buildDesktopLayout(BuildContext context, bool isDark) {
    return Row(
      children: [
        if (!_isMasterCollapsed)
          SizedBox(
            width: _masterWidth,
            child: widget.master(context),
          ),
        if (widget.showDivider && !_isMasterCollapsed)
          _buildDivider(isDark),
        Expanded(
          child: widget.detail(context),
        ),
      ],
    );
  }

  Widget _buildDivider(bool isDark) {
    return MouseRegion(
      cursor: SystemMouseCursors.resizeColumn,
      child: GestureDetector(
        onHorizontalDragStart: (_) {
          safeSetState(() {
            _isDragging = true;
          });
        },
        onHorizontalDragUpdate: _onDragUpdate,
        onHorizontalDragEnd: _onDragEnd,
        child: Container(
          width: widget.dividerWidth,
          color: _isDragging
              ? (isDark ? AppColors.primary.withValues(alpha: 0.8) : AppColors.primary)
              : (isDark ? AppColors.borderDarkMode : AppColors.border),
          child: Center(
            child: Container(
              width: 2,
              height: 40,
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.textSecondaryDarkMode
                    : AppColors.textSecondary,
                borderRadius: BorderRadius.circular(AppDimens.radiusSmall),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
