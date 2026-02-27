/// **CHAT COMPONENTS**
///
/// Barrel file exporting all chat-specific UI components.
///
/// **Architecture**: Clean Architecture + Design System
/// **Pattern**: Barrel export for clean imports
///
/// **Components**:
/// - AppMessageBubble: Message bubble with multiple content types
/// - AppReplyPreview: Reply preview widget
/// - AppReactionPicker: Emoji reaction picker
/// - AppTypingIndicator: Typing indicator animation
/// - AppVoiceWaveform: Audio waveform visualization
/// - AppReadReceipt: Message read receipt indicators
/// - AppMessageStatus: Message status indicators
///
/// **Usage**:
/// ```dart
/// import 'package:flutter_chat_app/presentation/widgets/design_system/chat/chat.dart';
///
/// // All chat components available
/// AppMessageBubble.text(...)
/// AppReplyPreview(...)
/// AppReactionPicker(...)
/// AppTypingIndicator(...)
/// AppVoiceWaveform(...)
/// AppReadReceipt(...)
/// AppMessageStatus(...)
/// ```
library;

// Components
export 'app_message_bubble.dart';
export 'app_message_status.dart';
export 'app_reaction_picker.dart';
export 'app_read_receipt.dart';
export 'app_reply_preview.dart';
export 'app_typing_indicator.dart';
export 'app_voice_waveform.dart';
export 'read_receipt_avatars.dart';
export 'read_receipt_bottom_sheet.dart';

// Enums
export 'chat_enums.dart';
