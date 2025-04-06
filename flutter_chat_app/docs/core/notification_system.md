# Hệ thống Thông báo (Notification)

Tài liệu này mô tả kiến trúc và cách triển khai hệ thống thông báo cho ứng dụng chat, bao gồm Push Notifications, In-app Notifications, và Badge Management.

## Kiến trúc Tổng quan

Ứng dụng chat sử dụng kiến trúc đa tầng để xử lý thông báo:

```
+-----------------+     +------------------+     +----------------+
| External        |     | Local            |     | UI             |
| Services        |     | Processing       |     | Components     |
+-----------------+     +------------------+     +----------------+
| - FCM / APNS    |     | - Notification   |     | - Badge UI     |
| - WebSocket     |<--->|   Manager        |<--->| - In-app       |
| - Background    |     | - Message Queue  |     |   Notifications|
|   Handlers      |     | - Badge Counter  |     | - Permission   |
+-----------------+     +------------------+     |   Flow         |
                                                 +----------------+
```

## Đăng ký Push Notification

### Setup FCM và APNS

```dart
class PushNotificationService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final _notificationStreamController = BehaviorSubject<RemoteMessage>();
  
  Stream<RemoteMessage> get notificationStream => _notificationStreamController.stream;
  
  Future<void> initialize() async {
    // Yêu cầu quyền
    final settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
    
    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      log('Push notification permission granted');
    } else {
      log('Push notification permission declined or partially granted');
    }
    
    // Xử lý message khi app đang chạy
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    
    // Xử lý message khi mở app từ terminated state
    FirebaseMessaging.instance.getInitialMessage().then(_handleInitialMessage);
    
    // Xử lý message khi mở app từ background
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);
    
    // Đăng ký handlers cho background/terminated state
    await _setupBackgroundHandlers();
    
    // Đặt foreground notification presentation options (iOS)
    await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
    
    // Lấy và lưu FCM token
    await _updateFCMToken();
  }
  
  Future<void> _setupBackgroundHandlers() async {
    // Đăng ký background handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }
  
  void _handleForegroundMessage(RemoteMessage message) {
    // Xử lý notification khi app đang chạy
    log('Foreground message received: ${message.messageId}');
    
    final notificationType = _getNotificationType(message);
    
    // Stream thông báo để các listener có thể xử lý
    _notificationStreamController.add(message);
    
    // Hiển thị thông báo in-app tùy thuộc vào loại và trạng thái app
    _showInAppNotification(message, notificationType);
    
    // Cập nhật badge count
    _updateBadgeCount(message);
  }
  
  void _handleInitialMessage(RemoteMessage? message) {
    if (message == null) return;
    
    // App đã được mở từ terminated state bởi notification
    log('Initial message received: ${message.messageId}');
    
    // Handle deep linking hoặc navigation dựa trên notification
    _handleNotificationNavigation(message);
  }
  
  void _handleMessageOpenedApp(RemoteMessage message) {
    // App đã được mở từ background bởi notification
    log('App opened from background message: ${message.messageId}');
    
    // Handle deep linking hoặc navigation
    _handleNotificationNavigation(message);
  }
  
  Future<void> _updateFCMToken() async {
    final token = await _firebaseMessaging.getToken();
    if (token != null) {
      log('FCM token: $token');
      
      // Lưu token vào local storage
      await GetIt.instance<PreferenceService>().setFCMToken(token);
      
      // Gửi token lên server để đăng ký
      await GetIt.instance<UserRepository>().updatePushToken(token);
      
      // Lắng nghe thay đổi token
      _firebaseMessaging.onTokenRefresh.listen((newToken) {
        log('FCM token refreshed: $newToken');
        // Cập nhật token mới lên server
        GetIt.instance<UserRepository>().updatePushToken(newToken);
      });
    }
  }
  
  NotificationType _getNotificationType(RemoteMessage message) {
    final data = message.data;
    final type = data['type'] ?? '';
    
    switch (type) {
      case 'new_message':
        return NotificationType.newMessage;
      case 'group_invite':
        return NotificationType.groupInvite;
      case 'mention':
        return NotificationType.mention;
      default:
        return NotificationType.other;
    }
  }
  
  void _showInAppNotification(RemoteMessage message, NotificationType type) {
    // Kiểm tra xem chat screen hiện tại có đang hiển thị chat liên quan không
    final currentChatId = GetIt.instance<AppNavigator>().currentChatId;
    final notificationChatId = message.data['chat_id'];
    
    // Không hiển thị in-app notification nếu đang ở trong chat đó
    if (currentChatId == notificationChatId) {
      return;
    }
    
    // Hiển thị thông báo in-app
    GetIt.instance<InAppNotificationService>().showNotification(
      title: message.notification?.title ?? 'Thông báo mới',
      body: message.notification?.body ?? '',
      type: type,
      data: message.data,
    );
  }
  
  void _updateBadgeCount(RemoteMessage message) {
    // Lấy badge count từ APNS payload hoặc tính toán dựa trên message data
    final badgeCount = int.tryParse(message.data['badge_count'] ?? '');
    if (badgeCount != null) {
      GetIt.instance<BadgeService>().setBadgeCount(badgeCount);
    } else {
      GetIt.instance<BadgeService>().incrementBadgeCount();
    }
  }
  
  void _handleNotificationNavigation(RemoteMessage message) {
    final data = message.data;
    final type = _getNotificationType(message);
    
    switch (type) {
      case NotificationType.newMessage:
        final chatId = data['chat_id'];
        if (chatId != null) {
          GetIt.instance<AppNavigator>().navigateToChatScreen(chatId);
        }
        break;
      case NotificationType.groupInvite:
        final groupId = data['group_id'];
        if (groupId != null) {
          GetIt.instance<AppNavigator>().navigateToGroupInviteScreen(groupId);
        }
        break;
      case NotificationType.mention:
        final chatId = data['chat_id'];
        final messageId = data['message_id'];
        if (chatId != null && messageId != null) {
          GetIt.instance<AppNavigator>().navigateToMessageInChat(chatId, messageId);
        }
        break;
      default:
        // Mặc định mở app home screen
        GetIt.instance<AppNavigator>().navigateToHomeScreen();
    }
  }
}

// Background message handler phải là top-level function
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Khởi tạo các dependency cần thiết cho background processing
  await Firebase.initializeApp();
  
  // Xử lý thông báo
  final badgeCount = int.tryParse(message.data['badge_count'] ?? '');
  if (badgeCount != null) {
    await _updateBadgeInBackground(badgeCount);
  }
}

Future<void> _updateBadgeInBackground(int count) async {
  // Cập nhật badge count cho app icon
  if (Platform.isIOS) {
    await FlutterAppBadger.updateBadgeCount(count);
  }
  
  // Lưu badge count để có thể đồng bộ khi app mở lại
  final prefs = await SharedPreferences.getInstance();
  await prefs.setInt('unread_badge_count', count);
}
```

