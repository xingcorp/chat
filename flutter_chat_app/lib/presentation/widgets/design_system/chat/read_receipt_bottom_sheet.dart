import 'package:flutter/material.dart';
import 'package:flutter_chat_app/core/base/base_bottom_sheet.dart';
import 'package:flutter_chat_app/core/constants/app_dimens.dart';
import 'package:flutter_chat_app/core/theme/app_text_styles.dart';
import 'package:flutter_chat_app/domain/entities/reader_info.dart';
import 'package:flutter_chat_app/l10n/l10n.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/media/app_avatar.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/typography/app_text.dart';

/// Bottom sheet hiển thị danh sách đầy đủ người đã đọc tin nhắn.
///
/// Sử dụng [BaseBottomSheet] trực tiếp (không qua [AppModalBottomSheet])
/// để tránh lỗi layout do DraggableScrollableSheet lồng trong SingleChildScrollView.
/// BaseBottomSheet đã cung cấp drag handle, title, và scrollable content.
class ReadReceiptBottomSheet extends BaseBottomSheet {
  const ReadReceiptBottomSheet({
    super.key,
    required this.readers,
  }) : super(
          showCloseButton: true,
          showDragHandle: true,
        );

  /// Danh sách reader đã sắp xếp theo thứ tự thời gian đọc.
  final List<ReaderInfo> readers;

  /// Hiển thị bottom sheet với danh sách đầy đủ readers.
  static Future<void> show(
    BuildContext context,
    List<ReaderInfo> readers,
  ) {
    return BaseBottomSheet.show(
      context: context,
      builder: (context) => ReadReceiptBottomSheet(readers: readers),
    );
  }

  @override
  Widget buildContent(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title
        Padding(
          padding: const EdgeInsets.only(bottom: AppDimens.spaceSmall),
          child: AppText(
            context.l10n.readReceiptTitle,
            style: AppTextStyles.titleMedium,
          ),
        ),
        // Reader list
        for (final reader in readers)
          Padding(
            padding: const EdgeInsets.only(bottom: AppDimens.spaceSmall),
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
