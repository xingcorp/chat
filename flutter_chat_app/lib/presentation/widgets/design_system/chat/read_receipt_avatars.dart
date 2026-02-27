import 'package:flutter/material.dart';
import 'package:flutter_chat_app/core/base/base_widget.dart';
import 'package:flutter_chat_app/core/constants/app_dimens.dart';
import 'package:flutter_chat_app/core/theme/app_colors.dart';
import 'package:flutter_chat_app/core/theme/app_text_styles.dart';
import 'package:flutter_chat_app/domain/entities/reader_info.dart';
import 'package:flutter_chat_app/l10n/l10n.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/media/app_avatar.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/typography/app_text.dart';

/// Widget hiển thị avatar nhỏ của người đã đọc bên dưới message bubble.
///
/// - Direct chat: hiển thị 1 avatar
/// - Group chat: hiển thị tối đa [maxAvatars] avatar + badge "+N" khi > 5 readers
/// - Sử dụng [AnimatedSize] cho smooth transition
/// - [GestureDetector] + [onTap] cho group chat
/// - [Semantics] label mô tả danh sách người đã đọc
class ReadReceiptAvatars extends BaseStatelessWidget {
  const ReadReceiptAvatars({
    super.key,
    required this.readers,
    required this.isGroupChat,
    this.maxAvatars = 4,
    this.avatarSize = 16.0,
    this.onTap,
  });

  /// Danh sách reader cần hiển thị avatar
  final List<ReaderInfo> readers;

  /// Có phải group chat hay không
  final bool isGroupChat;

  /// Số avatar tối đa hiển thị trong group chat
  final int maxAvatars;

  /// Kích thước mỗi avatar (dp)
  final double avatarSize;

  /// Callback khi nhấn vào read receipt (group chat)
  final VoidCallback? onTap;

  /// Overlap giữa các avatar = 1/4 kích thước avatar
  double get _overlapOffset => avatarSize * 0.25;

  @override
  Widget buildContent(BuildContext context) {
    if (readers.isEmpty) {
      return const SizedBox.shrink();
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedSize(
      duration: const Duration(milliseconds: AppDimens.durationMedium),
      curve: Curves.easeInOut,
      alignment: Alignment.centerRight,
      child: Padding(
        padding: const EdgeInsets.only(
          top: AppDimens.spaceXSmall,
          right: AppDimens.spaceXSmall,
        ),
        child: _buildContent(context, isDark),
      ),
    );
  }

  Widget _buildContent(BuildContext context, bool isDark) {
    final semanticsLabel = _buildSemanticsLabel(context);
    final avatarRow = isGroupChat
        ? _buildGroupChatAvatars(context, isDark)
        : _buildDirectChatAvatar(context);

    final Widget content = Semantics(
      label: semanticsLabel,
      child: Align(
        alignment: Alignment.centerRight,
        child: avatarRow,
      ),
    );

    if (isGroupChat && onTap != null) {
      return GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: AppDimens.avatarXSmall,
          ),
          child: content,
        ),
      );
    }

    return content;
  }

  Widget _buildDirectChatAvatar(BuildContext context) {
    final reader = readers.first;
    return _buildSingleAvatar(reader);
  }

  Widget _buildGroupChatAvatars(BuildContext context, bool isDark) {
    final showBadge = readers.length > 5;
    final displayCount = showBadge ? maxAvatars : readers.length;
    final displayReaders = readers.take(displayCount).toList();
    final remainingCount = readers.length - maxAvatars;

    final effectiveAvatarWidth = avatarSize - _overlapOffset;
    final children = <Widget>[];

    for (var i = 0; i < displayReaders.length; i++) {
      children.add(
        Positioned(
          left: i * effectiveAvatarWidth,
          child: _buildSingleAvatar(displayReaders[i]),
        ),
      );
    }

    if (showBadge) {
      children.add(
        Positioned(
          left: displayReaders.length * effectiveAvatarWidth,
          child: _buildBadge(context, remainingCount, isDark),
        ),
      );
    }

    // Calculate total width of the overlapping avatars + optional badge
    final avatarsWidth =
        avatarSize + (displayReaders.length - 1) * effectiveAvatarWidth;
    final badgeEstimatedWidth =
        showBadge ? avatarSize + AppDimens.paddingXSmall * 2 : 0.0;
    final totalWidth = showBadge
        ? displayReaders.length * effectiveAvatarWidth + badgeEstimatedWidth
        : avatarsWidth;

    return SizedBox(
      width: totalWidth,
      height: avatarSize,
      child: Stack(
        clipBehavior: Clip.none,
        children: children,
      ),
    );
  }

  Widget _buildSingleAvatar(ReaderInfo reader) {
    final Widget avatar;

    if (reader.avatarUrl != null) {
      avatar = AppAvatar.network(
        imageUrl: reader.avatarUrl ?? '',
        size: AvatarSize.small,
        borderColor: AppColors.surface,
      );
    } else {
      avatar = AppAvatar.initials(
        name: reader.fullName ?? reader.userId,
        size: AvatarSize.small,
        borderColor: AppColors.surface,
      );
    }

    // Scale AppAvatar (smallest enum = 32dp) down to avatarSize (16dp)
    return SizedBox(
      width: avatarSize,
      height: avatarSize,
      child: FittedBox(
        child: avatar,
      ),
    );
  }

  Widget _buildBadge(BuildContext context, int count, bool isDark) {
    final badgeColor = isDark
        ? AppColors.textSecondaryDarkMode
        : AppColors.textSecondary;

    return Container(
      height: avatarSize,
      constraints: BoxConstraints(minWidth: avatarSize),
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimens.paddingXSmall,
      ),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.surfaceDarkMode
            : AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(AppDimens.radiusCircular),
        border: Border.all(
          color: isDark
              ? AppColors.borderDarkMode
              : AppColors.border,
        ),
      ),
      alignment: Alignment.center,
      child: AppText(
        '+$count',
        style: AppTextStyles.caption(color: badgeColor),
      ),
    );
  }

  String _buildSemanticsLabel(BuildContext context) {
    final names = readers
        .where((r) => r.fullName != null)
        .map((r) => r.fullName!)
        .toList();

    if (names.isNotEmpty) {
      return context.l10n.readByNames(names.join(', '));
    }

    return context.l10n.readByCount(readers.length);
  }
}
