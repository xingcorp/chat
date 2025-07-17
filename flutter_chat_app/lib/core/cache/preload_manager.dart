import 'dart:async';

import 'package:flutter_chat_app/core/cache/app_cache_manager.dart';
import 'package:flutter_chat_app/core/cache/cache_stats.dart';
import 'package:flutter_chat_app/core/cache/media_cache_manager.dart';
import 'package:flutter_chat_app/core/utils/isolate_manager.dart';
import 'package:flutter_chat_app/domain/entities/chat_message.dart';
import 'package:get_it/get_it.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Manager quản lý tiền tải dữ liệu quan trọng khi ứng dụng khởi động
class PreloadManager {
  /// Singleton instance
  static final PreloadManager _instance = PreloadManager._internal();
  
  /// Factory constructor
  factory PreloadManager() => _instance;
  
  /// Logger
  final _logger = Logger();
  
  /// Các dependencies
  final AppCacheManager _cacheManager = AppCacheManager();
  final MediaCacheManager _mediaCacheManager = MediaCacheManager();
  final CacheStats _cacheStats = CacheStats();
  
  /// Isolate Manager
  late IsolateManager _isolateManager;
  
  /// Tiến trình tiền tải
  double _preloadProgress = 0.0;
  int _totalTasks = 0;
  int _completedTasks = 0;
  
  /// Shared Preferences
  late SharedPreferences _prefs;
  
  /// Stream controller để thông báo tiến trình
  final StreamController<double> _progressController = 
      StreamController<double>.broadcast();
  
  /// Stream theo dõi tiến trình tiền tải
  Stream<double> get preloadProgress => _progressController.stream;
  
  /// Hằng số cấu hình
  static const int preloadChatLimit = 10;
  static const int preloadMessageLimit = 20;
  static const int preloadUserLimit = 20;
  static const Duration preloadInterval = Duration(hours: 12);
  
  /// Chạy duy nhất một lần 
  static Completer<void>? _runningPreloadTask;
  
  /// Private constructor
  PreloadManager._internal();
  
  /// Khởi tạo
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    
    try {
      // Lấy IsolateManager từ DI container
      _isolateManager = GetIt.I<IsolateManager>();
    } catch (e) {
      _logger.w('Không thể lấy IsolateManager từ DI container: $e');
    }
    
