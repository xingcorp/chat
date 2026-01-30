import 'package:flutter/material.dart';
import 'package:flutter_chat_app/core/base/base_widget.dart';
import 'package:flutter_chat_app/core/constants/app_constants.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/layouts/layout_enums.dart';

/// APP STICKY HEADER
///
/// Header that sticks to the top when scrolling.
/// Supports smooth transitions and elevation changes.
class AppStickyHeader extends BaseStatefulWidget {
  const AppStickyHeader({
    super.key,
    required this.header,
    required this.body,
    this.mode = StickyHeaderMode.onScroll,
    this.scrollThreshold = 0,
    this.stickyElevation = 4,
    this.normalElevation = 0,
    this.enableShrinking = false,
    this.maxHeaderHeight,
    this.minHeaderHeight,
  });

  final Widget header;
  final Widget body;
  final StickyHeaderMode mode;
  final double scrollThreshold;
  final double stickyElevation;
  final double normalElevation;
  final bool enableShrinking;
  final double? maxHeaderHeight;
  final double? minHeaderHeight;

  @override
  AppStickyHeaderState createState() => AppStickyHeaderState();
}

class AppStickyHeaderState extends BaseState<AppStickyHeader> {
  final ScrollController _scrollController = ScrollController();
  bool _isSticky = false;
  double _scrollOffset = 0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _isSticky = widget.mode == StickyHeaderMode.always;
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (widget.mode == StickyHeaderMode.never) return;

    final offset = _scrollController.offset;
    final shouldBeSticky = offset > widget.scrollThreshold;

    if (shouldBeSticky != _isSticky) {
      safeSetState(() {
        _isSticky = shouldBeSticky;
      });
    }

    if (widget.enableShrinking) {
      safeSetState(() {
        _scrollOffset = offset;
      });
    }
  }

  double _getHeaderHeight() {
    if (!widget.enableShrinking) {
      return widget.maxHeaderHeight ?? kToolbarHeight;
    }

    final maxHeight = widget.maxHeaderHeight ?? kToolbarHeight * 2;
    final minHeight = widget.minHeaderHeight ?? kToolbarHeight;
    final shrinkOffset = _scrollOffset.clamp(0.0, maxHeight - minHeight);

    return maxHeight - shrinkOffset;
  }

  double _getElevation() {
    return _isSticky ? widget.stickyElevation : widget.normalElevation;
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      controller: _scrollController,
      slivers: [
        SliverAppBar(
          pinned: widget.mode.isSticky,
          floating: false,
          expandedHeight: widget.enableShrinking
              ? (widget.maxHeaderHeight ?? kToolbarHeight * 2)
              : null,
          collapsedHeight: widget.enableShrinking
              ? (widget.minHeaderHeight ?? kToolbarHeight)
              : null,
          elevation: _getElevation(),
          flexibleSpace: AnimatedContainer(
            duration: AppConstants.kDefaultAnimationDuration,
            curve: Curves.easeInOut,
            height: _getHeaderHeight(),
            child: widget.header,
          ),
        ),
        SliverToBoxAdapter(
          child: widget.body,
        ),
      ],
    );
  }
}
