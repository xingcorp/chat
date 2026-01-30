import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_app/core/base/base_widget.dart';
import 'package:flutter_chat_app/core/constants/app_dimens.dart';
import 'package:flutter_chat_app/l10n/l10n.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/buttons/app_button.dart';

/// A generic, reusable grid view component with pagination, pull-to-refresh,
/// and state management.
///
/// Features:
/// - Generic type support for type-safe item rendering
/// - Pull-to-refresh functionality
/// - Infinite scroll with pagination
/// - Empty, loading, and error state handling
/// - Customizable state widgets
/// - Configurable grid layout (crossAxisCount, aspect ratio)
/// - Performance optimized with lazy loading
/// - Accessibility compliant
/// - Dark mode support
///
/// Example:
/// ```dart
/// AppGridView<Product>(
///   items: products,
///   crossAxisCount: 2,
///   childAspectRatio: 0.75,
///   itemBuilder: (context, product, index) => ProductCard(product: product),
///   onRefresh: () async {
///     await fetchProducts();
///   },
///   onLoadMore: () async {
///     await loadMoreProducts();
///   },
///   hasMore: hasMoreProducts,
///   isLoading: isLoadingProducts,
/// )
/// ```
class AppGridView<T> extends BaseStatefulWidget {
  /// Creates an [AppGridView].
  const AppGridView({
    required this.items,
    required this.itemBuilder,
    this.crossAxisCount = 2,
    this.mainAxisSpacing,
    this.crossAxisSpacing,
    this.childAspectRatio = 1.0,
    this.onRefresh,
    this.onLoadMore,
    this.hasMore = false,
    this.isLoading = false,
    this.error,
    this.onRetry,
    this.emptyWidget,
    this.loadingWidget,
    this.errorWidget,
    this.physics,
    this.padding,
    this.shrinkWrap = false,
    this.primary,
    this.scrollDirection = Axis.vertical,
    this.reverse = false,
    this.controller,
    this.addAutomaticKeepAlives = true,
    this.addRepaintBoundaries = true,
    this.addSemanticIndexes = true,
    this.cacheExtent,
    this.semanticChildCount,
    this.dragStartBehavior = DragStartBehavior.start,
    this.keyboardDismissBehavior = ScrollViewKeyboardDismissBehavior.manual,
    this.restorationId,
    this.clipBehavior = Clip.hardEdge,
    super.key,
  });

  /// The list of items to display.
  final List<T> items;

  /// Builder function for each item in the grid.
  final Widget Function(BuildContext context, T item, int index) itemBuilder;

  /// Number of columns in the grid.
  final int crossAxisCount;

  /// Spacing between rows.
  final double? mainAxisSpacing;

  /// Spacing between columns.
  final double? crossAxisSpacing;

  /// Aspect ratio of each grid item.
  final double childAspectRatio;

  /// Callback when user pulls to refresh.
  final Future<void> Function()? onRefresh;

  /// Callback when user scrolls near the bottom.
  final Future<void> Function()? onLoadMore;

  /// Whether there are more items to load.
  final bool hasMore;

  /// Whether the grid is currently loading.
  final bool isLoading;

  /// Error message to display.
  final String? error;

  /// Callback when user taps retry button in error state.
  final VoidCallback? onRetry;

  /// Custom widget to display when grid is empty.
  final Widget? emptyWidget;

  /// Custom widget to display when grid is loading.
  final Widget? loadingWidget;

  /// Custom widget to display when there's an error.
  final Widget? errorWidget;

  /// The scroll physics for the grid.
  final ScrollPhysics? physics;

  /// Padding around the grid.
  final EdgeInsetsGeometry? padding;

  /// Whether the grid should shrink-wrap its contents.
  final bool shrinkWrap;

  /// Whether this is the primary scroll view.
  final bool? primary;

  /// The scroll direction.
  final Axis scrollDirection;

  /// Whether to reverse the scroll direction.
  final bool reverse;

  /// Optional scroll controller.
  final ScrollController? controller;

  /// Whether to wrap children in AutomaticKeepAlive widgets.
  final bool addAutomaticKeepAlives;

  /// Whether to wrap children in RepaintBoundary widgets.
  final bool addRepaintBoundaries;

  /// Whether to wrap children in IndexedSemantics widgets.
  final bool addSemanticIndexes;

  /// The cache extent for the viewport.
  final double? cacheExtent;

  /// The number of children for semantic purposes.
  final int? semanticChildCount;

  /// Determines the way that drag start behavior is handled.
  final DragStartBehavior dragStartBehavior;

  /// Defines how the keyboard dismissal should be handled.
  final ScrollViewKeyboardDismissBehavior keyboardDismissBehavior;

  /// Restoration ID for state restoration.
  final String? restorationId;

  /// The clip behavior for the grid.
  final Clip clipBehavior;

  @override
  AppGridViewState<T> createState() => AppGridViewState<T>();
}

