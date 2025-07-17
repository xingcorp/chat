/// Enterprise Base Dialog Pattern
/// 
/// Standardized dialog components for consistent UI patterns.
/// Follows enterprise messaging app standards (WhatsApp, Messenger, Telegram).
/// 
/// Author: Senior Flutter/Mobile Architect
library base_dialog;

import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_app/core/base/base_widget.dart';

/// Base dialog class for all dialogs in the application
/// 
/// Provides consistent styling, behavior, and accessibility
/// features across all dialog implementations.
abstract class BaseDialog extends BaseStatelessWidget {
  final String? title;
  final Widget? content;
  final List<DialogAction> actions;
  final bool dismissible;
  final EdgeInsets? contentPadding;
  final EdgeInsets? titlePadding;
  final EdgeInsets? actionsPadding;
  final Color? backgroundColor;
  final double? elevation;
  final ShapeBorder? shape;
  final Duration? insetAnimationDuration;
  final Curve? insetAnimationCurve;

  const BaseDialog({
    super.key,
    this.title,
    this.content,
    this.actions = const [],
    this.dismissible = true,
    this.contentPadding,
    this.titlePadding,
    this.actionsPadding,
    this.backgroundColor,
    this.elevation,
    this.shape,
    this.insetAnimationDuration,
    this.insetAnimationCurve,
  });

  @override
  Widget buildContent(BuildContext context) {
    return AlertDialog(
      title: title != null ? _buildTitle(context) : null,
      content: content ?? buildDialogContent(context),
      actions: _buildActions(context),
      contentPadding: contentPadding ?? _getDefaultContentPadding(context),
      titlePadding: titlePadding ?? _getDefaultTitlePadding(context),
      actionsPadding: actionsPadding ?? _getDefaultActionsPadding(context),
      backgroundColor: backgroundColor ?? Theme.of(context).dialogTheme.backgroundColor,
      elevation: elevation ?? 24.0,
      shape: shape ?? _getDefaultShape(context),
    );
  }

  /// Build dialog content - to be implemented by subclasses
  Widget? buildDialogContent(BuildContext context) => null;

  /// Build title widget
  Widget _buildTitle(BuildContext context) {
    return Text(
      title!,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w600,
      ),
    );
  }

  /// Build action buttons
  List<Widget> _buildActions(BuildContext context) {
    return actions.map((action) => action.build(context)).toList();
  }

  /// Get default content padding
  EdgeInsets _getDefaultContentPadding(BuildContext context) {
    return const EdgeInsets.fromLTRB(24.0, 20.0, 24.0, 24.0);
  }

  /// Get default title padding
  EdgeInsets _getDefaultTitlePadding(BuildContext context) {
    return const EdgeInsets.fromLTRB(24.0, 24.0, 24.0, 0.0);
  }

  /// Get default actions padding
  EdgeInsets _getDefaultActionsPadding(BuildContext context) {
    return const EdgeInsets.all(8.0);
  }

  /// Get default dialog shape
  ShapeBorder _getDefaultShape(BuildContext context) {
    return RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12.0),
    );
  }

  /// Show dialog helper method
  static Future<T?> show<T>({
    required BuildContext context,
    required BaseDialog dialog,
    bool barrierDismissible = true,
    Color? barrierColor,
    String? barrierLabel,
    bool useRootNavigator = true,
    RouteSettings? routeSettings,
  }) {
    return showDialog<T>(
      context: context,
      builder: (context) => dialog,
      barrierDismissible: barrierDismissible && dialog.dismissible,
      barrierColor: barrierColor,
      barrierLabel: barrierLabel,
      useRootNavigator: useRootNavigator,
      routeSettings: routeSettings,
    );
  }
}

/// Dialog action class for standardized button behavior
class DialogAction extends Equatable {
  final String text;
  final VoidCallback? onPressed;
  final DialogActionType type;
  final bool isEnabled;
  final bool isLoading;
  final IconData? icon;
  final Color? textColor;
  final Color? backgroundColor;

  const DialogAction({
    required this.text,
    this.onPressed,
    this.type = DialogActionType.secondary,
    this.isEnabled = true,
    this.isLoading = false,
    this.icon,
    this.textColor,
    this.backgroundColor,
  });

