/// Centralized SVG icon asset path registry.
///
/// Uses custom SVG files sourced from Phosphor Icons (MIT License)
/// with **Light** weight (1px stroke) for an Apple-style, premium
/// thin-line aesthetic. Fill variants for active/selected states.
///
/// **Rule: NEVER use `Icons.*` directly in UI code.**
/// Always reference via `AppIcons.*` to ensure consistency.
///
/// Pattern: `Inactive = Light (stroke) → Active = Fill (solid) + Brand Color`
///
/// Usage with [AppIcon] widget:
/// ```dart
/// AppIcon(AppIcons.send, size: 24, color: AppColors.primary)
/// ```
class AppIcons {
  AppIcons._();

  static const String _light = 'assets/icons/light';
  static const String _fill = 'assets/icons/fill';

  // ══════════════════════════════════════════════════════════════════════════
  // BOTTOM NAVIGATION (inactive / active pairs)
  // ══════════════════════════════════════════════════════════════════════════

  /// Chat tab — inactive (outline)
  static const String navChat = '$_light/chat-circle.svg';

  /// Chat tab — active (filled)
  static const String navChatActive = '$_fill/chat-circle.svg';

  /// Contacts tab — inactive
  static const String navContacts = '$_light/users.svg';

  /// Contacts tab — active
  static const String navContactsActive = '$_fill/users.svg';

  /// Settings tab — inactive
  static const String navSettings = '$_light/gear-six.svg';

  /// Settings tab — active
  static const String navSettingsActive = '$_fill/gear-six.svg';

  // ══════════════════════════════════════════════════════════════════════════
  // NAVIGATION / TOOLBAR
  // ══════════════════════════════════════════════════════════════════════════

  /// Back arrow (← AppBar leading)
  static const String arrowBack = '$_light/arrow-left.svg';

  /// Close / dismiss (×)
  static const String close = '$_light/x.svg';

  /// Search magnifying glass
  static const String search = '$_light/magnifying-glass.svg';

  /// Chevron right (list disclosure indicator)
  static const String chevronRight = '$_light/caret-right.svg';

  /// Plus icon (plain)
  static const String add = '$_light/plus.svg';

  /// Plus inside circle (attachment trigger — Zalo-style)
  static const String addCircle = '$_light/plus-circle.svg';

  /// Info / details button
  static const String info = '$_light/info.svg';

  /// Refresh / retry
  static const String refresh = '$_light/arrow-clockwise.svg';

  /// Home
  static const String home = '$_light/house.svg';

  // ══════════════════════════════════════════════════════════════════════════
  // CHAT INPUT
  // ══════════════════════════════════════════════════════════════════════════

  /// Send message (filled for emphasis)
  static const String send = '$_fill/paper-plane-tilt.svg';

  /// Microphone (voice recording — idle state)
  static const String mic = '$_light/microphone.svg';

  /// Emoji / smiley face picker
  static const String emoji = '$_light/smiley.svg';

  /// Attachment paperclip
  static const String attach = '$_light/paperclip.svg';

  // ══════════════════════════════════════════════════════════════════════════
  // MESSAGE ACTIONS
  // ══════════════════════════════════════════════════════════════════════════

  /// Reply to message
  static const String reply = '$_light/arrow-bend-up-left.svg';

  /// Forward message
  static const String forward = '$_light/arrow-bend-up-right.svg';

  /// Copy text
  static const String copy = '$_light/copy.svg';

  /// Edit message
  static const String edit = '$_light/pencil-simple.svg';

  /// Delete message / trash
  static const String delete = '$_light/trash.svg';

  /// More options (⋯)
  static const String moreHoriz = '$_light/dots-three.svg';

  /// Multi-select / checklist
  static const String select = '$_light/check-square.svg';

  /// Thumbs up reaction (inactive)
  static const String thumbUp = '$_light/thumbs-up.svg';

  /// Thumbs up reaction (active/filled)
  static const String thumbUpActive = '$_fill/thumbs-up.svg';

  /// Add reaction (smiley+)
  static const String addReaction = '$_light/smiley-plus.svg';

  // ══════════════════════════════════════════════════════════════════════════
  // ATTACHMENT MENU
  // ══════════════════════════════════════════════════════════════════════════

  /// Photo / image
  static const String photo = '$_light/image.svg';

  /// Video camera
  static const String video = '$_light/video-camera.svg';

