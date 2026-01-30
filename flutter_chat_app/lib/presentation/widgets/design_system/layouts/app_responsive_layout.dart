import 'package:flutter/material.dart';
import 'package:flutter_chat_app/core/base/base_widget.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/layouts/layout_enums.dart';

/// APP RESPONSIVE LAYOUT
class AppResponsiveLayout extends BaseStatelessWidget {
  const AppResponsiveLayout({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
    this.enableTransition = false,
    this.transitionDuration = const Duration(milliseconds: 300),
  });

  final WidgetBuilder mobile;
  final WidgetBuilder? tablet;
  final WidgetBuilder? desktop;
  final bool enableTransition;
  final Duration transitionDuration;

  @override
  Widget buildContent(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final layoutType = LayoutType.fromWidth(constraints.maxWidth);
        final child = _buildLayout(context, layoutType);

        if (enableTransition) {
          return AnimatedSwitcher(
            duration: transitionDuration,
            switchInCurve: Curves.easeInOut,
            switchOutCurve: Curves.easeInOut,
            transitionBuilder: (child, animation) {
              return FadeTransition(
                opacity: animation,
                child: child,
              );
            },
            child: KeyedSubtree(
              key: ValueKey(layoutType),
              child: child,
            ),
          );
        }

        return child;
      },
    );
  }

  Widget _buildLayout(BuildContext context, LayoutType layoutType) {
    return SafeArea(
      child: _getLayoutBuilder(layoutType)(context),
    );
  }

  WidgetBuilder _getLayoutBuilder(LayoutType layoutType) {
    switch (layoutType) {
      case LayoutType.mobile:
        return mobile;
      case LayoutType.tablet:
        return tablet ?? mobile;
      case LayoutType.desktop:
        return desktop ?? tablet ?? mobile;
    }
  }
}


/// APP RESPONSIVE BUILDER
class AppResponsiveBuilder extends BaseStatelessWidget {
  const AppResponsiveBuilder({
    super.key,
    required this.builder,
  });

  final Widget Function(BuildContext context, LayoutType layoutType) builder;

  @override
  Widget buildContent(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final layoutType = LayoutType.fromWidth(constraints.maxWidth);
        return builder(context, layoutType);
      },
    );
  }
}

/// APP RESPONSIVE VALUE
class AppResponsiveValue<T> {
  AppResponsiveValue({
    required BuildContext context,
    required this.mobile,
    this.tablet,
    this.desktop,
  }) : _layoutType = _getLayoutType(context);

  final T mobile;
  final T? tablet;
  final T? desktop;
  final LayoutType _layoutType;

  T get value {
    switch (_layoutType) {
      case LayoutType.mobile:
        return mobile;
      case LayoutType.tablet:
        return tablet ?? mobile;
      case LayoutType.desktop:
        return desktop ?? tablet ?? mobile;
    }
  }

  static LayoutType _getLayoutType(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return LayoutType.fromWidth(width);
  }
}

/// APP ORIENTATION BUILDER
class AppOrientationBuilder extends BaseStatelessWidget {
  const AppOrientationBuilder({
    super.key,
    required this.builder,
  });

  final Widget Function(BuildContext context, Orientation orientation) builder;

  @override
  Widget buildContent(BuildContext context) {
    return OrientationBuilder(builder: builder);
  }
}
