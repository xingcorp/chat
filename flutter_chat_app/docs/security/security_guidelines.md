# Hướng dẫn bảo mật

## Tổng quan

Tài liệu này mô tả các hướng dẫn bảo mật áp dụng cho ứng dụng chat, bao gồm các biện pháp bảo vệ dữ liệu người dùng, mã hóa giao tiếp, và quy trình phát hiện/phản hồi sự cố bảo mật.

## Nguyên tắc bảo mật cốt lõi

1. **Defense in Depth**: Áp dụng nhiều lớp bảo vệ để tránh phụ thuộc vào một cơ chế bảo mật duy nhất
2. **Least Privilege**: Chỉ cấp quyền tối thiểu cần thiết cho người dùng và các thành phần hệ thống
3. **Secure by Default**: Ứng dụng phải an toàn ngay từ khi cài đặt, không phụ thuộc vào cấu hình của người dùng
4. **Data Protection**: Bảo vệ dữ liệu cả khi lưu trữ và truyền tải
5. **Privacy by Design**: Tích hợp quyền riêng tư vào thiết kế từ đầu, không phải như một tính năng bổ sung

## Bảo mật dữ liệu

### Mã hóa dữ liệu

#### Dữ liệu đang truyền (Data in Transit)

Tất cả giao tiếp giữa ứng dụng và máy chủ phải được mã hóa bằng TLS 1.3 trở lên:

```dart
// Sử dụng HttpClient với cấu hình bảo mật
HttpClient client = HttpClient()
  ..badCertificateCallback = (cert, host, port) => false // Từ chối chứng chỉ không hợp lệ
  ..connectionTimeout = Duration(seconds: 10);

// Hoặc sử dụng package http với HTTPS
import 'package:http/http.dart' as http;
final response = await http.get(Uri.https('api.example.com', 'messages'));
```

#### Dữ liệu lưu trữ (Data at Rest)

Dữ liệu nhạy cảm được lưu trữ trong thiết bị phải được mã hóa:

- Sử dụng `Flutter Secure Storage` cho dữ liệu nhạy cảm (tokens, khóa mã hóa)
- Mã hóa cơ sở dữ liệu local bằng SQLCipher hoặc giải pháp tương tự
- Sử dụng biện pháp bảo vệ bổ sung cho các thiết bị đã root/jailbreak

```dart
// Lưu trữ dữ liệu nhạy cảm
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final storage = FlutterSecureStorage();
await storage.write(key: 'auth_token', value: token);

// Mã hóa cơ sở dữ liệu
import 'package:sqflite_sqlcipher/sqflite.dart';

final db = await openDatabase(
  'chat_database.db',
  password: 'complex_password_from_secure_storage', // Lấy từ secure storage
  version: 1,
);
```

#### End-to-End Encryption (E2EE)

Ứng dụng sử dụng mã hóa đầu-cuối cho tin nhắn và tệp đính kèm:

- Dựa trên giao thức Signal (Double Ratchet Algorithm)
- Mỗi thiết bị của người dùng có cặp khóa riêng
- Máy chủ không có khả năng giải mã dữ liệu

```dart
// Ví dụ sử dụng thư viện libolm hoặc libsignal trong Flutter
import 'package:olm/olm.dart' as olm;

// Khởi tạo thư viện
await olm.init();
final account = olm.Account();
account.create();

// Tạo khóa
final identityKeys = account.identityKeys();

// Tạo phiên mã hóa
final session = olm.Session();
session.createOutbound(account, recipientIdentityKey, recipientOneTimeKey);

// Mã hóa tin nhắn
final encrypted = session.encrypt("Tin nhắn bí mật");
```

### Xác thực và Phân quyền

#### Xác thực đa yếu tố (MFA)

Ứng dụng hỗ trợ và khuyến khích sử dụng xác thực đa yếu tố:

- SMS OTP
- Email OTP
- Authenticator apps (TOTP)
- Thông báo push
- Sinh trắc học (khi được thiết bị hỗ trợ)

```dart
// Xác thực sinh trắc học
import 'package:local_auth/local_auth.dart';

final auth = LocalAuthentication();
final authenticated = await auth.authenticate(
  localizedReason: 'Xác thực để xem tin nhắn',
  options: const AuthenticationOptions(
    biometricOnly: true,
    stickyAuth: true,
  ),
);

if (authenticated) {
  // Cho phép truy cập
}
```

#### Quản lý phiên và Token

- Sử dụng JWT cho xác thực phiên với thời hạn ngắn (15-30 phút)
- Sử dụng refresh token với thời hạn dài hơn (7-30 ngày) cho phép gia hạn phiên
- Hủy token khi đăng xuất, phát hiện hành vi đáng ngờ, hoặc thay đổi mật khẩu

