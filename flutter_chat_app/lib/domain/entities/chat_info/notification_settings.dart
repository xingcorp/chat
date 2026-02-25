import 'package:equatable/equatable.dart';

/// Thời lượng mute notification
enum MuteDuration {
  /// 1 giờ
  oneHour,

  /// 8 giờ
  eightHours,

  /// 1 ngày
  oneDay,

  /// Vĩnh viễn
  forever,
}

/// Extension để convert MuteDuration sang Duration
extension MuteDurationExtension on MuteDuration {
  Duration? toDuration() {
    switch (this) {
      case MuteDuration.oneHour:
        return const Duration(hours: 1);
      case MuteDuration.eightHours:
        return const Duration(hours: 8);
      case MuteDuration.oneDay:
        return const Duration(days: 1);
      case MuteDuration.forever:
        return null; // null = forever
    }
  }
}

/// Entity cho notification settings của chat
/// Domain layer - Pure Dart, NO Flutter dependencies
class NotificationSettings extends Equatable {
  /// ID của chat
  final String chatId;

  /// Có đang mute không
  final bool isMuted;

  /// Mute đến thời điểm nào (null = forever)
  final DateTime? mutedUntil;

  /// Chỉ thông báo khi được mention
  final bool mentionOnly;

  const NotificationSettings({
    required this.chatId,
    required this.isMuted,
    this.mutedUntil,
    this.mentionOnly = false,
  });

  /// Check xem có đang mute không (kiểm tra cả thời gian)
  bool get isCurrentlyMuted {
    if (!isMuted) return false;
    if (mutedUntil == null) return true; // Muted forever
    return DateTime.now().isBefore(mutedUntil!);
  }

  /// Copy with method
  NotificationSettings copyWith({
    String? chatId,
    bool? isMuted,
    DateTime? mutedUntil,
    bool? mentionOnly,
  }) {
    return NotificationSettings(
      chatId: chatId ?? this.chatId,
      isMuted: isMuted ?? this.isMuted,
      mutedUntil: mutedUntil ?? this.mutedUntil,
      mentionOnly: mentionOnly ?? this.mentionOnly,
    );
  }

  /// Mute với duration cụ thể
  NotificationSettings muteFor(MuteDuration duration) {
    final durationValue = duration.toDuration();
    return copyWith(
      isMuted: true,
      mutedUntil: durationValue != null
          ? DateTime.now().add(durationValue)
          : null, // null = forever
    );
  }

  /// Unmute
  NotificationSettings unmute() {
    return copyWith(
      isMuted: false,
      mutedUntil: null,
    );
  }

  @override
  List<Object?> get props => [chatId, isMuted, mutedUntil, mentionOnly];

  @override
  String toString() {
    return 'NotificationSettings(chatId: $chatId, isMuted: $isMuted, mutedUntil: $mutedUntil)';
  }
}
