import 'package:flutter/material.dart';
import 'package:flutter_chat_app/core/base/base_widget.dart';
import 'package:flutter_chat_app/core/constants/app_dimens.dart';
import 'package:flutter_chat_app/core/theme/app_colors.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/layouts/layout_enums.dart';

/// Panel configuration
class PanelConfig {
  const PanelConfig({
    required this.builder,
    this.initialSize = 1.0,
    this.minSize = 0.1,
    this.maxSize = double.infinity,
  });

  final WidgetBuilder builder;
  final double initialSize;
  final double minSize;
  final double maxSize;
}

/// APP RESIZABLE PANEL
///
/// Multiple panels with draggable dividers.
/// Supports horizontal and vertical layouts.
class AppResizablePanel extends BaseStatefulWidget {
  const AppResizablePanel({
    super.key,
    required this.panels,
    this.orientation = PanelOrientation.horizontal,
    this.dividerWidth = 8,
    this.persistSizes = false,
    this.storageKey = 'resizable_panel',
  });

  final List<PanelConfig> panels;
  final PanelOrientation orientation;
  final double dividerWidth;
  final bool persistSizes;
  final String storageKey;

  @override
  AppResizablePanelState createState() => AppResizablePanelState();
}

class AppResizablePanelState extends BaseState<AppResizablePanel> {
  late List<double> _panelSizes;
  int? _draggingIndex;

  @override
  void initState() {
    super.initState();
    _panelSizes = widget.panels.map((p) => p.initialSize).toList();
    _loadPanelSizes();
  }

  Future<void> _loadPanelSizes() async {
    if (!widget.persistSizes) return;
    // TODO: Load from SharedPreferences
  }

  Future<void> _savePanelSizes() async {
    if (!widget.persistSizes) return;
    // TODO: Save to SharedPreferences
  }

  void _onDragUpdate(int index, DragUpdateDetails details) {
    safeSetState(() {
      final delta = widget.orientation.isHorizontal
          ? details.delta.dx
          : details.delta.dy;

      final leftPanel = widget.panels[index];
      final rightPanel = widget.panels[index + 1];

      final newLeftSize = (_panelSizes[index] + delta)
          .clamp(leftPanel.minSize, leftPanel.maxSize);
      final newRightSize = (_panelSizes[index + 1] - delta)
          .clamp(rightPanel.minSize, rightPanel.maxSize);

      _panelSizes[index] = newLeftSize;
      _panelSizes[index + 1] = newRightSize;
    });
  }

  void _onDragEnd(DragEndDetails details) {
    safeSetState(() {
      _draggingIndex = null;
    });
    _savePanelSizes();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (widget.orientation.isHorizontal) {
      return _buildHorizontalLayout(isDark);
    } else {
      return _buildVerticalLayout(isDark);
    }
  }

  Widget _buildHorizontalLayout(bool isDark) {
    final children = <Widget>[];

    for (var i = 0; i < widget.panels.length; i++) {
      children.add(
        SizedBox(
          width: _panelSizes[i],
          child: widget.panels[i].builder(context),
        ),
      );

      if (i < widget.panels.length - 1) {
        children.add(_buildDivider(i, isDark, isHorizontal: true));
      }
    }

    return Row(children: children);
  }

  Widget _buildVerticalLayout(bool isDark) {
    final children = <Widget>[];

    for (var i = 0; i < widget.panels.length; i++) {
      children.add(
        SizedBox(
          height: _panelSizes[i],
          child: widget.panels[i].builder(context),
        ),
      );

      if (i < widget.panels.length - 1) {
        children.add(_buildDivider(i, isDark, isHorizontal: false));
      }
    }

    return Column(children: children);
  }

  Widget _buildDivider(int index, bool isDark, {required bool isHorizontal}) {
    return MouseRegion(
      cursor: isHorizontal
          ? SystemMouseCursors.resizeColumn
          : SystemMouseCursors.resizeRow,
      child: GestureDetector(
        onPanStart: (_) {
          safeSetState(() {
            _draggingIndex = index;
          });
        },
        onPanUpdate: (details) => _onDragUpdate(index, details),
        onPanEnd: _onDragEnd,
        child: Container(
          width: isHorizontal ? widget.dividerWidth : null,
          height: isHorizontal ? null : widget.dividerWidth,
          color: _draggingIndex == index
              ? (isDark ? AppColors.primary.withValues(alpha: 0.8) : AppColors.primary)
              : (isDark ? AppColors.borderDarkMode : AppColors.border),
          child: Center(
            child: Container(
              width: isHorizontal ? 2 : 40,
              height: isHorizontal ? 40 : 2,
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
