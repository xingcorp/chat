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

  /// Offline status
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