```dart
// Kiểm tra và làm mới token
Future<String> getValidToken() async {
  final tokenExpiry = await storage.read(key: 'token_expiry');
  final now = DateTime.now().millisecondsSinceEpoch;
  
  if (tokenExpiry != null && int.parse(tokenExpiry) > now) {
    return await storage.read(key: 'access_token');
  }
  
  final refreshToken = await storage.read(key: 'refresh_token');
  final response = await refreshTokenRequest(refreshToken);
  
  await storage.write(key: 'access_token', value: response.accessToken);
  await storage.write(
    key: 'token_expiry',
    value: (now + 15 * 60 * 1000).toString(), // 15 phút
  );
  
  return response.accessToken;
}
```

#### Quản lý mật khẩu

- Yêu cầu mật khẩu mạnh (độ dài tối thiểu, ký tự đặc biệt, chữ hoa/thường, số)
- Không lưu trữ mật khẩu gốc, chỉ lưu hash với salt
- Sử dụng hàm hash có mục đích cụ thể như Argon2, Bcrypt, PBKDF2
- Cung cấp tính năng đặt lại mật khẩu an toàn

```dart
// Kiểm tra độ mạnh của mật khẩu
bool isStrongPassword(String password) {
  if (password.length < 12) return false;
  
  final hasUppercase = RegExp(r'[A-Z]').hasMatch(password);
  final hasLowercase = RegExp(r'[a-z]').hasMatch(password);
  final hasDigit = RegExp(r'[0-9]').hasMatch(password);
  final hasSpecialChar = RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password);
  
  return hasUppercase && hasLowercase && hasDigit && hasSpecialChar;
}
```

### Bảo vệ dữ liệu người dùng

#### Khả năng xóa dữ liệu từ xa

Ứng dụng hỗ trợ xóa dữ liệu từ xa trong trường hợp thiết bị bị mất hoặc đánh cắp:

- Xóa dữ liệu cục bộ khi nhận lệnh từ máy chủ
- Đăng xuất khỏi tất cả các phiên
- Vô hiệu hóa tất cả các token

```dart
// Xử lý lệnh xóa từ xa
void handleRemoteWipe() async {
  // Xóa dữ liệu cục bộ
  await database.deleteAllData();
  await secureStorage.deleteAll();
  
  // Xóa bộ nhớ đệm
  await imageCache.clear();
  await clearSharedPrefs();
  
  // Đăng xuất
  await authService.logout();
  
  // Chuyển hướng người dùng về màn hình đăng nhập
  navigator.pushAndRemoveUntil(
    MaterialPageRoute(builder: (_) => LoginScreen()),
    (route) => false,
  );
}
```

#### Thời gian tự khóa màn hình

Ứng dụng tự động khóa và yêu cầu xác thực lại sau một khoảng thời gian không hoạt động:

- Cho phép người dùng cấu hình thời gian (30 giây, 1 phút, 5 phút,...)
- Áp dụng ngay lập tức khi ứng dụng chuyển sang chế độ nền
- Cung cấp tùy chọn sử dụng sinh trắc học để mở khóa nhanh

```dart
class InactivityTimer {
  Timer? _timer;
  final int timeoutSeconds;
  final VoidCallback onTimeout;
  
  InactivityTimer({required this.timeoutSeconds, required this.onTimeout});
  
  void reset() {
    _timer?.cancel();
    _timer = Timer(Duration(seconds: timeoutSeconds), onTimeout);
  }
  
  void cancel() {
    _timer?.cancel();
    _timer = null;
  }
}

// Sử dụng trong ứng dụng
final inactivityTimer = InactivityTimer(
  timeoutSeconds: 300, // 5 phút
  onTimeout: () {
    // Khóa ứng dụng và yêu cầu xác thực lại
    lockApp();
  },
);

// Trong mỗi tương tác người dùng
void onUserInteraction() {
  inactivityTimer.reset();
}
```

## Bảo mật ứng dụng

### Bảo vệ mã nguồn

#### Phòng chống đảo ngược mã nguồn

Áp dụng các biện pháp chống đảo ngược mã nguồn và gỡ lỗi:

- Sử dụng ProGuard/R8 để làm rối mã cho Android
- Tắt cờ gỡ lỗi trong bản build phát hành
- Phát hiện và phản ứng với việc gỡ lỗi động

