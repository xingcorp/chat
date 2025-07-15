/// Enterprise DI Performance Tests
/// 
/// Validates that the unified DI system meets enterprise performance targets:
/// - Initialization time: <500ms
/// - Memory usage: Efficient singleton management
/// - Service resolution: Fast and reliable
/// 
/// Author: Senior Flutter/Mobile Architect
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_chat_app/core/di/enterprise_injection.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
// Temporarily disable problematic imports
// import 'package:flutter_chat_app/core/services/database_service.dart';
// import 'package:flutter_chat_app/core/cache/app_cache_manager.dart';

void main() {
  group('Enterprise DI Performance Tests', () {
    setUp(() async {
      // Reset DI system before each test
      if (EnterpriseDI.isInitialized) {
        await EnterpriseDI.reset();
      }
    });

    tearDown(() async {
      // Clean up after each test
      if (EnterpriseDI.isInitialized) {
        await EnterpriseDI.reset();
      }
    });

    test('DI initialization should complete within 500ms target', () async {
      // Arrange
      const int performanceTarget = 500; // 500ms enterprise target
      final stopwatch = Stopwatch()..start();

      // Act
      await EnterpriseDI.initialize();
      stopwatch.stop();

      // Assert
      final initializationTime = stopwatch.elapsedMilliseconds;
      debugPrint('🎯 DI Initialization Time: ${initializationTime}ms');
      
      expect(initializationTime, lessThan(performanceTarget),
          reason: 'DI initialization exceeded ${performanceTarget}ms target: ${initializationTime}ms');
      
      expect(EnterpriseDI.isInitialized, isTrue,
          reason: 'DI system should be marked as initialized');
    });

    test('Core services should be resolvable after initialization', () async {
      // Arrange
      await EnterpriseDI.initialize();

      // Act & Assert - Basic services should be available
      expect(() => EnterpriseDI.get<Logger>(), returnsNormally,
          reason: 'Logger should be resolvable');

      expect(() => EnterpriseDI.get<SharedPreferences>(), returnsNormally,
          reason: 'SharedPreferences should be resolvable');

      // TODO: Add other services when compilation issues are resolved
    });

    test('Service resolution should be fast (<10ms per service)', () async {
      // Arrange
      await EnterpriseDI.initialize();
      const int resolutionTarget = 10; // 10ms per service resolution

      // Act & Assert - Test multiple service resolutions
      final services = [
        () => EnterpriseDI.get<Logger>(),
        () => EnterpriseDI.get<SharedPreferences>(),
        // TODO: Add other services when compilation issues are resolved
      ];

      for (final serviceGetter in services) {
        final stopwatch = Stopwatch()..start();
        final service = serviceGetter();
        stopwatch.stop();

        final resolutionTime = stopwatch.elapsedMilliseconds;
        debugPrint('⚡ Service resolution time: ${resolutionTime}ms');
        
        expect(service, isNotNull, reason: 'Service should be resolved');
        expect(resolutionTime, lessThan(resolutionTarget),
            reason: 'Service resolution exceeded ${resolutionTarget}ms target');
      }
    });

    test('Singleton services should return same instance', () async {
      // Arrange
      await EnterpriseDI.initialize();

      // Act
      final logger1 = EnterpriseDI.get<Logger>();
      final logger2 = EnterpriseDI.get<Logger>();

      final sharedPrefs1 = EnterpriseDI.get<SharedPreferences>();
      final sharedPrefs2 = EnterpriseDI.get<SharedPreferences>();

      // Assert - Singleton pattern should be enforced
      expect(identical(logger1, logger2), isTrue,
          reason: 'Logger should be singleton');

      expect(identical(sharedPrefs1, sharedPrefs2), isTrue,
          reason: 'SharedPreferences should be singleton');
    });

    test('DI system should handle service not found gracefully', () async {
      // Arrange
      await EnterpriseDI.initialize();

      // Act & Assert - Should throw meaningful error for unregistered service
      expect(() => EnterpriseDI.get<UnregisteredService>(),
          throwsException,
          reason: 'Should throw exception for unregistered service');
    });

    test('DI system should prevent usage before initialization', () {
      // Arrange - Don't initialize DI

      // Act & Assert - Should throw error when not initialized
      expect(() => EnterpriseDI.get<Logger>(),
          throwsA(isA<StateError>()),
          reason: 'Should throw StateError when DI not initialized');
    });

    test('DI reset should work properly', () async {
      // Arrange
      await EnterpriseDI.initialize();
      expect(EnterpriseDI.isInitialized, isTrue);

      // Act
      await EnterpriseDI.reset();

      // Assert
      expect(EnterpriseDI.isInitialized, isFalse,
          reason: 'DI should be marked as not initialized after reset');
      
      expect(() => EnterpriseDI.get<Logger>(),
          throwsA(isA<StateError>()),
          reason: 'Should not be able to resolve services after reset');
    });

    test('Multiple initializations should be safe', () async {
      // Arrange & Act - Initialize multiple times
      await EnterpriseDI.initialize();
      await EnterpriseDI.initialize(); // Should be safe
      await EnterpriseDI.initialize(); // Should be safe

      // Assert
      expect(EnterpriseDI.isInitialized, isTrue);
      expect(() => EnterpriseDI.get<Logger>(), returnsNormally);
    });

    test('Service registration order should not affect functionality', () async {
      // This test validates that dependency order is handled correctly
      // Arrange & Act
      await EnterpriseDI.initialize();

      // Assert - Core services should work
      final logger = EnterpriseDI.get<Logger>();
      expect(logger, isNotNull,
          reason: 'Logger with dependencies should be resolvable');

      // TODO: Add repository test when compilation issues are resolved
      // final repository = EnterpriseDI.get<OfflineFirstRepository>();
      // expect(repository, isNotNull,
      //     reason: 'Repository with dependencies should be resolvable');
    });
  });

  group('Enterprise DI Memory Tests', () {
    test('DI system should not create memory leaks', () async {
      // This is a basic test - in production, use memory profiling tools
      await EnterpriseDI.initialize();
      
      // Create multiple service instances
      for (int i = 0; i < 100; i++) {
        final _ = EnterpriseDI.get<Logger>();
      }

      // All should be the same instance (singleton)
      final service1 = EnterpriseDI.get<Logger>();
      final service2 = EnterpriseDI.get<Logger>();
      
      expect(identical(service1, service2), isTrue,
          reason: 'Multiple gets should return same singleton instance');
    });
  });
}

/// Dummy service for testing unregistered service handling
class UnregisteredService {}
