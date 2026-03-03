import 'package:flutter/material.dart';
import 'package:flutter_chat_app/core/constants/app_dimens.dart';
import 'package:flutter_chat_app/core/services/presence_service.dart';
import 'package:flutter_chat_app/core/theme/app_colors.dart';
import 'package:flutter_chat_app/core/theme/app_text_styles.dart';
import 'package:flutter_chat_app/domain/entities/user_presence.dart';
import 'package:flutter_chat_app/generated/l10n/app_localizations.dart';
import 'package:flutter_chat_app/l10n/l10n.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/feedback/app_progress_indicator.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/typography/app_text.dart';
import 'package:get_it/get_it.dart';

/// User presence/online status indicator.
class PresenceIndicator extends StatelessWidget {
  final bool isOnline;
  final DateTime? lastSeen;
  final bool showLabel;
  final bool showDot;
  final bool isLoading;
  final double dotSize;
  final TextStyle? textStyle;

  const PresenceIndicator({
    super.key,
    required this.isOnline,
    this.lastSeen,
    this.showLabel = true,
    this.showDot = true,
    this.isLoading = false,
    this.dotSize = AppDimens.spaceSmall,
    this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading && showLabel) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const AppProgressIndicator.circular(size: ProgressSize.small),
          const SizedBox(width: AppDimens.spaceXSmall),
          AppText(
            context.l10n.loading,
            style: _resolveTextStyle(context),
          ),
        ],
      );
    }

    final statusColor = isOnline ? AppColors.success : AppColors.greyDark;
    if (!showLabel) {
      if (!showDot) {
        return const SizedBox.shrink();
      }
      return _PresenceDot(
        color: statusColor,
        dotSize: dotSize,
        showBorder: true,
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (showDot)
          _PresenceDot(
            color: statusColor,
            dotSize: dotSize,
            showBorder: false,
          ),
        if (showDot) const SizedBox(width: AppDimens.spaceXSmall),
        AppText(
          _getStatusText(context.l10n),
          style: _resolveTextStyle(context),
        ),
      ],
    );
  }

  String _getStatusText(AppLocalizations l10n) {
    if (isOnline) {
      return l10n.online;
    }

    if (lastSeen == null) {
      return l10n.offline;
    }

    final difference = DateTime.now().difference(lastSeen!);
    if (difference.inMinutes < 1) {
      return l10n.lastSeenRecently;
    }
    if (difference.inMinutes < 60) {
      return l10n.lastSeenMinutesAgo(difference.inMinutes);
    }
    if (difference.inHours < 24) {
      return l10n.lastSeenHoursAgo(difference.inHours);
    }
    return l10n.lastSeenDaysAgo(difference.inDays);
  }

  TextStyle _resolveTextStyle(BuildContext context) {
    return textStyle ??
        AppTextStyles.bodySmall.copyWith(
          color: AppColors.textSecondary,
        );
  }
}

class _PresenceDot extends StatelessWidget {
  const _PresenceDot({
    required this.color,
    required this.dotSize,
    required this.showBorder,
  });

  final Color color;
  final double dotSize;
  final bool showBorder;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: dotSize,
      height: dotSize,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: showBorder
            ? Border.all(
                color: Theme.of(context).scaffoldBackgroundColor,
                width: 2.0,
              )
            : null,
      ),
    );
  }
}

/// Presence indicator for avatar overlay.
class AvatarPresenceIndicator extends StatelessWidget {
  final bool isOnline;
  final double size;
  final double offset;

  const AvatarPresenceIndicator({
    super.key,
    required this.isOnline,
    this.size = 12.0,
    this.offset = 0.0,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: offset,
      right: offset,
      child: _PresenceDot(
        color: isOnline ? AppColors.success : AppColors.greyDark,
        dotSize: size,
        showBorder: true,
      ),
    );
  }
}

/// Presence indicator connected to real-time `PresenceService`.
class LivePresenceIndicator extends StatelessWidget {
  final String userId;
  final bool showLabel;
  final double dotSize;
  final TextStyle? textStyle;
  final bool showDot;
  final UserPresence? fallbackPresence;
  final Stream<UserPresence>? presenceStream;
  final PresenceService? presenceService;

  const LivePresenceIndicator({
    super.key,
    required this.userId,
    this.showLabel = true,
    this.dotSize = AppDimens.spaceSmall,
    this.textStyle,
    this.showDot = true,
    this.fallbackPresence,
    this.presenceStream,
    this.presenceService,
  });

  @override
  Widget build(BuildContext context) {
    final stream = _resolvePresenceStream();
    if (stream == null) {
      final fallback = fallbackPresence ?? UserPresence.offlineFor(userId);
      return PresenceIndicator(
        isOnline: fallback.isOnline,
        lastSeen: fallback.lastSeen,
        showLabel: showLabel,
        showDot: showDot,
        dotSize: dotSize,
        textStyle: textStyle,
      );
    }

    return StreamBuilder<UserPresence>(
      stream: stream,
      builder: (context, snapshot) {
        final loading = snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData &&
            fallbackPresence == null;

        final presence = snapshot.hasError
            ? (fallbackPresence ?? UserPresence.offlineFor(userId))
            : (snapshot.data ?? fallbackPresence);

        return PresenceIndicator(
          isOnline: presence?.isOnline ?? false,
          lastSeen: presence?.lastSeen,
          showLabel: showLabel,
          showDot: showDot,
          dotSize: dotSize,
          textStyle: textStyle,
          isLoading: loading,
        );
      },
    );
  }

  Stream<UserPresence>? _resolvePresenceStream() {
    if (presenceStream != null) {
      return presenceStream;
    }

    if (presenceService != null) {
      return presenceService!.getUserPresenceStream(userId);
    }

    final getIt = GetIt.instance;
    if (!getIt.isRegistered<PresenceService>()) {
      return null;
    }

    return getIt<PresenceService>().getUserPresenceStream(userId);
  }
}