/// State for [AppGridView].
class AppGridViewState<T> extends BaseState<AppGridView<T>> {
  late ScrollController _scrollController;
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    _scrollController = widget.controller ?? ScrollController();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _scrollController.dispose();
    } else {
      _scrollController.removeListener(_onScroll);
    }
    super.dispose();
  }

  void _onScroll() {
    if (_isNearBottom() && !_isLoadingMore && widget.hasMore && !widget.isLoading) {
      _loadMore();
    }
  }

  bool _isNearBottom() {
    if (!_scrollController.hasClients) return false;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    return currentScroll >= (maxScroll * 0.9);
  }

  Future<void> _loadMore() async {
    if (widget.onLoadMore == null) return;

    safeSetState(() {
      _isLoadingMore = true;
    });

    try {
      await widget.onLoadMore!();
    } finally {
      if (mounted) {
        safeSetState(() {
          _isLoadingMore = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show error state
    if (widget.error != null) {
      return _buildErrorState(context);
    }

    // Show loading state (initial load)
    if (widget.isLoading && widget.items.isEmpty) {
      return _buildLoadingState(context);
    }

    // Show empty state
    if (!widget.isLoading && widget.items.isEmpty) {
      return _buildEmptyState(context);
    }

    // Show grid
    return _buildGrid(context);
  }

  Widget _buildGrid(BuildContext context) {
    final gridView = GridView.builder(
      controller: _scrollController,
      physics: widget.physics,
      padding: widget.padding ?? EdgeInsets.all(AppDimens.paddingMedium),
      shrinkWrap: widget.shrinkWrap,
      primary: widget.primary,
      scrollDirection: widget.scrollDirection,
      reverse: widget.reverse,
      addAutomaticKeepAlives: widget.addAutomaticKeepAlives,
      addRepaintBoundaries: widget.addRepaintBoundaries,
      addSemanticIndexes: widget.addSemanticIndexes,
      cacheExtent: widget.cacheExtent,
      semanticChildCount: widget.semanticChildCount ?? widget.items.length,
      dragStartBehavior: widget.dragStartBehavior,
      keyboardDismissBehavior: widget.keyboardDismissBehavior,
      restorationId: widget.restorationId,
      clipBehavior: widget.clipBehavior,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: widget.crossAxisCount,
        mainAxisSpacing: widget.mainAxisSpacing ?? AppDimens.spaceMedium,
        crossAxisSpacing: widget.crossAxisSpacing ?? AppDimens.spaceMedium,
        childAspectRatio: widget.childAspectRatio,
      ),
      itemCount: widget.items.length + (widget.hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        // Show bottom loading indicator
        if (index >= widget.items.length) {
          return _buildBottomLoader(context);
        }

        final item = widget.items[index];
        return widget.itemBuilder(context, item, index);
      },
    );

    // Wrap with RefreshIndicator if onRefresh is provided
    if (widget.onRefresh != null) {
      return RefreshIndicator(
        onRefresh: widget.onRefresh!,
        child: gridView,
      );
    }

    return gridView;
  }

  Widget _buildBottomLoader(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(AppDimens.paddingMedium),
        child: SizedBox(
          width: AppDimens.iconSizeMedium,
          height: AppDimens.iconSizeMedium,
          child: Semantics(
            label: context.l10n.loadingMore,
            child: const CircularProgressIndicator(
              strokeWidth: 2.0,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    if (widget.emptyWidget != null) {
      return widget.emptyWidget!;
    }

    return Center(
      child: Padding(
        padding: EdgeInsets.all(AppDimens.paddingLarge),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.grid_view_outlined,
              size: AppDimens.iconSizeXLarge,
              color: Theme.of(context).colorScheme.outline,
            ),
            SizedBox(height: AppDimens.spaceMedium),
            Text(
              context.l10n.noItemsFound,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: AppDimens.spaceSmall),
            Text(
              context.l10n.noItemsDescription,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    if (widget.loadingWidget != null) {
      return widget.loadingWidget!;
    }

    return Center(
      child: Padding(
        padding: EdgeInsets.all(AppDimens.paddingLarge),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: AppDimens.iconSizeLarge,
              height: AppDimens.iconSizeLarge,
              child: Semantics(
                label: context.l10n.loading,
                child: const CircularProgressIndicator(),
              ),
            ),
            SizedBox(height: AppDimens.spaceMedium),
            Text(
              context.l10n.loading,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context) {
    if (widget.errorWidget != null) {
      return widget.errorWidget!;
    }

    return Center(
      child: Padding(
        padding: EdgeInsets.all(AppDimens.paddingLarge),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: AppDimens.iconSizeXLarge,
              color: Theme.of(context).colorScheme.error,
            ),
            SizedBox(height: AppDimens.spaceMedium),
            Text(
              context.l10n.errorOccurred,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: AppDimens.spaceSmall),
            Text(
              widget.error ?? context.l10n.errorUnexpected,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
            if (widget.onRetry != null) ...[
              SizedBox(height: AppDimens.spaceLarge),
              AppButton.primary(
                onPressed: widget.onRetry,
                text: context.l10n.retry,
                icon: Icons.refresh,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