  /// File / document
  static const String file = '$_light/file.svg';

  /// Location pin
  static const String location = '$_light/map-pin.svg';

  /// Contact / person (single)
  static const String contact = '$_light/user.svg';

  /// Camera
  static const String camera = '$_light/camera.svg';

  // ══════════════════════════════════════════════════════════════════════════
  // MESSAGE STATUS
  // ══════════════════════════════════════════════════════════════════════════

  /// Pending / clock
  static const String statusPending = '$_light/clock.svg';

  /// Sending (same visual as pending)
  static const String statusSending = '$_light/clock.svg';

  /// Sent — single check
  static const String statusSent = '$_light/check.svg';

  /// Delivered — double check (outline)
  static const String statusDelivered = '$_light/checks.svg';

  /// Read — double check (filled for emphasis)
  static const String statusRead = '$_fill/checks.svg';

  /// Failed — warning circle
  static const String statusFailed = '$_light/warning-circle.svg';

  /// Cancelled
  static const String statusCancelled = '$_light/x-circle.svg';

  /// Conflict / warning
  static const String statusConflict = '$_light/warning.svg';

  /// Draft
  static const String statusDraft = '$_light/pencil-simple.svg';

  /// Blocked / deleted message
  static const String blocked = '$_light/prohibit.svg';

  // ══════════════════════════════════════════════════════════════════════════
  // CONNECTION STATUS
  // ══════════════════════════════════════════════════════════════════════════

  /// WiFi connected
  static const String wifiConnected = '$_light/wifi-high.svg';

  /// Network / long polling
  static const String networkCheck = '$_light/globe.svg';

  /// Cloud off / disconnected
  static const String cloudOff = '$_light/cloud-slash.svg';

  /// Cloud upload
  static const String cloudUpload = '$_light/cloud-arrow-up.svg';

  // ══════════════════════════════════════════════════════════════════════════
  // CONTACTS & MEMBERS
  // ══════════════════════════════════════════════════════════════════════════

  /// Add person / invite member
  static const String personAdd = '$_light/user-plus.svg';

  /// Person outline / view profile
  static const String personOutline = '$_light/user.svg';

  /// Group / users
  static const String group = '$_light/users-three.svg';

  /// Chat bubble with dots (start DM)
  static const String chatBubble = '$_light/chat-circle-dots.svg';

  // ══════════════════════════════════════════════════════════════════════════
  // SETTINGS
  // ══════════════════════════════════════════════════════════════════════════

  /// Notifications bell
  static const String notifications = '$_light/bell.svg';

  /// Language
  static const String language = '$_light/translate.svg';

  /// Dark mode — moon
  static const String darkMode = '$_light/moon.svg';

  /// Light mode — sun
  static const String lightMode = '$_light/sun.svg';

  /// Logout / sign out
  static const String logout = '$_light/sign-out.svg';

  /// System update check
  static const String systemUpdate = '$_light/arrows-clockwise.svg';

  /// Update ready to install
  static const String updateReady = '$_light/download-simple.svg';

  /// Password lock
  static const String lockOutline = '$_light/lock.svg';

  /// About / info
  static const String about = '$_light/info.svg';

  // ══════════════════════════════════════════════════════════════════════════
  // CREATE GROUP
  // ══════════════════════════════════════════════════════════════════════════

  /// Camera for group avatar
  static const String cameraAlt = '$_light/camera.svg';

  /// Notes / description
  static const String notes = '$_light/notepad.svg';

  /// Selected — filled check circle
  static const String checkCircle = '$_fill/check-circle.svg';

  /// Unselected — outline check circle
  static const String checkCircleOutline = '$_light/check-circle.svg';

  /// Remove member — x circle
  static const String removeMember = '$_light/x-circle.svg';

  // ══════════════════════════════════════════════════════════════════════════
  // EMPTY / ERROR STATES
  // ══════════════════════════════════════════════════════════════════════════

  /// Empty chat list
  static const String emptyChat = '$_light/chats-circle.svg';

  /// Empty contacts list
  static const String emptyContacts = '$_light/address-book.svg';

  /// Error / warning circle
  static const String errorOutline = '$_light/warning-circle.svg';

  // ══════════════════════════════════════════════════════════════════════════
  // DESKTOP COMPOSER TOOLBAR
  // ══════════════════════════════════════════════════════════════════════════

