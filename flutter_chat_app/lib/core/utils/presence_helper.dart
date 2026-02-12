/// Helper for formatting user presence status
/// Matches Facebook-style presence indicators
class PresenceHelper {
  /// Check if user is currently online (within last 5 minutes)
  static bool isOnline({
    required bool isConnected,
    DateTime? lastSeenAt,
  }) {
    if (!isConnected) return false;
    if (lastSeenAt == null) return true; // Assume online if no timestamp

    final now = DateTime.now();
    final difference = now.difference(lastSeenAt);
    return difference.inMinutes < 5;
  }

  /// Check if user was recently active (5-60 minutes ago)
  static bool isRecentlyActive({
    required bool isConnected,
    DateTime? lastSeenAt,
  }) {
    if (!isConnected || lastSeenAt == null) return false;

    final now = DateTime.now();
    final difference = now.difference(lastSeenAt);
    return difference.inMinutes >= 5 && difference.inMinutes < 60;
  }

  /// Format last seen text (e.g., "Active now", "Active 15m ago", "Active yesterday")
  /// Returns null if user has never been active or too long ago (> 7 days)
  static String? formatLastSeen({
    required bool isConnected,
    DateTime? lastSeenAt,
  }) {
    // If currently online
    if (isOnline(isConnected: isConnected, lastSeenAt: lastSeenAt)) {
      return 'Active now';
    }

    // If not connected or no timestamp, show offline
    if (!isConnected || lastSeenAt == null) {
      return null; // Don't show last seen
    }

    final now = DateTime.now();
    final difference = now.difference(lastSeenAt);

    // Within last hour: "Active 15m ago"
    if (difference.inMinutes < 60) {
      return 'Active ${difference.inMinutes}m ago';
    }

    // Within last 24 hours: "Active 2h ago"
    if (difference.inHours < 24) {
      return 'Active ${difference.inHours}h ago';
    }

    // Yesterday: "Active yesterday"
    if (difference.inDays == 1) {
      return 'Active yesterday';
    }

    // Within last week: "Active 3d ago"
    if (difference.inDays < 7) {
      return 'Active ${difference.inDays}d ago';
    }

    // Older than 7 days: don't show
    return null;
  }

  /// Get presence color (green for online, grey for offline)
  static PresenceStatus getPresenceStatus({
    required bool isConnected,
    DateTime? lastSeenAt,
  }) {
    if (isOnline(isConnected: isConnected, lastSeenAt: lastSeenAt)) {
      return PresenceStatus.online;
    }

    if (isRecentlyActive(isConnected: isConnected, lastSeenAt: lastSeenAt)) {
      return PresenceStatus.away;
    }

    return PresenceStatus.offline;
  }
}

/// User presence status
enum PresenceStatus {
  /// Online (< 5 min) - green dot
  online,

  /// Away (5-60 min) - light green/yellow dot
  away,

  /// Offline (> 60 min) - grey dot
  offline,
}
