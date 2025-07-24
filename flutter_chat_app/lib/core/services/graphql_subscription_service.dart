import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:injectable/injectable.dart';
import 'package:flutter_chat_app/core/services/realtime_connection_service.dart';
import 'package:uuid/uuid.dart';
import 'package:rxdart/rxdart.dart';

/// Định nghĩa các loại subscription
enum SubscriptionType {
  /// Nhận tin nhắn mới
  messageAdded,
  
  /// Cập nhật tin nhắn
  messageUpdated,
  
  /// Xóa tin nhắn
  messageDeleted,
  
  /// Cập nhật trạng thái người dùng (online/offline)
  userStatusChanged,
  
  /// Thêm người dùng vào chat
  userAddedToChat,
  
  /// Xóa người dùng khỏi chat
  userRemovedFromChat,
  
  /// Cập nhật chat
  chatUpdated,
  
  /// Thông báo typing
  typingIndicator,
}

/// Định nghĩa các trạng thái của subscription
enum SubscriptionStatus {
  /// Chưa subscribe
  inactive,
  
  /// Đang subscribe
  active,
  
  /// Tạm dừng
  paused,
  
  /// Đã hủy
  cancelled,
  
  /// Lỗi
  error,
}

/// Class quản lý GraphQL subscriptions thông qua WebSocket
@lazySingleton
class GraphQLSubscriptionService {
  /// Service quản lý kết nối realtime
  final RealtimeConnectionService _realtimeConnectionService;
  
  /// GraphQL Client
  final GraphQLClient _client;
  
  /// Danh sách các subscription đang hoạt động
  final Map<String, _Subscription> _activeSubscriptions = {};
  
  /// Danh sách subscription đang chờ kết nối
  final Map<String, _Subscription> _pendingSubscriptions = {};
  
  /// Uuid generator
  final _uuid = Uuid();
  
  /// Controller cho stream trạng thái kết nối
  final _connectionStatusController = StreamController<bool>.broadcast();
  
  /// Đăng ký lắng nghe trạng thái kết nối
  StreamSubscription? _connectionStateSubscription;
  
  /// Đăng ký lắng nghe tin nhắn
  StreamSubscription? _messageSubscription;
  
  /// Đã khởi tạo
  bool _initialized = false;
  
  /// Constructor
  GraphQLSubscriptionService(
    this._realtimeConnectionService,
    this._client,
  );
  
  /// Khởi tạo service
  Future<void> initialize() async {
    if (_initialized) return;
    
    // Đảm bảo RealtimeConnectionService đã được khởi tạo
    if (!_realtimeConnectionService.isConnected) {
      await _realtimeConnectionService.initialize();
    }
    
    // Lắng nghe trạng thái kết nối
    _connectionStateSubscription = _realtimeConnectionService.connectionStateStream.listen((state) {
      if (state == ConnectionState.connected) {
        _connectionStatusController.add(true);
        _resubscribeAll();
      } else if (state == ConnectionState.disconnected || 
                state == ConnectionState.closed) {
        _connectionStatusController.add(false);
        _markAllSubscriptionsAsPending();
      }
    });
    
    // Lắng nghe tin nhắn từ server
    _messageSubscription = _realtimeConnectionService.messageStream.listen(_handleMessage);
    
    _initialized = true;
  }
  
  /// Stream theo dõi trạng thái kết nối
  Stream<bool> get connectionStatus => _connectionStatusController.stream;
  
  /// Tạo subscription mới
  Stream<Map<String, dynamic>> subscribe({
    required String query,
    Map<String, dynamic>? variables,
    SubscriptionType type = SubscriptionType.messageAdded,
    String? operationName,
    bool retryOnError = true,
    Duration throttleWindow = const Duration(milliseconds: 500),
  }) {
    // Tạo ID cho subscription
    final id = _uuid.v4();
    
    // Tạo subscription controller với khả năng buffer khi mất kết nối
    // Controller này sẽ được close trong _unsubscribe() method khi subscription bị hủy
    final controller = StreamController<Map<String, dynamic>>.broadcast(
      onCancel: () {
        _unsubscribe(id);
      },
    );
    
    // Tạo subscription
    final subscription = _Subscription(
      id: id,
      query: query,
      variables: variables,
      type: type,
      controller: controller,
      operationName: operationName,
      status: SubscriptionStatus.inactive,
      retryOnError: retryOnError,
      throttleWindow: throttleWindow,
    );
    
    // Lưu subscription
    _activeSubscriptions[id] = subscription;
    
    // Bắt đầu subscription nếu đã kết nối
    if (_realtimeConnectionService.isConnected) {
      _startSubscription(subscription);
    } else {
      // Thêm vào danh sách chờ
      _pendingSubscriptions[id] = subscription;
      
      // Cố gắng kết nối
      _realtimeConnectionService.connect();
    }
    
    // Trả về stream với khoảng thời gian gộp sự kiện
    return controller.stream.debounceTime(throttleWindow);
  }
  