### Tùy chỉnh thông báo trên từng nền tảng

#### Android - Notification Channels

```dart
class AndroidNotificationChannelManager {
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin;
  
  AndroidNotificationChannelManager(this._flutterLocalNotificationsPlugin);
  
  Future<void> setupChannels() async {
    // Tạo các channel cho từng loại thông báo
    await _createMessagesChannel();
    await _createGroupsChannel();
    await _createMentionsChannel();
    await _createGeneralChannel();
  }
  
  Future<void> _createMessagesChannel() async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'messages_channel',
      'Chat Messages',
      description: 'Notifications for new chat messages',
      importance: Importance.high,
      enableVibration: true,
      showBadge: true,
      enableLights: true,
      ledColor: Colors.blue,
    );
    
    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }
  
  Future<void> _createGroupsChannel() async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'groups_channel',
      'Group Updates',
      description: 'Notifications for group invites and updates',
      importance: Importance.high,
    );
    
    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }
  
  // Các phương thức còn lại tương tự...
  
  String getChannelIdForType(NotificationType type) {
    switch (type) {
      case NotificationType.newMessage:
        return 'messages_channel';
      case NotificationType.groupInvite:
        return 'groups_channel';
      case NotificationType.mention:
        return 'mentions_channel';
      default:
        return 'general_channel';
    }
  }
}
```

