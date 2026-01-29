import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_chat_app/core/base/base_widget.dart';
import 'package:flutter_chat_app/core/constants/app_constants.dart';
import 'package:flutter_chat_app/core/constants/app_dimens.dart';
import 'package:flutter_chat_app/core/theme/app_colors.dart';
import 'package:flutter_chat_app/core/theme/app_text_styles.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/data/data_enums.dart';

/// **APP CAROUSEL**
///
/// Horizontal scrollable carousel with indicators and auto-play support.
/// Extends [BaseStatefulWidget] for lifecycle management.
///
/// **Features**:
/// - Page indicator dots/lines/numbers
/// - Auto-play with configurable interval
/// - Swipe gestures
/// - Snap to page
/// - Loop mode
/// - Custom transition animations
/// - Dark mode support
/// - Accessibility labels
///
/// **Architecture**: Clean Architecture + Design System
/// **Pattern**: Stateful widget with PageController
///
/// **Usage**:
/// ```dart
/// // Basic carousel
/// AppCarousel(
///   items: [
///     Image.network('url1'),
///     Image.network('url2'),
///     Image.network('url3'),
///   ],
/// )
///
/// // Auto-play carousel with custom indicators
/// AppCarousel(
///   items: items,
///   autoPlay: true,
///   autoPlayInterval: Duration(seconds: 3),
///   indicatorPosition: CarouselIndicatorPosition.bottom,
///   indicatorStyle: CarouselIndicatorStyle.dots,
///   loop: true,
/// )
/// ```
class AppCarousel extends BaseStatefulWidget {
  /// Creates a carousel.
  const AppCarousel({
    super.key,
    required this.items,
    this.height,
    this.aspectRatio = 16 / 9,
    this.autoPlay = false,
    this.autoPlayInterval = const Duration(seconds: 3),
    this.loop = false,
    this.indicatorPosition = CarouselIndicatorPosition.bottom,
    this.indicatorStyle = CarouselIndicatorStyle.dots,
    this.transitionType = CarouselTransitionType.slide,
    this.transitionDuration,
    this.initialPage = 0,
    this.viewportFraction = 1.0,
    this.onPageChanged,
  });

  /// List of carousel items
  final List<Widget> items;

  /// Fixed height (if null, uses aspectRatio)
  final double? height;

  /// Aspect ratio (width / height)
  final double aspectRatio;

  /// Whether to auto-play
  final bool autoPlay;

  /// Auto-play interval
  final Duration autoPlayInterval;

  /// Whether to loop infinitely
  final bool loop;

  /// Indicator position
  final CarouselIndicatorPosition indicatorPosition;

  /// Indicator style
  final CarouselIndicatorStyle indicatorStyle;

  /// Transition type
  final CarouselTransitionType transitionType;

  /// Transition duration
  final Duration? transitionDuration;

  /// Initial page index
  final int initialPage;

  /// Viewport fraction (1.0 = full width)
  final double viewportFraction;

  /// Callback when page changes
  final ValueChanged<int>? onPageChanged;

  @override
  State<AppCarousel> createState() => _AppCarouselState();
}

class _AppCarouselState extends BaseState<AppCarousel> {
  late PageController _pageController;
  late int _currentPage;
  Timer? _autoPlayTimer;

  @override
  void initState() {
    super.initState();
    _currentPage = widget.initialPage;
    _pageController = PageController(
      initialPage: widget.initialPage,
      viewportFraction: widget.viewportFraction,
    );

    if (widget.autoPlay) {
      _startAutoPlay();
    }
  }