  /// Hủy tất cả subscription
  Future<void> unsubscribeAll() async {
    final subscriptions = List<_Subscription>.from(_activeSubscriptions.values);
    
    for (final subscription in subscriptions) {
      await _unsubscribe(subscription.id);
    }
    
    // Xóa danh sách chờ
    _pendingSubscriptions.clear();
  }
  
  /// Hủy subscription
  Future<void> _unsubscribe(String id) async {
    final subscription = _activeSubscriptions[id];
    if (subscription == null) {
      // Kiểm tra trong danh sách chờ
      _pendingSubscriptions.remove(id);
      return;
    }
    
    // Gửi lệnh hủy subscription
    if (_realtimeConnectionService.isConnected &&
        subscription.status == SubscriptionStatus.active) {
      await _realtimeConnectionService.sendMessage(
        'stop',
        {'id': id},
        queueIfDisconnected: false,
      );
    }
    
    // Đóng controller và xóa khỏi danh sách
    subscription.controller.close();
    _activeSubscriptions.remove(id);
    _pendingSubscriptions.remove(id);
  }
  
  /// Bắt đầu subscription
  Future<void> _startSubscription(_Subscription subscription) async {
    try {
      // Cập nhật trạng thái
      subscription.status = SubscriptionStatus.active;
      
      // Chuẩn bị payload cho subscription
      final payload = {
        'id': subscription.id,
        'type': 'start',
        'payload': {
          'query': subscription.query,
          'variables': subscription.variables,
          'operationName': subscription.operationName,
        },
      };
      
      // Gửi yêu cầu subscription
      final success = await _realtimeConnectionService.sendMessage(
        'subscription',
        payload,
        queueIfDisconnected: true,
      );
      
      if (!success) {
        if (_realtimeConnectionService.isConnecting) {
          // Thêm vào danh sách chờ
          _pendingSubscriptions[subscription.id] = subscription;
        } else {
          subscription.status = SubscriptionStatus.error;
          subscription.controller.addError('Không thể bắt đầu subscription');
        }
      } else {
        // Xóa khỏi danh sách chờ nếu có
        _pendingSubscriptions.remove(subscription.id);
      }
    } catch (e) {
      subscription.status = SubscriptionStatus.error;
      subscription.controller.addError('Lỗi bắt đầu subscription: $e');
      
      // Thử lại nếu cần
      if (subscription.retryOnError) {
        _pendingSubscriptions[subscription.id] = subscription;
      }
    }
  }
  
  /// Đánh dấu tất cả subscription là đang chờ
  void _markAllSubscriptionsAsPending() {
    for (final subscription in _activeSubscriptions.values) {
      if (subscription.status == SubscriptionStatus.active) {
        subscription.status = SubscriptionStatus.paused;
        _pendingSubscriptions[subscription.id] = subscription;
      }
    }
  }
  
  /// Thực hiện lại tất cả subscription
  Future<void> _resubscribeAll() async {
    // Lấy danh sách subscription cần thực hiện lại
    final pendingSubscriptions = Map<String, _Subscription>.from(_pendingSubscriptions);
    _pendingSubscriptions.clear();
    
    // Thực hiện lại từng subscription
    for (final subscription in pendingSubscriptions.values) {
      if (subscription.status != SubscriptionStatus.cancelled) {
        await _startSubscription(subscription);
      }
    }
  }
  
  /// Xử lý tin nhắn từ server
  void _handleMessage(RealtimeMessage message) {
    // Chỉ xử lý tin nhắn liên quan đến subscription
    if (message.type != 'subscription' && 
        message.type != 'subscription_data' &&
        message.type != 'subscription_error') {
      return;
    }
    
    final data = message.data;
    if (data == null || data is! Map) return;
    
    // Lấy ID subscription
    final id = data['id'] as String?;
    if (id == null) return;
    
    // Tìm subscription
    final subscription = _activeSubscriptions[id];
    if (subscription == null) return;
    
    // Xử lý dữ liệu
    switch (message.type) {
      case 'subscription_data':
        final payload = data['payload'];
        if (payload is Map) {
          subscription.controller.add(Map<String, dynamic>.from(payload));
        }
        break;
        
      case 'subscription_error':
        final error = data['payload'] ?? 'Lỗi subscription không xác định';
        subscription.status = SubscriptionStatus.error;
        subscription.controller.addError(error);
        
        // Thử lại nếu cần
        if (subscription.retryOnError) {
          _pendingSubscriptions[id] = subscription;
          _startSubscription(subscription);
        }
        break;
        
      case 'subscription':
        if (data['type'] == 'complete') {
          subscription.status = SubscriptionStatus.cancelled;
          _unsubscribe(id);
        }
        break;
    }
  }
  
