import 'package:flutter/material.dart';
import 'package:flutter_chat_app/core/constants/app_dimens.dart';
import 'package:flutter_chat_app/core/theme/app_colors.dart';

/// **BASE DIALOG**
///
/// Base class for all dialogs in the application.
/// Provides consistent styling, animations, and behavior.
///
/// **Architecture**: Clean Architecture + Base Class Pattern
/// **Pattern**: Template Method Pattern
///
/// **Features**:
/// - Consistent padding and radius using [AppDimens]
/// - Automatic dark mode support
/// - Accessibility support with semantic labels
/// - Customizable barrier behavior
/// - Safe area handling
/// - Scrollable content option
///
/// **Usage**:
/// ```dart
/// class ConfirmDeleteDialog extends BaseDialog {
///   const ConfirmDeleteDialog({super.key});
///
///   @override
///   Widget buildContent(BuildContext context) {
///     return Text('Are you sure you want to delete this item?');
///   }
/// }
///
/// // Show dialog
/// final result = await BaseDialog.show<bool>(
///   context,
///   builder: (context) => ConfirmDeleteDialog(
///     title: Text('Confirm Delete'),
///     actions: [
///       TextButton(
///         onPressed: () => Navigator.pop(context, false),
///         child: Text('Cancel'),
///       ),
///       ElevatedButton(
///         onPressed: () => Navigator.pop(context, true),
///         child: Text('Delete'),
///       ),
///     ],
///   ),
/// );
/// ```
///
/// **Best Practices**:
/// - Extend this class for all custom dialogs
/// - Implement [buildContent] method
/// - Use [AppDimens] for spacing
/// - Provide accessibility labels
/// - Handle back button press
abstract class BaseDialog extends StatelessWidget {
  /// Creates a base dialog
  ///
  /// The [buildContent] method must be implemented by subclasses.
  const BaseDialog({
    super.key,
    this.title,
    this.titlePadding,
    this.contentPadding,
    this.actionsPadding,
    this.actions,
    this.backgroundColor,
    this.elevation,
    this.shape,
    this.insetPadding,
    this.clipBehavior = Clip.antiAlias,
    this.scrollable = false,
  });

  /// Dialog title widget
  ///
  /// Typically a [Text] widget with heading style.
  final Widget? title;

  /// Padding around title
  ///
  /// Defaults to [AppDimens.paddingDialog] on all sides except bottom (small).
  final EdgeInsetsGeometry? titlePadding;

  /// Padding around content
  ///
  /// Defaults to horizontal [AppDimens.paddingDialog] and vertical small.
  final EdgeInsetsGeometry? contentPadding;

  /// Padding around actions
  ///
  /// Defaults to [AppDimens.paddingDialog] on all sides except top (small).
  final EdgeInsetsGeometry? actionsPadding;

  /// Action buttons
  ///
  /// Typically a list of [TextButton] or [ElevatedButton].
  final List<Widget>? actions;

  /// Background color
  ///
  /// Defaults to theme surface color (light/dark aware).
  final Color? backgroundColor;

  /// Elevation
  ///
  /// Defaults to [AppDimens.elevationDialog].
  final double? elevation;

  /// Shape
  ///
  /// Defaults to rounded rectangle with [AppDimens.radiusDialog].
  final ShapeBorder? shape;

  /// Inset padding
  ///
  /// Padding around the dialog. Defaults to [AppDimens.paddingLarge].
  final EdgeInsets? insetPadding;

  /// Clip behavior
  ///
  /// Defaults to [Clip.antiAlias] for smooth corners.
  final Clip clipBehavior;

  /// Whether content is scrollable
  ///
  /// If true, wraps content in [SingleChildScrollView].
  final bool scrollable;

