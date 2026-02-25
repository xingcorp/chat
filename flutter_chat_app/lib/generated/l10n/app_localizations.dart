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
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

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
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
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

  /// Accessibility label for message timestamp
  ///
  /// In en, this message translates to:
  /// **'Sent at {time}'**
  String sentAt(String time);

  /// Today text
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// User online status
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

  /// Message when there are no users to display
  ///
  /// In en, this message translates to:
  /// **'No users'**
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

  /// Settings section title
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

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

  /// Success message when group is created
  ///
  /// In en, this message translates to:
  /// **'Group created successfully'**
  String get groupCreatedSuccessfully;

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

  /// Call button text for phone action
  ///
  /// In en, this message translates to:
  /// **'Call'**
  String get call;

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

  /// File label
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

  /// Accessibility label for button loading state
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get buttonLoading;

  /// Accessibility label for disabled button
  ///
  /// In en, this message translates to:
  /// **'Button disabled'**
  String get buttonDisabled;

  /// Accessibility label for primary button
  ///
  /// In en, this message translates to:
  /// **'Primary button'**
  String get primaryButton;

  /// Accessibility label for secondary button
  ///
  /// In en, this message translates to:
  /// **'Secondary button'**
  String get secondaryButton;

  /// Accessibility label for text button
  ///
  /// In en, this message translates to:
  /// **'Text button'**
  String get textButton;

  /// Accessibility label for outlined button
  ///
  /// In en, this message translates to:
  /// **'Outlined button'**
  String get outlinedButton;

  /// Accessibility label for icon button
  ///
  /// In en, this message translates to:
  /// **'Icon button'**
  String get iconButton;

  /// Accessibility label for floating action button
  ///
  /// In en, this message translates to:
  /// **'Floating action button'**
  String get floatingActionButton;

  /// Tooltip for show password button
  ///
  /// In en, this message translates to:
  /// **'Show password'**
  String get showPassword;

  /// Tooltip for hide password button
  ///
  /// In en, this message translates to:
  /// **'Hide password'**
  String get hidePassword;

  /// Tooltip for clear search button
  ///
  /// In en, this message translates to:
  /// **'Clear search'**
  String get clearSearch;

  /// Placeholder for text input
  ///
  /// In en, this message translates to:
  /// **'Enter text'**
  String get enterText;

  /// Character count display
  ///
  /// In en, this message translates to:
  /// **'{current} / {max} characters'**
  String characterCount(int current, int max);

  /// Validation message for required field
  ///
  /// In en, this message translates to:
  /// **'This field is required'**
  String get validationRequired;

  /// Validation message for invalid email
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email address'**
  String get validationEmail;

  /// Validation message for minimum length
  ///
  /// In en, this message translates to:
  /// **'Must be at least {length} characters'**
  String validationMinLength(int length);

  /// Validation message for maximum length
  ///
  /// In en, this message translates to:
  /// **'Must be no more than {length} characters'**
  String validationMaxLength(int length);

  /// Accessibility hint for tappable items
  ///
  /// In en, this message translates to:
  /// **'Tap to select'**
  String get tapToSelect;

  /// Accessibility hint for items that open on double tap
  ///
  /// In en, this message translates to:
  /// **'Double tap to open'**
  String get doubleTapToOpen;

  /// Empty state title when list has no items
  ///
  /// In en, this message translates to:
  /// **'No items found'**
  String get noItemsFound;

  /// Empty state description when list has no items
  ///
  /// In en, this message translates to:
  /// **'There are no items to display'**
  String get noItemsDescription;

  /// Title for no internet connection state
  ///
  /// In en, this message translates to:
  /// **'No Internet Connection'**
  String get noInternetConnection;

  /// Message for no internet connection state
  ///
  /// In en, this message translates to:
  /// **'Please check your internet connection and try again'**
  String get checkInternetConnection;

  /// Placeholder for dropdown/radio selection
  ///
  /// In en, this message translates to:
  /// **'Select an option'**
  String get selectOption;

  /// Enabled state label
  ///
  /// In en, this message translates to:
  /// **'Enabled'**
  String get enabled;

  /// Disabled state label
  ///
  /// In en, this message translates to:
  /// **'Disabled'**
  String get disabled;

  /// Value label for slider
  ///
  /// In en, this message translates to:
  /// **'Value'**
  String get value;

  /// Range label for slider
  ///
  /// In en, this message translates to:
  /// **'Range'**
  String get range;

  /// Minimum value label
  ///
  /// In en, this message translates to:
  /// **'Minimum'**
  String get minimum;

  /// Maximum value label
  ///
  /// In en, this message translates to:
  /// **'Maximum'**
  String get maximum;

  /// Placeholder text for search input
  ///
  /// In en, this message translates to:
  /// **'Search...'**
  String get searchPlaceholder;

  /// Message when search returns no results
  ///
  /// In en, this message translates to:
  /// **'No results found'**
  String get noResults;

  /// Date picker title
  ///
  /// In en, this message translates to:
  /// **'Select Date'**
  String get selectDate;

  /// Error message for invalid date
  ///
  /// In en, this message translates to:
  /// **'Invalid date'**
  String get invalidDate;

  /// Time picker title
  ///
  /// In en, this message translates to:
  /// **'Select Time'**
  String get selectTime;

  /// Error message for invalid time
  ///
  /// In en, this message translates to:
  /// **'Invalid time'**
  String get invalidTime;

  /// Rating label
  ///
  /// In en, this message translates to:
  /// **'Rating'**
  String get rating;

  /// Rating prompt
  ///
  /// In en, this message translates to:
  /// **'Rate this'**
  String get rateThis;

  /// Star count with pluralization
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 star} other{{count} stars}}'**
  String stars(int count);

  /// Validation message for required field
  ///
  /// In en, this message translates to:
  /// **'This field is required'**
  String get fieldRequired;

  /// Validation message for invalid input
  ///
  /// In en, this message translates to:
  /// **'Invalid input'**
  String get invalidInput;

  /// Checkbox checked state
  ///
  /// In en, this message translates to:
  /// **'Checked'**
  String get checked;

  /// Checkbox unchecked state
  ///
  /// In en, this message translates to:
  /// **'Unchecked'**
  String get unchecked;

  /// Checkbox indeterminate state
  ///
  /// In en, this message translates to:
  /// **'Indeterminate'**
  String get indeterminate;

  /// Selected state label
  ///
  /// In en, this message translates to:
  /// **'Selected'**
  String get selected;

  /// Unselected state label
  ///
  /// In en, this message translates to:
  /// **'Unselected'**
  String get unselected;

  /// Slider accessibility label
  ///
  /// In en, this message translates to:
  /// **'Slider'**
  String get slider;

  /// Separator for value ranges (e.g., '5 out of 10')
  ///
  /// In en, this message translates to:
  /// **'out of'**
  String get outOf;

  /// Volume control label
  ///
  /// In en, this message translates to:
  /// **'Volume'**
  String get volume;

  /// Accessibility label for message bubble
  ///
  /// In en, this message translates to:
  /// **'Message bubble'**
  String get messageBubble;

  /// Accessibility label for text message
  ///
  /// In en, this message translates to:
  /// **'Text message'**
  String get textMessage;

  /// Accessibility label for image message
  ///
  /// In en, this message translates to:
  /// **'Image message'**
  String get imageMessage;

  /// Accessibility label for video message
  ///
  /// In en, this message translates to:
  /// **'Video message'**
  String get videoMessage;

  /// Accessibility label for audio message
  ///
  /// In en, this message translates to:
  /// **'Audio message'**
  String get audioMessage;

  /// Accessibility label for file message
  ///
  /// In en, this message translates to:
  /// **'File message'**
  String get fileMessage;

  /// Accessibility label for location message
  ///
  /// In en, this message translates to:
  /// **'Location message'**
  String get locationMessage;

  /// Accessibility label for contact message
  ///
  /// In en, this message translates to:
  /// **'Contact message'**
  String get contactMessage;

  /// Accessibility label for system message
  ///
  /// In en, this message translates to:
  /// **'System message'**
  String get systemMessage;

  /// Message delivered status
  ///
  /// In en, this message translates to:
  /// **'Delivered'**
  String get delivered;

  /// Message read status
  ///
  /// In en, this message translates to:
  /// **'Read'**
  String get read;

  /// Message failed status
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get failed;

  /// Message pending status
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pending;

  /// Label for reply preview
  ///
  /// In en, this message translates to:
  /// **'Replying to {author}'**
  String replyingTo(String author);

  /// Button text to cancel reply
  ///
  /// In en, this message translates to:
  /// **'Cancel reply'**
  String get cancelReply;

  /// Voice message label
  ///
  /// In en, this message translates to:
  /// **'Voice message'**
  String get voiceMessage;

  /// Photo label
  ///
  /// In en, this message translates to:
  /// **'Photo'**
  String get photo;

  /// Video label
  ///
  /// In en, this message translates to:
  /// **'Video'**
  String get video;

  /// Audio label
  ///
  /// In en, this message translates to:
  /// **'Audio'**
  String get audio;

  /// Document label
  ///
  /// In en, this message translates to:
  /// **'Document'**
  String get document;

  /// Location label
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get location;

  /// Contact label
  ///
  /// In en, this message translates to:
  /// **'Contact'**
  String get contact;

  /// Button to add reaction to message
  ///
  /// In en, this message translates to:
  /// **'Add reaction'**
  String get addReaction;

  /// Button text to remove reaction
  ///
  /// In en, this message translates to:
  /// **'Remove reaction'**
  String get removeReaction;

  /// Reactions label
  ///
  /// In en, this message translates to:
  /// **'Reactions'**
  String get reactions;

  /// Recently used reactions section
  ///
  /// In en, this message translates to:
  /// **'Recently used'**
  String get recentlyUsed;

  /// Placeholder for emoji search
  ///
  /// In en, this message translates to:
  /// **'Search emoji'**
  String get searchEmoji;

  /// Emoji category
  ///
  /// In en, this message translates to:
  /// **'Smileys & People'**
  String get smileysAndPeople;

  /// Emoji category
  ///
  /// In en, this message translates to:
  /// **'Gestures & Body Parts'**
  String get gesturesAndBodyParts;

  /// Emoji category
  ///
  /// In en, this message translates to:
  /// **'People & Professions'**
  String get peopleAndProfessions;

  /// Emoji category
  ///
  /// In en, this message translates to:
  /// **'Animals & Nature'**
  String get animalsAndNature;

  /// Emoji category
  ///
  /// In en, this message translates to:
  /// **'Food & Drink'**
  String get foodAndDrink;

  /// Emoji category
  ///
  /// In en, this message translates to:
  /// **'Activities & Sports'**
  String get activitiesAndSports;

  /// Emoji category
  ///
  /// In en, this message translates to:
  /// **'Activity'**
  String get activity;

  /// Emoji category
  ///
  /// In en, this message translates to:
  /// **'Travel & Places'**
  String get travelAndPlaces;

  /// Emoji category
  ///
  /// In en, this message translates to:
  /// **'Objects'**
  String get objects;

  /// Emoji category
  ///
  /// In en, this message translates to:
  /// **'Symbols'**
  String get symbols;

  /// Emoji category
  ///
  /// In en, this message translates to:
  /// **'Flags'**
  String get flags;

  /// Message when emoji search returns no results
  ///
  /// In en, this message translates to:
  /// **'No emojis found'**
  String get noEmojisFound;

  /// Placeholder text for emoji search input
  ///
  /// In en, this message translates to:
  /// **'Search emojis'**
  String get searchEmojis;

  /// Text shown when there are no recent emojis
  ///
  /// In en, this message translates to:
  /// **'No recent emojis'**
  String get noRecentEmojis;

  /// Recent emoji category
  ///
  /// In en, this message translates to:
  /// **'Recent'**
  String get recent;

  /// Smileys emoji category
  ///
  /// In en, this message translates to:
  /// **'Smileys'**
  String get smileys;

  /// Animals emoji category
  ///
  /// In en, this message translates to:
  /// **'Animals'**
  String get animals;

  /// Food emoji category
  ///
  /// In en, this message translates to:
  /// **'Food'**
  String get food;

  /// Travel emoji category
  ///
  /// In en, this message translates to:
  /// **'Travel'**
  String get travel;

  /// Activities emoji category
  ///
  /// In en, this message translates to:
  /// **'Activities'**
  String get activities;

  /// Typing indicator text
  ///
  /// In en, this message translates to:
  /// **'{name} is typing...'**
  String isTyping(String name);

  /// Typing indicator for two users
  ///
  /// In en, this message translates to:
  /// **'{name1} and {name2} are typing...'**
  String areTyping(String name1, String name2);

  /// Multiple users typing
  ///
  /// In en, this message translates to:
  /// **'{count} people are typing...'**
  String multipleTyping(int count);

  /// Play button label
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get play;

  /// Pause button label
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get pause;

  /// Stop button label
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get stop;

  /// Playback speed selector label
  ///
  /// In en, this message translates to:
  /// **'Playback Speed'**
  String get playbackSpeed;

  /// Duration label
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get duration;

  /// Current playback time label
  ///
  /// In en, this message translates to:
  /// **'Current time'**
  String get currentTime;

  /// Loading audio message
  ///
  /// In en, this message translates to:
  /// **'Loading audio...'**
  String get loadingAudio;

  /// Remaining playback time label
  ///
  /// In en, this message translates to:
  /// **'Remaining time'**
  String get remainingTime;

  /// Recording status
  ///
  /// In en, this message translates to:
  /// **'Recording...'**
  String get recording;

  /// Button text to record voice message
  ///
  /// In en, this message translates to:
  /// **'Record voice message'**
  String get recordVoiceMessage;

  /// Button text to send voice message
  ///
  /// In en, this message translates to:
  /// **'Send voice message'**
  String get sendVoiceMessage;

  /// Button text to cancel recording
  ///
  /// In en, this message translates to:
  /// **'Cancel recording'**
  String get cancelRecording;

  /// Hint text for voice recording
  ///
  /// In en, this message translates to:
  /// **'Long press to record'**
  String get longPressToRecord;

  /// Hint text to cancel voice recording
  ///
  /// In en, this message translates to:
  /// **'Slide to cancel'**
  String get slideToCancel;

  /// Hint text to send voice recording
  ///
  /// In en, this message translates to:
  /// **'Release to send'**
  String get releaseToSend;

  /// Accessibility label for message options menu
  ///
  /// In en, this message translates to:
  /// **'Message options'**
  String get messageOptions;

  /// Hint text for message long press
  ///
  /// In en, this message translates to:
  /// **'Long press for options'**
  String get longPressForOptions;

  /// Hint text to view media
  ///
  /// In en, this message translates to:
  /// **'Tap to view'**
  String get tapToView;

  /// Hint text to download file
  ///
  /// In en, this message translates to:
  /// **'Tap to download'**
  String get tapToDownload;

  /// Downloading status
  ///
  /// In en, this message translates to:
  /// **'Downloading...'**
  String get downloading;

  /// Downloaded status
  ///
  /// In en, this message translates to:
  /// **'Downloaded'**
  String get downloaded;

  /// Download failed status
  ///
  /// In en, this message translates to:
  /// **'Download failed'**
  String get downloadFailed;

  /// Error message when file upload fails
  ///
  /// In en, this message translates to:
  /// **'Failed to upload file'**
  String get uploadFailed;

  /// Status text when uploading file
  ///
  /// In en, this message translates to:
  /// **'Uploading...'**
  String get uploading;

  /// Uploaded status
  ///
  /// In en, this message translates to:
  /// **'Uploaded'**
  String get uploaded;

  /// Button text to retry upload
  ///
  /// In en, this message translates to:
  /// **'Retry upload'**
  String get retryUpload;

  /// Button text to retry download
  ///
  /// In en, this message translates to:
  /// **'Retry download'**
  String get retryDownload;

  /// Button text to cancel upload
  ///
  /// In en, this message translates to:
  /// **'Cancel upload'**
  String get cancelUpload;

  /// Button text to cancel download
  ///
  /// In en, this message translates to:
  /// **'Cancel download'**
  String get cancelDownload;

  /// File size label
  ///
  /// In en, this message translates to:
  /// **'File size'**
  String get fileSize;

  /// File name label
  ///
  /// In en, this message translates to:
  /// **'File name'**
  String get fileName;

  /// File type label
  ///
  /// In en, this message translates to:
  /// **'File type'**
  String get fileType;

  /// Error message for unsupported file type
  ///
  /// In en, this message translates to:
  /// **'Unsupported file type'**
  String get unsupportedFileType;

  /// Error message when file exceeds size limit
  ///
  /// In en, this message translates to:
  /// **'{fileName} is too large. Maximum size is {maxSize}'**
  String fileTooLarge(String fileName, String maxSize);

  /// Text showing maximum file size
  ///
  /// In en, this message translates to:
  /// **'Max file size: {size}'**
  String maxFileSize(String size);

  /// Hint text to retry failed operation
  ///
  /// In en, this message translates to:
  /// **'Tap to retry'**
  String get tapToRetry;

  /// Tooltip for sort ascending button
  ///
  /// In en, this message translates to:
  /// **'Sort ascending'**
  String get sortAscending;

  /// Tooltip for sort descending button
  ///
  /// In en, this message translates to:
  /// **'Sort descending'**
  String get sortDescending;

  /// Tooltip for filter column button
  ///
  /// In en, this message translates to:
  /// **'Filter column'**
  String get filterColumn;

  /// Button text to clear filter
  ///
  /// In en, this message translates to:
  /// **'Clear filter'**
  String get clearFilter;

  /// Button text to select all items
  ///
  /// In en, this message translates to:
  /// **'Select all'**
  String get selectAll;

  /// Button text to deselect all items
  ///
  /// In en, this message translates to:
  /// **'Deselect all'**
  String get deselectAll;

  /// Selected items count with pluralization
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No items selected} =1{1 item selected} other{{count} items selected}}'**
  String selectedItems(int count);

  /// Message shown when table has no data
  ///
  /// In en, this message translates to:
  /// **'No data available'**
  String get noDataAvailable;

  /// Label for rows per page selector
  ///
  /// In en, this message translates to:
  /// **'Rows per page'**
  String get rowsPerPage;

  /// Pagination info
  ///
  /// In en, this message translates to:
  /// **'Page {current} of {total}'**
  String pageOf(int current, int total);

  /// Tooltip for first page button
  ///
  /// In en, this message translates to:
  /// **'First page'**
  String get firstPage;

  /// Tooltip for previous page button
  ///
  /// In en, this message translates to:
  /// **'Previous page'**
  String get previousPage;

  /// Tooltip for next page button
  ///
  /// In en, this message translates to:
  /// **'Next page'**
  String get nextPage;

  /// Text showing current page items range
  ///
  /// In en, this message translates to:
  /// **'Showing {start}-{end} of {total}'**
  String showingItems(int start, int end, int total);

  /// Text showing current page number
  ///
  /// In en, this message translates to:
  /// **'Page {current} of {total}'**
  String pageInfo(int current, int total);

  /// Placeholder text for filter input
  ///
  /// In en, this message translates to:
  /// **'Filter'**
  String get filter;

  /// Tooltip for last page button
  ///
  /// In en, this message translates to:
  /// **'Last page'**
  String get lastPage;

  /// Text shown when dragging files over upload area
  ///
  /// In en, this message translates to:
  /// **'Drop files here'**
  String get dropFilesHere;

  /// Text shown in file upload area
  ///
  /// In en, this message translates to:
  /// **'Drag & drop files here or click to browse'**
  String get dragDropOrClickToUpload;

  /// Text shown when max files limit is reached
  ///
  /// In en, this message translates to:
  /// **'Maximum number of files reached'**
  String get maxFilesReached;

  /// Text showing allowed file types
  ///
  /// In en, this message translates to:
  /// **'Allowed types: {types}'**
  String allowedFileTypes(String types);

  /// Error message when file picker fails
  ///
  /// In en, this message translates to:
  /// **'Error picking files'**
  String get errorPickingFiles;

  /// Error message when file type is not allowed
  ///
  /// In en, this message translates to:
  /// **'{fileName} file type is not allowed'**
  String fileTypeNotAllowed(String fileName);

  /// Remove button text
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// Text shown when gallery is empty
  ///
  /// In en, this message translates to:
  /// **'No images available'**
  String get noImagesAvailable;

  /// Share button text
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// Download button text
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get download;

  /// Error message when video fails to load
  ///
  /// In en, this message translates to:
  /// **'Error loading video'**
  String get errorLoadingVideo;

  /// Video quality selector label
  ///
  /// In en, this message translates to:
  /// **'Quality'**
  String get quality;

  /// Picture in picture button tooltip
  ///
  /// In en, this message translates to:
  /// **'Picture in Picture'**
  String get pictureInPicture;

  /// Enter fullscreen button tooltip
  ///
  /// In en, this message translates to:
  /// **'Enter Fullscreen'**
  String get enterFullscreen;

  /// Exit fullscreen button tooltip
  ///
  /// In en, this message translates to:
  /// **'Exit Fullscreen'**
  String get exitFullscreen;

  /// Loop button tooltip
  ///
  /// In en, this message translates to:
  /// **'Loop'**
  String get loop;

  /// Rewind 10 seconds button tooltip
  ///
  /// In en, this message translates to:
  /// **'Rewind 10 seconds'**
  String get rewind10Seconds;

  /// Forward 10 seconds button tooltip
  ///
  /// In en, this message translates to:
  /// **'Forward 10 seconds'**
  String get forward10Seconds;

  /// Error message when audio fails to load
  ///
  /// In en, this message translates to:
  /// **'Error loading audio'**
  String get errorLoadingAudio;

  /// Button text to deselect all items
  ///
  /// In en, this message translates to:
  /// **'Select none'**
  String get selectNone;

  /// Hint text for pasting OTP code
  ///
  /// In en, this message translates to:
  /// **'Paste code'**
  String get pasteCode;

  /// Error message when maximum number of tags is reached
  ///
  /// In en, this message translates to:
  /// **'Maximum tags reached'**
  String get maxTagsReached;

  /// Error message when trying to add a duplicate tag
  ///
  /// In en, this message translates to:
  /// **'Tag already exists'**
  String get duplicateTag;

  /// Placeholder text for tag input
  ///
  /// In en, this message translates to:
  /// **'Add tag'**
  String get addTag;

  /// Reply preview text for image messages
  ///
  /// In en, this message translates to:
  /// **'[Photo]'**
  String get replyPreviewImage;

  /// Reply preview text for video messages
  ///
  /// In en, this message translates to:
  /// **'[Video]'**
  String get replyPreviewVideo;

  /// Reply preview text for audio messages
  ///
  /// In en, this message translates to:
  /// **'[Audio]'**
  String get replyPreviewAudio;

  /// Reply preview text for file messages
  ///
  /// In en, this message translates to:
  /// **'[File] {fileName}'**
  String replyPreviewFile(String fileName);

  /// Reply preview text for location messages
  ///
  /// In en, this message translates to:
  /// **'[Location]'**
  String get replyPreviewLocation;

  /// Reply preview text for link messages
  ///
  /// In en, this message translates to:
  /// **'[Link]'**
  String get replyPreviewLink;

  /// Reply preview text for system event messages
  ///
  /// In en, this message translates to:
  /// **'[System event]'**
  String get replyPreviewSystemEvent;

  /// Fallback actor name for system events
  ///
  /// In en, this message translates to:
  /// **'Someone'**
  String get eventSomeone;

  /// System event when members are added
  ///
  /// In en, this message translates to:
  /// **'{actor} added {targets} to the group'**
  String eventAddMember(String actor, String targets);

  /// System event when members are removed
  ///
  /// In en, this message translates to:
  /// **'{actor} removed {targets} from the group'**
  String eventRemoveMember(String actor, String targets);

  /// System event when someone leaves the group
  ///
  /// In en, this message translates to:
  /// **'{actor} left the group'**
  String eventLeaveConversation(String actor);

  /// System event when group name is changed with old and new values
  ///
  /// In en, this message translates to:
  /// **'{actor} changed the group name from \"{oldName}\" to \"{newName}\"'**
  String eventChangeNameFromTo(String actor, String oldName, String newName);

  /// System event when group name is changed
  ///
  /// In en, this message translates to:
  /// **'{actor} changed the group name to \"{newName}\"'**
  String eventChangeName(String actor, String newName);

  /// System event when group avatar is changed
  ///
  /// In en, this message translates to:
  /// **'{actor} changed the group photo'**
  String eventChangeAvatar(String actor);

  /// System event when group is created
  ///
  /// In en, this message translates to:
  /// **'{actor} created the group'**
  String eventCreateConversation(String actor);

  /// System event when a message is pinned
  ///
  /// In en, this message translates to:
  /// **'{actor} pinned a message'**
  String eventPinMessage(String actor);

  /// System event when a message is unpinned
  ///
  /// In en, this message translates to:
  /// **'{actor} unpinned a message'**
  String eventUnpinMessage(String actor);

  /// System event when someone joins the group
  ///
  /// In en, this message translates to:
  /// **'{actor} joined the group'**
  String eventJoinConversation(String actor);

  /// Fallback system event text
  ///
  /// In en, this message translates to:
  /// **'{actor} performed an action'**
  String eventPerformedAction(String actor);

  /// Label for unread messages separator
  ///
  /// In en, this message translates to:
  /// **'Unread messages'**
  String get unreadSeparatorLabel;

  /// Title for attachment picker bottom sheet
  ///
  /// In en, this message translates to:
  /// **'Pick attachment'**
  String get pickAttachment;

  /// Option to take photo with camera
  ///
  /// In en, this message translates to:
  /// **'Take photo'**
  String get takePhoto;

  /// Option to choose from photo gallery
  ///
  /// In en, this message translates to:
  /// **'Choose from gallery'**
  String get chooseFromGallery;

  /// Option to choose file from device
  ///
  /// In en, this message translates to:
  /// **'Choose file'**
  String get chooseFile;

  /// Option to share current location
  ///
  /// In en, this message translates to:
  /// **'Share location'**
  String get shareLocation;

  /// Status text when compressing image/video
  ///
  /// In en, this message translates to:
  /// **'Compressing...'**
  String get compressing;

  /// Upload progress percentage
  ///
  /// In en, this message translates to:
  /// **'Uploading {progress}%'**
  String uploadProgress(int progress);

  /// Error when file exceeds size limit
  ///
  /// In en, this message translates to:
  /// **'File too large. Maximum size: {maxSize}MB'**
  String fileTooLargeMax(int maxSize);

  /// Error when image compression fails
  ///
  /// In en, this message translates to:
  /// **'Image compression failed'**
  String get imageCompressionFailed;

  /// Typing indicator when name is unknown
  ///
  /// In en, this message translates to:
  /// **'Someone is typing...'**
  String get someoneIsTyping;

  /// User last seen status
  ///
  /// In en, this message translates to:
  /// **'Last seen recently'**
  String get lastSeenRecently;

  /// User last seen with time
  ///
  /// In en, this message translates to:
  /// **'Last seen at {time}'**
  String lastSeenAt(String time);

  /// User last seen minutes ago
  ///
  /// In en, this message translates to:
  /// **'Last seen {minutes} minutes ago'**
  String lastSeenMinutesAgo(int minutes);

  /// User last seen hours ago
  ///
  /// In en, this message translates to:
  /// **'Last seen {hours} hours ago'**
  String lastSeenHoursAgo(int hours);

  /// User last seen days ago
  ///
  /// In en, this message translates to:
  /// **'Last seen {days} days ago'**
  String lastSeenDaysAgo(int days);

  /// Error when trying to scroll to a message that is not loaded
  ///
  /// In en, this message translates to:
  /// **'Message not found'**
  String get messageNotFound;

  /// Label shown when editing a message
  ///
  /// In en, this message translates to:
  /// **'Editing message'**
  String get editingMessage;

  /// Title for forward message sheet
  ///
  /// In en, this message translates to:
  /// **'Forward to...'**
  String get forwardTo;

  /// Hint text in forward message sheet
  ///
  /// In en, this message translates to:
  /// **'Select a conversation'**
  String get selectChat;

  /// Tooltip for scroll to bottom FAB
  ///
  /// In en, this message translates to:
  /// **'Scroll to bottom'**
  String get scrollToBottom;

  /// Badge text for new messages on scroll-to-bottom FAB
  ///
  /// In en, this message translates to:
  /// **'{count} new messages'**
  String newMessagesCount(int count);

  /// Title in selection mode app bar
  ///
  /// In en, this message translates to:
  /// **'{count} selected'**
  String selectedCount(int count);

  /// Confirmation dialog for deleting multiple messages
  ///
  /// In en, this message translates to:
  /// **'Delete {count} messages?'**
  String confirmDeleteMultiple(int count);

  /// Label for link preview card
  ///
  /// In en, this message translates to:
  /// **'Link preview'**
  String get linkPreview;

  /// Button to open link in browser
  ///
  /// In en, this message translates to:
  /// **'Open link'**
  String get openLink;

  /// Button to copy link to clipboard
  ///
  /// In en, this message translates to:
  /// **'Copy link'**
  String get copyLink;

  /// Read receipt tooltip showing who has seen the message
  ///
  /// In en, this message translates to:
  /// **'Seen by {names}'**
  String readBy(String names);

  /// Text shown for empty message content
  ///
  /// In en, this message translates to:
  /// **'No message'**
  String get emptyMessage;

  /// Generic attachment label
  ///
  /// In en, this message translates to:
  /// **'Attachment'**
  String get attachment;

  /// Time indicator for days ago (compact format)
  ///
  /// In en, this message translates to:
  /// **'{days}d'**
  String daysAgo(int days);

  /// Fallback name for unknown users
  ///
  /// In en, this message translates to:
  /// **'Unknown User'**
  String get unknownUser;

  /// Tooltip for attachment picker button
  ///
  /// In en, this message translates to:
  /// **'Attachments'**
  String get attachments;

  /// Tooltip for emoji picker button
  ///
  /// In en, this message translates to:
  /// **'Insert emoji'**
  String get insertEmoji;

  /// Message shown while uploading files
  ///
  /// In en, this message translates to:
  /// **'Uploading file...'**
  String get uploadingFile;

  /// Error when location permission is denied
  ///
  /// In en, this message translates to:
  /// **'Location permission denied'**
  String get locationPermissionDenied;

  /// Loading message when getting location
  ///
  /// In en, this message translates to:
  /// **'Getting your location...'**
  String get gettingLocation;

  /// Success message after sending location
  ///
  /// In en, this message translates to:
  /// **'Location sent'**
  String get locationSent;

  /// Title for reaction picker
  ///
  /// In en, this message translates to:
  /// **'Select reaction'**
  String get selectReaction;

  /// Notification when someone reacts to a message
  ///
  /// In en, this message translates to:
  /// **'{user} reacted with {emoji}'**
  String reactedWith(String user, String emoji);

  /// Tooltip for mention user feature
  ///
  /// In en, this message translates to:
  /// **'Mention user'**
  String get mentionUser;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'vi'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'vi':
      return AppLocalizationsVi();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