#### iOS - Notification Categories

```dart
class IOSNotificationCategoryManager {
  Future<void> setupCategories() async {
    // Đăng ký các category cho iOS để hỗ trợ action buttons
    final messageCategory = UNNotificationCategory(
      identifier: 'message_category',
      actions: [
        UNNotificationAction(
          identifier: 'reply',
          title: 'Reply',
          options: UNNotificationActionOptions.foreground,
        ),
        UNNotificationAction(
          identifier: 'mark_read',
          title: 'Mark as Read',
          options: UNNotificationActionOptions.authenticationRequired,
        ),
      ],
      intentIdentifiers: [],
      options: UNNotificationCategoryOptions.customDismissAction,
    );
    
    final groupInviteCategory = UNNotificationCategory(
      identifier: 'group_invite_category',
      actions: [
        UNNotificationAction(
          identifier: 'accept',
          title: 'Accept',
          options: UNNotificationActionOptions.foreground,
        ),
        UNNotificationAction(
          identifier: 'decline',
          title: 'Decline',
          options: UNNotificationActionOptions.destructive,
        ),
      ],
      intentIdentifiers: [],
      options: UNNotificationCategoryOptions.customDismissAction,
    );
    
    // Đăng ký categories với iOS
    await FirebaseMessaging.instance.setNotificationCategories([
      messageCategory,
      groupInviteCategory,
    ]);
  }
  
  String getCategoryForType(NotificationType type) {
    switch (type) {
      case NotificationType.newMessage:
        return 'message_category';
      case NotificationType.groupInvite:
        return 'group_invite_category';
      default:
        return '';
    }
  }
}
```

## In-App Notifications

```dart
class InAppNotificationService {
  final _overlayKey = GlobalKey<OverlayState>();
  OverlayEntry? _currentNotification;
  Timer? _dismissTimer;
  
  void initialize(GlobalKey<NavigatorState> navigatorKey) {
    // Lấy overlay key từ navigator
    _overlayKey.currentState = navigatorKey.currentState?.overlay;
  }
  
  void showNotification({
    required String title,
    required String body,
    required NotificationType type,
    Map<String, dynamic>? data,
    Duration duration = const Duration(seconds: 4),
  }) {
    // Hủy notification cũ nếu có
    _dismissCurrentNotification();
    
    // Hiển thị notification mới
    _currentNotification = OverlayEntry(
      builder: (context) => InAppNotificationWidget(
        title: title,
        body: body,
        type: type,
        onTap: () => _handleNotificationTap(type, data),
        onDismiss: _dismissCurrentNotification,
      ),
    );
    
    _overlayKey.currentState?.insert(_currentNotification!);
    
    // Tự động ẩn sau khoảng thời gian
    _dismissTimer = Timer(duration, _dismissCurrentNotification);
  }
  
  void _dismissCurrentNotification() {
    _dismissTimer?.cancel();
    _dismissTimer = null;
    
    if (_currentNotification != null) {
      _currentNotification!.remove();
      _currentNotification = null;
    }
  }
  
  void _handleNotificationTap(NotificationType type, Map<String, dynamic>? data) {
    _dismissCurrentNotification();
    
    if (data == null) return;
    
    switch (type) {
      case NotificationType.newMessage:
        final chatId = data['chat_id'];
        if (chatId != null) {
          GetIt.instance<AppNavigator>().navigateToChatScreen(chatId);
        }
        break;
      // Xử lý các loại notification khác...
    }
  }
}

class InAppNotificationWidget extends StatefulWidget {
  final String title;
  final String body;
  final NotificationType type;
  final VoidCallback onTap;
  final VoidCallback onDismiss;
  
  @override
  _InAppNotificationWidgetState createState() => _InAppNotificationWidgetState();
}

class _InAppNotificationWidgetState extends State<InAppNotificationWidget> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Offset> _offsetAnimation;
  
  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    
    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
      reverseCurve: Curves.easeIn,
    ));
    
    _animationController.forward();
  }
  
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Positioned(
        top: 0,
        left: 0,
        right: 0,
        child: SlideTransition(
          position: _offsetAnimation,
          child: GestureDetector(
            onTap: widget.onTap,
            onVerticalDragEnd: (details) {
              if (details.velocity.pixelsPerSecond.dy < -200) {
                _dismissNotification();
              }
            },
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: _buildNotificationContent(),
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildNotificationContent() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            _buildNotificationIcon(),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.body,
                    style: const TextStyle(fontSize: 14),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildNotificationIcon() {
    IconData iconData;
    Color iconColor;
    
    switch (widget.type) {
      case NotificationType.newMessage:
        iconData = Icons.chat_bubble;
        iconColor = Colors.blue;
        break;
      case NotificationType.groupInvite:
        iconData = Icons.group_add;
        iconColor = Colors.green;
        break;
      case NotificationType.mention:
        iconData = Icons.alternate_email;
        iconColor = Colors.orange;
        break;
      default:
        iconData = Icons.notifications;
        iconColor = Colors.grey;
    }
    
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: iconColor.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(
        iconData,
        color: iconColor,
        size: 24,
      ),
    );
  }
  
  void _dismissNotification() {
    _animationController.reverse().then((_) => widget.onDismiss());
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
}
```

