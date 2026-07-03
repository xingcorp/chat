import 'package:flutter/material.dart';
import 'package:flutter_chat_app/core/base/base_widget.dart';
import 'package:flutter_chat_app/core/constants/app_dimens.dart';
import 'package:flutter_chat_app/core/constants/app_icons.dart';
import 'package:flutter_chat_app/core/theme/app_colors.dart';
import 'package:flutter_chat_app/core/theme/app_text_styles.dart';
import 'package:flutter_chat_app/l10n/l10n.dart';
import 'package:flutter_chat_app/shared/domain/entities/chat.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/buttons/app_icon_button.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/media/app_avatar.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/typography/app_text.dart';
import 'package:intl/intl.dart';

/// Header cho Chat Info Panel - TUÂN THỦ DESIGN SYSTEM
/// ✅ SỬ DỤNG AppText thay vì Text
/// ✅ SỬ DỤNG AppAvatar thay vì CircleAvatar
/// ✅ SỬ DỤNG AppIconButton thay vì IconButton
/// ✅ SỬ DỤNG context.l10n cho strings
/// ✅ SỬ DỤNG AppColors.*DarkMode cho colors
/// ✅ SỬ DỤNG AppDimens.* cho dimensions
class ChatInfoHeader extends BaseStatelessWidget {
  final Chat chat;
  final VoidCallback? onClose;

  const ChatInfoHeader({
    super.key,
    required this.chat,
    this.onClose,
  });

  @override
  Widget buildContent(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.all(AppDimens.paddingMedium),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.surfaceDarkMode
            : AppColors.surface,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(AppDimens.radiusLarge),
          topRight: Radius.circular(AppDimens.radiusLarge),
        ),
      ),
      child: Column(
        children: [
          // Close button row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AppText(
                context.l10n.chatInfo,
                style: AppTextStyles.titleLarge.copyWith(
                  color: isDark
                      ? AppColors.textPrimaryDarkMode
                      : AppColors.textPrimary,
                ),
              ),
              if (onClose != null)
                AppIconButton(
                  icon: AppIcons.close,
                  onPressed: onClose,
                  tooltip: context.l10n.close,
                ),
            ],
          ),

          SizedBox(height: AppDimens.spaceMedium),

          // Avatar
          AppAvatar(
            imageUrl: chat.avatarUrl,
            initials: chat.name?.substring(0, 1) ?? '?',
          ),

          SizedBox(height: AppDimens.spaceSmall),

          // Name
          AppText(
            chat.name ?? context.l10n.unknownUser,
            style: AppTextStyles.headlineSmall.copyWith(
              color: isDark
                  ? AppColors.textPrimaryDarkMode
                  : AppColors.textPrimary,
            ),
          ),

          SizedBox(height: AppDimens.spaceXSmall),

          // Status/Member count
          if (chat.type == ChatType.group) ...[
            AppText(
              '${chat.members.length} ${context.l10n.members}',
              style: AppTextStyles.bodyMedium.copyWith(
                color: isDark
                    ? AppColors.textSecondaryDarkMode
                    : AppColors.textSecondary,
              ),
            ),

            // Group creation info
            if (chat.creatorName != null || chat.createdAt != null) ...[
              SizedBox(height: AppDimens.spaceXSmall),
              AppText(
                _buildGroupCreateInfo(context),
                style: AppTextStyles.bodySmall.copyWith(
                  color: isDark
                      ? AppColors.textSecondaryDarkMode
                      : AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ],
      ),
    );
  }

  /// Build group creation info text
  String _buildGroupCreateInfo(BuildContext context) {
    final parts = <String>[];

    if (chat.creatorName != null) {
      parts.add('${context.l10n.createdBy} ${chat.creatorName}');
    }

    if (chat.createdAt != null) {
      parts.add(DateFormat('dd/MM/yyyy HH:mm').format(chat.createdAt!));
    }

    return parts.join(', ');
  }
}
