// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Vietnamese (`vi`).
class AppLocalizationsVi extends AppLocalizations {
  AppLocalizationsVi([String locale = 'vi']) : super(locale);

  @override
  String get appTitle => 'Ứng dụng Chat Flutter';

  @override
  String get ok => 'OK';

  @override
  String get cancel => 'Hủy';

  @override
  String get save => 'Lưu';

  @override
  String get delete => 'Xóa';

  @override
  String get edit => 'Sửa';

  @override
  String get loading => 'Đang tải...';

  @override
  String get errorOccurred => 'Đã xảy ra lỗi';

  @override
  String get retry => 'Thử lại';

  @override
  String get send => 'Gửi';

  @override
  String get close => 'Đóng';

  @override
  String get login => 'Đăng nhập';

  @override
  String get logout => 'Đăng xuất';

  @override
  String get register => 'Đăng ký';

  @override
  String get forgotPassword => 'Quên mật khẩu';

  @override
  String get username => 'Tên đăng nhập';

  @override
  String get password => 'Mật khẩu';

  @override
  String get email => 'Email';

  @override
  String get confirmPassword => 'Xác nhận mật khẩu';

  @override
  String get newMessage => 'Tin nhắn mới';

  @override
  String get typeMessage => 'Nhập tin nhắn...';

  @override
  String get noMessages => 'Chưa có tin nhắn';

  @override
  String get loadMore => 'Tải thêm';

  @override
  String get yesterday => 'Hôm qua';

  @override
  String get today => 'Hôm nay';

  @override
  String get online => 'Trực tuyến';

  @override
  String get offline => 'Ngoại tuyến';

  @override
  String get connecting => 'Đang kết nối...';

  @override
  String get reconnecting => 'Đang kết nối lại...';

