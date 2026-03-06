import 'package:flutter/material.dart';
import 'package:flutter_chat_app/core/constants/app_dimens.dart';
import 'package:flutter_chat_app/core/theme/app_colors.dart';

/// **BASE BOTTOM SHEET**
///
/// Base class for all bottom sheets in the application.
/// Provides consistent styling, animations, and behavior.
///
/// **Architecture**: Clean Architecture + Base Class Pattern
/// **Pattern**: Template Method Pattern
///
/// **Features**:
/// - Consistent padding and radius using [AppDimens]
/// - Automatic dark mode support
/// - Drag handle for better UX
/// - Optional close button
/// - Safe area handling
/// - Scrollable content
/// - Modal and persistent variants
///
/// **Usage**:
/// ```dart
/// class SettingsBottomSheet extends BaseBottomSheet {
///   const SettingsBottomSheet({super.key});
///
///   @override
///   Widget buildContent(BuildContext context) {
///     return Column(
///       children: [
///         ListTile(title: Text('Setting 1')),
///         ListTile(title: Text('Setting 2')),
///       ],
///     );
///   }
/// }
///
/// // Show modal bottom sheet
/// await BaseBottomSheet.show(
///   context,
///   builder: (context) => SettingsBottomSheet(
///     title: Text('Settings'),
///     showCloseButton: true,
///   ),
/// );
///
/// // Show persistent bottom sheet
/// final controller = BaseBottomSheet.showPersistent(
///   context,
///   builder: (context) => SettingsBottomSheet(),
/// );
/// ```
///
/// **Best Practices**:
/// - Extend this class for all custom bottom sheets
/// - Implement [buildContent] method
/// - Use [AppDimens] for spacing
/// - Provide accessibility labels
/// - Handle drag gestures properly
abstract class BaseBottomSheet extends StatelessWidget {
  /// Creates a base bottom sheet
  ///
  /// The [buildContent] method must be implemented by subclasses.
  const BaseBottomSheet({
    super.key,
    this.title,
    this.showDragHandle = true,
    this.showCloseButton = false,
    this.backgroundColor,
    this.elevation,
    this.shape,
    this.padding,
    this.isScrollControlled = true,
    this.enableDrag = true,
  });

  /// Bottom sheet title
  ///
  /// Typically a [Text] widget with heading style.
  final Widget? title;

  /// Show drag handle at top
  ///
  /// Provides visual affordance for dragging. Defaults to true.
  final bool showDragHandle;

  /// Show close button
  ///
  /// Adds an IconButton to close the bottom sheet. Defaults to false.
  final bool showCloseButton;

  /// Background color
  ///
  /// Defaults to theme surface color (light/dark aware).
  final Color? backgroundColor;

  /// Elevation
  ///
  /// Defaults to [AppDimens.elevationBottomSheet].
  final double? elevation;

  /// Shape
  ///
  /// Defaults to rounded top corners with [AppDimens.radiusBottomSheet].
  final ShapeBorder? shape;

  /// Content padding
  ///
  /// Defaults to [AppDimens.paddingBottomSheet] horizontal and bottom.
  final EdgeInsetsGeometry? padding;

  /// Whether bottom sheet is scroll controlled
  ///
  /// If true, bottom sheet can expand to full height. Defaults to true.
  final bool isScrollControlled;

  /// Whether bottom sheet can be dragged
  ///
  /// If false, disables drag gestures. Defaults to true.
  final bool enableDrag;

  /// Build bottom sheet content
  ///
  /// Implement this method in subclasses to provide bottom sheet content.
  ///
  /// Example:
  /// ```dart
  /// @override
  /// Widget buildContent(BuildContext context) {
  ///   return Column(
  ///     mainAxisSize: MainAxisSize.min,
  ///     children: [
  ///       ListTile(
  ///         leading: Icon(Icons.settings),
  ///         title: Text('Settings'),
  ///         onTap: () => _handleSettings(context),
  ///       ),
  ///       ListTile(
  ///         leading: Icon(Icons.help),
  ///         title: Text('Help'),
  ///         onTap: () => _handleHelp(context),
  ///       ),
  ///     ],
  ///   );
  /// }
  /// ```
  Widget buildContent(BuildContext context);

  /// Whether the content should be wrapped in the default scroll view.
  ///
  /// Subclasses that manage their own scroll/drag behavior, such as those
  /// using [DraggableScrollableSheet], should override this to `false`.
  @protected
  bool get wrapContentInScrollView => true;

