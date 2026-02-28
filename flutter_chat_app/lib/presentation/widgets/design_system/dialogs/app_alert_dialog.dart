import 'package:flutter/material.dart';
import 'package:flutter_chat_app/core/base/base_dialog.dart';
import 'package:flutter_chat_app/core/constants/app_dimens.dart';
import 'package:flutter_chat_app/l10n/l10n.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/buttons/app_button.dart';

/// An alert dialog component with consistent styling.
///
/// Features:
/// - Title and content
/// - Customizable actions
/// - Icon support
/// - Scrollable content
/// - Accessibility compliant
/// - Dark mode support
///
/// Example:
/// ```dart
/// AppAlertDialog.show(
///   context: context,
///   title: 'Delete Item',
///   content: 'Are you sure you want to delete this item?',
///   icon: Icons.warning_amber_rounded,
///   iconColor: Colors.orange,
///   actions: [
///     AppButton.text(
///       onPressed: () => Navigator.pop(context),
///       text: 'Cancel',
///     ),
///     AppButton.primary(
///       onPressed: () {
///         // Delete logic
///         Navigator.pop(context);
///       },
///       text: 'Delete',
///     ),
///   ],
/// );
/// ```
class AppAlertDialog extends BaseDialog {
  /// Creates an [AppAlertDialog].
  const AppAlertDialog({
    required this.content,
    String? title,
    this.icon,
    this.iconColor,
    List<Widget> actions = const [],
    super.key,
  })  : _titleText = title,
        super(actions: actions);

  /// The title text of the dialog (stored internally).
  final String? _titleText;

  /// The content of the dialog.
  final String content;

  /// Optional icon to display above the title.
  final IconData? icon;

  /// Color for the icon.
  final Color? iconColor;

  /// Shows the alert dialog.
  static Future<T?> show<T>({
    required BuildContext context,
    required String content,
    String? title,
    IconData? icon,
    Color? iconColor,
    List<Widget> actions = const [],
    bool barrierDismissible = true,
  }) {
    return BaseDialog.show<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (context) => AppAlertDialog(
        title: title,
        content: content,
        icon: icon,
        iconColor: iconColor,
        actions: actions,
      ),
    );
  }

  @override
  Widget buildContent(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(
            icon,
            size: AppDimens.iconSizeXLarge,
            color: iconColor ?? Theme.of(context).colorScheme.primary,
          ),
          SizedBox(height: AppDimens.spaceMedium),
        ],
        if (_titleText != null) ...[
          Text(
            _titleText!,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: AppDimens.spaceMedium),
        ],
        Text(
          content,
          style: Theme.of(context).textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