  @override
  String messageCount(int count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.compact(
      locale: localeName,
      
    );
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString tin nhắn',
      one: '1 tin nhắn',
      zero: 'Không có tin nhắn',
    );
    return '$_temp0';
  }

  @override
  String lastSeen(String time) {
    return 'Hoạt động $time';
  }

  @override
  String get settingsTitle => 'Cài đặt';

  @override
  String get profileSettings => 'Hồ sơ';

  @override
  String get chatSettings => 'Cài đặt trò chuyện';

  @override
  String get notificationSettings => 'Thông báo';

  @override
  String get languageSettings => 'Ngôn ngữ';

  @override
  String get aboutSettings => 'Giới thiệu';

  @override
  String get systemDefault => 'Theo hệ thống';

  @override
  String get selectLanguage => 'Chọn ngôn ngữ';

  @override
  String get languageChanged => 'Đổi ngôn ngữ thành công';

  @override
  String get poorConnection => 'Kết nối kém';

  @override
  String get goodConnection => 'Kết nối tốt';

  @override
  String get excellentConnection => 'Kết nối rất tốt';

  @override
  String get testData => 'Dữ liệu kiểm thử';

  @override
  String get createTestData => 'Tạo dữ liệu kiểm thử';

  @override
  String get clearData => 'Xóa dữ liệu';

  @override
  String get dataCleared => 'Đã xóa dữ liệu';

  @override
  String get users => 'Người dùng';

  @override
  String get chats => 'Trò chuyện';

  @override
  String get messages => 'Tin nhắn';

  @override
  String get noUsers => 'Chưa có người dùng';

  @override
  String get noChats => 'Chưa có cuộc trò chuyện';

  @override
  String get connectionError => 'Lỗi kết nối';

  @override
  String get databaseError => 'Lỗi cơ sở dữ liệu';

  @override
  String get syncError => 'Lỗi đồng bộ hóa';

  @override
  String get uploadError => 'Lỗi tải lên';

  @override
  String get downloadError => 'Lỗi tải xuống';

  @override
  String get themeSettings => 'Giao diện';

  @override
  String get lightTheme => 'Sáng';

  @override
  String get darkTheme => 'Tối';

  @override
  String get systemTheme => 'Theo hệ thống';

  @override
  String get themeChanged => 'Đã thay đổi giao diện';

  @override
  String get appearance => 'Giao diện';

  @override
  String get general => 'Chung';

  @override
  String get privacy => 'Riêng tư';

  @override
  String get security => 'Bảo mật';

  @override
  String get help => 'Trợ giúp';

  @override
  String get feedback => 'Phản hồi';

  @override
  String get version => 'Phiên bản';

  @override
  String get account => 'Tài khoản';

  @override
  String get profile => 'Hồ sơ';

  @override
  String get avatar => 'Ảnh đại diện';

  @override
  String get displayName => 'Tên hiển thị';

  @override
  String get bio => 'Tiểu sử';

  @override
  String get accessibility => 'Khả năng tiếp cận';

  @override
  String get fontSize => 'Cỡ chữ';

  @override
  String get animations => 'Hoạt ảnh';

  @override
  String get pleaseEnterGroupName => 'Vui lòng nhập tên nhóm';

  @override
  String get pleaseSelectMembers => 'Vui lòng chọn ít nhất một thành viên';

  @override
  String get createNewGroup => 'Tạo nhóm mới';

  @override
  String get create => 'Tạo';

  @override
  String get dontHaveAccount => 'Chưa có tài khoản?';

  @override
  String chatTitle(String chatId) {
    return 'Chat $chatId';
  }

  @override
  String get comingSoon => 'Sắp ra mắt';

  @override
  String get viewInfo => 'Xem thông tin';

  @override
  String get groupName => 'Tên nhóm';

  @override
  String get members => 'Thành viên';

  @override
  String get addMembers => 'Thêm thành viên';

  @override
  String get search => 'Tìm kiếm';

  @override
  String get muteNotifications => 'Tắt thông báo';

  @override
  String memberCount(int count) {
    return '$count thành viên';
  }

  @override
  String get typing => 'Đang nhập...';

  @override
  String get seen => 'Đã xem';

  @override
  String get sent => 'Đã gửi';

  @override
  String get sending => 'Đang gửi...';

  @override
  String get cannotLoadMessages => 'Không thể tải tin nhắn';

  @override
  String get justNow => 'Vừa xong';

  @override
  String minutesAgo(int minutes) {
    return '$minutes phút trước';
  }

  @override
  String hoursAgo(int hours) {
    return '$hours giờ trước';
  }

  @override
  String get reply => 'Trả lời';

  @override
  String get forward => 'Chuyển tiếp';

  @override
  String get confirmDelete => 'Bạn có chắc chắn muốn xóa tin nhắn này?';

  @override
  String get contacts => 'Danh bạ';

  @override
  String get groups => 'Nhóm';

  @override
  String get welcomeToChat => 'Chào mừng đến với Flutter Chat App';

  @override
  String get errorNoInternet => 'Không có kết nối internet. Vui lòng kiểm tra mạng của bạn.';

  @override
  String get errorServer => 'Lỗi máy chủ. Vui lòng thử lại sau.';

  @override
  String get errorCache => 'Không thể tải dữ liệu đã lưu.';

  @override
  String get errorUnexpected => 'Đã xảy ra lỗi không mong muốn. Vui lòng thử lại.';

  @override
  String get errorValidation => 'Dữ liệu không hợp lệ. Vui lòng kiểm tra lại.';

  @override
  String get loadingConversations => 'Đang tải cuộc trò chuyện...';

  @override
  String get loadingMessages => 'Đang tải tin nhắn...';

  @override
  String get sendingMessage => 'Đang gửi tin nhắn...';

  @override
  String get creatingGroup => 'Đang tạo nhóm...';

  @override
  String get updatingGroup => 'Đang cập nhật nhóm...';

  @override
  String get deletingConversation => 'Đang xóa cuộc trò chuyện...';

  @override
  String get leavingConversation => 'Đang rời khỏi cuộc trò chuyện...';

  @override
  String get noConversations => 'Chưa có cuộc trò chuyện. Bắt đầu trò chuyện mới!';

  @override
  String get noMessagesInChat => 'Chưa có tin nhắn. Gửi tin nhắn đầu tiên!';

  @override
  String get noSearchResults => 'Không tìm thấy kết quả nào.';

  @override
  String get messageEmpty => 'Tin nhắn không được để trống';

  @override
  String get nameRequired => 'Tên là bắt buộc';

  @override
  String get membersRequired => 'Vui lòng chọn ít nhất một thành viên';

  @override
  String get conversationIdRequired => 'ID cuộc trò chuyện là bắt buộc';

  @override
  String get messageIdRequired => 'ID tin nhắn là bắt buộc';

  @override
  String get invalidPageSize => 'Kích thước trang phải từ 1 đến 100';

  @override
  String get invalidPageNumber => 'Số trang phải lớn hơn hoặc bằng 0';

  @override
  String get invalidReadCount => 'Số lượng đọc phải lớn hơn 0';

  @override
  String get retryOperation => 'Thử lại';

  @override
  String get pullToRefresh => 'Kéo để làm mới';

  @override
  String get releaseToRefresh => 'Thả để làm mới';

  @override
  String get refreshing => 'Đang làm mới...';

  @override
  String get loadingMore => 'Đang tải thêm...';

  @override
  String get syncing => 'Đang đồng bộ...';

  @override
  String get edited => 'Đã chỉnh sửa';

  @override
  String get deleted => 'Tin nhắn đã bị xóa';

  @override
  String get you => 'Bạn';

  @override
  String get admin => 'Quản trị viên';

  @override
  String get leaveGroup => 'Rời nhóm';

  @override
  String get deleteConversation => 'Xóa cuộc trò chuyện';

  @override
  String get editGroup => 'Chỉnh sửa nhóm';

  @override
  String get groupInfo => 'Thông tin nhóm';

  @override
  String get conversationDeleted => 'Đã xóa cuộc trò chuyện thành công';

  @override
  String get leftConversation => 'Bạn đã rời khỏi cuộc trò chuyện';

  @override
  String get groupCreated => 'Đã tạo nhóm thành công';

  @override
  String get groupCreatedSuccessfully => 'Đã tạo nhóm thành công';

  @override
  String get groupUpdated => 'Đã cập nhật nhóm thành công';

  @override
  String get messageSent => 'Đã gửi tin nhắn';

  @override
  String get messageEdited => 'Đã chỉnh sửa tin nhắn';

  @override
  String get messageDeleted => 'Đã xóa tin nhắn';

  @override
  String get confirmLeaveGroup => 'Bạn có chắc chắn muốn rời khỏi nhóm này?';

  @override
  String get confirmDeleteConversation => 'Bạn có chắc chắn muốn xóa cuộc trò chuyện này?';

  @override
  String get searchConversations => 'Tìm kiếm cuộc trò chuyện...';

  @override
  String get searchMessages => 'Tìm kiếm tin nhắn...';

  @override
  String get selectMembers => 'Chọn thành viên';

  @override
  String get groupDescription => 'Mô tả nhóm';

  @override
  String get optional => 'Tùy chọn';

  @override
  String get required => 'Bắt buộc';

  @override
  String get addPhoto => 'Thêm ảnh';

  @override
  String get changePhoto => 'Đổi ảnh';

  @override
  String get removePhoto => 'Xóa ảnh';

  @override
  String get camera => 'Máy ảnh';

  @override
  String get gallery => 'Thư viện';

  @override
  String get file => 'Tệp';

  @override
  String get attachFile => 'Đính kèm tệp';

  @override
  String replyTo(String name) {
    return 'Trả lời $name';
  }

  @override
  String get forwardedMessage => 'Tin nhắn được chuyển tiếp';

  @override
  String mentionedYou(String name) {
    return '$name đã nhắc đến bạn';
  }

  @override
  String unreadMessages(int count) {
    return '$count tin nhắn chưa đọc';
  }

  @override
  String get markAsRead => 'Đánh dấu đã đọc';

  @override
  String get markAsUnread => 'Đánh dấu chưa đọc';

  @override
  String get copyMessage => 'Sao chép tin nhắn';

  @override
  String get editMessage => 'Chỉnh sửa tin nhắn';

  @override
  String get deleteMessage => 'Xóa tin nhắn';

  @override
  String get forwardMessage => 'Chuyển tiếp tin nhắn';

  @override
  String get replyMessage => 'Trả lời tin nhắn';

  @override
  String get reactToMessage => 'Bày tỏ cảm xúc';

  @override
  String get messageCopied => 'Đã sao chép tin nhắn vào clipboard';

  @override
  String get offlineMode => 'Bạn đang ngoại tuyến. Tin nhắn sẽ được gửi khi kết nối lại.';

  @override
  String get syncingMessages => 'Đang đồng bộ tin nhắn...';

  @override
  String get messageQueued => 'Tin nhắn đã được xếp hàng để gửi';

  @override
  String get operationQueued => 'Thao tác đã được xếp hàng. Sẽ xử lý khi có kết nối.';

  @override
  String get backOnline => 'Đã kết nối lại. Đang đồng bộ...';

  @override
  String get connectionLost => 'Mất kết nối. Đang làm việc ngoại tuyến.';

  @override
  String get buttonLoading => 'Đang tải...';

  @override
  String get buttonDisabled => 'Nút bị vô hiệu hóa';

  @override
  String get primaryButton => 'Nút chính';

  @override
  String get secondaryButton => 'Nút phụ';

  @override
  String get textButton => 'Nút văn bản';

  @override
  String get outlinedButton => 'Nút viền';

  @override
  String get iconButton => 'Nút biểu tượng';

  @override
  String get floatingActionButton => 'Nút hành động nổi';

  @override
  String get showPassword => 'Hiện mật khẩu';

  @override
  String get hidePassword => 'Ẩn mật khẩu';

  @override
  String get clearSearch => 'Xóa tìm kiếm';

  @override
  String get enterText => 'Nhập văn bản';

  @override
  String characterCount(int current, int max) {
    return '$current / $max ký tự';
  }

  @override
  String get validationRequired => 'Trường này là bắt buộc';

  @override
  String get validationEmail => 'Vui lòng nhập địa chỉ email hợp lệ';

  @override
  String validationMinLength(int length) {
    return 'Phải có ít nhất $length ký tự';
  }

  @override
  String validationMaxLength(int length) {
    return 'Không được vượt quá $length ký tự';
  }

  @override
  String get tapToSelect => 'Nhấn để chọn';

  @override
  String get doubleTapToOpen => 'Nhấn đúp để mở';

  @override
  String get noItemsFound => 'Không tìm thấy mục nào';

  @override
  String get noItemsDescription => 'Không có mục nào để hiển thị';

  @override
  String get noInternetConnection => 'Không có kết nối Internet';

  @override
  String get checkInternetConnection => 'Vui lòng kiểm tra kết nối internet và thử lại';
}
