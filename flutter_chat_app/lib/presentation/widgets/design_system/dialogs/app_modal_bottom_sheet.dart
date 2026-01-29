import 'package:flutter/material.dart';
import 'package:flutter_chat_app/core/base/base_bottom_sheet.dart';
import 'package:flutter_chat_app/core/constants/app_dimens.dart';

/// A modal bottom sheet component with consistent styling.
///
/// Features:
/// - Title and close button
/// - Scrollable content
/// - Drag handle
/// - Customizable height
/// - Accessibility compliant
/// - Dark mode support
///
/// Example:
/// ```dart
/// AppModalBottomSheet.show(
///   context: context,
///   title: 'Select Option',
///   builder: (context) => Column(
///     children: [
///       ListTile(
///         leading: Icon(Icons.edit),
///         title: Text('Edit'),
///         onTap: () {
///           Navigator.pop(context);
///           // Edit logic
///         },
///       ),
///       ListTile(
///         leading: Icon(Icons.delete),
///         title: Text('Delete'),
///         onTap: () {
///           Navigator.pop(context);
///           // Delete logic
///         },
///       ),
///     ],
///   ),
/// );
/// ```
class AppModalBottomSheet extends BaseBottomSheet {
  /// Creates an [AppModalBottomSheet].
  const AppModalBottomSheet({
    required this.builder,
    this.title,
    this.showCloseButton = true,
    this.initialChildSize = 0.5,
    this.minChildSize = 0.25,
    this.maxChildSize = 0.95,
    super.key,
  });

  /// Builder for the bottom sheet content.
  final WidgetBuilder builder;

  /// The title of the bottom sheet.
  final String? title;

  /// Whether to show the close button.
  final bool showCloseButton;

  /// Initial size of the bottom sheet (0.0 to 1.0).
  final double initialChildSize;

  /// Minimum size of the bottom sheet (0.0 to 1.0).
  final double minChildSize;

  /// Maximum size of the bottom sheet (0.0 to 1.0).
  final double maxChildSize;

  /// Shows the modal bottom sheet.
  static Future<T?> show<T>({
    required BuildContext context,
    required WidgetBuilder builder,
    String? title,
    bool showCloseButton = true,
    double initialChildSize = 0.5,
    double minChildSize = 0.25,
    double maxChildSize = 0.95,
    bool isDismissible = true,
    bool enableDrag = true,
  }) {
    return BaseBottomSheet.show<T>(
      context: context,
      isDismissible: isDismissible,
      enableDrag: enableDrag,
      builder: (context) => AppModalBottomSheet(
        builder: builder,
        title: title,
        showCloseButton: showCloseButton,
        initialChildSize: initialChildSize,
        minChildSize: minChildSize,
        maxChildSize: maxChildSize,
      ),
    );
  }

  /// Shows a persistent modal bottom sheet.
  static PersistentBottomSheetController<T> showPersistent<T>({
    required BuildContext context,
    required WidgetBuilder builder,
    String? title,
    bool showCloseButton = true,
  }) {
    return BaseBottomSheet.showPersistent<T>(
      context: context,
      builder: (context) => AppModalBottomSheet(
        builder: builder,
        title: title,
        showCloseButton: showCloseButton,
      ),
    );
  }

  @override
  Widget buildContent(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: initialChildSize,
      minChildSize: minChildSize,
      maxChildSize: maxChildSize,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            if (title != null || showCloseButton) ...[
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: AppDimens.paddingMedium,
                  vertical: AppDimens.paddingSmall,
                ),
                child: Row(
                  children: [
                    if (title != null)
                      Expanded(
                        child: Text(
                          title!,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ),
                    if (showCloseButton)
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(context).pop(),
                        tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                      ),
                  ],
                ),
              ),
              Divider(height: 1, thickness: 1),
            ],
            Expanded(
              child: SingleChildScrollView(
                controller: scrollController,
                padding: EdgeInsets.all(AppDimens.paddingMedium),
                child: builder(context),
              ),
            ),
          ],
        );
      },
    );
  }
}
