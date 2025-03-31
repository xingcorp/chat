import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:injectable/injectable.dart';
import 'package:flutter_chat_app/core/services/realtime_connection_service.dart';
import 'package:uuid/uuid.dart';

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
  
  /// Uuid generator
  final _uuid = Uuid();
  
  /// Controller cho stream trạng thái kết nối
  final _connectionStatusController = StreamController<bool>.broadcast();
  
  /// Constructor
  GraphQLSubscriptionService(
    this._realtimeConnectionService,
    this._client,
  ) {
    // Lắng nghe trạng thái kết nối
    _realtimeConnectionService.connectionStateStream.listen((state) {
      if (state == ConnectionState.connected) {
        _connectionStatusController.add(true);
        _resubscribeAll();
      } else if (state == ConnectionState.disconnected || 
                state == ConnectionState.closed) {
        _connectionStatusController.add(false);
      }
    });
    
    // Lắng nghe tin nhắn từ server
    _realtimeConnectionService.messageStream.listen(_handleMessage);
  }
  
  /// Stream theo dõi trạng thái kết nối
  Stream<bool> get connectionStatus => _connectionStatusController.stream;
  
  /// Tạo subscription mới
  Stream<Map<String, dynamic>> subscribe({
    required String query,
    Map<String, dynamic>? variables,
    SubscriptionType type = SubscriptionType.messageAdded,
    String? operationName,
  }) {
    // Tạo ID cho subscription
    final id = _uuid.v4();
    
    // Tạo subscription controller
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
    );
    
    // Lưu subscription
    _activeSubscriptions[id] = subscription;
    
    // Bắt đầu subscription nếu đã kết nối
    if (_realtimeConnectionService.isConnected) {
      _startSubscription(subscription);
    }
    
    return controller.stream;
  }
  
  /// Hủy tất cả subscription
  Future<void> unsubscribeAll() async {
    final subscriptions = List<_Subscription>.from(_activeSubscriptions.values);
    
    for (final subscription in subscriptions) {
      await _unsubscribe(subscription.id);
    }
  }
  
  /// Hủy subscription
  Future<void> _unsubscribe(String id) async {
    final subscription = _activeSubscriptions[id];
    if (subscription == null) return;
    
    // Gửi lệnh hủy subscription
    if (_realtimeConnectionService.isConnected &&
        subscription.status == SubscriptionStatus.active) {
      await _realtimeConnectionService.sendMessage(
        'stop',
        {'id': id},
      );
    }
    
    // Đóng controller và xóa khỏi danh sách
    subscription.controller.close();
    _activeSubscriptions.remove(id);
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
      );
      
      if (!success) {
        subscription.status = SubscriptionStatus.error;
        subscription.controller.addError('Không thể bắt đầu subscription');
      }
    } catch (e) {
      subscription.status = SubscriptionStatus.error;
      subscription.controller.addError('Lỗi bắt đầu subscription: $e');
    }
  }
  
  /// Thực hiện lại tất cả subscription
  Future<void> _resubscribeAll() async {
    final subscriptions = List<_Subscription>.from(_activeSubscriptions.values);
    
    for (final subscription in subscriptions) {
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
    await _connectionStatusController.close();
  }
  
  /// Truy vấn và subscription cùng lúc
  Future<Stream<Map<String, dynamic>>> queryAndSubscribe({
    required String query,
    required String subscriptionQuery,
    Map<String, dynamic>? variables,
    FetchPolicy fetchPolicy = FetchPolicy.networkOnly,
    SubscriptionType type = SubscriptionType.messageAdded,
    String? operationName,
  }) async {
    // Thực hiện query trước
    try {
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
      
      // Tạo subscription
      final subscription = subscribe(
        query: subscriptionQuery,
        variables: variables,
        type: type,
        operationName: operationName,
      );
      
      // Trả về stream với dữ liệu ban đầu
      final controller = StreamController<Map<String, dynamic>>.broadcast();
      
      // Thêm kết quả ban đầu
      controller.add(result.data!);
      
      // Chuyển tiếp dữ liệu từ subscription
      subscription.listen(
        controller.add,
        onError: controller.addError,
        onDone: controller.close,
      );
      
      return controller.stream;
    } catch (e) {
      debugPrint('Lỗi query và subscribe: $e');
      return subscribe(
        query: subscriptionQuery,
        variables: variables,
        type: type,
        operationName: operationName,
      );
    }
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
  });
} 