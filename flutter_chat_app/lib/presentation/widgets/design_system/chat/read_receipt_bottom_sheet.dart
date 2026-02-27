import 'package:flutter/material.dart';
import 'package:flutter_chat_app/core/constants/app_dimens.dart';
import 'package:flutter_chat_app/core/theme/app_text_styles.dart';
import 'package:flutter_chat_app/domain/entities/reader_info.dart';
import 'package:flutter_chat_app/l10n/l10n.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/dialogs/app_modal_bottom_sheet.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/media/app_avatar.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/typography/app_text.dart';

/// Bottom sheet hiển thị danh sách đầy đủ người đã đọc tin nhắn.
///
/// Sử dụng [AppModalBottomSheet] để hiển thị danh sách readers
/// với [AppAvatar] + [AppText] cho mỗi reader.
/// Readers được giữ nguyên thứ tự thời gian đọc (truyền từ caller).
class ReadReceiptBottomSheet {
  ReadReceiptBottomSheet._();

  /// Hiển thị bottom sheet với danh sách đầy đủ readers.
  ///
  /// [readers] đã được sắp xếp theo thứ tự thời gian đọc từ caller.
  static Future<void> show(
    BuildContext context,
    List<ReaderInfo> readers,
  ) {
    return AppModalBottomSheet.show(
      context: context,
      title: context.l10n.readReceiptTitle,
      initialChildSize: 0.4,
      minChildSize: 0.25,
      maxChildSize: 0.7,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final reader in readers)
            Padding(
              padding: const EdgeInsets.only(
                bottom: AppDimens.spaceSmall,
              ),
              child: Row(
                children: [
                  _buildAvatar(reader),
                  const SizedBox(width: AppDimens.spaceSmall),
                  Expanded(
                    child: AppText(
                      reader.fullName ?? reader.userId,
                      style: AppTextStyles.bodyMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  static Widget _buildAvatar(ReaderInfo reader) {
    if (reader.avatarUrl != null) {
      return AppAvatar.network(
        imageUrl: reader.avatarUrl ?? '',
        size: AvatarSize.small,
      );
    }

    return AppAvatar.initials(
      name: reader.fullName ?? reader.userId,
      size: AvatarSize.small,
    );
  }
}