  /// Create primary action (e.g., "OK", "Save", "Send")
  const DialogAction.primary({
    required this.text,
    this.onPressed,
    this.isEnabled = true,
    this.isLoading = false,
    this.icon,
  })  : type = DialogActionType.primary,
        textColor = null,
        backgroundColor = null;

  /// Create secondary action (e.g., "Cancel", "Close")
  const DialogAction.secondary({
    required this.text,
    this.onPressed,
    this.isEnabled = true,
    this.isLoading = false,
    this.icon,
  })  : type = DialogActionType.secondary,
        textColor = null,
        backgroundColor = null;

  /// Create destructive action (e.g., "Delete", "Remove")
  const DialogAction.destructive({
    required this.text,
    this.onPressed,
    this.isEnabled = true,
    this.isLoading = false,
    this.icon,
  })  : type = DialogActionType.destructive,
        textColor = null,
        backgroundColor = null;

  /// Build action widget
  Widget build(BuildContext context) {
    if (isLoading) {
      return _buildLoadingButton(context);
    }

    switch (type) {
      case DialogActionType.primary:
        return _buildPrimaryButton(context);
      case DialogActionType.secondary:
        return _buildSecondaryButton(context);
      case DialogActionType.destructive:
        return _buildDestructiveButton(context);
    }
  }

  Widget _buildPrimaryButton(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: isEnabled ? onPressed : null,
      icon: icon != null ? Icon(icon, size: 18) : const SizedBox.shrink(),
      label: Text(text),
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor ?? Theme.of(context).primaryColor,
        foregroundColor: textColor ?? Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }

  Widget _buildSecondaryButton(BuildContext context) {
    return TextButton.icon(
      onPressed: isEnabled ? onPressed : null,
      icon: icon != null ? Icon(icon, size: 18) : const SizedBox.shrink(),
      label: Text(text),
      style: TextButton.styleFrom(
        foregroundColor: textColor ?? Theme.of(context).textTheme.bodyLarge?.color,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }

  Widget _buildDestructiveButton(BuildContext context) {
    return TextButton.icon(
      onPressed: isEnabled ? onPressed : null,
      icon: icon != null ? Icon(icon, size: 18) : const SizedBox.shrink(),
      label: Text(text),
      style: TextButton.styleFrom(
        foregroundColor: textColor ?? Colors.red,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }

  Widget _buildLoadingButton(BuildContext context) {
    return ElevatedButton(
      onPressed: null,
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor ?? Theme.of(context).primaryColor.withValues(alpha: 0.6),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          const SizedBox(width: 8),
          Text(text, style: const TextStyle(color: Colors.white)),
        ],
      ),
    );
  }

  @override
  List<Object?> get props => [
        text,
        type,
        isEnabled,
        isLoading,
        icon,
        textColor,
        backgroundColor,
      ];
}

/// Dialog action types
enum DialogActionType {
  primary,
  secondary,
  destructive,
}

/// Confirmation dialog implementation
class ConfirmationDialog extends BaseDialog {
  final String message;
  final String confirmText;
  final String cancelText;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;
  final DialogActionType confirmType;

  const ConfirmationDialog({
    super.key,
    super.title,
    required this.message,
    this.confirmText = 'OK',
    this.cancelText = 'Cancel',
    this.onConfirm,
    this.onCancel,
    this.confirmType = DialogActionType.primary,
  }) : super(
          actions: const [], // Will be built in _buildActions
        );

  @override
  Widget buildDialogContent(BuildContext context) {
    return Text(
      message,
      style: Theme.of(context).textTheme.bodyLarge,
    );
  }

  @override
  Widget buildContent(BuildContext context) {
    return AlertDialog(
      title: title != null ? Text(title!) : null,
      content: buildDialogContent(context),
      actions: [
        DialogAction.secondary(
          text: cancelText,
          onPressed: onCancel ?? () => Navigator.of(context).pop(false),
        ).build(context),
        DialogAction(
          text: confirmText,
          type: confirmType,
          onPressed: onConfirm ?? () => Navigator.of(context).pop(true),
        ).build(context),
      ],
    );
  }
}
