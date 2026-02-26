import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_app/core/base/base_widget.dart';
import 'package:flutter_chat_app/core/constants/app_dimens.dart';
import 'package:flutter_chat_app/l10n/l10n.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/buttons/app_button.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

/// A generic, reusable positioned list view component built on top of
/// [ScrollablePositionedList] from the `scrollable_positioned_list` package.
///
/// Provides programmatic scroll-to-index capabilities, which is useful for
/// chat message lists, search result navigation, and any list where you need
/// to jump to a specific item by index.
///
/// Features:
/// - Scroll to any item by index with animation
/// - Track visible item positions via [ItemPositionsListener]
/// - Pull-to-refresh functionality
/// - Infinite scroll with pagination
/// - Empty, loading, and error state handling
/// - Separator support
/// - Reverse mode (for chat-style bottom-to-top lists)
/// - Dark mode support
///
/// Example:
/// ```dart
/// final itemScrollController = ItemScrollController();
/// final itemPositionsListener = ItemPositionsListener.create();
///
/// AppPositionedListView<Message>(
///   items: messages,
///   itemBuilder: (context, message, index) => MessageBubble(message: message),
///   itemScrollController: itemScrollController,
///   itemPositionsListener: itemPositionsListener,
///   reverse: true,
///   onLoadMore: () async => await loadOlderMessages(),
///   hasMore: hasMoreMessages,
/// )
///
/// // Scroll to item at index 5
/// itemScrollController.scrollTo(
///   index: 5,
///   duration: Duration(milliseconds: 300),
/// );
/// ```
class AppPositionedListView<T> extends BaseStatefulWidget {
  /// Creates an [AppPositionedListView].
  const AppPositionedListView({
    required this.items,
    required this.itemBuilder,
    this.itemScrollController,
    this.scrollOffsetController,
    this.itemPositionsListener,
    this.scrollOffsetListener,
    this.onRefresh,
    this.onLoadMore,
    this.hasMore = false,
    this.isLoading = false,
    this.error,
    this.onRetry,
    this.emptyWidget,
    this.loadingWidget,
    this.errorWidget,
    this.separatorBuilder,
    this.physics,
    this.padding,
    this.shrinkWrap = false,
    this.scrollDirection = Axis.vertical,
    this.reverse = false,
    this.initialScrollIndex = 0,
    this.initialAlignment = 0.0,
    this.addAutomaticKeepAlives = true,
    this.addRepaintBoundaries = true,
    this.addSemanticIndexes = true,
    this.minCacheExtent,
    this.semanticChildCount,
    this.dragStartBehavior = DragStartBehavior.start,
    this.keyboardDismissBehavior = ScrollViewKeyboardDismissBehavior.manual,
    this.loadMoreThreshold = 3,
    super.key,
  });

  /// The list of items to display.
  final List<T> items;

  /// Builder function for each item in the list.
  final Widget Function(BuildContext context, T item, int index) itemBuilder;

  /// Controller for programmatic scrolling to specific items.
  /// Use [ItemScrollController.scrollTo] or [ItemScrollController.jumpTo].
  final ItemScrollController? itemScrollController;

  /// Controller for programmatic scrolling by offset.
  final ScrollOffsetController? scrollOffsetController;

  /// Listener that reports which items are currently visible.
  final ItemPositionsListener? itemPositionsListener;

  /// Listener that reports scroll offset changes.
  final ScrollOffsetListener? scrollOffsetListener;

  /// Callback when user pulls to refresh.
  /// If null, pull-to-refresh is disabled.
  final Future<void> Function()? onRefresh;

  /// Callback when user scrolls near the edge (top or bottom depending on [reverse]).
  /// Used for pagination/infinite scroll.
  final Future<void> Function()? onLoadMore;

  /// Whether there are more items to load.
  final bool hasMore;

  /// Whether the list is currently loading.
  final bool isLoading;

  /// Error message to display.
  final String? error;

  /// Callback when user taps retry button in error state.
  final VoidCallback? onRetry;

  /// Custom widget to display when list is empty.
  final Widget? emptyWidget;

  /// Custom widget to display when list is loading.
  final Widget? loadingWidget;

  /// Custom widget to display when there's an error.
  final Widget? errorWidget;

  /// Builder for separators between items.
  final Widget Function(BuildContext context, int index)? separatorBuilder;

  /// The scroll physics for the list.
  final ScrollPhysics? physics;

  /// Padding around the list.
  final EdgeInsets? padding;

  /// Whether the list should shrink-wrap its contents.
  final bool shrinkWrap;

  /// The scroll direction.
  final Axis scrollDirection;

  /// Whether to reverse the scroll direction.
  /// Useful for chat lists where newest items are at the bottom.
  final bool reverse;

  /// Index of the item to initially align within the viewport.
  final int initialScrollIndex;

