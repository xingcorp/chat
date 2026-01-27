// App Localizations
// Vietnamese localization support cho permissions và UI
// Enterprise-grade localization với fallback support

import 'package:flutter/material.dart';

class AppLocalizations {
  AppLocalizations(this.locale);

  final Locale locale;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations) ??
        AppLocalizations(const Locale('vi', 'VN'));
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  // ========================================
  // PERMISSIONS ONBOARDING
  // ========================================

  String get permissionsOnboardingTitle => 'Cấp quyền cho OXII Chat';

  String get permissionsOnboardingSubtitle =>
      'Để sử dụng đầy đủ tính năng, vui lòng cấp các quyền cần thiết';

  String get permissionsOnboardingComplete => 'Hoàn thành!';

  String get permissionsOnboardingCompleteDescription =>
      'Bạn đã cấp quyền thành công. Giờ có thể sử dụng đầy đủ tính năng của OXII Chat.';

  // ========================================
  // PERMISSION TYPES
  // ========================================

  String get permissionCamera => 'Camera';
  String get permissionMicrophone => 'Microphone';
  String get permissionStorage => 'Lưu trữ';
  String get permissionNotification => 'Thông báo';
  String get permissionContacts => 'Danh bạ';
  String get permissionLocation => 'Vị trí';
  String get permissionPhone => 'Điện thoại';
  String get permissionCalendar => 'Lịch';
  String get permissionSms => 'SMS';
  String get permissionBiometric => 'Sinh trắc học';
  String get permissionBluetooth => 'Bluetooth';

  // ========================================
  // PERMISSION DESCRIPTIONS
  // ========================================

  String get permissionCameraDescription =>
      'Cho phép chụp ảnh và quay video để chia sẻ trong cuộc trò chuyện';

  String get permissionMicrophoneDescription =>
      'Cho phép ghi âm tin nhắn thoại và thực hiện cuộc gọi';

  String get permissionStorageDescription =>
      'Cho phép lưu trữ và chia sẻ file, ảnh, video';

  String get permissionNotificationDescription =>
      'Cho phép nhận thông báo tin nhắn và cuộc gọi';

  String get permissionContactsDescription =>
      'Cho phép tìm và kết nối với bạn bè trong danh bạ';

  String get permissionLocationDescription =>
      'Cho phép chia sẻ vị trí hiện tại với bạn bè';

  String get permissionPhoneDescription =>
      'Cho phép thực hiện cuộc gọi trực tiếp từ ứng dụng';

  String get permissionCalendarDescription =>
      'Cho phép tạo sự kiện và nhắc nhở từ cuộc trò chuyện';

  String get permissionSmsDescription =>
      'Cho phép sao lưu và khôi phục tin nhắn qua SMS';

  String get permissionBiometricDescription =>
      'Cho phép sử dụng vân tay/Face ID để bảo mật ứng dụng';

  String get permissionBluetoothDescription =>
      'Cho phép kết nối với tai nghe và thiết bị Bluetooth';

  // ========================================
  // PERMISSION RATIONALES
  // ========================================

  String get permissionCameraRationale =>
      'Camera cần thiết để chụp ảnh và quay video gửi cho bạn bè. Bạn có thể chụp ảnh trực tiếp trong cuộc trò chuyện.';

  String get permissionMicrophoneRationale =>
      'Microphone cần thiết để ghi âm tin nhắn thoại và thực hiện cuộc gọi. Tin nhắn thoại giúp giao tiếp nhanh chóng hơn.';

  String get permissionStorageRationale =>
      'Quyền lưu trữ cần thiết để lưu và chia sẻ file, ảnh, video. Chúng tôi chỉ truy cập những file bạn chọn chia sẻ.';

  String get permissionNotificationRationale =>
      'Thông báo giúp bạn không bỏ lỡ tin nhắn và cuộc gọi quan trọng ngay cả khi không mở ứng dụng.';

  String get permissionContactsRationale =>
      'Danh bạ giúp bạn tìm và kết nối với bạn bè đang sử dụng ứng dụng. Chúng tôi không lưu trữ danh bạ trên server.';

  String get permissionLocationRationale =>
      'Vị trí giúp bạn chia sẻ địa điểm hiện tại với bạn bè khi cần thiết. Vị trí chỉ được chia sẻ khi bạn chủ động.';

  // ========================================
  // COMMON ACTIONS
  // ========================================

  String get allow => 'Cho phép';
  String get deny => 'Từ chối';
  String get skip => 'Bỏ qua';
  String get next => 'Tiếp theo';
  String get back => 'Quay lại';
  String get done => 'Hoàn thành';
  String get cancel => 'Hủy';
  String get ok => 'OK';
  String get retry => 'Thử lại';
  String get settings => 'Cài đặt';

  // ========================================
  // ERROR MESSAGES
  // ========================================

  String get errorPermissionDenied => 'Quyền bị từ chối';
  String get errorPermissionPermanentlyDenied =>
      'Quyền bị từ chối vĩnh viễn. Vui lòng vào Cài đặt để cấp quyền.';
  String get errorPermissionRestricted => 'Quyền bị hạn chế bởi hệ thống';
  String get errorPermissionNotSupported =>
      'Quyền này không được hỗ trợ trên thiết bị';
  String get errorUnknown => 'Đã xảy ra lỗi không xác định';

  // ========================================
  // SUCCESS MESSAGES
  // ========================================

  String get successPermissionGranted => 'Đã cấp quyền thành công';
  String get successAllPermissionsGranted => 'Đã cấp tất cả quyền thành công';
  String get successCriticalPermissionsGranted =>
      'Đã cấp các quyền quan trọng thành công';

  // ========================================
  // DIALOG TITLES
  // ========================================

  String get dialogPermissionRequired => 'Cần cấp quyền';
  String get dialogPermissionDenied => 'Quyền bị từ chối';
  String get dialogGoToSettings => 'Mở Cài đặt';

  // ========================================
  // DIALOG MESSAGES
  // ========================================

  String permissionRequiredMessage(String permissionName) =>
      'Ứng dụng cần quyền $permissionName để hoạt động đúng cách.';

  String permissionDeniedMessage(String permissionName) =>
      'Quyền $permissionName bị từ chối. Một số tính năng có thể không hoạt động.';

  String permissionPermanentlyDeniedMessage(String permissionName) =>
      'Quyền $permissionName bị từ chối vĩnh viễn. Vui lòng vào Cài đặt > Ứng dụng > OXII Chat > Quyền để cấp quyền.';

  // ========================================
  // ONBOARDING STEPS
  // ========================================

  String get onboardingStep1Title => 'Thông báo quan trọng';
  String get onboardingStep1Description =>
      'Cho phép nhận thông báo để không bỏ lỡ tin nhắn quan trọng';

  String get onboardingStep2Title => 'Tính năng cốt lõi';
  String get onboardingStep2Description =>
      'Cấp quyền cho các tính năng cơ bản của ứng dụng chat';

  String get onboardingStep3Title => 'Tính năng nâng cao';
  String get onboardingStep3Description =>
      'Kích hoạt các tính năng nâng cao để trải nghiệm tốt hơn';

  // ========================================
  // BUTTON TEXTS
  // ========================================

  String get buttonGrantPermissions => 'Cấp quyền';
  String get buttonGrantAndContinue => 'Cấp quyền & Tiếp tục';
  String get buttonSkipForNow => 'Bỏ qua tạm thời';
  String get buttonOpenSettings => 'Mở Cài đặt';
  String get buttonTryAgain => 'Thử lại';

  // ========================================
  // STATUS MESSAGES
  // ========================================

  String get statusCheckingPermissions => 'Đang kiểm tra quyền...';
  String get statusRequestingPermissions => 'Đang yêu cầu quyền...';
  String get statusPermissionsGranted => 'Quyền đã được cấp';
  String get statusPermissionsDenied => 'Quyền bị từ chối';

  // ========================================
  // HELPER METHODS
  // ========================================

  String getPermissionName(String permissionType) {
    switch (permissionType.toLowerCase()) {
      case 'camera':
        return permissionCamera;
      case 'microphone':
        return permissionMicrophone;
      case 'storage':
        return permissionStorage;
      case 'notification':
        return permissionNotification;
      case 'contacts':
        return permissionContacts;
      case 'location':
        return permissionLocation;
      case 'phone':
        return permissionPhone;
      case 'calendar':
        return permissionCalendar;
      case 'sms':
        return permissionSms;
      case 'biometric':
        return permissionBiometric;
      case 'bluetooth':
        return permissionBluetooth;
      default:
        return permissionType;
    }
  }

  String getPermissionDescription(String permissionType) {
    switch (permissionType.toLowerCase()) {
      case 'camera':
        return permissionCameraDescription;
      case 'microphone':
        return permissionMicrophoneDescription;
      case 'storage':
        return permissionStorageDescription;
      case 'notification':
        return permissionNotificationDescription;
      case 'contacts':
        return permissionContactsDescription;
      case 'location':
        return permissionLocationDescription;
      case 'phone':
        return permissionPhoneDescription;
      case 'calendar':
        return permissionCalendarDescription;
      case 'sms':
        return permissionSmsDescription;
      case 'biometric':
        return permissionBiometricDescription;
      case 'bluetooth':
        return permissionBluetoothDescription;
      default:
        return 'Quyền $permissionType';
    }
  }
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['vi', 'en'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
