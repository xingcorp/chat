import 'dart:async';

import 'package:flutter_chat_app/core/network/socket_manager.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:flutter/foundation.dart';
import 'package:flutter_chat_app/core/utils/logger.dart';

import 'socket_manager_test.mocks.dart';

@GenerateMocks([io.Socket, Logger])
void main() {
  late SocketManager socketManager;
  late MockSocket mockSocket;
  late MockLogger mockLogger;
  
  setUp(() {
    mockSocket = MockSocket();
    mockLogger = MockLogger();
    
    // Giả lập socket.connect() return socket instance để có thể chaining
    when(mockSocket.connect()).thenReturn(mockSocket);
    when(mockSocket.disconnect()).thenReturn(mockSocket);
    when(mockSocket.on(any, any)).thenReturn(mockSocket);
    when(mockSocket.onConnect(any)).thenReturn(mockSocket);
    when(mockSocket.onDisconnect(any)).thenReturn(mockSocket);
    when(mockSocket.onConnectError(any)).thenReturn(mockSocket);
    when(mockSocket.onError(any)).thenReturn(mockSocket);
    
    // Mặc định trạng thái socket là disconnected
    when(mockSocket.connected).thenReturn(false);
    
    socketManager = SocketManager(
      socket: mockSocket,
      logger: mockLogger
    );
  });

  tearDown(() {
    socketManager.dispose();
  });
  
  group('SocketManager Initialization Tests', () {
    test('should initialize with correct state', () {
      expect(socketManager.connectionState, equals(SocketConnectionState.disconnected));
      
      // Kiểm tra rằng tất cả các event handlers được đăng ký
      verify(mockSocket.onConnect(any)).called(1);
      verify(mockSocket.onDisconnect(any)).called(1);
      verify(mockSocket.onConnectError(any)).called(1);
      verify(mockSocket.onError(any)).called(1);
    });
  });
  
  group('Connection Tests', () {
    test('should connect to socket and update state', () {
      // Setup
      when(mockSocket.connected).thenReturn(false);
      
      // Hành động
      socketManager.connect();
      
      // Kiểm tra
      verify(mockSocket.connect()).called(1);
      expect(socketManager.connectionState, equals(SocketConnectionState.connecting));
    });
    
    test('should not connect if already connected', () {
      // Setup
      when(mockSocket.connected).thenReturn(true);
      
      // Hành động
      socketManager.connect();
      
      // Kiểm tra - không gọi connect nữa nếu đã connected
      verifyNever(mockSocket.connect());
    });

    test('should disconnect from socket', () {
      // Hành động
      socketManager.disconnect();
      
      // Kiểm tra
      verify(mockSocket.disconnect()).called(1);
    });
  });
  
  group('Event Handling Tests', () {
    test('should update connection state on socket connect event', () {
      // Tìm onConnect callback handler
      final Function onConnectHandler = verify(mockSocket.onConnect(captureAny)).captured.first;
      
      // Gọi callback để simulate socket connect event
      onConnectHandler([]);
      
      // Kiểm tra state được cập nhật
      expect(socketManager.connectionState, equals(SocketConnectionState.connected));
    });

    test('should update connection state on socket disconnect event', () {
      // Đặt trạng thái ban đầu là connected
      socketManager.connectionState = SocketConnectionState.connected;
      
      // Tìm onDisconnect callback handler
      final Function onDisconnectHandler = verify(mockSocket.onDisconnect(captureAny)).captured.first;
      
      // Gọi callback để simulate socket disconnect event
      onDisconnectHandler([]);
      
      // Kiểm tra state được cập nhật
      expect(socketManager.connectionState, equals(SocketConnectionState.disconnected));
    });

    test('should update connection state on socket error event', () {
      // Tìm onError callback handler
      final Function onErrorHandler = verify(mockSocket.onError(captureAny)).captured.first;
      
      // Gọi callback để simulate socket error event
      onErrorHandler(['Test error']);
      
      // Kiểm tra state được cập nhật
      expect(socketManager.connectionState, equals(SocketConnectionState.error));
    });

    test('should update connection state on socket connect error event', () {
      // Tìm onConnectError callback handler
      final Function onConnectErrorHandler = verify(mockSocket.onConnectError(captureAny)).captured.first;
      
      // Gọi callback để simulate connect error event
      onConnectErrorHandler(['Connection error']);
      
      // Kiểm tra state được cập nhật
      expect(socketManager.connectionState, equals(SocketConnectionState.error));
    });
  });
  
  group('Event Emission Tests', () {
    test('should emit events when socket is connected', () {
      // Setup
      when(mockSocket.connected).thenReturn(true);
      when(mockSocket.emit(any, any)).thenReturn(mockSocket);
      
      // Hành động
      socketManager.emit('test_event', {'data': 'test'});
      
      // Kiểm tra
      verify(mockSocket.emit('test_event', {'data': 'test'})).called(1);
    });
    
    test('should not emit events when socket is disconnected', () {
      // Setup
      when(mockSocket.connected).thenReturn(false);
      
      // Hành động
      socketManager.emit('test_event', {'data': 'test'});
      
      // Kiểm tra - không emit vì không connected
      verifyNever(mockSocket.emit(any, any));
      verify(mockLogger.e(any)).called(1);
    });
  });
  
  group('Event Listening Tests', () {
    test('should create a stream for socket events and emit data', () async {
      // Setup - Capture event handler being registered
      when(mockSocket.on(any, any)).thenReturn(mockSocket);
      
      // Hành động - Lấy stream cho event
      final stream = socketManager.on('test_event');
      expect(stream, isA<Stream>());
      
      // Xác minh handler được đăng ký
      final eventName = verify(mockSocket.on(captureAny, any)).captured.first;
      final eventHandler = verify(mockSocket.on(any, captureAny)).captured.first;
      
      expect(eventName, equals('test_event'));
      
      // Kiểm tra dữ liệu được emit qua Stream khi handler được gọi
      expectLater(stream, emits({'message': 'test_data'}));
      
      // Gọi handler để simulate socket event
      eventHandler({'message': 'test_data'});
    });
  });
  
  group('Background Mode Handling Tests', () {
    test('should handle entering background mode', () {
      // Setup
      socketManager.connectionState = SocketConnectionState.connected;
      
      // Hành động
      socketManager.enterBackground();
      
      // Kiểm tra
      verify(mockSocket.disconnect()).called(1);
      expect(socketManager.connectionState, equals(SocketConnectionState.disconnected));
    });

    test('should handle entering foreground mode', () {
      // Setup
      socketManager.connectionState = SocketConnectionState.disconnected;
      when(mockSocket.connected).thenReturn(false);
      
      // Hành động
      socketManager.enterForeground();
      
      // Kiểm tra
      verify(mockSocket.connect()).called(1);
      expect(socketManager.connectionState, equals(SocketConnectionState.connecting));
    });
  });
  
  group('Connection Resilience Tests', () {
    test('should attempt to reconnect after error', () async {
      // Setup fakeAsync
      final completer = Completer<void>();
      
      // Đặt trạng thái ban đầu
      socketManager.connectionState = SocketConnectionState.connected;
      when(mockSocket.connected).thenReturn(true);
      
      // Tìm onError callback handler
      final Function onErrorHandler = verify(mockSocket.onError(captureAny)).captured.first;
      
      // Override createReconnectTimer để kiểm tra reconnect
      socketManager.createReconnectTimer = () {
        // Gọi hàm reconnect ngay lập tức thay vì dùng timer
        socketManager.reconnectIfNeeded();
        completer.complete();
        return null; // Không tạo timer thật
      };
      
      // Simulate error
      onErrorHandler(['Socket error']);
      
      // Đợi reconnect được gọi
      await completer.future;
      
      // Kiểm tra
      verify(mockSocket.connect()).called(1);
      expect(socketManager.connectionState, equals(SocketConnectionState.reconnecting));
    });
  });
  
  group('Resource Management Tests', () {
    test('should clean up resources when disposed', () {
      // Setup
      socketManager.connectionState = SocketConnectionState.connected;
      
      // Hành động
      socketManager.dispose();
      
      // Kiểm tra
      verify(mockSocket.disconnect()).called(1);
      verify(mockSocket.dispose()).called(1);
    });
  });
} 