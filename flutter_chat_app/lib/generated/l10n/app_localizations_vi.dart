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
  String get readMore => 'Xem thêm';

  @override
  String get showLess => 'Thu gọn';

  @override
  String get yesterday => 'Hôm qua';

  @override
  String sentAt(String time) {
    return 'Đã gửi lúc $time';
  }

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
  String get noUsers => 'Không có người dùng';

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
  String get imagePreview => 'Xem trước';

  @override
  String get retake => 'Chụp lại';

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
  String get settings => 'Cài đặt';

  @override
  String get groups => 'Nhóm';

  @override
  String get welcomeToChat => 'Chào mừng đến với Flutter Chat App';

  @override
  String get errorNoInternet =>
      'Không có kết nối internet. Vui lòng kiểm tra mạng của bạn.';

  @override
  String get errorServer => 'Lỗi máy chủ. Vui lòng thử lại sau.';

  @override
  String get errorCache => 'Không thể tải dữ liệu đã lưu.';

  @override
  String get errorUnexpected =>
      'Đã xảy ra lỗi không mong muốn. Vui lòng thử lại.';

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
  String get noConversations =>
      'Chưa có cuộc trò chuyện. Bắt đầu trò chuyện mới!';

  @override
  String get allConversations => 'Tất cả';

  @override
  String get directConversations => 'Cá nhân';

  @override
  String get groupConversations => 'Nhóm';

  @override
  String get noDirectConversations => 'Không có chat cá nhân';

  @override
  String get noGroupConversations => 'Không có nhóm';

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
  String get chatInfo => 'Thông tin chat';

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
  String get confirmDeleteConversation =>
      'Bạn có chắc chắn muốn xóa cuộc trò chuyện này?';

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
  String get call => 'Gọi';

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
  String get onlyTextMessagesCanBeCopied =>
      'Chỉ tin nhắn văn bản mới có thể sao chép';

  @override
  String get offlineMode =>
      'Bạn đang ngoại tuyến. Tin nhắn sẽ được gửi khi kết nối lại.';

  @override
  String get syncingMessages => 'Đang đồng bộ tin nhắn...';

  @override
  String get messageQueued => 'Tin nhắn đã được xếp hàng để gửi';

  @override
  String get operationQueued =>
      'Thao tác đã được xếp hàng. Sẽ xử lý khi có kết nối.';

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
  String get checkInternetConnection =>
      'Vui lòng kiểm tra kết nối internet và thử lại';

  @override
  String get selectOption => 'Chọn một tùy chọn';

  @override
  String get enabled => 'Bật';

  @override
  String get disabled => 'Tắt';

  @override
  String get value => 'Giá trị';

  @override
  String get range => 'Phạm vi';

  @override
  String get minimum => 'Tối thiểu';

  @override
  String get maximum => 'Tối đa';

  @override
  String get searchPlaceholder => 'Tìm kiếm...';

  @override
  String get noResults => 'Không tìm thấy kết quả';

  @override
  String get selectDate => 'Chọn ngày';

  @override
  String get invalidDate => 'Ngày không hợp lệ';

  @override
  String get selectTime => 'Chọn giờ';

  @override
  String get invalidTime => 'Giờ không hợp lệ';

  @override
  String get rating => 'Đánh giá';

  @override
  String get rateThis => 'Đánh giá';

  @override
  String stars(int count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.compact(
      locale: localeName,
    );
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString sao',
      one: '1 sao',
    );
    return '$_temp0';
  }

  @override
  String get fieldRequired => 'Trường này là bắt buộc';

  @override
  String get invalidInput => 'Dữ liệu không hợp lệ';

  @override
  String get checked => 'Đã chọn';

  @override
  String get unchecked => 'Chưa chọn';

  @override
  String get indeterminate => 'Không xác định';

  @override
  String get selected => 'Đã chọn';

  @override
  String get unselected => 'Chưa chọn';

  @override
  String get slider => 'Thanh trượt';

  @override
  String get outOf => 'trên';

  @override
  String get volume => 'Âm lượng';

  @override
  String get messageBubble => 'Bong bóng tin nhắn';

  @override
  String get textMessage => 'Tin nhắn văn bản';

  @override
  String get imageMessage => 'Tin nhắn hình ảnh';

  @override
  String get videoMessage => 'Tin nhắn video';

  @override
  String get audioMessage => 'Tin nhắn âm thanh';

  @override
  String get fileMessage => 'Tin nhắn tệp';

  @override
  String get locationMessage => 'Tin nhắn vị trí';

  @override
  String get contactMessage => 'Tin nhắn liên hệ';

  @override
  String get systemMessage => 'Tin nhắn hệ thống';

  @override
  String get delivered => 'Đã gửi';

  @override
  String get read => 'Đã đọc';

  @override
  String get failed => 'Thất bại';

  @override
  String get pending => 'Đang chờ';

  @override
  String replyingTo(String author) {
    return 'Đang trả lời $author';
  }

  @override
  String get cancelReply => 'Hủy trả lời';

  @override
  String get voiceMessage => 'Tin nhắn thoại';

  @override
  String get photo => 'Ảnh';

  @override
  String get video => 'Video';

  @override
  String get audio => 'Âm thanh';

  @override
  String get document => 'Tài liệu';

  @override
  String get location => 'Vị trí';

  @override
  String get contact => 'Liên hệ';

  @override
  String get addReaction => 'Thêm biểu cảm';

  @override
  String get removeReaction => 'Xóa phản ứng';

  @override
  String get reactions => 'Phản ứng';

  @override
  String get recentlyUsed => 'Gần đây';

  @override
  String get searchEmoji => 'Tìm kiếm emoji';

  @override
  String get smileysAndPeople => 'Mặt cười & Con người';

  @override
  String get gesturesAndBodyParts => 'Cử chỉ & Bộ phận cơ thể';

  @override
  String get peopleAndProfessions => 'Con người & Nghề nghiệp';

  @override
  String get animalsAndNature => 'Động vật & Thiên nhiên';

  @override
  String get foodAndDrink => 'Đồ ăn & Đồ uống';

  @override
  String get activitiesAndSports => 'Hoạt động & Thể thao';

  @override
  String get activity => 'Hoạt động';

  @override
  String get travelAndPlaces => 'Du lịch & Địa điểm';

  @override
  String get objects => 'Đồ vật';

  @override
  String get symbols => 'Ký hiệu';

  @override
  String get flags => 'Cờ';

  @override
  String get noEmojisFound => 'Không tìm thấy emoji';

  @override
  String get searchEmojis => 'Tìm kiếm emoji';

  @override
  String get noRecentEmojis => 'Chưa có emoji gần đây';

  @override
  String get recent => 'Gần đây';

  @override
  String get smileys => 'Mặt cười';

  @override
  String get animals => 'Động vật';

  @override
  String get food => 'Đồ ăn';

  @override
  String get travel => 'Du lịch';

  @override
  String get activities => 'Hoạt động';

  @override
  String isTyping(String name) {
    return '$name đang nhập...';
  }

  @override
  String areTyping(String name1, String name2) {
    return '$name1 và $name2 đang nhập...';
  }

  @override
  String multipleTyping(int count) {
    return '$count người đang nhập...';
  }

  @override
  String get play => 'Phát';

  @override
  String get pause => 'Tạm dừng';

  @override
  String get stop => 'Dừng';

  @override
  String get playbackSpeed => 'Tốc độ phát';

  @override
  String get duration => 'Thời lượng';

  @override
  String get currentTime => 'Thời gian hiện tại';

  @override
  String get loadingAudio => 'Đang tải âm thanh...';

  @override
  String get remainingTime => 'Thời gian còn lại';

  @override
  String get recording => 'Đang ghi âm...';

  @override
  String get recordVoiceMessage => 'Ghi âm tin nhắn';

  @override
  String get sendVoiceMessage => 'Gửi tin nhắn thoại';

  @override
  String get cancelRecording => 'Hủy ghi âm';

  @override
  String get longPressToRecord => 'Giữ để ghi âm';

  @override
  String get slideToCancel => 'Trượt để hủy';

  @override
  String get releaseToSend => 'Thả để gửi';

  @override
  String get messageOptions => 'Tùy chọn tin nhắn';

  @override
  String get longPressForOptions => 'Giữ lâu để xem tùy chọn';

  @override
  String get tapToView => 'Nhấn để xem';

  @override
  String get tapToDownload => 'Nhấn để tải xuống';

  @override
  String get downloading => 'Đang tải xuống...';

  @override
  String get downloaded => 'Đã tải xuống';

  @override
  String get downloadFailed => 'Tải xuống thất bại';

  @override
  String get uploadFailed => 'Tải tệp lên thất bại';

  @override
  String get uploading => 'Đang tải lên...';

  @override
  String get uploaded => 'Đã tải lên';

  @override
  String get retryUpload => 'Thử lại tải lên';

  @override
  String get retryDownload => 'Thử lại tải xuống';

  @override
  String get cancelUpload => 'Hủy tải lên';

  @override
  String get cancelDownload => 'Hủy tải xuống';

  @override
  String get fileSize => 'Kích thước tệp';

  @override
  String get fileName => 'Tên tệp';

  @override
  String get fileType => 'Loại tệp';

  @override
  String get unsupportedFileType => 'Loại tệp không được hỗ trợ';

  @override
  String fileTooLarge(String fileName, String maxSize) {
    return '$fileName quá lớn. Kích thước tối đa là $maxSize';
  }

  @override
  String maxFileSize(String size) {
    return 'Kích thước tệp tối đa: $size';
  }

  @override
  String get tapToRetry => 'Nhấn để thử lại';

  @override
  String get sortAscending => 'Sắp xếp tăng dần';

  @override
  String get sortDescending => 'Sắp xếp giảm dần';

  @override
  String get filterColumn => 'Lọc cột';

  @override
  String get clearFilter => 'Xóa bộ lọc';

  @override
  String get selectAll => 'Chọn tất cả';

  @override
  String get deselectAll => 'Bỏ chọn tất cả';

  @override
  String selectedItems(int count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.compact(
      locale: localeName,
    );
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString mục được chọn',
      one: '1 mục được chọn',
      zero: 'Không có mục nào được chọn',
    );
    return '$_temp0';
  }

  @override
  String get noDataAvailable => 'Không có dữ liệu';

  @override
  String get rowsPerPage => 'Số hàng mỗi trang';

  @override
  String pageOf(int current, int total) {
    return 'Trang $current / $total';
  }

  @override
  String get firstPage => 'Trang đầu';

  @override
  String get previousPage => 'Trang trước';

  @override
  String get nextPage => 'Trang sau';

  @override
  String showingItems(int start, int end, int total) {
    return 'Hiển thị $start-$end trong tổng số $total';
  }

  @override
  String pageInfo(int current, int total) {
    return 'Trang $current / $total';
  }

  @override
  String get filter => 'Lọc';

  @override
  String get lastPage => 'Trang cuối';

  @override
  String get dropFilesHere => 'Thả tệp vào đây';

  @override
  String get dragDropOrClickToUpload =>
      'Kéo & thả tệp vào đây hoặc nhấp để chọn';

  @override
  String get maxFilesReached => 'Đã đạt số lượng tệp tối đa';

  @override
  String allowedFileTypes(String types) {
    return 'Loại tệp cho phép: $types';
  }

  @override
  String get errorPickingFiles => 'Lỗi khi chọn tệp';

  @override
  String fileTypeNotAllowed(String fileName) {
    return 'Loại tệp $fileName không được phép';
  }

  @override
  String get remove => 'Xóa';

  @override
  String get noImagesAvailable => 'Không có hình ảnh';

  @override
  String get share => 'Chia sẻ';

  @override
  String get download => 'Tải xuống';

  @override
  String get errorLoadingVideo => 'Lỗi tải video';

  @override
  String get quality => 'Chất lượng';

  @override
  String get pictureInPicture => 'Hình trong hình';

  @override
  String get enterFullscreen => 'Toàn màn hình';

  @override
  String get exitFullscreen => 'Thoát toàn màn hình';

  @override
  String get loop => 'Lặp lại';

  @override
  String get rewind10Seconds => 'Tua lại 10 giây';

  @override
  String get forward10Seconds => 'Tua tới 10 giây';

  @override
  String get errorLoadingAudio => 'Lỗi tải âm thanh';

  @override
  String get selectNone => 'Bỏ chọn tất cả';

  @override
  String get pasteCode => 'Dán mã';

  @override
  String get maxTagsReached => 'Đã đạt số lượng thẻ tối đa';

  @override
  String get duplicateTag => 'Thẻ đã tồn tại';

  @override
  String get addTag => 'Thêm thẻ';

  @override
  String get replyPreviewImage => '[Hình ảnh]';

  @override
  String get replyPreviewVideo => '[Video]';

  @override
  String get replyPreviewAudio => '[Ghi âm]';

  @override
  String replyPreviewFile(String fileName) {
    return '[Tệp] $fileName';
  }

  @override
  String get replyPreviewLocation => '[Vị trí]';

  @override
  String get replyPreviewLink => '[Liên kết]';

  @override
  String get replyPreviewSystemEvent => '[Sự kiện hệ thống]';

  @override
  String get eventSomeone => 'Ai đó';

  @override
  String eventAddMember(String actor, String targets) {
    return '$actor đã thêm $targets vào nhóm';
  }

  @override
  String eventRemoveMember(String actor, String targets) {
    return '$actor đã xóa $targets khỏi nhóm';
  }

  @override
  String eventLeaveConversation(String actor) {
    return '$actor đã rời khỏi nhóm';
  }

  @override
  String eventChangeNameFromTo(String actor, String oldName, String newName) {
    return '$actor đã đổi tên nhóm từ \"$oldName\" thành \"$newName\"';
  }

  @override
  String eventChangeName(String actor, String newName) {
    return '$actor đã đổi tên nhóm thành \"$newName\"';
  }

  @override
  String eventChangeAvatar(String actor) {
    return '$actor đã thay đổi ảnh nhóm';
  }

  @override
  String eventCreateConversation(String actor) {
    return '$actor đã tạo nhóm';
  }

  @override
  String eventPinMessage(String actor) {
    return '$actor đã ghim một tin nhắn';
  }

  @override
  String eventUnpinMessage(String actor) {
    return '$actor đã bỏ ghim một tin nhắn';
  }

  @override
  String eventJoinConversation(String actor) {
    return '$actor đã tham gia nhóm';
  }

  @override
  String eventChangeBackground(String actor) {
    return '$actor đã thay đổi hình nền nhóm';
  }

  @override
  String eventPromoteAdmin(String actor, String targets) {
    return '$actor đã thăng cấp $targets lên quản trị viên';
  }

  @override
  String eventDemoteAdmin(String actor, String targets) {
    return '$actor đã hạ cấp $targets khỏi quản trị viên';
  }

  @override
  String eventPerformedAction(String actor) {
    return '$actor đã thực hiện hành động';
  }

  @override
  String get unreadSeparatorLabel => 'Tin nhắn chưa đọc';

  @override
  String get pickAttachment => 'Chọn tệp đính kèm';

  @override
  String get takePhoto => 'Chụp ảnh';

  @override
  String get chooseFromGallery => 'Chọn từ thư viện';

  @override
  String get chooseFile => 'Chọn tệp';

  @override
  String get shareLocation => 'Chia sẻ vị trí';

  @override
  String get compressing => 'Đang nén...';

  @override
  String uploadProgress(int progress) {
    return 'Đang tải lên $progress%';
  }

  @override
  String fileTooLargeMax(int maxSize) {
    return 'Tệp quá lớn. Kích thước tối đa: ${maxSize}MB';
  }

  @override
  String get imageCompressionFailed => 'Nén ảnh thất bại';

  @override
  String get someoneIsTyping => 'Ai đó đang nhập...';

  @override
  String get lastSeenRecently => 'Hoạt động gần đây';

  @override
  String lastSeenAt(String time) {
    return 'Lần cuối truy cập: $time';
  }

  @override
  String lastSeenMinutesAgo(int minutes) {
    return 'Hoạt động $minutes phút trước';
  }

  @override
  String lastSeenHoursAgo(int hours) {
    return 'Hoạt động $hours giờ trước';
  }

  @override
  String lastSeenDaysAgo(int days) {
    return 'Hoạt động $days ngày trước';
  }

  @override
  String get messageNotFound => 'Không tìm thấy tin nhắn';

  @override
  String get editingMessage => 'Đang chỉnh sửa tin nhắn';

  @override
  String get forwardTo => 'Chuyển tiếp đến...';

  @override
  String get selectChat => 'Chọn cuộc hội thoại';

  @override
  String get scrollToBottom => 'Cuộn xuống cuối';

  @override
  String newMessagesCount(int count) {
    return '$count tin nhắn mới';
  }

  @override
  String selectedCount(int count) {
    return 'Đã chọn $count';
  }

  @override
  String confirmDeleteMultiple(int count) {
    return 'Xóa $count tin nhắn?';
  }

  @override
  String get linkPreview => 'Xem trước liên kết';

  @override
  String get openLink => 'Mở liên kết';

  @override
  String get copyLink => 'Sao chép liên kết';

  @override
  String readBy(String names) {
    return 'Đã xem bởi $names';
  }

  @override
  String get emptyMessage => 'Không có tin nhắn';

  @override
  String get attachment => 'Tệp đính kèm';

  @override
  String daysAgo(int days) {
    return '$days ngày';
  }

  @override
  String get unknownUser => 'Người dùng không xác định';

  @override
  String get attachments => 'Đính kèm';

  @override
  String get insertEmoji => 'Chèn biểu tượng cảm xúc';

  @override
  String get uploadingFile => 'Đang tải tệp lên...';

  @override
  String get locationPermissionDenied => 'Quyền truy cập vị trí bị từ chối';

  @override
  String get gettingLocation => 'Đang lấy vị trí của bạn...';

  @override
  String get locationSent => 'Đã gửi vị trí';

  @override
  String get selectReaction => 'Chọn biểu cảm';

  @override
  String reactedWith(String user, String emoji) {
    return '$user đã thả $emoji';
  }

  @override
  String get mentionUser => 'Nhắc đến người dùng';

  @override
  String membersCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count thành viên',
      one: '1 thành viên',
      zero: 'Không có thành viên',
    );
    return '$_temp0';
  }

  @override
  String get sharedMedia => 'Media đã chia sẻ';

  @override
  String get photos => 'Ảnh';

  @override
  String get videos => 'Video';

  @override
  String get files => 'Tệp';

  @override
  String get links => 'Liên kết';

  @override
  String get items => 'mục';

  @override
  String get unknownFile => 'Tệp không xác định';

  @override
  String get fileExtensionDefault => 'TỆP';

  @override
  String get searchMedia => 'Tìm kiếm media...';

  @override
  String get thisWeek => 'Tuần này';

  @override
  String get thisMonth => 'Tháng này';

  @override
  String get older => 'Cũ hơn';

  @override
  String dateFormatDayMonth(int day, String monthName) {
    return '$day tháng $monthName';
  }

  @override
  String get monthJanuary => '1';

  @override
  String get monthFebruary => '2';

  @override
  String get monthMarch => '3';

  @override
  String get monthApril => '4';

  @override
  String get monthMay => '5';

  @override
  String get monthJune => '6';

  @override
  String get monthJuly => '7';

  @override
  String get monthAugust => '8';

  @override
  String get monthSeptember => '9';

  @override
  String get monthOctober => '10';

  @override
  String get monthNovember => '11';

  @override
  String get monthDecember => '12';

  @override
  String get errorOpeningFile => 'Không thể mở tệp này';

  @override
  String get errorOpeningLink => 'Không thể mở liên kết này';

  @override
  String get viewAll => 'Xem tất cả';

  @override
  String get notifications => 'Thông báo';

  @override
  String get muteFor => 'Tắt trong';

  @override
  String get oneHour => '1 giờ';

  @override
  String get eightHours => '8 giờ';

  @override
  String get oneDay => '1 ngày';

  @override
  String get forever => 'Vĩnh viễn';

  @override
  String get blockUser => 'Chặn người dùng';

  @override
  String get unblockUser => 'Bỏ chặn người dùng';

  @override
  String get reportChat => 'Báo cáo chat';

  @override
  String get deleteChat => 'Xóa chat';

  @override
  String get noMediaYet => 'Chưa có media';

  @override
  String get createdBy => 'Tạo bởi';

  @override
  String get noMembers => 'Không có thành viên';

  @override
  String get searchMembers => 'Tìm thành viên';

  @override
  String get searchMessagesTitle => 'Tìm kiếm tin nhắn';

  @override
  String get typeToSearchMessages => 'Nhập để tìm kiếm tin nhắn';

  @override
  String get searchErrorOffline =>
      'Bạn đang ngoại tuyến. Vui lòng kiểm tra kết nối và thử lại.';

  @override
  String get searchErrorGeneric => 'Tìm kiếm thất bại. Vui lòng thử lại.';

  @override
  String searchResultCount(int count) {
    return 'Tìm thấy $count kết quả';
  }

  @override
  String get newConversation => 'Thêm cuộc hội thoại';

  @override
  String get removeMemberFromGroup => 'Xóa khỏi nhóm';

  @override
  String confirmRemoveMember(String name) {
    return 'Bạn có chắc muốn xóa $name khỏi nhóm không?';
  }

  @override
  String readByCount(int count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.compact(
      locale: localeName,
    );
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Đã xem bởi $countString người',
      one: 'Đã xem bởi 1 người',
      zero: 'Chưa ai đọc',
    );
    return '$_temp0';
  }

  @override
  String readByNames(String names) {
    return 'Đã xem bởi $names';
  }

  @override
  String get readReceiptTitle => 'Đã xem bởi';

  @override
  String get conversationNotFound =>
      'Cuộc trò chuyện không tồn tại hoặc đã bị xóa';

  @override
  String get cannotOpenConversation => 'Không thể mở cuộc trò chuyện';

  @override
  String get deleteMessageNotImplemented =>
      'Chức năng xóa tin nhắn chưa được triển khai';

  @override
  String get unknownError => 'Lỗi không xác định';

  @override
  String errorWithMessage(String message) {
    return 'Lỗi: $message';
  }

  @override
  String get selectConversationToStart => 'Chọn một cuộc trò chuyện để bắt đầu';

  @override
  String get cannotLoadMedia => 'Không thể tải media';

  @override
  String get attachmentImage => 'Hình ảnh';

  @override
  String get attachmentVideo => 'Video';

  @override
  String get attachmentFile => 'Tệp tin';

  @override
  String get attachmentLocation => 'Vị trí';

  @override
  String get notificationsMuted => 'Thông báo đã tắt';

  @override
  String get notificationsEnabled => 'Thông báo đang bật';

  @override
  String get userBlocked => 'Người dùng đã bị chặn';

  @override
  String get blockThisUser => 'Chặn người dùng này';

  @override
  String get reportSpamOrAbuse => 'Báo cáo spam hoặc lạm dụng';

  @override
  String get leaveThisGroup => 'Rời khỏi nhóm này';

  @override
  String get deleteThisConversation => 'Xóa cuộc trò chuyện này';

  @override
  String get viewProfile => 'Xem hồ sơ';

  @override
  String get sendDirectMessage => 'Nhắn tin riêng';

  @override
  String get viewFullImage => 'Xem ảnh đầy đủ';

  @override
  String get memberInfo => 'Thông tin thành viên';

  @override
  String get usernameLabel => 'Tên đăng nhập';

  @override
  String get currentlyOnline => 'Đang trực tuyến';

  @override
  String get stickers => 'Sticker';

  @override
  String get recentStickers => 'Gần đây';

  @override
  String get noStickersAvailable => 'Không có sticker';

  @override
  String get replyPreviewSticker => 'Sticker';
}
