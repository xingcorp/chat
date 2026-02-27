
import 'package:flutter/scheduler.dart';
import 'package:flutter_chat_app/core/cache/app_cache_manager.dart';
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';

/// Manager quản lý chiến lược đồng bộ và invalidate cache
@singleton
class CacheSyncStrategy {
  /// Singleton instance
  static final CacheSyncStrategy _instance = CacheSyncStrategy._internal();
  
  /// Factory constructor
  factory CacheSyncStrategy() => _instance;
  
  /// Logger
  final _logger = Logger();
  
  /// AppCacheManager instance
  final AppCacheManager _cacheManager = AppCacheManager();
  
  /// Cache prefixes
  static const String chatListPrefix = 'chat_list';
  static const String chatDetailPrefix = 'chat_detail_';
  static const String chatMessagesPrefix = 'chat_messages_';
  static const String userDataPrefix = 'user_data_';
  
  /// Flags để đánh dấu các loại dữ liệu đã bị thay đổi
  bool _chatListDirty = false;
  bool _userDataDirty = false;
  final Map<String, bool> _chatDetailsDirty = {};
  final Map<String, bool> _chatMessagesDirty = {};
  
  /// Thời gian cập nhật cuối cùng của chat list
  DateTime? _lastChatListUpdate;
  
  /// Private constructor
  CacheSyncStrategy._internal();
  
  /// Đánh dấu chat list đã thay đổi (khi có chat mới hoặc cập nhật)
  void markChatListDirty() {
    _chatListDirty = true;
    // _logger.t('Đánh dấu chat list đã thay đổi');
  }
  
  /// Đánh dấu chi tiết của một chat đã thay đổi
  void markChatDetailsDirty(String chatId) {
    _chatDetailsDirty[chatId] = true;
    _logger.t('Đánh dấu chi tiết chat $chatId đã thay đổi');
  }
  
  /// Đánh dấu tin nhắn của một chat đã thay đổi
  void markChatMessagesDirty(String chatId) {
    _chatMessagesDirty[chatId] = true;
    _logger.t('Đánh dấu tin nhắn của chat $chatId đã thay đổi');
  }
  
  /// Đánh dấu dữ liệu người dùng đã thay đổi
  void markUserDataDirty() {
    _userDataDirty = true;
    _logger.t('Đánh dấu dữ liệu người dùng đã thay đổi');
  }
  
  /// Đánh dấu tất cả cache đã thay đổi (thường gọi sau khi đăng nhập/đăng xuất)
  void markAllDirty() {
    _chatListDirty = true;
    _userDataDirty = true;
    _chatDetailsDirty.clear();
    _chatMessagesDirty.clear();
    _logger.i('Đánh dấu tất cả cache đã thay đổi');
  }
  
  /// Kiểm tra xem chat list cache có cần làm mới không
  bool shouldRefreshChatList() {
    // Nếu đã đánh dấu dirty, cần refresh
    if (_chatListDirty) {
      return true;
    }
    
    // Kiểm tra thời gian cập nhật cuối cùng
    if (_lastChatListUpdate != null) {
      final timeSinceLastUpdate = DateTime.now().difference(_lastChatListUpdate!);
      // Refresh nếu đã hơn 5 phút kể từ lần cập nhật cuối
      if (timeSinceLastUpdate > const Duration(minutes: 5)) {
        _logger.t('Cần refresh chat list do đã quá 5 phút từ lần cập nhật cuối');
        return true;
      }
    }
    
    return false;
  }
  
  /// Kiểm tra xem chi tiết chat có cần làm mới không
  bool shouldRefreshChatDetails(String chatId) {
    return _chatDetailsDirty[chatId] ?? false;
  }
  
  /// Kiểm tra xem tin nhắn của chat có cần làm mới không
  bool shouldRefreshChatMessages(String chatId) {
    return _chatMessagesDirty[chatId] ?? false;
  }
  
  /// Kiểm tra xem dữ liệu người dùng có cần làm mới không
  bool shouldRefreshUserData() {
    return _userDataDirty;
  }
  
  /// Reset dirty flags sau khi đã làm mới chat list
  void resetChatListDirtyFlag() {
    _chatListDirty = false;
    _lastChatListUpdate = DateTime.now();
    _logger.t('Reset dirty flag cho chat list');
  }
  
  /// Reset dirty flag sau khi đã làm mới chi tiết chat
  void resetChatDetailsDirtyFlag(String chatId) {
    _chatDetailsDirty[chatId] = false;
    _logger.t('Reset dirty flag cho chi tiết chat $chatId');
  }
  
  /// Reset dirty flag sau khi đã làm mới tin nhắn chat
  void resetChatMessagesDirtyFlag(String chatId) {
    _chatMessagesDirty[chatId] = false;
    // _logger.t('Reset dirty flag cho tin nhắn chat $chatId');
  }
  
  /// Reset dirty flag sau khi đã làm mới dữ liệu người dùng
  void resetUserDataDirtyFlag() {
    _userDataDirty = false;
    _logger.t('Reset dirty flag cho dữ liệu người dùng');
  }
  