  /// Determines where the leading edge of the item at [initialScrollIndex]
  /// should be placed. 0.0 = top, 1.0 = bottom.
  final double initialAlignment;

  /// Whether to wrap children in AutomaticKeepAlive widgets.
  final bool addAutomaticKeepAlives;

  /// Whether to wrap children in RepaintBoundary widgets.
  final bool addRepaintBoundaries;

  /// Whether to wrap children in IndexedSemantics widgets.
  final bool addSemanticIndexes;

  /// The minimum cache extent for the viewport.
  final double? minCacheExtent;

  /// The number of children for semantic purposes.
  final int? semanticChildCount;

  /// Determines the way that drag start behavior is handled.
  final DragStartBehavior dragStartBehavior;

  /// Defines how the keyboard dismissal should be handled.
  final ScrollViewKeyboardDismissBehavior keyboardDismissBehavior;

  /// Number of items from the edge to trigger [onLoadMore].
  /// Default is 3 items from the edge.
  final int loadMoreThreshold;

  @override
  AppPositionedListViewState<T> createState() =>
      AppPositionedListViewState<T>();
}

/// State for [AppPositionedListView].
class AppPositionedListViewState<T>
    extends BaseState<AppPositionedListView<T>> {
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    widget.itemPositionsListener?.itemPositions.addListener(_onPositionsChanged);
  }

  @override
  void dispose() {
    widget.itemPositionsListener?.itemPositions
        .removeListener(_onPositionsChanged);
    super.dispose();
  }

  void _onPositionsChanged() {
    if (_isLoadingMore || !widget.hasMore || widget.isLoading) return;
    if (widget.onLoadMore == null) return;

    final positions = widget.itemPositionsListener?.itemPositions.value;
    if (positions == null || positions.isEmpty) return;

    final totalItems = widget.items.length;
    if (totalItems == 0) return;

    final maxIndex = positions
        .map((p) => p.index)
        .reduce((a, b) => a > b ? a : b);
    if (maxIndex >= totalItems - widget.loadMoreThreshold) {
      _loadMore();
    }
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

    // Show list
    return _buildList(context);
  }

  Widget _buildList(BuildContext context) {
    final itemCount = widget.items.length;

    final listView = ScrollablePositionedList.separated(
      itemCount: itemCount,
      itemScrollController: widget.itemScrollController,
      scrollOffsetController: widget.scrollOffsetController,
      itemPositionsListener: widget.itemPositionsListener,
      scrollOffsetListener: widget.scrollOffsetListener,
      initialScrollIndex: widget.initialScrollIndex,
      initialAlignment: widget.initialAlignment,
      physics: widget.physics,
      padding: widget.padding ?? const EdgeInsets.all(AppDimens.paddingMedium),
      shrinkWrap: widget.shrinkWrap,
      scrollDirection: widget.scrollDirection,
      reverse: widget.reverse,
      addAutomaticKeepAlives: widget.addAutomaticKeepAlives,
      addRepaintBoundaries: widget.addRepaintBoundaries,
      addSemanticIndexes: widget.addSemanticIndexes,
      minCacheExtent: widget.minCacheExtent,
      semanticChildCount: widget.semanticChildCount ?? itemCount,
      separatorBuilder: (context, index) {
        if (widget.separatorBuilder != null) {
          return widget.separatorBuilder!(context, index);
        }
        return const SizedBox.shrink();
      },
      itemBuilder: (context, index) {
        if (index < 0 || index >= widget.items.length) {
          return const SizedBox.shrink();
        }
        final item = widget.items[index];
        return widget.itemBuilder(context, item, index);
      },
    );

    // Wrap with RefreshIndicator if onRefresh is provided
    if (widget.onRefresh != null) {
      return RefreshIndicator(
        onRefresh: widget.onRefresh!,
        child: listView,
      );
    }

    return listView;
  }

  Widget _buildEmptyState(BuildContext context) {
    if (widget.emptyWidget != null) {
      return widget.emptyWidget!;
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimens.paddingLarge),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: AppDimens.iconSizeXLarge,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: AppDimens.spaceMedium),
            Text(
              context.l10n.noItemsFound,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppDimens.spaceSmall),
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
        padding: const EdgeInsets.all(AppDimens.paddingLarge),
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
            const SizedBox(height: AppDimens.spaceMedium),
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
        padding: const EdgeInsets.all(AppDimens.paddingLarge),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: AppDimens.iconSizeXLarge,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: AppDimens.spaceMedium),
            Text(
              context.l10n.errorOccurred,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppDimens.spaceSmall),
            Text(
              widget.error ?? context.l10n.errorUnexpected,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
            if (widget.onRetry != null) ...[
              const SizedBox(height: AppDimens.spaceLarge),
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
