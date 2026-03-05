import 'package:flutter/material.dart';
import 'package:flutter_chat_app/core/base/base_widget.dart';
import 'package:flutter_chat_app/core/constants/app_dimens.dart';
import 'package:flutter_chat_app/l10n/l10n.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/buttons/app_button.dart';

/// Reusable sliver list with built-in pagination and list states.
///
/// Designed for `CustomScrollView` use-cases where header/footer are also
/// represented as slivers.
class AppSliverListView<T> extends BaseStatefulWidget {
  const AppSliverListView({
    required this.items,
    required this.itemBuilder,
    this.onLoadMore,
    this.hasMore = false,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
    this.onRetry,
    this.emptyWidget,
    this.loadingWidget,
    this.errorWidget,
    this.separatorBuilder,
    this.padding,
    this.controller,
    this.loadMoreTriggerThreshold = 240,
    this.autoLoadWhenNotScrollable = true,
    super.key,
  });

  final List<T> items;
  final Widget Function(BuildContext context, T item, int index) itemBuilder;
  final Future<void> Function()? onLoadMore;
  final bool hasMore;
  final bool isLoading;
  final bool isLoadingMore;
  final String? error;
  final VoidCallback? onRetry;
  final Widget? emptyWidget;
  final Widget? loadingWidget;
  final Widget? errorWidget;
  final Widget Function(BuildContext context, int index)? separatorBuilder;
  final EdgeInsetsGeometry? padding;
  final ScrollController? controller;
  final double loadMoreTriggerThreshold;
  final bool autoLoadWhenNotScrollable;

  @override
  State<AppSliverListView<T>> createState() => _AppSliverListViewState<T>();
}

class _AppSliverListViewState<T> extends BaseState<AppSliverListView<T>> {
  late ScrollController _scrollController;
  bool _ownsController = false;
  bool _isLoadingMoreInternally = false;

  @override
  void initState() {
    super.initState();
    _attachController(widget.controller);
  }

  @override
  void didUpdateWidget(covariant AppSliverListView<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      _detachController();
      _attachController(widget.controller);
    }
  }

  @override
  void dispose() {
    _detachController();
    super.dispose();
  }

  void _attachController(ScrollController? controller) {
    if (controller != null) {
      _scrollController = controller;
      _ownsController = false;
    } else {
      _scrollController = ScrollController();
      _ownsController = true;
    }
    _scrollController.addListener(_onScroll);
  }

  void _detachController() {
    _scrollController.removeListener(_onScroll);
    if (_ownsController) {
      _scrollController.dispose();
    }
  }

  bool get _canLoadMore {
    return widget.onLoadMore != null &&
        widget.hasMore &&
        !widget.isLoading &&
        !widget.isLoadingMore &&
        !_isLoadingMoreInternally;
  }

  void _onScroll() {
    if (!_canLoadMore || !_scrollController.hasClients) return;
    if (_scrollController.position.extentAfter >
        widget.loadMoreTriggerThreshold) {
      return;
    }
    _loadMore();
  }

  void _scheduleAutoLoadMoreIfNeeded() {
    if (!widget.autoLoadWhenNotScrollable) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (!_canLoadMore || !_scrollController.hasClients) return;
      if (_scrollController.position.maxScrollExtent > 0) return;
      _loadMore();
    });
  }

  Future<void> _loadMore() async {
    if (!_canLoadMore) return;
    safeSetState(() {
      _isLoadingMoreInternally = true;
    });
    try {
      await widget.onLoadMore?.call();
    } finally {
      if (mounted) {
        safeSetState(() {
          _isLoadingMoreInternally = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    _scheduleAutoLoadMoreIfNeeded();

    if (widget.error != null) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: _buildErrorState(context),
      );
    }

    if (widget.isLoading && widget.items.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: _buildLoadingState(context),
      );
    }

    if (!widget.isLoading && widget.items.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: _buildEmptyState(context),
      );
    }

    return _buildList(context);
  }

  Widget _buildList(BuildContext context) {
    final showBottomLoader = widget.isLoadingMore || widget.hasMore;
    final hasSeparator = widget.separatorBuilder != null;
    final dataCount = widget.items.length;

    final childCount = hasSeparator
        ? _buildSeparatedChildCount(dataCount, showBottomLoader)
        : dataCount + (showBottomLoader ? 1 : 0);

    Widget sliver = SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          if (hasSeparator) {
            return _buildSeparatedChild(
              context: context,
              index: index,
              dataCount: dataCount,
              showBottomLoader: showBottomLoader,
            );
          }

          if (index >= dataCount) {
            return _buildBottomLoader(context);
          }

          final item = widget.items[index];
          return widget.itemBuilder(context, item, index);
        },
        childCount: childCount,
      ),
    );

    if (widget.padding != null) {
      sliver = SliverPadding(
        padding: widget.padding!,
        sliver: sliver,
      );
    }

    return sliver;
  }

  int _buildSeparatedChildCount(int dataCount, bool showBottomLoader) {
    if (dataCount == 0) {
      return showBottomLoader ? 1 : 0;
    }
    final separatorCount = dataCount - 1;
    return dataCount + separatorCount + (showBottomLoader ? 1 : 0);
  }

  Widget _buildSeparatedChild({
    required BuildContext context,
    required int index,
    required int dataCount,
    required bool showBottomLoader,
  }) {
    final lastIndex =
        _buildSeparatedChildCount(dataCount, showBottomLoader) - 1;
    if (showBottomLoader && index == lastIndex) {
      return _buildBottomLoader(context);
    }

    if (index.isOdd) {
      final separatorIndex = index ~/ 2;
      return widget.separatorBuilder!.call(context, separatorIndex);
    }

    final itemIndex = index ~/ 2;
    final item = widget.items[itemIndex];
    return widget.itemBuilder(context, item, itemIndex);
  }

  Widget _buildBottomLoader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppDimens.paddingMedium),
      child: Center(
        child: SizedBox(
          width: AppDimens.iconSizeMedium,
          height: AppDimens.iconSizeMedium,
          child: Semantics(
            label: context.l10n.loadingMore,
            child: const CircularProgressIndicator(
              strokeWidth: 2,
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
