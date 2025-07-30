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
}
