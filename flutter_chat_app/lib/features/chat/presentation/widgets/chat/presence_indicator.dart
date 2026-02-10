import 'package:flutter/material.dart';
import 'package:flutter_chat_app/generated/l10n/app_localizations.dart';
import 'package:flutter_chat_app/l10n/l10n.dart';

/// User presence/online status indicator
///
/// Features:
/// - Online: green dot + "Online" text
/// - Offline: grey dot + "Last seen X ago" text
/// - Theme-aware design
/// - i18n support for all status text
/// - Flexible layout (compact or full)
class PresenceIndicator extends StatelessWidget {
  /// Is user currently online
  final bool isOnline;

  /// Last seen timestamp (for offline users)
  final DateTime? lastSeen;

  /// Show text label (Online/Last seen)
  final bool showLabel;

  /// Dot size
  final double dotSize;

  /// Text style
  final TextStyle? textStyle;

  const PresenceIndicator({
    Key? key,
    required this.isOnline,
    this.lastSeen,
    this.showLabel = true,
    this.dotSize = 8.0,
    this.textStyle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;

    final statusColor = isOnline ? Colors.green : Colors.grey;

    if (!showLabel) {
      // Compact mode - dot only
      return Container(
        width: dotSize,
        height: dotSize,
        decoration: BoxDecoration(
          color: statusColor,
          shape: BoxShape.circle,
          border: Border.all(
            color: theme.scaffoldBackgroundColor,
            width: 2.0,
          ),
        ),
      );
    }

    // Full mode - dot + text
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: dotSize,
          height: dotSize,
          decoration: BoxDecoration(
            color: statusColor,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6.0),
        Text(
          _getStatusText(l10n),
          style: textStyle ??
              theme.textTheme.bodySmall?.copyWith(
                color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
              ),
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

    final now = DateTime.now();
    final difference = now.difference(lastSeen!);

    if (difference.inMinutes < 1) {
      return l10n.lastSeenRecently;
    } else if (difference.inMinutes < 60) {
      return l10n.lastSeenMinutesAgo(difference.inMinutes);
    } else if (difference.inHours < 24) {
      return l10n.lastSeenHoursAgo(difference.inHours);
    } else {
      return l10n.lastSeenDaysAgo(difference.inDays);
    }
  }
}

/// Presence indicator specifically for avatar overlay
///
/// Shows a small colored dot at bottom-right of avatar
class AvatarPresenceIndicator extends StatelessWidget {
  /// Is user online
  final bool isOnline;

  /// Size of the presence dot
  final double size;

  /// Position offset from bottom-right
  final double offset;

  const AvatarPresenceIndicator({
    Key? key,
    required this.isOnline,
    this.size = 12.0,
    this.offset = 0.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: offset,
      right: offset,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: isOnline ? Colors.green : Colors.grey,
          shape: BoxShape.circle,
          border: Border.all(
            color: Theme.of(context).scaffoldBackgroundColor,
            width: 2.0,
          ),
        ),
      ),
    );
  }
}

/// Presence indicator with real-time updates
///
/// Connects to WebSocket for real-time presence updates
class LivePresenceIndicator extends StatelessWidget {
  /// User ID to track
  final String userId;

  /// Show text label
  final bool showLabel;

  /// Dot size
  final double dotSize;

  /// Text style
  final TextStyle? textStyle;

  /// TODO: Connect to WebSocket presence stream
  /// For now, just shows static presence based on user data
  const LivePresenceIndicator({
    Key? key,
    required this.userId,
    this.showLabel = true,
    this.dotSize = 8.0,
    this.textStyle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // TODO: StreamBuilder connecting to presence service
    // For now, show offline status
    return PresenceIndicator(
      isOnline: false,
      lastSeen: DateTime.now().subtract(const Duration(minutes: 5)),
      showLabel: showLabel,
      dotSize: dotSize,
      textStyle: textStyle,
    );

    // Future implementation:
    // return StreamBuilder<UserPresence>(
    //   stream: presenceService.getUserPresenceStream(userId),
    //   builder: (context, snapshot) {
    //     if (!snapshot.hasData) {
    //       return PresenceIndicator(
    //         isOnline: false,
    //         showLabel: showLabel,
    //         dotSize: dotSize,
    //         textStyle: textStyle,
    //       );
    //     }
    //
    //     final presence = snapshot.data!;
    //     return PresenceIndicator(
    //       isOnline: presence.isOnline,
    //       lastSeen: presence.lastSeen,
    //       showLabel: showLabel,
    //       dotSize: dotSize,
    //       textStyle: textStyle,
    //     );
    //   },
    // );
  }
}
