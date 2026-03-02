import 'package:flutter/material.dart';
import 'package:flutter_chat_app/core/base/base_bottom_sheet.dart';
import 'package:flutter_chat_app/core/theme/app_colors.dart';
import 'package:flutter_chat_app/l10n/l10n.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/lists/app_list_tile.dart';
import 'package:image_picker/image_picker.dart';

/// Bottom sheet chọn nguồn ảnh đại diện nhóm.
///
/// Dùng [BaseBottomSheet] trực tiếp để tránh lỗi layout của
/// DraggableScrollableSheet lồng trong SingleChildScrollView.
class GroupAvatarSourceBottomSheet extends BaseBottomSheet {
  const GroupAvatarSourceBottomSheet({super.key})
      : super(
          showCloseButton: true,
          showDragHandle: true,
        );

  static Future<ImageSource?> show(BuildContext context) {
    return BaseBottomSheet.show<ImageSource>(
      context: context,
      builder: (_) => const GroupAvatarSourceBottomSheet(),
    );
  }

  @override
  Widget buildContent(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppListTile(
          leading: Icon(
            Icons.photo_library_outlined,
            color: isDark ? AppColors.iconDarkMode : AppColors.icon,
          ),
          title: context.l10n.gallery,
          onTap: () => Navigator.of(context).pop(ImageSource.gallery),
        ),
        AppListTile(
          leading: Icon(
            Icons.camera_alt_outlined,
            color: isDark ? AppColors.iconDarkMode : AppColors.icon,
          ),
          title: context.l10n.camera,
          onTap: () => Navigator.of(context).pop(ImageSource.camera),
        ),
      ],
    );
  }
}