## Badge Management

```dart
class BadgeService {
  int _totalUnreadCount = 0;
  final _badgeUpdates = BehaviorSubject<int>.seeded(0);
  Stream<int> get badgeUpdates => _badgeUpdates.stream;
  
  final PreferenceService _preferenceService;
  
  BadgeService(this._preferenceService);
  
  Future<void> initialize() async {
    // Load saved badge count
    _totalUnreadCount = await _preferenceService.getUnreadBadgeCount();
    _badgeUpdates.add(_totalUnreadCount);
    
    // Update app icon badge
    _updateAppIconBadge();
  }
  
  Future<void> setBadgeCount(int count) async {
    _totalUnreadCount = count;
    _badgeUpdates.add(_totalUnreadCount);
    
    // Persist the badge count
    await _preferenceService.setUnreadBadgeCount(_totalUnreadCount);
    
    // Update app icon badge
    await _updateAppIconBadge();
  }
  
  Future<void> incrementBadgeCount([int increment = 1]) async {
    await setBadgeCount(_totalUnreadCount + increment);
  }
  
  Future<void> decrementBadgeCount([int decrement = 1]) async {
    final newCount = math.max(0, _totalUnreadCount - decrement);
    await setBadgeCount(newCount);
  }
  
  Future<void> clearBadgeCount() async {
    await setBadgeCount(0);
  }
  
  Future<void> _updateAppIconBadge() async {
    if (Platform.isIOS || Platform.isAndroid) {
      if (_totalUnreadCount > 0) {
        await FlutterAppBadger.updateBadgeCount(_totalUnreadCount);
      } else {
        await FlutterAppBadger.removeBadge();
      }
    }
  }
  
  Future<void> refreshBadgeCount() async {
    // Lấy số lượng tin nhắn chưa đọc từ repository
    final messageCount = await GetIt.instance<MessageRepository>().getUnreadMessageCount();
    
    // Cập nhật badge
    await setBadgeCount(messageCount);
  }
}
```

## Deep Linking

### Xử lý deep link từ notification

