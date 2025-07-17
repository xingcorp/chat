import 'dart:async';

import 'package:flutter_chat_app/core/network/socket_analytics.dart';
import 'package:flutter_chat_app/core/network/socket_manager.dart';
import 'package:flutter_chat_app/core/network/models/socket_connection_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:rxdart/rxdart.dart';

import 'socket_analytics_test.mocks.dart';

@GenerateMocks([SocketManager, Logger])
void main() {
  late SocketAnalytics socketAnalytics;
  late MockSocketManager mockSocketManager;
  late MockLogger mockLogger;
  late StreamController<SocketConnectionState> connectionStateController;
  
  setUp(() {
    mockSocketManager = MockSocketManager();
    mockLogger = MockLogger();
    connectionStateController = StreamController<SocketConnectionState>.broadcast();
    
    // Setup mock stream for connection state changes
    when(mockSocketManager.connectionStateStream)
        .thenAnswer((_) => connectionStateController.stream);
    when(mockSocketManager.connectionState)
        .thenReturn(SocketConnectionState.disconnected);
    
    socketAnalytics = SocketAnalytics(
      socketManager: mockSocketManager,
      logger: mockLogger
    );
  });
  
  tearDown(() {
    connectionStateController.close();
    socketAnalytics.dispose();
  });
  
  group('Connection State Monitoring', () {
    test('should track connection state changes', () async {
      // Simulate connection state changes
      connectionStateController.add(SocketConnectionState.connecting);
      connectionStateController.add(SocketConnectionState.connected);
      
      // Wait for event processing
      await Future.delayed(Duration.zero);
      
      // Verify state tracking
      expect(socketAnalytics.lastConnectionState, equals(SocketConnectionState.connected));
      expect(socketAnalytics.connectionAttemptCount, equals(1));
    });
    
    test('should calculate connection success rate', () async {
      // Simulate successful connection
      connectionStateController.add(SocketConnectionState.connecting);
      connectionStateController.add(SocketConnectionState.connected);
      
      // Wait for event processing
      await Future.delayed(Duration.zero);
      
      // Should have 100% success rate after one successful connection
      expect(socketAnalytics.connectionSuccessRate, equals(100.0));
      
      // Simulate another attempt with error
      connectionStateController.add(SocketConnectionState.connecting);
      connectionStateController.add(SocketConnectionState.error);
      
      // Wait for event processing
      await Future.delayed(Duration.zero);
      
      // Should have 50% success rate (1 success, 1 failure)
      expect(socketAnalytics.connectionSuccessRate, equals(50.0));
    });
  });
  
  group('Message Tracking', () {
    test('should count sent messages', () {
      // Act - Track sent messages
      socketAnalytics.trackMessageSent('chat_message');
      socketAnalytics.trackMessageSent('typing_indicator');
      socketAnalytics.trackMessageSent('chat_message');
      
      // Assert - Total and by type
      expect(socketAnalytics.totalSentMessages, equals(3));
      expect(socketAnalytics.sentMessagesByType['chat_message'], equals(2));
      expect(socketAnalytics.sentMessagesByType['typing_indicator'], equals(1));
    });
    
    test('should count received messages', () {
      // Act - Track received messages
      socketAnalytics.trackMessageReceived('chat_message');
      socketAnalytics.trackMessageReceived('user_presence');
      socketAnalytics.trackMessageReceived('chat_message');
      
      // Assert - Total and by type
      expect(socketAnalytics.totalReceivedMessages, equals(3));
      expect(socketAnalytics.receivedMessagesByType['chat_message'], equals(2));
      expect(socketAnalytics.receivedMessagesByType['user_presence'], equals(1));
    });
    
    test('should provide connection health check with message counts', () {
      // Arrange - Track some messages
      socketAnalytics.trackMessageSent('event1');
      socketAnalytics.trackMessageSent('event2');
      socketAnalytics.trackMessageReceived('event3');
      
      // Act - Get health check
      final healthCheck = socketAnalytics.getConnectionHealthCheck();
      
      // Assert - Check message counts in health report
      expect(healthCheck['sent_messages'], equals(2));
      expect(healthCheck['received_messages'], equals(1));
    });
  });
  
  group('Latency Measurement', () {
    test('should calculate average latency', () {
      // Arrange - Add some latency measurements
      socketAnalytics.trackLatency(100); // 100ms
      socketAnalytics.trackLatency(200); // 200ms
      socketAnalytics.trackLatency(300); // 300ms
      
      // Act & Assert
      expect(socketAnalytics.averageLatency, equals(200)); // (100+200+300)/3 = 200
    });
    
    test('should track min and max latency', () {
      // Act - Track various latencies
      socketAnalytics.trackLatency(150);
      socketAnalytics.trackLatency(50);
      socketAnalytics.trackLatency(200);
      
      // Assert
      expect(socketAnalytics.minLatency, equals(50));
      expect(socketAnalytics.maxLatency, equals(200));
    });
    
    test('should track latency via ping', () async {
      // Arrange
      final completer = Completer<void>();
      when(mockSocketManager.emit(any, any)).thenAnswer((_) {
        // Simulate server responding to ping
        Future.delayed(Duration(milliseconds: 50), () {
          // Get the captured handler
          final pingHandler = verify(mockSocketManager.on(captureAny)).captured.firstWhere(
            (handler) => handler == 'pong',
            orElse: () => '',
          );
          
          // Call the handler directly if found
          if (pingHandler == 'pong') {
            final pongHandler = verify(mockSocketManager.on(any, captureAny)).captured.last;
            pongHandler({});
            completer.complete();
          }
        });
        return null;
      });
      
      // Act
      socketAnalytics.measureLatency();
      
      // Wait for the ping-pong to complete
      await completer.future;
      
      // Assert - Should have tracked some latency (might not be exactly 50ms due to test execution time)
      expect(socketAnalytics.latencyHistory.isNotEmpty, isTrue);
      expect(socketAnalytics.averageLatency, greaterThan(0));
    });
  });
  
  group('Error Tracking', () {
    test('should count errors by type', () {
      // Act - Track various errors
      socketAnalytics.trackError('connection_timeout');
      socketAnalytics.trackError('auth_failure');
      socketAnalytics.trackError('connection_timeout');
      
      // Assert
      expect(socketAnalytics.totalErrors, equals(3));
      expect(socketAnalytics.errorsByType['connection_timeout'], equals(2));
      expect(socketAnalytics.errorsByType['auth_failure'], equals(1));
    });
    
    test('should track error distribution', () {
      // Arrange - Add various errors
      socketAnalytics.trackError('timeout');
      socketAnalytics.trackError('network');
      socketAnalytics.trackError('timeout');
      socketAnalytics.trackError('server');
      socketAnalytics.trackError('timeout');
      
      // Act
      final errorDistribution = socketAnalytics.getErrorDistribution();
      
      // Assert
      expect(errorDistribution['timeout'], equals(60.0)); // 3/5 = 60%
      expect(errorDistribution['network'], equals(20.0)); // 1/5 = 20%
      expect(errorDistribution['server'], equals(20.0)); // 1/5 = 20%
    });
  });
  
  group('Connection Quality Assessment', () {
    test('should calculate connection quality based on latency', () {
      // Excellent connection (<50ms)
      socketAnalytics.trackLatency(20);
      socketAnalytics.trackLatency(30);
      expect(socketAnalytics.connectionQuality, equals('excellent'));
      
      // Good connection (50-100ms)
      socketAnalytics.resetMetrics();
      socketAnalytics.trackLatency(60);
      socketAnalytics.trackLatency(80);
      expect(socketAnalytics.connectionQuality, equals('good'));
      
      // Fair connection (100-300ms)
      socketAnalytics.resetMetrics();
      socketAnalytics.trackLatency(150);
      socketAnalytics.trackLatency(250);
      expect(socketAnalytics.connectionQuality, equals('fair'));
      
      // Poor connection (>300ms)
      socketAnalytics.resetMetrics();
      socketAnalytics.trackLatency(350);
      socketAnalytics.trackLatency(450);
      expect(socketAnalytics.connectionQuality, equals('poor'));
    });
  });
  
  group('Uptime Tracking', () {
    test('should calculate uptime percentage', () async {
      // Start with connected state
      when(mockSocketManager.connectionState).thenReturn(SocketConnectionState.connected);
      connectionStateController.add(SocketConnectionState.connected);
      
      // Wait some time in connected state
      await Future.delayed(Duration(milliseconds: 100));
      
      // Switch to disconnected
      when(mockSocketManager.connectionState).thenReturn(SocketConnectionState.disconnected);
      connectionStateController.add(SocketConnectionState.disconnected);
      
      // Wait some time in disconnected state
      await Future.delayed(Duration(milliseconds: 100));
      
      // Switch back to connected
      when(mockSocketManager.connectionState).thenReturn(SocketConnectionState.connected);
      connectionStateController.add(SocketConnectionState.connected);
      
      // Wait some more time
      await Future.delayed(Duration(milliseconds: 100));
      
      // Check uptime percentage - should be approximately 2/3 of the time (two periods connected, one disconnected)
      // But allow some flexibility due to test timing
      final uptime = socketAnalytics.uptimePercentage;
      expect(uptime, greaterThan(50.0)); // Should be around 66%, but be flexible
      expect(uptime, lessThan(90.0)); // Should not be too high
    });
  });
  
  group('Resource Management', () {
    test('should reset metrics', () {
      // Arrange - Add some data
      socketAnalytics.trackMessageSent('event');
      socketAnalytics.trackMessageReceived('event');
      socketAnalytics.trackLatency(100);
      socketAnalytics.trackError('timeout');
      
      // Act
      socketAnalytics.resetMetrics();
      
      // Assert
      expect(socketAnalytics.totalSentMessages, equals(0));
      expect(socketAnalytics.totalReceivedMessages, equals(0));
      expect(socketAnalytics.latencyHistory, isEmpty);
      expect(socketAnalytics.totalErrors, equals(0));
    });
    
    test('should clean up resources when disposed', () async {
      // Arrange
      final mockSubscription = MockStreamSubscription<SocketConnectionState>();
      
      // Mock private field access using reflection or setter injection
      // This is a simplified test since we can't directly access private fields
      
      // Act
      socketAnalytics.dispose();
      
      // Assert - Verify no more interaction with socket manager
      verifyNoMoreInteractions(mockSocketManager);
    });
  });
}

// Mock StreamSubscription for testing dispose
class MockStreamSubscription<T> extends Mock implements StreamSubscription<T> {} 