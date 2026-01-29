// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Flutter Chat App';

  @override
  String get ok => 'OK';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get delete => 'Delete';

  @override
  String get edit => 'Edit';

  @override
  String get loading => 'Loading...';

  @override
  String get errorOccurred => 'An error occurred';

  @override
  String get retry => 'Retry';

  @override
  String get send => 'Send';

  @override
  String get close => 'Close';

  @override
  String get login => 'Login';

  @override
  String get logout => 'Logout';

  @override
  String get register => 'Register';

  @override
  String get forgotPassword => 'Forgot Password';

  @override
  String get username => 'Username';

  @override
  String get password => 'Password';

  @override
  String get email => 'Email';

  @override
  String get confirmPassword => 'Confirm Password';

  @override
  String get newMessage => 'New Message';

  @override
  String get typeMessage => 'Type a message...';

  @override
  String get noMessages => 'No messages yet';

  @override
  String get loadMore => 'Load More';

  @override
  String get yesterday => 'Yesterday';

  @override
  String sentAt(String time) {
    return 'Sent at $time';
  }

  @override
  String get today => 'Today';

  @override
  String get online => 'Online';

  @override
  String get offline => 'Offline';

  @override
  String get connecting => 'Connecting...';

  @override
  String get reconnecting => 'Reconnecting...';

  @override
  String messageCount(int count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.compact(
      locale: localeName,
      
    );
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString messages',
      one: '1 message',
      zero: 'No messages',
    );
    return '$_temp0';
  }

  @override
  String lastSeen(String time) {
    return 'Last seen $time';
  }

  @override
  String get settingsTitle => 'Settings';

  @override
  String get profileSettings => 'Profile';

  @override
  String get chatSettings => 'Chat Settings';

  @override
  String get notificationSettings => 'Notifications';

  @override
  String get languageSettings => 'Language';

  @override
  String get aboutSettings => 'About';

  @override
  String get systemDefault => 'System Default';

  @override
  String get selectLanguage => 'Select Language';

  @override
  String get languageChanged => 'Language changed successfully';

  @override
  String get poorConnection => 'Poor connection';

  @override
  String get goodConnection => 'Good connection';

  @override
  String get excellentConnection => 'Excellent connection';

  @override
  String get testData => 'Test Data';

  @override
  String get createTestData => 'Create Test Data';

  @override
  String get clearData => 'Clear Data';

  @override
  String get dataCleared => 'Data cleared';

  @override
  String get users => 'Users';

  @override
  String get chats => 'Chats';

  @override
  String get messages => 'Messages';

  @override
  String get noUsers => 'No users yet';

  @override
  String get noChats => 'No chats yet';

  @override
  String get connectionError => 'Connection error';

  @override
  String get databaseError => 'Database error';

  @override
  String get syncError => 'Sync error';

  @override
  String get uploadError => 'Upload error';

  @override
  String get downloadError => 'Download error';

  @override
  String get themeSettings => 'Theme';

  @override
  String get lightTheme => 'Light';

  @override
  String get darkTheme => 'Dark';

  @override
  String get systemTheme => 'System';

  @override
  String get themeChanged => 'Theme changed successfully';

  @override
  String get appearance => 'Appearance';

  @override
  String get general => 'General';

  @override
  String get privacy => 'Privacy';

  @override
  String get security => 'Security';

  @override
  String get help => 'Help';

  @override
  String get feedback => 'Feedback';

  @override
  String get version => 'Version';

  @override
  String get account => 'Account';

  @override
  String get profile => 'Profile';

  @override
  String get avatar => 'Avatar';

  @override
  String get displayName => 'Display Name';

  @override
  String get bio => 'Bio';

  @override
  String get accessibility => 'Accessibility';

  @override
  String get fontSize => 'Font Size';

  @override
  String get animations => 'Animations';

  @override
  String get pleaseEnterGroupName => 'Please enter group name';

  @override
  String get pleaseSelectMembers => 'Please select at least one member';

  @override
  String get createNewGroup => 'Create New Group';

  @override
  String get create => 'Create';

  @override
  String get dontHaveAccount => 'Don\'t have an account?';

  @override
  String chatTitle(String chatId) {
    return 'Chat $chatId';
  }

  @override
  String get comingSoon => 'Coming Soon';

  @override
  String get viewInfo => 'View Info';

  @override
  String get groupName => 'Group Name';

  @override
  String get members => 'Members';

  @override
  String get addMembers => 'Add Members';

  @override
  String get search => 'Search';

  @override
  String get muteNotifications => 'Mute Notifications';

  @override
  String memberCount(int count) {
    return '$count members';
  }

  @override
  String get typing => 'Typing...';

  @override
  String get seen => 'Seen';

  @override
  String get sent => 'Sent';

  @override
  String get sending => 'Sending...';

  @override
  String get cannotLoadMessages => 'Cannot load messages';

  @override
  String get justNow => 'Just now';

  @override
  String minutesAgo(int minutes) {
    return '$minutes minutes ago';
  }

  @override
  String hoursAgo(int hours) {
    return '$hours hours ago';
  }

  @override
  String get reply => 'Reply';

  @override
  String get forward => 'Forward';

  @override
  String get confirmDelete => 'Are you sure you want to delete this message?';

  @override
  String get contacts => 'Contacts';

  @override
  String get groups => 'Groups';

  @override
  String get welcomeToChat => 'Welcome to Flutter Chat App';

  @override
  String get errorNoInternet => 'No internet connection. Please check your network.';

  @override
  String get errorServer => 'Server error. Please try again later.';

  @override
  String get errorCache => 'Failed to load cached data.';

  @override
  String get errorUnexpected => 'An unexpected error occurred. Please try again.';

  @override
  String get errorValidation => 'Invalid input. Please check your data.';

  @override
  String get loadingConversations => 'Loading conversations...';

  @override
  String get loadingMessages => 'Loading messages...';

  @override
  String get sendingMessage => 'Sending message...';

  @override
  String get creatingGroup => 'Creating group...';

  @override
  String get updatingGroup => 'Updating group...';

  @override
  String get deletingConversation => 'Deleting conversation...';

  @override
  String get leavingConversation => 'Leaving conversation...';

  @override
  String get noConversations => 'No conversations yet. Start a new chat!';

  @override
  String get noMessagesInChat => 'No messages yet. Send the first message!';

  @override
  String get noSearchResults => 'No results found for your search.';

  @override
  String get messageEmpty => 'Message cannot be empty';

  @override
  String get nameRequired => 'Name is required';

  @override
  String get membersRequired => 'Please select at least one member';

  @override
  String get conversationIdRequired => 'Conversation ID is required';

  @override
  String get messageIdRequired => 'Message ID is required';

  @override
  String get invalidPageSize => 'Page size must be between 1 and 100';

  @override
  String get invalidPageNumber => 'Page number must be 0 or greater';

  @override
  String get invalidReadCount => 'Read count must be greater than 0';

  @override
  String get retryOperation => 'Retry';

  @override
  String get pullToRefresh => 'Pull to refresh';

  @override
  String get releaseToRefresh => 'Release to refresh';

  @override
  String get refreshing => 'Refreshing...';

  @override
  String get loadingMore => 'Loading more...';

  @override
  String get syncing => 'Syncing...';

  @override
  String get edited => 'Edited';

  @override
  String get deleted => 'This message was deleted';

  @override
  String get you => 'You';

  @override
  String get admin => 'Admin';

  @override
  String get leaveGroup => 'Leave Group';

  @override
  String get deleteConversation => 'Delete Conversation';

  @override
  String get editGroup => 'Edit Group';

  @override
  String get groupInfo => 'Group Info';

  @override
  String get conversationDeleted => 'Conversation deleted successfully';

  @override
  String get leftConversation => 'You left the conversation';

  @override
  String get groupCreated => 'Group created successfully';

  @override
  String get groupCreatedSuccessfully => 'Group created successfully';

  @override
  String get groupUpdated => 'Group updated successfully';

  @override
  String get messageSent => 'Message sent';

  @override
  String get messageEdited => 'Message edited';

  @override
  String get messageDeleted => 'Message deleted';

  @override
  String get confirmLeaveGroup => 'Are you sure you want to leave this group?';

  @override
  String get confirmDeleteConversation => 'Are you sure you want to delete this conversation?';

  @override
  String get searchConversations => 'Search conversations...';

  @override
  String get searchMessages => 'Search messages...';

  @override
  String get selectMembers => 'Select Members';

  @override
  String get groupDescription => 'Group Description';

  @override
  String get optional => 'Optional';

  @override
  String get required => 'Required';

  @override
  String get addPhoto => 'Add Photo';

  @override
  String get changePhoto => 'Change Photo';

  @override
  String get removePhoto => 'Remove Photo';

  @override
  String get camera => 'Camera';

  @override
  String get gallery => 'Gallery';

  @override
  String get file => 'File';

  @override
  String get attachFile => 'Attach File';

  @override
  String replyTo(String name) {
    return 'Reply to $name';
  }

  @override
  String get forwardedMessage => 'Forwarded message';

  @override
  String mentionedYou(String name) {
    return '$name mentioned you';
  }

  @override
  String unreadMessages(int count) {
    return '$count unread messages';
  }

  @override
  String get markAsRead => 'Mark as read';

  @override
  String get markAsUnread => 'Mark as unread';

  @override
  String get copyMessage => 'Copy message';

  @override
  String get editMessage => 'Edit message';

  @override
  String get deleteMessage => 'Delete message';

  @override
  String get forwardMessage => 'Forward message';

  @override
  String get replyMessage => 'Reply to message';

  @override
  String get reactToMessage => 'React to message';

  @override
  String get messageCopied => 'Message copied to clipboard';

  @override
  String get offlineMode => 'You are offline. Messages will be sent when you reconnect.';

  @override
  String get syncingMessages => 'Syncing messages...';

  @override
  String get messageQueued => 'Message queued for sending';

  @override
  String get operationQueued => 'Operation queued. Will be processed when online.';

  @override
  String get backOnline => 'Back online. Syncing...';

  @override
  String get connectionLost => 'Connection lost. Working offline.';

  @override
  String get buttonLoading => 'Loading...';

  @override
  String get buttonDisabled => 'Button disabled';

  @override
  String get primaryButton => 'Primary button';

  @override
  String get secondaryButton => 'Secondary button';

  @override
  String get textButton => 'Text button';

  @override
  String get outlinedButton => 'Outlined button';

  @override
  String get iconButton => 'Icon button';

  @override
  String get floatingActionButton => 'Floating action button';

  @override
  String get showPassword => 'Show password';

  @override
  String get hidePassword => 'Hide password';

  @override
  String get clearSearch => 'Clear search';

  @override
  String get enterText => 'Enter text';

  @override
  String characterCount(int current, int max) {
    return '$current / $max characters';
  }

  @override
  String get validationRequired => 'This field is required';

  @override
  String get validationEmail => 'Please enter a valid email address';

  @override
  String validationMinLength(int length) {
    return 'Must be at least $length characters';
  }

  @override
  String validationMaxLength(int length) {
    return 'Must be no more than $length characters';
  }

  @override
  String get tapToSelect => 'Tap to select';

  @override
  String get doubleTapToOpen => 'Double tap to open';

  @override
  String get noItemsFound => 'No items found';

  @override
  String get noItemsDescription => 'There are no items to display';

  @override
  String get noInternetConnection => 'No Internet Connection';

  @override
  String get checkInternetConnection => 'Please check your internet connection and try again';

  @override
  String get selectOption => 'Select an option';

  @override
  String get enabled => 'Enabled';

  @override
  String get disabled => 'Disabled';

  @override
  String get value => 'Value';

  @override
  String get range => 'Range';

  @override
  String get minimum => 'Minimum';

  @override
  String get maximum => 'Maximum';

  @override
  String get searchPlaceholder => 'Search...';

  @override
  String get noResults => 'No results found';

  @override
  String get selectDate => 'Select Date';

  @override
  String get invalidDate => 'Invalid date';

  @override
  String get selectTime => 'Select Time';

  @override
  String get invalidTime => 'Invalid time';

  @override
  String get rating => 'Rating';

  @override
  String get rateThis => 'Rate this';

  @override
  String stars(int count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.compact(
      locale: localeName,
      
    );
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString stars',
      one: '1 star',
    );
    return '$_temp0';
  }

  @override
  String get fieldRequired => 'This field is required';

  @override
  String get invalidInput => 'Invalid input';

  @override
  String get checked => 'Checked';

  @override
  String get unchecked => 'Unchecked';

  @override
  String get indeterminate => 'Indeterminate';

  @override
  String get selected => 'Selected';

  @override
  String get unselected => 'Unselected';

  @override
  String get slider => 'Slider';

  @override
  String get outOf => 'out of';

  @override
  String get volume => 'Volume';

  @override
  String get messageBubble => 'Message bubble';

  @override
  String get textMessage => 'Text message';

  @override
  String get imageMessage => 'Image message';

  @override
  String get videoMessage => 'Video message';

  @override
  String get audioMessage => 'Audio message';

  @override
  String get fileMessage => 'File message';

  @override
  String get locationMessage => 'Location message';

  @override
  String get contactMessage => 'Contact message';

  @override
  String get systemMessage => 'System message';

  @override
  String get delivered => 'Delivered';

  @override
  String get read => 'Read';

  @override
  String get failed => 'Failed';

  @override
  String get pending => 'Pending';

  @override
  String replyingTo(String author) {
    return 'Replying to $author';
  }

  @override
  String get cancelReply => 'Cancel reply';

  @override
  String get voiceMessage => 'Voice message';

  @override
  String get photo => 'Photo';

  @override
  String get video => 'Video';

  @override
  String get audio => 'Audio';

  @override
  String get document => 'Document';

  @override
  String get location => 'Location';

  @override
  String get contact => 'Contact';

  @override
  String get addReaction => 'Add reaction';

  @override
  String get removeReaction => 'Remove reaction';

  @override
  String get reactions => 'Reactions';

  @override
  String get recentlyUsed => 'Recently used';

  @override
  String get searchEmoji => 'Search emoji';

  @override
  String get smileysAndPeople => 'Smileys & People';

  @override
  String get gesturesAndBodyParts => 'Gestures & Body Parts';

  @override
  String get peopleAndProfessions => 'People & Professions';

  @override
  String get animalsAndNature => 'Animals & Nature';

  @override
  String get foodAndDrink => 'Food & Drink';

  @override
  String get activitiesAndSports => 'Activities & Sports';

  @override
  String get activity => 'Activity';

  @override
  String get travelAndPlaces => 'Travel & Places';

  @override
  String get objects => 'Objects';

  @override
  String get symbols => 'Symbols';

  @override
  String get flags => 'Flags';

  @override
  String get noEmojisFound => 'No emojis found';

  @override
  String isTyping(String name) {
    return '$name is typing...';
  }

  @override
  String areTyping(String name1, String name2) {
    return '$name1 and $name2 are typing...';
  }

  @override
  String multipleTyping(String name, int count) {
    return '$name and $count others are typing...';
  }

  @override
  String get play => 'Play';

  @override
  String get pause => 'Pause';

  @override
  String get stop => 'Stop';

  @override
  String get playbackSpeed => 'Playback Speed';

  @override
  String get duration => 'Duration';

  @override
  String get currentTime => 'Current time';

  @override
  String get loadingAudio => 'Loading audio...';

  @override
  String get remainingTime => 'Remaining time';

  @override
  String get recording => 'Recording...';

  @override
  String get recordVoiceMessage => 'Record voice message';

  @override
  String get sendVoiceMessage => 'Send voice message';

  @override
  String get cancelRecording => 'Cancel recording';

  @override
  String get longPressToRecord => 'Long press to record';

  @override
  String get slideToCancel => 'Slide to cancel';

  @override
  String get releaseToSend => 'Release to send';

  @override
  String get messageOptions => 'Message options';

  @override
  String get longPressForOptions => 'Long press for options';

  @override
  String get tapToView => 'Tap to view';

  @override
  String get tapToDownload => 'Tap to download';

  @override
  String get downloading => 'Downloading...';

  @override
  String get downloaded => 'Downloaded';

  @override
  String get downloadFailed => 'Download failed';

  @override
  String get uploadFailed => 'Upload failed';

  @override
  String get uploading => 'Uploading...';

  @override
  String get uploaded => 'Uploaded';

  @override
  String get retryUpload => 'Retry upload';

  @override
  String get retryDownload => 'Retry download';

  @override
  String get cancelUpload => 'Cancel upload';

  @override
  String get cancelDownload => 'Cancel download';

  @override
  String get fileSize => 'File size';

  @override
  String get fileName => 'File name';

  @override
  String get fileType => 'File type';

  @override
  String get unsupportedFileType => 'Unsupported file type';

  @override
  String fileTooLarge(String fileName, String maxSize) {
    return '$fileName is too large. Maximum size is $maxSize';
  }

  @override
  String maxFileSize(String size) {
    return 'Max file size: $size';
  }

  @override
  String get tapToRetry => 'Tap to retry';

  @override
  String get sortAscending => 'Sort ascending';

  @override
  String get sortDescending => 'Sort descending';

  @override
  String get filterColumn => 'Filter column';

  @override
  String get clearFilter => 'Clear filter';

  @override
  String get selectAll => 'Select all';

  @override
  String get deselectAll => 'Deselect all';

  @override
  String selectedItems(int count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.compact(
      locale: localeName,
      
    );
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString items selected',
      one: '1 item selected',
      zero: 'No items selected',
    );
    return '$_temp0';
  }

  @override
  String get noDataAvailable => 'No data available';

  @override
  String get rowsPerPage => 'Rows per page';

  @override
  String pageOf(int current, int total) {
    return 'Page $current of $total';
  }

  @override
  String get firstPage => 'First page';

  @override
  String get previousPage => 'Previous page';

  @override
  String get nextPage => 'Next page';

  @override
  String get lastPage => 'Last page';

  @override
  String get dropFilesHere => 'Drop files here';

  @override
  String get dragDropOrClickToUpload => 'Drag & drop files here or click to browse';

  @override
  String get maxFilesReached => 'Maximum number of files reached';

  @override
  String allowedFileTypes(String types) {
    return 'Allowed types: $types';
  }

  @override
  String get errorPickingFiles => 'Error picking files';

  @override
  String fileTypeNotAllowed(String fileName) {
    return '$fileName file type is not allowed';
  }

  @override
  String get remove => 'Remove';

  @override
  String get noImagesAvailable => 'No images available';

  @override
  String get share => 'Share';

  @override
  String get download => 'Download';

  @override
  String get errorLoadingVideo => 'Error loading video';

  @override
  String get quality => 'Quality';

  @override
  String get pictureInPicture => 'Picture in Picture';

  @override
  String get enterFullscreen => 'Enter Fullscreen';

  @override
  String get exitFullscreen => 'Exit Fullscreen';
}
