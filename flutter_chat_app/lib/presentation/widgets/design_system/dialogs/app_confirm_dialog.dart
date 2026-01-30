import 'package:flutter/material.dart';
import 'package:flutter_chat_app/core/base/base_dialog.dart';
import 'package:flutter_chat_app/core/constants/app_dimens.dart';
import 'package:flutter_chat_app/core/theme/app_text_styles.dart';
import 'package:flutter_chat_app/l10n/l10n.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/buttons/app_button.dart';

/// A confirmation dialog component with consistent styling.
///
/// Features:
/// - Title and content
/// - Confirm and cancel actions
/// - Icon support
/// - Customizable button labels
/// - Returns boolean result
/// - Accessibility compliant
/// - Dark mode support
///
/// Example:
/// ```dart
/// final confirmed = await AppConfirmDialog.show(
///   context: context,
///   title: 'Delete Item',
///   content: 'Are you sure you want to delete this item? This action cannot be undone.',
///   confirmText: 'Delete',
///   cancelText: 'Cancel',
///   isDestructive: true,
/// );
///
/// if (confirmed == true) {
///   // Perform delete
/// }
/// ```
class AppConfirmDialog extends BaseDialog {
  /// Creates an [AppConfirmDialog].
  const AppConfirmDialog({
    required this.content,
    String? title,
    this.icon,
    this.iconColor,
    this.confirmText,
    this.cancelText,
    this.isDestructive = false,
    super.key,
  }) : _titleText = title;

  /// The title text of the dialog (stored internally).
  final String? _titleText;

  /// The content of the dialog.
  final String content;

  /// Optional icon to display above the title.
  final IconData? icon;

  /// Color for the icon.
  final Color? iconColor;

  /// Text for the confirm button.
  final String? confirmText;

  /// Text for the cancel button.
  final String? cancelText;

  /// Whether this is a destructive action (uses error color).
  final bool isDestructive;

  /// Shows the confirmation dialog and returns true if confirmed.
  static Future<bool?> show({
    required BuildContext context,
    required String content,
    String? title,
    IconData? icon,
    Color? iconColor,
    String? confirmText,
    String? cancelText,
    bool isDestructive = false,
    bool barrierDismissible = true,
  }) {
    return BaseDialog.show<bool>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (context) => AppConfirmDialog(
        title: title,
        content: content,
        icon: icon,
        iconColor: iconColor,
        confirmText: confirmText,
        cancelText: cancelText,
        isDestructive: isDestructive,
      ),
    );
  }

  @override
  Widget buildContent(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(
            icon,
            size: AppDimens.iconSizeXLarge,
            color: iconColor ??
                (isDestructive
                    ? theme.colorScheme.error
                    : theme.colorScheme.primary),
          ),
          SizedBox(height: AppDimens.spaceMedium),
        ],
        if (_titleText != null) ...[
          Text(
            _titleText!,
            style: AppTextStyles.titleLarge.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: AppDimens.spaceMedium),
        ],
        Text(
          content,
          style: AppTextStyles.bodyMedium,
          textAlign: TextAlign.center,
        ),
        SizedBox(height: AppDimens.spaceLarge),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            AppButton.text(
              onPressed: () => Navigator.of(context).pop(false),
              text: cancelText ?? l10n.cancel,
            ),
            const SizedBox(width: AppDimens.spaceSmall),
            if (isDestructive)
              AppButton.primary(
                onPressed: () => Navigator.of(context).pop(true),
                text: confirmText ?? l10n.ok,
                backgroundColor: theme.colorScheme.error,
                foregroundColor: theme.colorScheme.onError,
              )
            else
              AppButton.primary(
                onPressed: () => Navigator.of(context).pop(true),
                text: confirmText ?? l10n.ok,
              ),
          ],
        ),
      ],
    );
  }
}