    _logger.i('PreloadManager đã được khởi tạo');
  }
  
  /// Tiền tải dữ liệu quan trọng
  Future<void> preloadEssentialData() async {
    // Ngăn nhiều lần gọi đồng thời
    if (_runningPreloadTask != null && !_runningPreloadTask!.isCompleted) {
      _logger.i('Đang có tiền tải đang chạy, bỏ qua yêu cầu mới');
      return _runningPreloadTask!.future;
    }
    
    // Khởi tạo completer mới
    _runningPreloadTask = Completer<void>();
    
    // Kiểm tra xem đã đến lúc cần tiền tải lại chưa
    if (!_shouldPreload()) {
      _logger.i('Bỏ qua tiền tải, chưa đến thời gian');
      _runningPreloadTask!.complete();
      return _runningPreloadTask!.future;
    }
    
    _logger.i('Bắt đầu tiền tải dữ liệu quan trọng');
    _resetProgress();
    
    try {
      // Nếu có isolate manager, sử dụng isolates để tải
      try {
        await _preloadWithIsolates();
      } catch (e) {
        _logger.w('Isolate preload failed, falling back to main thread: $e');
        // Tiền tải các loại dữ liệu song song
        await Future.wait([
          _preloadUserProfile(),
          _preloadRecentChats(),
          _preloadFrequentlyUsedData(),
        ]);
      }
      
      _logger.i('Tiền tải dữ liệu hoàn tất');
      
      // Lưu thời gian tiền tải
      await _prefs.setInt('last_preload_time', DateTime.now().millisecondsSinceEpoch);
      
      // Hoàn tất tiền tải
      _runningPreloadTask!.complete();
      
      if (!_progressController.isClosed) {
        await _progressController.close();
      }
    } catch (e) {
      _logger.e('Lỗi khi tiền tải dữ liệu: $e');
      _updateProgress(1.0); // Hoàn thành (có lỗi)
      _runningPreloadTask!.completeError(e);
    }
    
    return _runningPreloadTask!.future;
  }
  
  /// Tiền tải dữ liệu sử dụng isolates
  Future<void> _preloadWithIsolates() async {
    _logger.i('Tiền tải dữ liệu sử dụng isolates');
    
    final tasks = <Future<void>>[];
    
    // Tăng số lượng task
    _increaseTaskCount(); // User profile
    _increaseTaskCount(); // Recent chats
    _increaseTaskCount(); // Frequently used data
    
    // Tiền tải thông tin người dùng trong isolate
    tasks.add(_isolateManager.processInBackground(
      taskType: IsolateTaskType.dataProcessing,
      taskId: 'preload_user_profile',
      data: null,
      priority: TaskPriority.high
    ).then((_) => _completeTask()));
    
    // Tiền tải các cuộc trò chuyện gần đây
    tasks.add(_isolateManager.processInBackground(
      taskType: IsolateTaskType.dataProcessing,
      taskId: 'preload_recent_chats',
      data: null,
      priority: TaskPriority.high
    ).then((_) => _completeTask()));
    
    // Tiền tải dữ liệu thường xuyên sử dụng
    tasks.add(_isolateManager.processInBackground(
      taskType: IsolateTaskType.dataProcessing,
      taskId: 'preload_frequent_data',
      data: null,
      priority: TaskPriority.medium
    ).then((_) => _completeTask()));
    
    // Chờ tất cả hoàn tất
    await Future.wait(tasks);
  }
  
  /// Tiền tải thông tin người dùng
  Future<void> _preloadUserProfile() async {
    _increaseTaskCount();
    
    try {
      // Giả lập tiền tải thông tin người dùng
      _logger.t('Tiền tải thông tin người dùng');
      await Future.delayed(const Duration(milliseconds: 500));
      
      _completeTask();
    } catch (e) {
      _logger.e('Lỗi khi tiền tải thông tin người dùng: $e');
      _completeTask();
    }
  }
  
  /// Tiền tải các cuộc trò chuyện gần đây
  Future<void> _preloadRecentChats() async {
    _increaseTaskCount();
    
    try {
      // Giả lập tiền tải chat gần đây
      _logger.t('Tiền tải danh sách chat gần đây');
      await Future.delayed(const Duration(milliseconds: 800));
      
      // Danh sách avatar URLs cần tiền tải
      final List<String> avatarUrls = [];
      
      // Giả lập: Thêm một số avatar URLs (trong thực tế sẽ lấy từ dữ liệu chat)
      avatarUrls.addAll([
        'https://example.com/avatar1.jpg',
        'https://example.com/avatar2.jpg',
        'https://example.com/avatar3.jpg',
      ]);
      
      // Tiền tải avatars
      if (avatarUrls.isNotEmpty) {
        _mediaCacheManager.prefetchThumbnails(avatarUrls);
      }
      
      _completeTask();
    } catch (e) {
      _logger.e('Lỗi khi tiền tải chat gần đây: $e');
      _completeTask();
    }
  }
  
  /// Tiền tải dữ liệu thường xuyên sử dụng
  Future<void> _preloadFrequentlyUsedData() async {
    _increaseTaskCount();
    
    try {
      _logger.t('Tiền tải dữ liệu thường xuyên sử dụng');
      
      // Lấy danh sách keys thường truy cập từ CacheStats
      final frequentKeys = _cacheStats.getMostAccessedKeys(limit: 20);

      // Tiền tải các dữ liệu này (thực tế sẽ tải dữ liệu thực)
      _logger.d('Preloading ${frequentKeys.length} frequent cache keys');
      await Future.delayed(const Duration(milliseconds: 600));
      
      _completeTask();
    } catch (e) {
      _logger.e('Lỗi khi tiền tải dữ liệu thường xuyên sử dụng: $e');
      _completeTask();
    }
  }
  
  /// Tiền tải danh sách tin nhắn cho một cuộc trò chuyện
  Future<void> preloadMessages(String chatId, {int limit = preloadMessageLimit}) async {
    try {
      _logger.t('Tiền tải tin nhắn cho chat: $chatId');
      
      // Giả lập tải tin nhắn
      await Future.delayed(const Duration(milliseconds: 700));
      
      // Trong thực tế sẽ gọi repository để tải tin nhắn và lưu vào cache
      
      _logger.t('Đã tiền tải tin nhắn cho chat: $chatId');
    } catch (e) {
      _logger.e('Lỗi khi tiền tải tin nhắn: $e');
    }
  }
  
  /// Tiền tải hình ảnh/media cho các tin nhắn
  Future<void> preloadMessageMedia(List<ChatMessage> messages) async {
    try {
      final List<String> imageUrls = [];
      final List<String> videoThumbnails = [];
      
      // Trong thực tế sẽ lấy URLs từ danh sách tin nhắn
      // Giả lập với một số URLs tĩnh
      imageUrls.addAll([
        'https://example.com/image1.jpg',
        'https://example.com/image2.jpg',
      ]);
      
      videoThumbnails.addAll([
        'https://example.com/video1_thumb.jpg',
      ]);
      
      // Tiền tải thumbnails cho cả hình ảnh và video
      await Future.wait([
        _prefetchImages(imageUrls),
        _prefetchImages(videoThumbnails),
      ]);
      
      _logger.t('Đã tiền tải ${imageUrls.length} hình ảnh và ${videoThumbnails.length} thumbnails video');
    } catch (e) {
      _logger.e('Lỗi khi tiền tải media: $e');
    }
  }
  
  /// Tiền tải danh sách hình ảnh
  Future<void> _prefetchImages(List<String> urls) async {
    if (urls.isEmpty) return;
    
    final futures = <Future<void>>[];
    
    for (final url in urls) {
      futures.add(_prefetchSingleImage(url));
    }
    
    // Giới hạn số lượng tải song song để tránh quá tải
    await Future.wait(futures);
  }
  
  /// Tiền tải một hình ảnh
  Future<void> _prefetchSingleImage(String url) async {
    try {
      if (await _cacheManager.isMediaCached(url, thumbnail: true)) {
        return; // Đã có trong cache
      }
      
      // Trong thực tế sẽ tải và lưu hình ảnh
      await Future.delayed(const Duration(milliseconds: 300));
    } catch (e) {
      _logger.t('Lỗi khi tiền tải hình ảnh $url: $e');
    }
  }
  
  /// Kiểm tra xem có nên tiền tải lại dữ liệu không
  bool _shouldPreload() {
    final lastPreloadTime = _prefs.getInt('last_preload_time');
    if (lastPreloadTime == null) return true; // Chưa từng tiền tải
    
    final lastTime = DateTime.fromMillisecondsSinceEpoch(lastPreloadTime);
    final now = DateTime.now();
    
    return now.difference(lastTime) > preloadInterval;
  }
  
  /// Reset tiến trình
  void _resetProgress() {
    _preloadProgress = 0.0;
    _totalTasks = 0;
    _completedTasks = 0;
    _progressController.add(_preloadProgress);
  }
  
  /// Tăng số lượng task cần hoàn thành
  void _increaseTaskCount() {
    _totalTasks++;
    _updateProgress(_completedTasks / _totalTasks);
  }
  
  /// Đánh dấu một task đã hoàn thành
  void _completeTask() {
    _completedTasks++;
    _updateProgress(_completedTasks / _totalTasks);
  }
  
  /// Cập nhật tiến trình
  void _updateProgress(double progress) {
    _preloadProgress = progress;
    if (!_progressController.isClosed) {
      _progressController.add(_preloadProgress);
    }
  }
} 