  /// Sticker
  static const String sticker = '$_light/sticker.svg';

  /// Image gallery
  static const String imageGallery = '$_light/images.svg';

  /// Screenshot
  static const String screenshot = '$_light/screencast.svg';

  /// Text format toggle
  static const String textFormat = '$_light/text-aa.svg';

  // ══════════════════════════════════════════════════════════════════════════
  // FORMATTING PANEL
  // ══════════════════════════════════════════════════════════════════════════

  /// Bold
  static const String formatBold = '$_light/text-b.svg';

  /// Italic
  static const String formatItalic = '$_light/text-italic.svg';

  /// Underline
  static const String formatUnderline = '$_light/text-underline.svg';

  /// Strikethrough
  static const String formatStrikethrough = '$_light/text-strikethrough.svg';

  /// Bullet list
  static const String formatBulletList = '$_light/list-bullets.svg';

  /// Numbered list
  static const String formatNumberList = '$_light/list-numbers.svg';

  /// Insert link
  static const String formatLink = '$_light/link.svg';

  /// Clear formatting
  static const String formatClear = '$_light/text-t.svg';

  /// Undo
  static const String undo = '$_light/arrow-counter-clockwise.svg';

  /// Redo
  static const String redo = '$_light/arrow-clockwise.svg';

  // ══════════════════════════════════════════════════════════════════════════
  // VOICE RECORDING
  // ══════════════════════════════════════════════════════════════════════════

  /// Microphone active / recording (filled)
  static const String micRecording = '$_fill/microphone.svg';

  /// Delete recording
  static const String deleteRecording = '$_light/trash.svg';

  // ══════════════════════════════════════════════════════════════════════════
  // ADDITIONAL ICONS
  // ══════════════════════════════════════════════════════════════════════════
  
  /// Caret down arrow
  static const String caretDown = '$_light/caret-down.svg';

  /// Phone call / handset (inactive)
  static const String phone = '$_light/phone.svg';

  /// Phone call / handset (active/filled)
  static const String phoneActive = '$_fill/phone.svg';

  /// Vertical three dots (vertical context menu)
  static const String dotsThreeVertical = '$_light/dots-three-vertical.svg';

  /// Stop icon
  static const String stop = '$_light/stop.svg';

  /// Chart / analytics bar
  static const String chartBar = '$_light/chart-bar.svg';

  /// Palette / theme selection
  static const String palette = '$_light/palette.svg';

  /// Gauge / speed indicator
  static const String gauge = '$_light/gauge.svg';

  /// CPU / memory / hardware info
  static const String cpu = '$_light/cpu.svg';

  /// Bug / bug report
  static const String bug = '$_light/bug.svg';

  /// Text align right / text direction format
  static const String textAlignRight = '$_light/text-align-right.svg';

  /// Calendar / date
  static const String calendar = '$_light/calendar.svg';

  /// Chat text / SMS indicator
  static const String chatText = '$_light/chat-text.svg';

  /// Fingerprint / biometric
  static const String fingerprint = '$_light/fingerprint.svg';

  /// Bluetooth
  static const String bluetooth = '$_light/bluetooth.svg';

  /// Play triangle
  static const String play = '$_light/play.svg';

  /// Play circle (inactive)
  static const String playCircle = '$_light/play-circle.svg';

  /// Play circle (active/filled)
  static const String playCircleActive = '$_fill/play-circle.svg';

  /// Open in new window/tab
  static const String openInNew = '$_light/arrow-square-out.svg';

  /// Audio / music track
  static const String audioTrack = '$_light/music-notes.svg';

  /// PDF document file
  static const String filePdf = '$_light/file-pdf.svg';

  /// Security shield
  static const String security = '$_light/shield.svg';

  /// Help / question indicator
  static const String help = '$_light/question.svg';

  /// WiFi disconnected
  static const String wifiOff = '$_light/wifi-slash.svg';

  /// Login / sign in
  static const String login = '$_light/sign-in.svg';

  /// Lightning / offline bolt
  static const String lightning = '$_light/lightning.svg';

  /// Support / agent headset
  static const String support = '$_light/headset.svg';

  /// Storage / hard drive
  static const String storage = '$_light/hard-drive.svg';

  /// Lightbulb / tip idea
  static const String lightbulb = '$_light/lightbulb.svg';
}
