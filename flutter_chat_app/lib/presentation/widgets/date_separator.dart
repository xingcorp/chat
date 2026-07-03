import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_chat_app/core/base/base_widget.dart';
import 'package:flutter_chat_app/core/constants/app_dimens.dart';
import 'package:flutter_chat_app/core/services/date_formatter_service.dart';
import 'package:flutter_chat_app/core/theme/app_colors.dart';
import 'package:flutter_chat_app/core/theme/app_text_styles.dart';

/// Glassmorphism date separator that floats over the message list as a
/// frosted-glass pill, showing the date boundary between message groups.
class DateSeparator extends BaseStatelessWidget {
  /// The date to display
  final DateTime date;

  /// Optional maximum width constraint
  final double? maxWidth;

  const DateSeparator({
    super.key,
    required this.date,
    this.maxWidth,
  });

  @override
  Widget buildContent(BuildContext context) {
    final formattedDate = DateFormatterService.formatDateForGrouping(date);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      constraints:
          maxWidth != null ? BoxConstraints(maxWidth: maxWidth ?? 0) : null,
      margin: const EdgeInsets.symmetric(vertical: AppDimens.spaceSmall),
      child: Center(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppDimens.tabPillRadius),
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: AppDimens.glassBlurSigma,
              sigmaY: AppDimens.glassBlurSigma,
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimens.paddingMedium,
                vertical: AppDimens.paddingXSmall,
              ),
              decoration: BoxDecoration(
                color: isDarkMode
                    ? AppColors.glassBgDark
                    : AppColors.glassBgLight,
                borderRadius: BorderRadius.circular(AppDimens.tabPillRadius),
              ),
              child: Text(
                formattedDate,
                style: AppTextStyles.labelSmall.copyWith(
                  color: isDarkMode
                      ? AppColors.textSecondaryDarkMode
                      : AppColors.textSecondary,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}