```dart
// Kiểm tra gỡ lỗi trong production
Future<bool> isBeingDebugged() async {
  if (kReleaseMode) {
    try {
      // Android
      if (Platform.isAndroid) {
        // Các kiểm tra như TracerPid
      }
      
      // iOS
      if (Platform.isIOS) {
        // Gọi native code để kiểm tra
      }
    } catch (e) {
      // Xử lý lỗi
    }
  }
  return false;
}
```

#### Phòng chống root/jailbreak

Ứng dụng phát hiện thiết bị đã root/jailbreak và áp dụng biện pháp bảo vệ bổ sung:

- Giới hạn chức năng nhạy cảm
- Tăng cường mã hóa
- Hiển thị cảnh báo cho người dùng

```dart
import 'package:flutter_jailbreak_detection/flutter_jailbreak_detection.dart';

Future<bool> isDeviceCompromised() async {
  bool jailbroken = await FlutterJailbreakDetection.jailbroken;
  bool developerMode = await FlutterJailbreakDetection.developerMode;
  
  return jailbroken || developerMode;
}

// Sử dụng trong ứng dụng
void checkDeviceSecurity() async {
  final compromised = await isDeviceCompromised();
  if (compromised) {
    showSecurityWarning();
    applyStricterSecurityMeasures();
  }
}
```

### Cấu hình bảo mật

#### Bảo mật TLS/SSL

Ứng dụng thực hiện các biện pháp bảo mật TLS/SSL mạnh mẽ:

- Certificate pinning để ngăn chặn tấn công MITM
- Chỉ chấp nhận chứng chỉ hợp lệ
- Chỉ hỗ trợ TLS 1.2+ và bộ mã hóa mạnh

```dart
import 'package:dio/dio.dart';
import 'package:dio_pinning/dio_pinning.dart';

void configureDioWithCertificatePinning() {
  final dio = Dio();
  
  // Thêm certificate pinning
  dio.httpClientAdapter = PinningHttpClientAdapter(
    allowedSHAFingerprints: [
      'sha256/AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=', // Thay bằng fingerprint thực tế
      'sha256/BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB=', // Dự phòng
    ],
  );
  
  // Sử dụng dio cho các request
}
```

### Bảo mật giao diện người dùng

#### Chống chụp màn hình và quay video

Ngăn chặn chụp màn hình và quay video trong các màn hình nhạy cảm:

```dart
import 'package:flutter_windowmanager/flutter_windowmanager.dart';

Future<void> secureScreen() async {
  if (Platform.isAndroid) {
    await FlutterWindowManager.addFlags(FlutterWindowManager.FLAG_SECURE);
  }
}

Future<void> removeScreenSecurity() async {
  if (Platform.isAndroid) {
    await FlutterWindowManager.clearFlags(FlutterWindowManager.FLAG_SECURE);
  }
}

class SecureScreen extends StatefulWidget {
  @override
  _SecureScreenState createState() => _SecureScreenState();
}

class _SecureScreenState extends State<SecureScreen> {
  @override
  void initState() {
    super.initState();
    secureScreen();
  }
  
  @override
  void dispose() {
    removeScreenSecurity();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    // Nội dung màn hình bảo mật
  }
}
```

#### Ẩn thông tin nhạy cảm

Ẩn thông tin nhạy cảm trong giao diện người dùng:

- Mặc định ẩn nội dung tin nhắn trong thông báo
- Tùy chọn ẩn danh sách trò chuyện gần đây khi khóa ứng dụng
- Hỗ trợ "chế độ ẩn danh" để sử dụng ứng dụng trong môi trường công cộng

```dart
// Cho phép tùy chỉnh mức độ riêng tư
enum PrivacyLevel {
  standard, // Hiển thị tên người gửi và preview trong thông báo
  enhanced, // Chỉ hiển thị tên người gửi, không có preview
  strict    // Hiển thị "Tin nhắn mới" mà không có thông tin chi tiết
}

// Cấu hình thông báo dựa trên mức độ riêng tư
NotificationDetails buildNotificationDetails(PrivacyLevel privacyLevel, Message message) {
  switch (privacyLevel) {
    case PrivacyLevel.standard:
      return NotificationDetails(
        android: AndroidNotificationDetails(
          'messages_channel',
          'Messages',
          channelDescription: 'Message notifications',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: IOSNotificationDetails(),
      );
    case PrivacyLevel.enhanced:
      // Tùy chỉnh thông báo để chỉ hiển thị tên người gửi
      // ...
    case PrivacyLevel.strict:
      // Tùy chỉnh thông báo để ẩn mọi chi tiết
      // ...
  }
}
```

## Phát hiện và phản hồi sự cố

### Giám sát và ghi nhật ký

#### Ghi nhật ký bảo mật