```dart
class DeepLinkHandler {
  final AppNavigator _navigator;
  
  DeepLinkHandler(this._navigator);
  
  Future<void> handleDeepLink(Uri deepLink) async {
    log('Handling deep link: $deepLink');
    
    final pathSegments = deepLink.pathSegments;
    if (pathSegments.isEmpty) return;
    
    switch (pathSegments[0]) {
      case 'chat':
        if (pathSegments.length >= 2) {
          final chatId = pathSegments[1];
          
          // Kiểm tra xem có cần nhảy đến message cụ thể không
          String? messageId;
          if (deepLink.queryParameters.containsKey('message_id')) {
            messageId = deepLink.queryParameters['message_id'];
          }
          
          if (messageId != null) {
            await _navigator.navigateToMessageInChat(chatId, messageId);
          } else {
            await _navigator.navigateToChatScreen(chatId);
          }
        }
        break;
        
      case 'group':
        if (pathSegments.length >= 2) {
          final groupId = pathSegments[1];
          await _navigator.navigateToGroupScreen(groupId);
        }
        break;
        
      case 'profile':
        if (pathSegments.length >= 2) {
          final userId = pathSegments[1];
          await _navigator.navigateToProfileScreen(userId);
        }
        break;
        
      // Các loại deep link khác...
    }
  }
  
  // Tạo deep link URL cho notification
  String createChatDeepLink(String chatId, [String? messageId]) {
    final link = 'chatapp://chat/$chatId';
    if (messageId != null) {
      return '$link?message_id=$messageId';
    }
    return link;
  }
  
  String createGroupDeepLink(String groupId) {
    return 'chatapp://group/$groupId';
  }
  
  String createProfileDeepLink(String userId) {
    return 'chatapp://profile/$userId';
  }
}
```

## Quản lý Notification Permission

```dart
class NotificationPermissionManager {
  final _permissionStatus = BehaviorSubject<NotificationPermissionStatus>.seeded(
    NotificationPermissionStatus.unknown
  );
  Stream<NotificationPermissionStatus> get permissionStatus => _permissionStatus.stream;
  
  Future<NotificationPermissionStatus> checkPermissionStatus() async {
    NotificationPermissionStatus status;
    
    if (Platform.isIOS) {
      final settings = await FirebaseMessaging.instance.getNotificationSettings();
      
      switch (settings.authorizationStatus) {
        case AuthorizationStatus.authorized:
          status = NotificationPermissionStatus.granted;
          break;
        case AuthorizationStatus.denied:
          status = NotificationPermissionStatus.denied;
          break;
        case AuthorizationStatus.notDetermined:
          status = NotificationPermissionStatus.unknown;
          break;
        default:
          status = NotificationPermissionStatus.unknown;
      }
    } else if (Platform.isAndroid) {
      // Android doesn't require permission before Android 13
      if (await _isAndroid13OrHigher()) {
        final granted = await Permission.notification.isGranted;
        status = granted 
            ? NotificationPermissionStatus.granted 
            : NotificationPermissionStatus.denied;
      } else {
        status = NotificationPermissionStatus.granted;
      }
    } else {
      status = NotificationPermissionStatus.unknown;
    }
    
    _permissionStatus.add(status);
    return status;
  }
  
  Future<NotificationPermissionStatus> requestPermission() async {
    if (Platform.isIOS) {
      final settings = await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      
      final status = settings.authorizationStatus == AuthorizationStatus.authorized
          ? NotificationPermissionStatus.granted
          : NotificationPermissionStatus.denied;
          
      _permissionStatus.add(status);
      return status;
    } else if (Platform.isAndroid) {
      if (await _isAndroid13OrHigher()) {
        final result = await Permission.notification.request();
        final status = result.isGranted
            ? NotificationPermissionStatus.granted
            : NotificationPermissionStatus.denied;
            
        _permissionStatus.add(status);
        return status;
      } else {
        // Luôn được granted trên Android < 13
        _permissionStatus.add(NotificationPermissionStatus.granted);
        return NotificationPermissionStatus.granted;
      }
    }
    
    return NotificationPermissionStatus.unknown;
  }
  
  Future<bool> _isAndroid13OrHigher() async {
    if (Platform.isAndroid) {
      final deviceInfo = DeviceInfoPlugin();
      final androidInfo = await deviceInfo.androidInfo;
      return androidInfo.version.sdkInt >= 33; // Android 13 is API 33
    }
    return false;
  }
  
  void showPermissionRationale(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Bật thông báo'),
        content: const Text(
          'Thông báo giúp bạn không bỏ lỡ tin nhắn và cập nhật quan trọng. Bạn có muốn bật thông báo?'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Để sau'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              requestPermission();
            },
            child: const Text('Bật ngay'),
          ),
        ],
      ),
    );
  }
  
  void openAppSettings() {
    openAppSettings();
  }
}

enum NotificationPermissionStatus {
  granted,
  denied,
  unknown,
}
```

