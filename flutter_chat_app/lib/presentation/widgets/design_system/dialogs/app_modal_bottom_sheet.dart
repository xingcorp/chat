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
    String? title,
    bool showCloseButton = true,
    this.initialChildSize = 0.5,
    this.minChildSize = 0.25,
    this.maxChildSize = 0.95,
    super.key,
  }) : _titleText = title,
       _showCloseButton = showCloseButton;

  /// Builder for the bottom sheet content.
  final WidgetBuilder builder;

  /// The title text of the bottom sheet (stored internally).
  final String? _titleText;

  /// Whether to show the close button (stored internally).
  final bool _showCloseButton;

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
  static PersistentBottomSheetController showPersistent({
    required BuildContext context,
    required WidgetBuilder builder,
    String? title,
    bool showCloseButton = true,
  }) {
    return BaseBottomSheet.showPersistent(
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
            if (_titleText != null || _showCloseButton) ...[
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: AppDimens.paddingMedium,
                  vertical: AppDimens.paddingSmall,
                ),
                child: Row(
                  children: [
                    if (_titleText != null)
                      Expanded(
                        child: Text(
                          _titleText!,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ),
                    if (_showCloseButton)
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