Triển khai ghi nhật ký phù hợp cho mục đích bảo mật:

- Ghi lại các sự kiện bảo mật quan trọng (đăng nhập, thay đổi mật khẩu, quyền truy cập)
- Không ghi lại dữ liệu nhạy cảm (mật khẩu, tokens, nội dung tin nhắn)
- Cung cấp tùy chọn báo cáo sự cố cho nhóm phát triển

```dart
enum SecurityEventType {
  login,
  logout,
  passwordChange,
  accountRecovery,
  permissionChange,
  failedLogin,
  suspiciousActivity,
}

class SecurityLogger {
  final LogService _logService;
  
  SecurityLogger(this._logService);
  
  void logEvent(
    SecurityEventType type,
    {Map<String, dynamic>? metadata, bool sendToServer = true}
  ) {
    // Loại bỏ bất kỳ thông tin nhạy cảm nào từ metadata
    final sanitizedMetadata = _sanitizeMetadata(metadata);
    
    final event = {
      'type': type.toString(),
      'timestamp': DateTime.now().toIso8601String(),
      'metadata': sanitizedMetadata,
    };
    
    // Ghi vào bộ nhớ cục bộ
    _logService.logLocally('security', event);
    
    // Gửi đến server nếu được yêu cầu và có kết nối
    if (sendToServer) {
      _logService.sendToServer('security', event);
    }
  }
  
  Map<String, dynamic>? _sanitizeMetadata(Map<String, dynamic>? metadata) {
    if (metadata == null) return null;
    
    final result = Map<String, dynamic>.from(metadata);
    
    // Loại bỏ thông tin nhạy cảm
    final sensitiveKeys = ['password', 'token', 'secret', 'pin'];
    for (final key in sensitiveKeys) {
      if (result.containsKey(key)) {
        result[key] = '***REDACTED***';
      }
    }
    
    return result;
  }
}
```

### Phản hồi sự cố

#### Quy trình phản hồi sự cố

Ứng dụng có quy trình phản hồi sự cố bảo mật rõ ràng:

1. **Phát hiện**: Hệ thống giám sát và người dùng có thể báo cáo sự cố
2. **Đánh giá**: Đánh giá mức độ nghiêm trọng và phạm vi ảnh hưởng
3. **Ngăn chặn**: Thực hiện các biện pháp ngăn chặn thiệt hại lan rộng
4. **Khắc phục**: Sửa lỗi và khôi phục hoạt động bình thường
5. **Thông báo**: Thông báo cho người dùng bị ảnh hưởng theo quy định hiện hành
6. **Học hỏi**: Cập nhật quy trình bảo mật để ngăn chặn sự cố tương tự

```dart
class IncidentResponse {
  // Phát hiện hoạt động đáng ngờ
  Future<void> detectSuspiciousActivity() async {
    // Thuật toán phát hiện dựa trên mô hình hành vi người dùng
    
    // Nếu phát hiện, kích hoạt quy trình phản hồi
    await triggerIncidentResponse();
  }
  
  // Quy trình phản hồi
  Future<void> triggerIncidentResponse() async {
    // 1. Ghi nhật ký sự cố
    securityLogger.logEvent(
      SecurityEventType.suspiciousActivity,
      metadata: {'severity': 'high'},
    );
    
    // 2. Thực hiện các biện pháp bảo vệ
    await forcePasswordReset();
    await notifyUserOfSuspiciousActivity();
    await temporarilyLimitAccountAccess();
    
    // 3. Thông báo cho đội ngũ phản hồi sự cố
    await notifySecurityTeam();
  }
}
```

## Kiểm thử bảo mật

### SAST & DAST

#### Static Application Security Testing (SAST)

Thực hiện phân tích mã tĩnh để phát hiện lỗ hổng trước khi triển khai:

- Tích hợp công cụ SAST vào CI/CD pipeline
- Ưu tiên các lỗi bảo mật cao
- Đảm bảo fix các lỗi bảo mật trước khi phát hành

Công cụ khuyến nghị:
- SonarQube
- Fortify
- Veracode

#### Dynamic Application Security Testing (DAST)

Thực hiện kiểm thử bảo mật động để kiểm tra ứng dụng đang chạy:

- Tự động hóa kiểm tra API bằng các công cụ như OWASP ZAP
- Kiểm tra các lỗ hổng phổ biến như XSS, CSRF, SQL Injection
- Thực hiện penetration testing định kỳ

### Bảo mật mã nguồn

#### Quản lý bí mật

Thực hiện quản lý bí mật an toàn:

- Không bao giờ lưu trữ khóa API, mật khẩu, hoặc bí mật trong mã nguồn
- Sử dụng giải pháp quản lý bí mật như HashiCorp Vault hoặc AWS Secrets Manager
- Sử dụng biến môi trường và tệp cấu hình được mã hóa

```dart
// KHÔNG làm thế này
const String API_KEY = "abcd1234efgh5678";

// Thay vào đó, tải từ cấu hình bảo mật
final apiKey = await SecretManager.getSecret('api_key');
```

#### Kiểm tra dependencies

Thường xuyên kiểm tra các dependencies để phát hiện lỗ hổng:

- Sử dụng công cụ như Dependabot, Snyk, hoặc OWASP Dependency Check
- Cập nhật các dependencies có lỗ hổng bảo mật kịp thời
- Theo dõi các thông báo bảo mật từ cộng đồng Flutter và Dart

```bash
# Sử dụng công cụ như Dependabot hoặc GitHub Security Alerts
# hoặc thực hiện kiểm tra thủ công với các công cụ như:
flutter pub outdated
```

## Tích hợp bảo mật vào quy trình phát triển

### DevSecOps

#### Tích hợp vào CI/CD

Tích hợp kiểm tra bảo mật vào quy trình CI/CD:

1. **Kiểm tra mã tĩnh**: Chạy SAST trong bước build
2. **Kiểm tra dependencies**: Phát hiện các dependencies có lỗ hổng
3. **Unit tests bảo mật**: Kiểm tra các chức năng bảo mật
4. **Kiểm tra cấu hình**: Đảm bảo cấu hình bảo mật đúng
5. **Kiểm thử bảo mật động**: Chạy công cụ DAST trên môi trường staging

```yaml
# Ví dụ cấu hình GitHub Actions workflow cho kiểm tra bảo mật
name: Security Checks

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main, develop ]

jobs:
  security:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v2
    
    - name: Set up Flutter
      uses: subosito/flutter-action@v2
      with:
        flutter-version: '3.0.0'
    
    - name: Install dependencies
      run: flutter pub get
    
    - name: Run dependency check
      run: flutter pub outdated
    
    - name: Run static code analysis
      run: flutter analyze
    
    - name: Run security unit tests
      run: flutter test --tags=security
```

#### Security Champions

Chỉ định "Security Champions" trong mỗi team phát triển:

- Đào tạo về bảo mật ứng dụng mobile
- Thực hiện code review tập trung vào bảo mật
- Chia sẻ kiến thức và thực hành tốt nhất về bảo mật

## Tuân thủ và quy định

### GDPR và quy định bảo mật dữ liệu

Ứng dụng tuân thủ các quy định bảo vệ dữ liệu hiện hành:

- Cung cấp thông báo rõ ràng về việc thu thập và sử dụng dữ liệu
- Cho phép người dùng truy cập, sửa đổi, và xóa dữ liệu cá nhân
- Thực hiện "quyền được quên" để xóa hoàn toàn dữ liệu người dùng
- Đảm bảo dữ liệu được lưu trữ theo vùng địa lý khi cần thiết

```dart
class DataPrivacyManager {
  // Xuất dữ liệu người dùng ở định dạng có thể đọc được
  Future<Map<String, dynamic>> exportUserData(String userId) async {
    // Truy vấn và định dạng tất cả dữ liệu cá nhân
    return userRepository.getAllUserData(userId);
  }
  
  // Xóa tất cả dữ liệu người dùng
  Future<void> deleteAllUserData(String userId) async {
    // Xóa dữ liệu trên thiết bị
    await localDataSource.deleteUserData(userId);
    
    // Gửi yêu cầu xóa đến máy chủ
    await apiService.requestAccountDeletion(userId);
    
    // Đăng xuất và xóa tất cả tokens
    await authService.logout(deleteTokens: true);
  }
  
  // Cập nhật tùy chọn quyền riêng tư
  Future<void> updatePrivacySettings(PrivacySettings settings) async {
    await userRepository.updatePrivacySettings(settings);
    
    // Đồng bộ với máy chủ
    await apiService.updatePrivacyPreferences(settings);
  }
}
```

## Tài liệu tham khảo

- [OWASP Mobile Top 10](https://owasp.org/www-project-mobile-top-10/)
- [OWASP Mobile Security Testing Guide](https://owasp.org/www-project-mobile-security-testing-guide/)
- [Flutter Security Best Practices](https://flutter.dev/security)
- [Signal Protocol Specification](https://signal.org/docs/)
- [NIST Cybersecurity Framework](https://www.nist.gov/cyberframework)
- [GDPR Compliance](https://gdpr.eu/) 