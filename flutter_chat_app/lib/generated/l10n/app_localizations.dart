import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_vi.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('vi')
  ];

  /// The title of the application
  ///
  /// In en, this message translates to:
  /// **'Flutter Chat App'**
  String get appTitle;

  /// OK button text
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// Cancel button text
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// Save button text
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// Delete button text
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// Edit button text
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// Loading indicator text
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// Generic error message
  ///
  /// In en, this message translates to:
  /// **'An error occurred'**
  String get errorOccurred;

  /// Retry button text
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// Send button text
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get send;

  /// Close button text
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// Login button text
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// Logout button text
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// Register button text
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get register;

  /// Forgot password button text
  ///
  /// In en, this message translates to:
  /// **'Forgot Password'**
  String get forgotPassword;

  /// Username field label
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get username;

  /// Password field label
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// Email field label
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// Confirm password field label
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmPassword;

  /// New message title
  ///
  /// In en, this message translates to:
  /// **'New Message'**
  String get newMessage;

  /// Placeholder text for message input
  ///
  /// In en, this message translates to:
  /// **'Type a message...'**
  String get typeMessage;

  /// Text shown when there are no messages
  ///
  /// In en, this message translates to:
  /// **'No messages yet'**
  String get noMessages;

  /// Load more button text
  ///
  /// In en, this message translates to:
  /// **'Load More'**
  String get loadMore;

  /// Yesterday text
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get yesterday;

  /// Today text
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// Online status
  ///
  /// In en, this message translates to:
  /// **'Online'**
  String get online;

  /// Offline status message
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get offline;

  /// Connecting status
  ///
  /// In en, this message translates to:
  /// **'Connecting...'**
  String get connecting;

  /// Reconnection status
  ///
  /// In en, this message translates to:
  /// **'Reconnecting...'**
  String get reconnecting;

  /// Message count with pluralization
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No messages} =1{1 message} other{{count} messages}}'**
  String messageCount(int count);

  /// Last seen with time
  ///
  /// In en, this message translates to:
  /// **'Last seen {time}'**
  String lastSeen(String time);

  /// Settings page title
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// Profile settings option
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profileSettings;

  /// Chat settings option
  ///
  /// In en, this message translates to:
  /// **'Chat Settings'**
  String get chatSettings;

  /// Notification settings option
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notificationSettings;

  /// Language settings option
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageSettings;

  /// About settings option
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get aboutSettings;

  /// System default language option
  ///
  /// In en, this message translates to:
  /// **'System Default'**
  String get systemDefault;

  /// Language selection title
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get selectLanguage;

  /// Message shown when language is changed
  ///
  /// In en, this message translates to:
  /// **'Language changed successfully'**
  String get languageChanged;

  /// Poor connection status
  ///
  /// In en, this message translates to:
  /// **'Poor connection'**
  String get poorConnection;

  /// Good connection status
  ///
  /// In en, this message translates to:
  /// **'Good connection'**
  String get goodConnection;

  /// Excellent connection status
  ///
  /// In en, this message translates to:
  /// **'Excellent connection'**
  String get excellentConnection;

  /// Test data title
  ///
  /// In en, this message translates to:
  /// **'Test Data'**
  String get testData;

  /// Create test data button text
  ///
  /// In en, this message translates to:
  /// **'Create Test Data'**
  String get createTestData;

  /// Clear data button text
  ///
  /// In en, this message translates to:
  /// **'Clear Data'**
  String get clearData;

  /// Message shown when data is cleared
  ///
  /// In en, this message translates to:
  /// **'Data cleared'**
  String get dataCleared;

  /// Users title
  ///
  /// In en, this message translates to:
  /// **'Users'**
  String get users;

  /// Chats section title
  ///
  /// In en, this message translates to:
  /// **'Chats'**
  String get chats;

  /// Messages title
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get messages;

  /// No users message
  ///
  /// In en, this message translates to:
  /// **'No users yet'**
  String get noUsers;

  /// No chats message
  ///
  /// In en, this message translates to:
  /// **'No chats yet'**
  String get noChats;

  /// Connection error message
  ///
  /// In en, this message translates to:
  /// **'Connection error'**
  String get connectionError;

  /// Database error message
  ///
  /// In en, this message translates to:
  /// **'Database error'**
  String get databaseError;

  /// Sync error message
  ///
  /// In en, this message translates to:
  /// **'Sync error'**
  String get syncError;

  /// Upload error message
  ///
  /// In en, this message translates to:
  /// **'Upload error'**
  String get uploadError;

  /// Download error message
  ///
  /// In en, this message translates to:
  /// **'Download error'**
  String get downloadError;

  /// Theme settings option
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get themeSettings;

  /// Light theme option
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get lightTheme;

  /// Dark theme option
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get darkTheme;

  /// System theme option
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get systemTheme;

  /// Message shown when theme is changed
  ///
  /// In en, this message translates to:
  /// **'Theme changed successfully'**
  String get themeChanged;

  /// Appearance settings section
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// General settings section
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get general;

  /// Privacy settings section
  ///
  /// In en, this message translates to:
  /// **'Privacy'**
  String get privacy;

  /// Security settings section
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get security;

  /// Help settings section
  ///
  /// In en, this message translates to:
  /// **'Help'**
  String get help;

  /// Feedback settings option
  ///
  /// In en, this message translates to:
  /// **'Feedback'**
  String get feedback;

  /// Version information
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get version;

  /// Account settings section
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get account;

  /// Profile settings section
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// Avatar settings option
  ///
  /// In en, this message translates to:
  /// **'Avatar'**
  String get avatar;

  /// Display name field
  ///
  /// In en, this message translates to:
  /// **'Display Name'**
  String get displayName;

  /// Bio field
  ///
  /// In en, this message translates to:
  /// **'Bio'**
  String get bio;

  /// Accessibility settings section
  ///
  /// In en, this message translates to:
  /// **'Accessibility'**
  String get accessibility;

  /// Font size setting
  ///
  /// In en, this message translates to:
  /// **'Font Size'**
  String get fontSize;

  /// Animations setting
  ///
  /// In en, this message translates to:
  /// **'Animations'**
  String get animations;

  /// Validation message for empty group name
  ///
  /// In en, this message translates to:
  /// **'Please enter group name'**
  String get pleaseEnterGroupName;

  /// Validation message for no selected members
  ///
  /// In en, this message translates to:
  /// **'Please select at least one member'**
  String get pleaseSelectMembers;

  /// Create group page title
  ///
  /// In en, this message translates to:
  /// **'Create New Group'**
  String get createNewGroup;

  /// Create button text
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get create;

  /// Text asking if user doesn't have account
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account?'**
  String get dontHaveAccount;

  /// Chat page title with ID
  ///
  /// In en, this message translates to:
  /// **'Chat {chatId}'**
  String chatTitle(String chatId);

  /// Coming soon placeholder text
  ///
  /// In en, this message translates to:
  /// **'Coming Soon'**
  String get comingSoon;

  /// View information button text
  ///
  /// In en, this message translates to:
  /// **'View Info'**
  String get viewInfo;

  /// Group name label
  ///
  /// In en, this message translates to:
  /// **'Group Name'**
  String get groupName;

  /// Members label
  ///
  /// In en, this message translates to:
  /// **'Members'**
  String get members;

  /// Add members button text
  ///
  /// In en, this message translates to:
  /// **'Add Members'**
  String get addMembers;

  /// Search button text
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// Mute notifications option
  ///
  /// In en, this message translates to:
  /// **'Mute Notifications'**
  String get muteNotifications;

  /// Number of members in group
  ///
  /// In en, this message translates to:
  /// **'{count} members'**
  String memberCount(int count);

  /// Typing indicator text
  ///
  /// In en, this message translates to:
  /// **'Typing...'**
  String get typing;

  /// Message seen status
  ///
  /// In en, this message translates to:
  /// **'Seen'**
  String get seen;

  /// Message sent status
  ///
  /// In en, this message translates to:
  /// **'Sent'**
  String get sent;

  /// Message sending status
  ///
  /// In en, this message translates to:
  /// **'Sending...'**
  String get sending;

  /// Error when messages fail to load
  ///
  /// In en, this message translates to:
  /// **'Cannot load messages'**
  String get cannotLoadMessages;

  /// Time indicator for recent messages
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get justNow;

  /// Time indicator for minutes
  ///
  /// In en, this message translates to:
  /// **'{minutes} minutes ago'**
  String minutesAgo(int minutes);

  /// Time indicator for hours
  ///
  /// In en, this message translates to:
  /// **'{hours} hours ago'**
  String hoursAgo(int hours);

  /// Reply to message action
  ///
  /// In en, this message translates to:
  /// **'Reply'**
  String get reply;

  /// Forward message action
  ///
  /// In en, this message translates to:
  /// **'Forward'**
  String get forward;

  /// Confirmation dialog for deleting message
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this message?'**
  String get confirmDelete;

  /// Contacts section title
  ///
  /// In en, this message translates to:
  /// **'Contacts'**
  String get contacts;

  /// Groups section title
  ///
  /// In en, this message translates to:
  /// **'Groups'**
  String get groups;

  /// Welcome message on home screen
  ///
  /// In en, this message translates to:
  /// **'Welcome to Flutter Chat App'**
  String get welcomeToChat;

  /// Error message when there is no internet connection
  ///
  /// In en, this message translates to:
  /// **'No internet connection. Please check your network.'**
  String get errorNoInternet;

  /// Error message when server returns an error
  ///
  /// In en, this message translates to:
  /// **'Server error. Please try again later.'**
  String get errorServer;

  /// Error message when cache operation fails
  ///
  /// In en, this message translates to:
  /// **'Failed to load cached data.'**
  String get errorCache;

  /// Error message for unexpected errors
  ///
  /// In en, this message translates to:
  /// **'An unexpected error occurred. Please try again.'**
  String get errorUnexpected;

  /// Error message for validation errors
  ///
  /// In en, this message translates to:
  /// **'Invalid input. Please check your data.'**
  String get errorValidation;

  /// Loading message when fetching conversations
  ///
  /// In en, this message translates to:
  /// **'Loading conversations...'**
  String get loadingConversations;

  /// Loading message when fetching messages
  ///
  /// In en, this message translates to:
  /// **'Loading messages...'**
  String get loadingMessages;

  /// Loading message when sending a message
  ///
  /// In en, this message translates to:
  /// **'Sending message...'**
  String get sendingMessage;

  /// Loading message when creating a group
  ///
  /// In en, this message translates to:
  /// **'Creating group...'**
  String get creatingGroup;

  /// Loading message when updating a group
  ///
  /// In en, this message translates to:
  /// **'Updating group...'**
  String get updatingGroup;

  /// Loading message when deleting a conversation
  ///
  /// In en, this message translates to:
  /// **'Deleting conversation...'**
  String get deletingConversation;

  /// Loading message when leaving a conversation
  ///
  /// In en, this message translates to:
  /// **'Leaving conversation...'**
  String get leavingConversation;

  /// Empty state message when there are no conversations
  ///
  /// In en, this message translates to:
  /// **'No conversations yet. Start a new chat!'**
  String get noConversations;

  /// Empty state message when there are no messages in a chat
  ///
  /// In en, this message translates to:
  /// **'No messages yet. Send the first message!'**
  String get noMessagesInChat;

  /// Empty state message when search returns no results
  ///
  /// In en, this message translates to:
  /// **'No results found for your search.'**
  String get noSearchResults;

  /// Validation message when message is empty
  ///
  /// In en, this message translates to:
  /// **'Message cannot be empty'**
  String get messageEmpty;

  /// Validation message when name field is empty
  ///
  /// In en, this message translates to:
  /// **'Name is required'**
  String get nameRequired;

  /// Validation message when no members are selected
  ///
  /// In en, this message translates to:
  /// **'Please select at least one member'**
  String get membersRequired;

  /// Validation message when conversation ID is missing
  ///
  /// In en, this message translates to:
  /// **'Conversation ID is required'**
  String get conversationIdRequired;

  /// Validation message when message ID is missing
  ///
  /// In en, this message translates to:
  /// **'Message ID is required'**
  String get messageIdRequired;

  /// Validation message for invalid page size
  ///
  /// In en, this message translates to:
  /// **'Page size must be between 1 and 100'**
  String get invalidPageSize;

  /// Validation message for invalid page number
  ///
  /// In en, this message translates to:
  /// **'Page number must be 0 or greater'**
  String get invalidPageNumber;

  /// Validation message for invalid read count
  ///
  /// In en, this message translates to:
  /// **'Read count must be greater than 0'**
  String get invalidReadCount;

  /// Button text to retry a failed operation
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retryOperation;

  /// Pull to refresh instruction
  ///
  /// In en, this message translates to:
  /// **'Pull to refresh'**
  String get pullToRefresh;

  /// Release to refresh instruction
  ///
  /// In en, this message translates to:
  /// **'Release to refresh'**
  String get releaseToRefresh;

  /// Refreshing status message
  ///
  /// In en, this message translates to:
  /// **'Refreshing...'**
  String get refreshing;

  /// Loading more items message
  ///
  /// In en, this message translates to:
  /// **'Loading more...'**
  String get loadingMore;

  /// Syncing data message
  ///
  /// In en, this message translates to:
  /// **'Syncing...'**
  String get syncing;

  /// Label shown on edited messages
  ///
  /// In en, this message translates to:
  /// **'Edited'**
  String get edited;

  /// Text shown for deleted messages
  ///
  /// In en, this message translates to:
  /// **'This message was deleted'**
  String get deleted;

  /// Label for current user
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get you;

  /// Label for admin users
  ///
  /// In en, this message translates to:
  /// **'Admin'**
  String get admin;

  /// Button text to leave a group
  ///
  /// In en, this message translates to:
  /// **'Leave Group'**
  String get leaveGroup;

  /// Button text to delete a conversation
  ///
  /// In en, this message translates to:
  /// **'Delete Conversation'**
  String get deleteConversation;

  /// Button text to edit group details
  ///
  /// In en, this message translates to:
  /// **'Edit Group'**
  String get editGroup;

  /// Group information page title
  ///
  /// In en, this message translates to:
  /// **'Group Info'**
  String get groupInfo;

  /// Success message when conversation is deleted
  ///
  /// In en, this message translates to:
  /// **'Conversation deleted successfully'**
  String get conversationDeleted;

  /// Success message when user leaves a conversation
  ///
  /// In en, this message translates to:
  /// **'You left the conversation'**
  String get leftConversation;

  /// Success message when group is created
  ///
  /// In en, this message translates to:
  /// **'Group created successfully'**
  String get groupCreated;

  /// Success message when group is updated
  ///
  /// In en, this message translates to:
  /// **'Group updated successfully'**
  String get groupUpdated;

  /// Success message when message is sent
  ///
  /// In en, this message translates to:
  /// **'Message sent'**
  String get messageSent;

  /// Success message when message is edited
  ///
  /// In en, this message translates to:
  /// **'Message edited'**
  String get messageEdited;

  /// Success message when message is deleted
  ///
  /// In en, this message translates to:
  /// **'Message deleted'**
  String get messageDeleted;

  /// Confirmation dialog for leaving a group
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to leave this group?'**
  String get confirmLeaveGroup;

  /// Confirmation dialog for deleting a conversation
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this conversation?'**
  String get confirmDeleteConversation;

  /// Placeholder text for conversation search
  ///
  /// In en, this message translates to:
  /// **'Search conversations...'**
  String get searchConversations;

  /// Placeholder text for message search
  ///
  /// In en, this message translates to:
  /// **'Search messages...'**
  String get searchMessages;

  /// Title for member selection screen
  ///
  /// In en, this message translates to:
  /// **'Select Members'**
  String get selectMembers;

  /// Label for group description field
  ///
  /// In en, this message translates to:
  /// **'Group Description'**
  String get groupDescription;

  /// Label for optional fields
  ///
  /// In en, this message translates to:
  /// **'Optional'**
  String get optional;

  /// Label for required fields
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get required;

  /// Button text to add a photo
  ///
  /// In en, this message translates to:
  /// **'Add Photo'**
  String get addPhoto;

  /// Button text to change a photo
  ///
  /// In en, this message translates to:
  /// **'Change Photo'**
  String get changePhoto;

  /// Button text to remove a photo
  ///
  /// In en, this message translates to:
  /// **'Remove Photo'**
  String get removePhoto;

  /// Camera option
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get camera;

  /// Gallery option
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get gallery;

  /// File option
  ///
  /// In en, this message translates to:
  /// **'File'**
  String get file;

  /// Button text to attach a file
  ///
  /// In en, this message translates to:
  /// **'Attach File'**
  String get attachFile;

  /// Reply to message indicator
  ///
  /// In en, this message translates to:
  /// **'Reply to {name}'**
  String replyTo(String name);

  /// Label for forwarded messages
  ///
  /// In en, this message translates to:
  /// **'Forwarded message'**
  String get forwardedMessage;

  /// Notification when someone mentions you
  ///
  /// In en, this message translates to:
  /// **'{name} mentioned you'**
  String mentionedYou(String name);

  /// Unread message count
  ///
  /// In en, this message translates to:
  /// **'{count} unread messages'**
  String unreadMessages(int count);

  /// Button text to mark messages as read
  ///
  /// In en, this message translates to:
  /// **'Mark as read'**
  String get markAsRead;

  /// Button text to mark messages as unread
  ///
  /// In en, this message translates to:
  /// **'Mark as unread'**
  String get markAsUnread;

  /// Button text to copy message
  ///
  /// In en, this message translates to:
  /// **'Copy message'**
  String get copyMessage;

  /// Button text to edit message
  ///
  /// In en, this message translates to:
  /// **'Edit message'**
  String get editMessage;

  /// Button text to delete message
  ///
  /// In en, this message translates to:
  /// **'Delete message'**
  String get deleteMessage;

  /// Button text to forward message
  ///
  /// In en, this message translates to:
  /// **'Forward message'**
  String get forwardMessage;

  /// Button text to reply to message
  ///
  /// In en, this message translates to:
  /// **'Reply to message'**
  String get replyMessage;

  /// Button text to react to message
  ///
  /// In en, this message translates to:
  /// **'React to message'**
  String get reactToMessage;

  /// Success message when message is copied
  ///
  /// In en, this message translates to:
  /// **'Message copied to clipboard'**
  String get messageCopied;

  /// Information message when user is offline
  ///
  /// In en, this message translates to:
  /// **'You are offline. Messages will be sent when you reconnect.'**
  String get offlineMode;

  /// Message shown when syncing offline messages
  ///
  /// In en, this message translates to:
  /// **'Syncing messages...'**
  String get syncingMessages;

  /// Message shown when message is queued offline
  ///
  /// In en, this message translates to:
  /// **'Message queued for sending'**
  String get messageQueued;

  /// Message shown when operation is queued offline
  ///
  /// In en, this message translates to:
  /// **'Operation queued. Will be processed when online.'**
  String get operationQueued;

  /// Message shown when connection is restored
  ///
  /// In en, this message translates to:
  /// **'Back online. Syncing...'**
  String get backOnline;

  /// Message shown when connection is lost
  ///
  /// In en, this message translates to:
  /// **'Connection lost. Working offline.'**
  String get connectionLost;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'vi'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en': return AppLocalizationsEn();
    case 'vi': return AppLocalizationsVi();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
