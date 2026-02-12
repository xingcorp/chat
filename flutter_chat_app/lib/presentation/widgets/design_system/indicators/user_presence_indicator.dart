import 'package:flutter/material.dart';
import 'package:flutter_chat_app/core/utils/presence_helper.dart';

/// User presence indicator widget (green/yellow/grey dot)
/// Matches Facebook-style online indicator
class UserPresenceIndicator extends StatelessWidget {
  /// Whether user is connected
  final bool isConnected;

  /// Last seen timestamp (optional)
  final DateTime? lastSeenAt;

  /// Size of the indicator dot
  final double size;

  /// Show border around the dot (for overlaying on avatar)
  final bool showBorder;

  const UserPresenceIndicator({
    super.key,
    required this.isConnected,
    this.lastSeenAt,
    this.size = 12.0,
    this.showBorder = true,
  });

  @override
  Widget build(BuildContext context) {
    final status = PresenceHelper.getPresenceStatus(
      isConnected: isConnected,
      lastSeenAt: lastSeenAt,
    );

    Color dotColor;
    switch (status) {
      case PresenceStatus.online:
        dotColor = const Color(0xFF44b700); // Facebook green
        break;
      case PresenceStatus.away:
        dotColor = const Color(0xFFffa500); // Orange/yellow
        break;
      case PresenceStatus.offline:
        dotColor = Colors.grey.shade400;
        break;
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: dotColor,
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

/// User presence badge (overlay on avatar)
class UserPresenceBadge extends StatelessWidget {
  /// Avatar widget to overlay presence indicator on
  final Widget child;

  /// Whether user is connected
  final bool isConnected;

  /// Last seen timestamp (optional)
  final DateTime? lastSeenAt;

  /// Size of the presence dot
  final double indicatorSize;

  const UserPresenceBadge({
    super.key,
    required this.child,
    required this.isConnected,
    this.lastSeenAt,
    this.indicatorSize = 12.0,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        Positioned(
          right: 0,
          bottom: 0,
          child: UserPresenceIndicator(
            isConnected: isConnected,
            lastSeenAt: lastSeenAt,
            size: indicatorSize,
            showBorder: true,
          ),
        ),
      ],
    );
  }
}

/// User presence text (e.g., "Active now", "Active 15m ago")
class UserPresenceText extends StatelessWidget {
  /// Whether user is connected
  final bool isConnected;

  /// Last seen timestamp (optional)
  final DateTime? lastSeenAt;

  /// Text style
  final TextStyle? style;

  const UserPresenceText({
    super.key,
    required this.isConnected,
    this.lastSeenAt,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    final lastSeenText = PresenceHelper.formatLastSeen(
      isConnected: isConnected,
      lastSeenAt: lastSeenAt,
    );

    if (lastSeenText == null) {
      return const SizedBox.shrink();
    }

    final status = PresenceHelper.getPresenceStatus(
      isConnected: isConnected,
      lastSeenAt: lastSeenAt,
    );

    Color textColor;
    switch (status) {
      case PresenceStatus.online:
        textColor = const Color(0xFF44b700); // Green
        break;
      case PresenceStatus.away:
        textColor = Colors.grey.shade600;
        break;
      case PresenceStatus.offline:
        textColor = Colors.grey.shade500;
        break;
    }

    return Text(
      lastSeenText,
      style: style ??
          TextStyle(
            fontSize: 12.0,
            color: textColor,
            fontWeight: status == PresenceStatus.online
                ? FontWeight.w600
                : FontWeight.normal,
          ),
    );
  }
}