  /// Đóng service
  Future<void> dispose() async {
    await unsubscribeAll();
    
    // Hủy các subscription
    _connectionStateSubscription?.cancel();
    _messageSubscription?.cancel();
    
    await _connectionStatusController.close();
    
    _initialized = false;
  }
  
  /// Truy vấn và subscription cùng lúc
  Future<Stream<Map<String, dynamic>>> queryAndSubscribe({
    required String query,
    required String subscriptionQuery,
    Map<String, dynamic>? variables,
    FetchPolicy fetchPolicy = FetchPolicy.networkOnly,
    SubscriptionType type = SubscriptionType.messageAdded,
    String? operationName,
    Duration throttleWindow = const Duration(milliseconds: 500),
    int maxRetryAttempts = 3,
  }) async {
    // Tạo controller với khả năng buffer khi mất kết nối
    final controller = StreamController<Map<String, dynamic>>.broadcast();
    
    // Biến đánh dấu đã thêm kết quả ban đầu
    bool initialDataAdded = false;
    
    // Hàm thực hiện query
    Future<void> executeQuery() async {
      int retryCount = 0;
      bool success = false;
      
      while (!success && retryCount < maxRetryAttempts) {
        try {
          // Thực hiện query
          final result = await _client.query(
            QueryOptions(
              document: gql(query),
              variables: variables ?? {},
              fetchPolicy: fetchPolicy,
              operationName: operationName,
            ),
          );
          
          // Kiểm tra lỗi
          if (result.hasException) {
            throw result.exception!;
          }
          
          // Thêm kết quả vào stream và đánh dấu đã thêm
          if (!controller.isClosed && !initialDataAdded) {
            controller.add(result.data!);
            initialDataAdded = true;
          }
          
          success = true;
        } catch (e) {
          debugPrint('Query error (attempt ${retryCount + 1}): $e');
          retryCount++;
          
          // Đợi trước khi thử lại
          if (retryCount < maxRetryAttempts) {
            await Future.delayed(Duration(seconds: retryCount * 2));
          }
        }
      }
      
      // Nếu không thành công sau nhiều lần thử, báo lỗi
      if (!success && !controller.isClosed) {
        controller.addError('Không thể lấy dữ liệu sau $maxRetryAttempts lần thử');
      }
    }
    
    // Thực hiện query đầu tiên
    executeQuery();
    
    // Tạo subscription
    final subscription = subscribe(
      query: subscriptionQuery,
      variables: variables,
      type: type,
      operationName: operationName,
      throttleWindow: throttleWindow,
    );
    
    // Chuyển tiếp dữ liệu từ subscription
    subscription.listen(
      (data) {
        if (!controller.isClosed) {
          controller.add(data);
        }
      },
      onError: (error) {
        if (!controller.isClosed) {
          controller.addError(error);
        }
      },
      onDone: () {
        if (!controller.isClosed) {
          controller.close();
        }
      },
    );
    
    return controller.stream;
  }
  
  /// Kiểm tra trạng thái kết nối
  bool get isConnected => _realtimeConnectionService.isConnected;
  
  /// Kết nối thủ công
  Future<bool> connect() async {
    return _realtimeConnectionService.connect();
  }
}

/// Lớp đại diện cho một subscription
class _Subscription {
  /// ID của subscription
  final String id;
  
  /// Query GraphQL
  final String query;
  
  /// Biến cho query
  final Map<String, dynamic>? variables;
  
  /// Loại subscription
  final SubscriptionType type;
  
  /// Controller cho stream
  final StreamController<Map<String, dynamic>> controller;
  
  /// Tên operation
  final String? operationName;
  
  /// Thử lại khi lỗi
  final bool retryOnError;
  
  /// Thời gian chờ giữa các sự kiện trùng lặp
  final Duration throttleWindow;
  
  /// Trạng thái subscription
  SubscriptionStatus status;
  
  /// Constructor
  _Subscription({
    required this.id,
    required this.query,
    this.variables,
    required this.type,
    required this.controller,
    this.operationName,
    this.status = SubscriptionStatus.inactive,
    this.retryOnError = true,
    this.throttleWindow = const Duration(milliseconds: 500),
  });
} 