import 'package:flutter/material.dart';
import 'package:flutter_chat_app/core/base/base_widget.dart';
import 'package:flutter_chat_app/core/constants/app_dimens.dart';
import 'package:flutter_chat_app/core/theme/app_text_styles.dart';
import 'package:flutter_chat_app/l10n/l10n.dart';

/// A customizable progress indicator component.
///
/// Features:
/// - Circular and linear variants
/// - Determinate and indeterminate modes
/// - Size variants
/// - Label support
/// - Accessibility compliant
/// - Dark mode support
///
/// Example:
/// ```dart
/// // Circular indeterminate
/// AppProgressIndicator.circular()
///
/// // Circular determinate
/// AppProgressIndicator.circular(
///   value: 0.75,
///   label: '75%',
/// )
///
/// // Linear indeterminate
/// AppProgressIndicator.linear()
///
/// // Linear determinate
/// AppProgressIndicator.linear(
///   value: 0.5,
///   label: 'Uploading...',
/// )
/// ```
class AppProgressIndicator extends BaseStatelessWidget {
  /// Creates an [AppProgressIndicator].
  const AppProgressIndicator({
    this.value,
    this.label,
    this.size = ProgressSize.medium,
    this.isLinear = false,
    this.color,
    this.backgroundColor,
    this.strokeWidth,
    super.key,
  });

  /// Creates a circular progress indicator.
  const AppProgressIndicator.circular({
    double? value,
    String? label,
    ProgressSize size = ProgressSize.medium,
    Color? color,
    Color? backgroundColor,
    double? strokeWidth,
    Key? key,
  }) : this(
          value: value,
          label: label,
          size: size,
          isLinear: false,
          color: color,
          backgroundColor: backgroundColor,
          strokeWidth: strokeWidth,
          key: key,
        );

  /// Creates a linear progress indicator.
  const AppProgressIndicator.linear({
    double? value,
    String? label,
    Color? color,
    Color? backgroundColor,
    Key? key,
  }) : this(
          value: value,
          label: label,
          size: ProgressSize.medium,
          isLinear: true,
          color: color,
          backgroundColor: backgroundColor,
          key: key,
        );

  /// The progress value (0.0 to 1.0). If null, shows indeterminate progress.
  final double? value;

  /// Optional label to display below the progress indicator.
  final String? label;

  /// The size of the progress indicator.
  final ProgressSize size;

  /// Whether to show a linear progress indicator.
  final bool isLinear;

  /// The color of the progress indicator.
  final Color? color;

  /// The background color of the progress indicator.
  final Color? backgroundColor;

  /// The stroke width for circular progress indicator.
  final double? strokeWidth;

  @override
  Widget buildContent(BuildContext context) {
    final theme = Theme.of(context);
    final progressColor = color ?? theme.colorScheme.primary;
    final bgColor = backgroundColor ?? theme.colorScheme.surfaceVariant;

    if (isLinear) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            label: label ?? context.l10n.loading,
            value: value != null ? '${(value! * 100).toInt()}%' : null,
            child: LinearProgressIndicator(
              value: value,
              color: progressColor,
              backgroundColor: bgColor,
              minHeight: 4.0,
            ),
          ),
          if (label != null) ...[
            SizedBox(height: AppDimens.spaceSmall),
            Text(
              label!,
              style: AppTextStyles.bodySmall(context).copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      );
    }

    final indicatorSize = _getSize(size);
    final strokeW = strokeWidth ?? _getStrokeWidth(size);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(
          label: label ?? context.l10n.loading,
          value: value != null ? '${(value! * 100).toInt()}%' : null,
          child: SizedBox(
            width: indicatorSize,
            height: indicatorSize,
            child: CircularProgressIndicator(
              value: value,
              color: progressColor,
              backgroundColor: bgColor,
              strokeWidth: strokeW,
            ),
          ),
        ),
        if (label != null) ...[
          SizedBox(height: AppDimens.spaceSmall),
          Text(
            label!,
            style: AppTextStyles.bodySmall(context).copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }

  double _getSize(ProgressSize size) {
    switch (size) {
      case ProgressSize.small:
        return AppDimens.iconSizeSmall;
      case ProgressSize.medium:
        return AppDimens.iconSizeMedium;
      case ProgressSize.large:
        return AppDimens.iconSizeLarge;
    }
  }

  double _getStrokeWidth(ProgressSize size) {
    switch (size) {
      case ProgressSize.small:
        return 2.0;
      case ProgressSize.medium:
        return 3.0;
      case ProgressSize.large:
        return 4.0;
    }
  }
}

/// Size variants for progress indicators.
enum ProgressSize {
  /// Small progress indicator.
  small,

  /// Medium progress indicator.
  medium,

  /// Large progress indicator.
  large,
}
