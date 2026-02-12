import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_app/core/base/base_widget.dart';
import 'package:flutter_chat_app/core/constants/app_constants.dart';
import 'package:flutter_chat_app/core/constants/app_dimens.dart';
import 'package:flutter_chat_app/l10n/l10n.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/buttons/app_button.dart';

/// A generic, reusable list view component with pagination, pull-to-refresh,
/// and state management.
///
/// Features:
/// - Generic type support for type-safe item rendering
/// - Pull-to-refresh functionality
/// - Infinite scroll with pagination
/// - Empty, loading, and error state handling
/// - Customizable state widgets
/// - Performance optimized with lazy loading
/// - Accessibility compliant
/// - Dark mode support
///
/// Example:
/// ```dart
/// AppListView<User>(
///   items: users,
///   itemBuilder: (context, user, index) => UserListItem(user: user),
///   onRefresh: () async {
///     await fetchUsers();
///   },
///   onLoadMore: () async {
///     await loadMoreUsers();
///   },
///   hasMore: hasMoreUsers,
///   isLoading: isLoadingUsers,
///   error: errorMessage,
///   onRetry: () => retryFetch(),
/// )
/// ```
class AppListView<T> extends BaseStatefulWidget {
  /// Creates an [AppListView].
  const AppListView({
    required this.items,
    required this.itemBuilder,
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
    this.primary,
    this.scrollDirection = Axis.vertical,
    this.reverse = false,
    this.controller,
    this.itemExtent,
    this.prototypeItem,
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

  /// Builder function for each item in the list.
  final Widget Function(BuildContext context, T item, int index) itemBuilder;

  /// Callback when user pulls to refresh.
  /// If null, pull-to-refresh is disabled.
  final Future<void> Function()? onRefresh;

  /// Callback when user scrolls near the bottom.
  /// Used for pagination/infinite scroll.
  final Future<void> Function()? onLoadMore;

  /// Whether there are more items to load.
  final bool hasMore;

  /// Whether the list is currently loading.
  final bool isLoading;

  /// Error message to display.
  /// If not null, shows error state.
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
  final EdgeInsetsGeometry? padding;

  /// Whether the list should shrink-wrap its contents.
  final bool shrinkWrap;

  /// Whether this is the primary scroll view.
  final bool? primary;

  /// The scroll direction.
  final Axis scrollDirection;

  /// Whether to reverse the scroll direction.
  final bool reverse;

  /// Optional scroll controller.
  final ScrollController? controller;

  /// The extent of each item in the scroll direction.
  final double? itemExtent;

  /// A prototype item to use for sizing.
  final Widget? prototypeItem;

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

  /// The clip behavior for the list.
  final Clip clipBehavior;

  @override
  AppListViewState<T> createState() => AppListViewState<T>();
}

/// State for [AppListView].
class AppListViewState<T> extends BaseState<AppListView<T>> {
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
    // Trigger when 90% scrolled
    final near = currentScroll >= (maxScroll * 0.9);
    return near;
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
    final listView = ListView.separated(
      controller: _scrollController,
      physics: widget.physics,
      padding: widget.padding ?? EdgeInsets.all(AppDimens.paddingMedium),
      shrinkWrap: widget.shrinkWrap,
      primary: widget.primary,
      scrollDirection: widget.scrollDirection,
      reverse: widget.reverse,
      // itemExtent, prototypeItem, semanticChildCount not supported by ListView.separated
      addAutomaticKeepAlives: widget.addAutomaticKeepAlives,
      addRepaintBoundaries: widget.addRepaintBoundaries,
      addSemanticIndexes: widget.addSemanticIndexes,
      cacheExtent: widget.cacheExtent,
      dragStartBehavior: widget.dragStartBehavior,
      keyboardDismissBehavior: widget.keyboardDismissBehavior,
      restorationId: widget.restorationId,
      clipBehavior: widget.clipBehavior,
      itemCount: widget.items.length + (widget.hasMore ? 1 : 0),
      separatorBuilder: (context, index) {
        if (widget.separatorBuilder != null) {
          return widget.separatorBuilder!(context, index);
        }
        return const SizedBox.shrink();
      },
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
        child: listView,
      );
    }

    return listView;
  }

  Widget _buildBottomLoader(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(AppDimens.paddingMedium),
      child: Center(
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
              Icons.inbox_outlined,
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
