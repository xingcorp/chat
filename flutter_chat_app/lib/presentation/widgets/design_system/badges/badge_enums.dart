/// Types of badges.
enum BadgeType {
  /// Notification badge (red).
  notification,

  /// Status badge (uses theme colors).
  status,

  /// Count badge (shows number).
  count,

  /// Dot badge (small indicator).
  dot,
}

/// Types of chips.
enum ChipType {
  /// Filter chip (can be selected).
  filter,

  /// Choice chip (single selection).
  choice,

  /// Action chip (triggers action).
  action,

  /// Input chip (can be deleted).
  input,
}