  /// Build dialog content
  ///
  /// Implement this method in subclasses to provide dialog content.
  ///
  /// Example:
  /// ```dart
  /// @override
  /// Widget buildContent(BuildContext context) {
  ///   return Column(
  ///     mainAxisSize: MainAxisSize.min,
  ///     children: [
  ///       Text('Dialog message'),
  ///       SizedBox(height: AppDimens.spaceSmall),
  ///       Text('Additional details'),
  ///     ],
  ///   );
  /// }
  /// ```
  Widget buildContent(BuildContext context);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Dialog(
      backgroundColor: backgroundColor ??
          (isDark ? AppColors.surfaceDarkMode : AppColors.surface),
      elevation: elevation ?? AppDimens.elevationDialog,
      shape: shape ??
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimens.radiusDialog),
          ),
      insetPadding: insetPadding ??
          const EdgeInsets.symmetric(
            horizontal: AppDimens.paddingLarge,
            vertical: AppDimens.paddingLarge,
          ),
      clipBehavior: clipBehavior,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: AppDimens.dialogMaxWidth,
          minWidth: AppDimens.dialogMinWidth,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Title
            if (title != null)
              Padding(
                padding: titlePadding ??
                    const EdgeInsets.fromLTRB(
                      AppDimens.paddingDialog,
                      AppDimens.paddingDialog,
                      AppDimens.paddingDialog,
                      AppDimens.paddingSmall,
                    ),
                child: DefaultTextStyle(
                  style: theme.textTheme.titleLarge!,
                  child: title!,
                ),
              ),
            
            // Content
            Flexible(
              child: scrollable
                  ? SingleChildScrollView(
                      padding: contentPadding ??
                          const EdgeInsets.symmetric(
                            horizontal: AppDimens.paddingDialog,
                            vertical: AppDimens.paddingSmall,
                          ),
                      child: buildContent(context),
                    )
                  : Padding(
                      padding: contentPadding ??
                          const EdgeInsets.symmetric(
                            horizontal: AppDimens.paddingDialog,
                            vertical: AppDimens.paddingSmall,
                          ),
                      child: buildContent(context),
                    ),
            ),
            
            // Actions
            if (actions != null && actions!.isNotEmpty)
              Padding(
                padding: actionsPadding ??
                    const EdgeInsets.fromLTRB(
                      AppDimens.paddingDialog,
                      AppDimens.paddingSmall,
                      AppDimens.paddingDialog,
                      AppDimens.paddingDialog,
                    ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: _buildActions(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Build actions with proper spacing
  List<Widget> _buildActions() {
    final actionWidgets = <Widget>[];
    for (var i = 0; i < actions!.length; i++) {
      if (i > 0) {
        actionWidgets.add(const SizedBox(width: AppDimens.spaceSmall));
      }
      actionWidgets.add(actions![i]);
    }
    return actionWidgets;
  }

  /// Show dialog with standard configuration
  ///
  /// Returns a [Future] that resolves to the value passed to [Navigator.pop].
  ///
  /// Example:
  /// ```dart
  /// final confirmed = await BaseDialog.show<bool>(
  ///   context,
  ///   builder: (context) => MyDialog(),
  ///   barrierDismissible: false,
  /// );
  ///
  /// if (confirmed == true) {
  ///   // User confirmed
  /// }
  /// ```
  ///
  /// Parameters:
  /// - [context]: Build context
  /// - [builder]: Dialog builder function
  /// - [barrierDismissible]: Whether tapping outside dismisses dialog
  /// - [barrierColor]: Color of the modal barrier
  /// - [barrierLabel]: Semantic label for barrier
  /// - [useSafeArea]: Whether to avoid system intrusions
  /// - [useRootNavigator]: Whether to use root navigator
  /// - [routeSettings]: Route settings for navigation
  /// - [anchorPoint]: Anchor point for dialog positioning
  static Future<T?> show<T>({
    required BuildContext context,
    required WidgetBuilder builder,
    bool barrierDismissible = true,
    Color? barrierColor,
    String? barrierLabel,
    bool useSafeArea = true,
    bool useRootNavigator = true,
    RouteSettings? routeSettings,
    Offset? anchorPoint,
  }) {
    return showDialog<T>(
      context: context,
      builder: builder,
      barrierDismissible: barrierDismissible,
      barrierColor: barrierColor ?? Colors.black54,
      barrierLabel: barrierLabel,
      useSafeArea: useSafeArea,
      useRootNavigator: useRootNavigator,
      routeSettings: routeSettings,
      anchorPoint: anchorPoint,
    );
  }
}