  @override
  void dispose() {
    _autoPlayTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.indicatorPosition == CarouselIndicatorPosition.top)
          _buildIndicators(),
        _buildCarousel(),
        if (widget.indicatorPosition == CarouselIndicatorPosition.bottom)
          _buildIndicators(),
      ],
    );
  }

  Widget _buildCarousel() {
    Widget carousel = SizedBox(
      height: widget.height,
      child: AspectRatio(
        aspectRatio: widget.height != null ? 1.0 : widget.aspectRatio,
        child: PageView.builder(
          controller: _pageController,
          onPageChanged: _onPageChanged,
          itemCount: widget.loop ? null : widget.items.length,
          itemBuilder: (context, index) {
            final itemIndex = index % widget.items.length;
            return _buildItem(widget.items[itemIndex]);
          },
        ),
      ),
    );

    if (widget.indicatorPosition == CarouselIndicatorPosition.left ||
        widget.indicatorPosition == CarouselIndicatorPosition.right) {
      carousel = Row(
        children: [
          if (widget.indicatorPosition == CarouselIndicatorPosition.left)
            _buildIndicators(),
          Expanded(child: carousel),
          if (widget.indicatorPosition == CarouselIndicatorPosition.right)
            _buildIndicators(),
        ],
      );
    }

    return carousel;
  }

  Widget _buildItem(Widget item) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppDimens.paddingSmall),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppDimens.radiusMedium),
        child: item,
      ),
    );
  }

  Widget _buildIndicators() {
    if (widget.indicatorPosition == CarouselIndicatorPosition.none) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    switch (widget.indicatorStyle) {
      case CarouselIndicatorStyle.dots:
        return _buildDotIndicators(isDark);
      case CarouselIndicatorStyle.lines:
        return _buildLineIndicators(isDark);
      case CarouselIndicatorStyle.numbers:
        return _buildNumberIndicator(isDark);
      case CarouselIndicatorStyle.thumbnails:
        return _buildThumbnailIndicators();
    }
  }

  Widget _buildDotIndicators(bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(AppDimens.paddingSmall),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(
          widget.items.length,
          (index) => AnimatedContainer(
            duration: AppConstants.kDefaultAnimationDuration,
            margin: const EdgeInsets.symmetric(horizontal: AppDimens.paddingXSmall),
            width: _currentPage == index ? 24.0 : 8.0,
            height: 8.0,
            decoration: BoxDecoration(
              color: _currentPage == index
                  ? (isDark ? AppColors.primaryDarkMode : AppColors.primary)
                  : (isDark ? Colors.white38 : Colors.black38),
              borderRadius: BorderRadius.circular(AppDimens.radiusSmall),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLineIndicators(bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(AppDimens.paddingSmall),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(
          widget.items.length,
          (index) => Expanded(
            child: AnimatedContainer(
              duration: AppConstants.kDefaultAnimationDuration,
              margin: const EdgeInsets.symmetric(horizontal: AppDimens.paddingXSmall),
              height: 4.0,
              decoration: BoxDecoration(
                color: _currentPage == index
                    ? (isDark ? AppColors.primaryDarkMode : AppColors.primary)
                    : (isDark ? Colors.white38 : Colors.black38),
                borderRadius: BorderRadius.circular(AppDimens.radiusSmall),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNumberIndicator(bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(AppDimens.paddingSmall),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimens.paddingSmall,
          vertical: AppDimens.paddingXSmall,
        ),
        decoration: BoxDecoration(
          color: (isDark ? Colors.black54 : Colors.white70),
          borderRadius: BorderRadius.circular(AppDimens.radiusMedium),
        ),
        child: Text(
          '${_currentPage + 1}/${widget.items.length}',
          style: AppTextStyles.bodySmall(context).copyWith(
            color: isDark ? Colors.white : Colors.black,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildThumbnailIndicators() {
    return SizedBox(
      height: 60,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: widget.items.length,
        itemBuilder: (context, index) {
          final isSelected = _currentPage == index;
          return GestureDetector(
            onTap: () => _goToPage(index),
            child: AnimatedContainer(
              duration: AppConstants.kDefaultAnimationDuration,
              margin: const EdgeInsets.all(AppDimens.paddingXSmall),
              decoration: BoxDecoration(
                border: Border.all(
                  color: isSelected ? AppColors.primary : Colors.transparent,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(AppDimens.radiusSmall),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppDimens.radiusSmall),
                child: SizedBox(
                  width: 80,
                  child: widget.items[index],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _onPageChanged(int page) {
    safeSetState(() {
      _currentPage = page % widget.items.length;
    });
    widget.onPageChanged?.call(_currentPage);
  }

  void _goToPage(int page) {
    _pageController.animateToPage(
      page,
      duration: widget.transitionDuration ?? AppConstants.kDefaultAnimationDuration,
      curve: Curves.easeInOut,
    );
  }

  void _startAutoPlay() {
    _autoPlayTimer = Timer.periodic(widget.autoPlayInterval, (_) {
      if (!mounted) return;

      final nextPage = _currentPage + 1;
      if (widget.loop || nextPage < widget.items.length) {
        _pageController.animateToPage(
          nextPage,
          duration: widget.transitionDuration ?? AppConstants.kDefaultAnimationDuration,
          curve: Curves.easeInOut,
        );
      } else {
        _autoPlayTimer?.cancel();
      }
    });
  }
}