  /// Xử lý sự kiện real-time và invalidate cache tương ứng
  /// [eventType] là loại sự kiện, [data] là dữ liệu của sự kiện
  void handleRealTimeEvent(String eventType, dynamic data) {
    _logger.t('Xử lý sự kiện real-time: $eventType');
    
    switch (eventType) {
      case 'new_message':
      case 'message_updated':
      case 'message_deleted':
        if (data is Map && data.containsKey('chatId')) {
          final chatId = data['chatId'] as String;
          markChatMessagesDirty(chatId);
          markChatListDirty(); // Vì last message cũng cập nhật
          
          // Invalidate cụ thể cache key liên quan đến message này
          if (data.containsKey('id')) {
            final messageId = data['id'] as String;
            _invalidateMessageCache(chatId, messageId);
          }
        }
        break;
        
      case 'chat_created':
      case 'chat_updated':
      case 'chat_deleted':
        markChatListDirty();
        
        if (data is Map && data.containsKey('id')) {
          final chatId = data['id'] as String;
          markChatDetailsDirty(chatId);
          _invalidateChatCache(chatId);
        }
        break;
        
      case 'user_updated':
      case 'user_status_changed':
        markUserDataDirty();
        
        if (data is Map && data.containsKey('id')) {
          final userId = data['id'] as String;
          _invalidateUserCache(userId);
        }
        break;
        
      case 'typing_indicator':
        // Typing indicators không ảnh hưởng đến cache
        break;
        
      default:
        _logger.w('Sự kiện không xác định: $eventType');
        break;
    }
  }
  
  /// Invalidate cache liên quan đến một tin nhắn cụ thể
  void _invalidateMessageCache(String chatId, String messageId) {
    // Invalidate tin nhắn cụ thể
    _cacheManager.invalidateCache('message_$messageId');
    
    // Invalidate danh sách tin nhắn (với các prefix phổ biến)
    _invalidateWithPrefix('$chatMessagesPrefix$chatId');
  }
  
  /// Invalidate cache liên quan đến một chat cụ thể
  void _invalidateChatCache(String chatId) {
    // Invalidate chi tiết chat
    _cacheManager.invalidateCache('$chatDetailPrefix$chatId');
    
    // Invalidate danh sách chat
    _invalidateWithPrefix(chatListPrefix);
  }
  
  /// Invalidate cache liên quan đến một người dùng cụ thể
  void _invalidateUserCache(String userId) {
    _cacheManager.invalidateCache('$userDataPrefix$userId');
  }
  
  /// Invalidate tất cả cache bắt đầu bằng một prefix
  void _invalidateWithPrefix(String prefix) {
    // Thực hiện invalidate
    SchedulerBinding.instance.addPostFrameCallback((_) async {
      try {
        _logger.t('Invalidate cache với prefix: $prefix');
        
        // Lấy tất cả key bắt đầu bằng prefix
        final allKeys = _cacheManager.isInitialized 
            ? await _cacheManager.getAllCacheKeys() 
            : <String>[];
        
        final keysToInvalidate = allKeys
            .where((key) => key.startsWith(prefix))
            .toList();
        
        if (keysToInvalidate.isEmpty) {
          _logger.t('Không tìm thấy key nào với prefix: $prefix');
          return;
        }
        
        _logger.t('Tìm thấy ${keysToInvalidate.length} key với prefix: $prefix');
        
        // Invalidate từng key
        for (final key in keysToInvalidate) {
          await _cacheManager.invalidateCache(key);
        }
        
        _logger.i('Đã invalidate ${keysToInvalidate.length} cache entries với prefix: $prefix');
      } catch (e) {
        _logger.e('Lỗi khi invalidate cache với prefix $prefix: $e');
      }
    });
  }
  
  /// Xử lý tin nhắn mới và đảm bảo cache được cập nhật
  void handleNewMessage(String chatId, dynamic messageData) {
    // Đánh dấu các cache liên quan đến dirty
    markChatMessagesDirty(chatId);
    markChatListDirty(); // Vì tin nhắn cuối cùng trong danh sách chat thay đổi
    
    // Invalidate cache cụ thể cho tin nhắn
    if (messageData != null && messageData is Map && messageData.containsKey('id')) {
      final messageId = messageData['id'] as String;
      _invalidateMessageCache(chatId, messageId);
    }
    
    _logger.i('Đã xử lý tin nhắn mới cho chat $chatId');
  }
  
  /// Xử lý cập nhật trạng thái đọc tin nhắn
  void handleReadReceipt(String chatId, List<String> messageIds) {
    // Đánh dấu tin nhắn chat đã thay đổi
    markChatMessagesDirty(chatId);
    
    // Invalidate từng tin nhắn cụ thể đã được đọc
    for (final messageId in messageIds) {
      _cacheManager.invalidateCache('message_$messageId');
    }
    
    _logger.i('Đã xử lý trạng thái đọc tin nhắn cho ${messageIds.length} tin nhắn trong chat $chatId');
  }
  
  /// Xử lý cập nhật trạng thái online/offline của người dùng
  void handleUserStatusChange(String userId, String status) {
    // Đánh dấu dữ liệu người dùng đã thay đổi
    markUserDataDirty();
    
    // Invalidate cache cụ thể cho người dùng này
    _invalidateUserCache(userId);
    
    _logger.i('Đã xử lý thay đổi trạng thái của người dùng $userId: $status');
  }
} 