  Widget _buildSheetBody(BuildContext context) {
    if (!wrapContentInScrollView) {
      return Flexible(
        child: buildContent(context),
      );
    }

    return Flexible(
      child: SingleChildScrollView(
        padding: padding ??
            const EdgeInsets.fromLTRB(
              AppDimens.paddingBottomSheet,
              0,
              AppDimens.paddingBottomSheet,
              AppDimens.paddingBottomSheet,
            ),
        child: buildContent(context),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor ??
            (isDark ? AppColors.surfaceDarkMode : AppColors.surface),
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppDimens.radiusBottomSheet),
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drag handle
            if (showDragHandle)
              Center(
                child: Container(
                  margin: const EdgeInsets.symmetric(
                    vertical: AppDimens.paddingSmall,
                  ),
                  width: 32,
                  height: 4,
                  decoration: BoxDecoration(
                    color:
                        isDark ? AppColors.dividerDarkMode : AppColors.divider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

            // Header with title and close button
            if (title != null || showCloseButton)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppDimens.paddingBottomSheet,
                  AppDimens.paddingSmall,
                  AppDimens.paddingBottomSheet,
                  AppDimens.paddingSmall,
                ),
                child: Row(
                  children: [
                    if (title != null)
                      Expanded(
                        child: DefaultTextStyle(
                          style: theme.textTheme.titleLarge!,
                          child: title!,
                        ),
                      ),
                    if (showCloseButton)
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(context).pop(),
                        tooltip: MaterialLocalizations.of(context)
                            .closeButtonTooltip,
                        constraints: const BoxConstraints(
                          minWidth: AppDimens.iconButtonSize,
                          minHeight: AppDimens.iconButtonSize,
                        ),
                      ),
                  ],
                ),
              ),

            // Content
            _buildSheetBody(context),
          ],
        ),
      ),
    );
  }

  /// Show modal bottom sheet with standard configuration
  ///
  /// Returns a [Future] that resolves to the value passed to [Navigator.pop].
  ///
  /// Example:
  /// ```dart
  /// final result = await BaseBottomSheet.show<String>(
  ///   context,
  ///   builder: (context) => MyBottomSheet(),
  ///   isDismissible: true,
  ///   enableDrag: true,
  /// );
  ///
  /// if (result != null) {
  ///   print('Selected: $result');
  /// }
  /// ```
  ///
  /// Parameters:
  /// - [context]: Build context
  /// - [builder]: Bottom sheet builder function
  /// - [backgroundColor]: Background color (defaults to transparent for custom styling)
  /// - [elevation]: Elevation level
  /// - [shape]: Custom shape
  /// - [clipBehavior]: Clip behavior
  /// - [constraints]: Size constraints
  /// - [barrierColor]: Color of the modal barrier
  /// - [isScrollControlled]: Whether bottom sheet can expand to full height
  /// - [useRootNavigator]: Whether to use root navigator
  /// - [isDismissible]: Whether tapping outside dismisses bottom sheet
  /// - [enableDrag]: Whether bottom sheet can be dragged
  /// - [routeSettings]: Route settings for navigation
  /// - [transitionAnimationController]: Custom animation controller
  static Future<T?> show<T>({
    required BuildContext context,
    required WidgetBuilder builder,
    Color? backgroundColor,
    double? elevation,
    ShapeBorder? shape,
    Clip? clipBehavior,
    BoxConstraints? constraints,
    Color? barrierColor,
    bool isScrollControlled = true,
    bool useRootNavigator = false,
    bool isDismissible = true,
    bool enableDrag = true,
    RouteSettings? routeSettings,
    AnimationController? transitionAnimationController,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      builder: builder,
      backgroundColor: backgroundColor ?? Colors.transparent,
      elevation: elevation,
      shape: shape,
      clipBehavior: clipBehavior,
      constraints: constraints,
      barrierColor: barrierColor,
      isScrollControlled: isScrollControlled,
      useRootNavigator: useRootNavigator,
      isDismissible: isDismissible,
      enableDrag: enableDrag,
      routeSettings: routeSettings,
      transitionAnimationController: transitionAnimationController,
    );
  }

  /// Show persistent bottom sheet
  ///
  /// Returns a [PersistentBottomSheetController] that can be used to
  /// programmatically close the bottom sheet.
  ///
  /// Example:
  /// ```dart
  /// final controller = BaseBottomSheet.showPersistent<String>(
  ///   context: context,
  ///   builder: (context) => MyBottomSheet(),
  /// );
  ///
  /// // Later, close programmatically
  /// controller.close();
  /// ```
  ///
  /// Parameters:
  /// - [context]: Build context
  /// - [builder]: Bottom sheet builder function
  /// - [backgroundColor]: Background color
  /// - [elevation]: Elevation level
  /// - [shape]: Custom shape
  /// - [clipBehavior]: Clip behavior
  /// - [constraints]: Size constraints
  /// - [enableDrag]: Whether bottom sheet can be dragged
  /// - [transitionAnimationController]: Custom animation controller
  static PersistentBottomSheetController showPersistent({
    required BuildContext context,
    required WidgetBuilder builder,
    Color? backgroundColor,
    double? elevation,
    ShapeBorder? shape,
    Clip? clipBehavior,
    BoxConstraints? constraints,
    bool enableDrag = true,
    AnimationController? transitionAnimationController,
  }) {
    return showBottomSheet(
      context: context,
      builder: builder,
      backgroundColor: backgroundColor,
      elevation: elevation,
      shape: shape,
      clipBehavior: clipBehavior,
      constraints: constraints,
      enableDrag: enableDrag,
      transitionAnimationController: transitionAnimationController,
    );
  }
}