## Dependency Injection

```dart
void setupNotificationDependencies() {
  // Đăng ký các service
  GetIt.instance.registerLazySingleton<BadgeService>(() => 
    BadgeService(GetIt.instance<PreferenceService>())
  );
  
  GetIt.instance.registerLazySingleton<PushNotificationService>(() => 
    PushNotificationService()
  );
  
  GetIt.instance.registerLazySingleton<InAppNotificationService>(() => 
    InAppNotificationService()
  );
  
  GetIt.instance.registerLazySingleton<DeepLinkHandler>(() => 
    DeepLinkHandler(GetIt.instance<AppNavigator>())
  );
  
  GetIt.instance.registerLazySingleton<NotificationPermissionManager>(() => 
    NotificationPermissionManager()
  );
  
  // Đăng ký các manager cho từng nền tảng
  if (Platform.isAndroid) {
    GetIt.instance.registerLazySingleton<AndroidNotificationChannelManager>(() => 
      AndroidNotificationChannelManager(
        GetIt.instance<FlutterLocalNotificationsPlugin>()
      )
    );
  }
  
  if (Platform.isIOS) {
    GetIt.instance.registerLazySingleton<IOSNotificationCategoryManager>(() => 
      IOSNotificationCategoryManager()
    );
  }
}
```

## Best Practices

### Tối ưu hóa Firebase Cloud Messaging

1. **Gửi notification với data payload**
   - Kết hợp notification và data trong FCM message để xử lý custom logic
   - Thêm đủ thông tin để hỗ trợ deep linking mà không cần server roundtrip

2. **Sử dụng FCM Topic cho group messaging**
   - Đăng ký các chat ID và group ID như là FCM topics
   - Giảm số lượng API call cần thiết cho server khi gửi tin nhắn nhóm

3. **Triển khai notification grouping**
   - Nhóm nhiều thông báo từ cùng một chat/người gửi
   - Sử dụng summary text thông minh: "5 tin nhắn mới từ Nhóm ABC"

### Tối ưu Badge và In-app Notification

1. **Maintain badge theo context**
   - Giảm badge count khi người dùng xem tin nhắn
   - Cập nhật badge ở nhiều điểm: FCM, realtime updates, và local changes
   - Đồng bộ badge state giữa các thiết bị

2. **In-app notification có độ ưu tiên**
   - Hiển thị in-app notification khi app đang chạy
   - Không hiển thị notification cho chat đang mở
   - Thêm animation mượt mà cho in-app notification

### Tối ưu hóa Permission Flow

1. **Xây dựng pre-permission priming screen**
   - Giải thích lợi ích của việc bật thông báo trước khi yêu cầu quyền
   - Tăng tỷ lệ chấp nhận quyền thông báo

2. **Xử lý từ chối quyền**
   - Theo dõi trạng thái quyền và cung cấp cách kích hoạt lại
   - Không yêu cầu quá nhiều lần và gây phiền toái

### Tiết kiệm pin

1. **Sử dụng priority khác nhau**
   - Dùng priority cao cho tin nhắn trực tiếp
   - Dùng priority thấp cho thông báo không quan trọng

2. **Tối ưu wake-up của thiết bị**
   - Gộp thông báo khi có thể để giảm thiểu wake-up
   - Sử dụng FCM message pattern tối ưu

## Tham khảo

- [Firebase Cloud Messaging Documentation](https://firebase.google.com/docs/cloud-messaging)
- [Flutter Local Notifications Plugin](https://pub.dev/packages/flutter_local_notifications)
- [Firebase FCM 101](https://firebase.blog/posts/2020/06/fcm-chat-tutorial)
- [Android Notification Channels](https://developer.android.com/guide/topics/ui/notifiers/notifications#ManageChannels)
- [iOS Push Notification Guide](https://developer.apple.com/documentation/usernotifications)