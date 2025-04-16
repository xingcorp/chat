import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Device performance capability levels
enum DevicePerformanceTier {
  /// Low-end devices, need to reduce animation complexity
  low,
  
  /// Medium-end devices, use standard animations
  medium,
  
  /// High-end devices, can use complex animations
  high
}

/// Class for detecting and determining device capabilities
class DeviceCapabilityDetector {
  static const String _prefsKey = 'device_performance_tier';
  static const String _lastDetectionTimeKey = 'last_performance_detection_time';
  static DevicePerformanceTier? _cachedTier;
  
  /// Validity duration for performance assessment (7 days)
  static const Duration _tierValidityDuration = Duration(days: 7);
  
  /// Detect device capabilities
  static Future<DevicePerformanceTier> detectCapabilities() async {
    // Return cached value if available
    if (_cachedTier != null) {
      return _cachedTier!;
    }
    
    // Check if we have info from previous run
    final prefs = await SharedPreferences.getInstance();
    final savedTier = prefs.getString(_prefsKey);
    final lastDetectionTimeStr = prefs.getString(_lastDetectionTimeKey);
    
    // Check validity of previous assessment
    bool isValid = false;
    if (lastDetectionTimeStr != null) {
      try {
        final lastDetectionTime = DateTime.parse(lastDetectionTimeStr);
        final currentTime = DateTime.now();
        isValid = currentTime.difference(lastDetectionTime) < _tierValidityDuration;
      } catch (_) {
        // Format error, consider invalid
      }
    }
    
    if (savedTier != null && isValid) {
      try {
        _cachedTier = DevicePerformanceTier.values.firstWhere(
          (e) => e.toString() == savedTier
        );
        return _cachedTier!;
      } catch (_) {
        // If error, continue with new detection
      }
    }
    
    // Detect based on platform
    DevicePerformanceTier detectedTier;
    
    if (kIsWeb) {
      // Check performance on web
      detectedTier = await _detectWebCapabilities();
    } else if (Platform.isAndroid) {
      // For Android, check device specs
      detectedTier = await _detectAndroidCapabilities();
    } else if (Platform.isIOS) {
      // For iOS, check model
      detectedTier = await _detectIOSCapabilities();
    } else {
      // Desktop defaults to high
      detectedTier = DevicePerformanceTier.high;
    }
    
    // Save result for future use
    await prefs.setString(_prefsKey, detectedTier.toString());
    await prefs.setString(_lastDetectionTimeKey, DateTime.now().toIso8601String());
    _cachedTier = detectedTier;
    
    return detectedTier;
  }
  
  /// Assess Android device capabilities
  static Future<DevicePerformanceTier> _detectAndroidCapabilities() async {
    try {
      final deviceInfo = DeviceInfoPlugin();
      final androidInfo = await deviceInfo.androidInfo;
      
      // Get RAM info - Use available properties
      final int? sdkVersion = androidInfo.version.sdkInt;
      
      // Estimate configuration based on model, cores and SDK version
      final bool isEmulator = androidInfo.isPhysicalDevice == false;
      final int processorCount = androidInfo.supportedAbis?.length ?? 0;
      
      // Determine performance based on device info
      if (isEmulator) {
        // Emulators typically have lower performance than real devices
        return DevicePerformanceTier.medium;
      }
      
      // Newer SDK versions (Android 9+) typically have better performance
      if (sdkVersion != null) {
        if (sdkVersion >= 29 && processorCount >= 6) { // Android 10+ with many cores
          return DevicePerformanceTier.high;
        } else if (sdkVersion >= 26) { // Android 8.0+
          return DevicePerformanceTier.medium;
        } else {
          return DevicePerformanceTier.low;
        }
      }
      
      // Fallback based on CPU cores
      if (processorCount >= 6) {
        return DevicePerformanceTier.high;
      } else if (processorCount >= 4) {
        return DevicePerformanceTier.medium;
      } else {
        return DevicePerformanceTier.low;
      }
    } catch (_) {
      // If unable to get information, perform micro-benchmark
      return _fallbackPerformanceDetection();
    }
  }
  
  /// Assess iOS device capabilities
  static Future<DevicePerformanceTier> _detectIOSCapabilities() async {
    try {
      final deviceInfo = DeviceInfoPlugin();
      final iosInfo = await deviceInfo.iosInfo;
      
      // Get model name (e.g. iPhone10,1)
      final modelName = iosInfo.utsname.machine;
      
      // iOS version
      final systemVersion = double.tryParse(iosInfo.systemVersion.split('.').first) ?? 0;
      
      // Categorize device by model name
      // iPhone 8 and above considered medium or higher
      if (modelName.contains('iPhone')) {
        int? modelNumber;
        try {
          // Extract model number (iPhone10,1 -> 10)
          modelNumber = int.tryParse(modelName.replaceAll('iPhone', '').split(',').first);
        } catch (_) {}
        
        if (modelNumber != null) {
          if (modelNumber >= 12 || systemVersion >= 15) {
            return DevicePerformanceTier.high;
          } else if (modelNumber >= 8) {
            return DevicePerformanceTier.medium;
          }
        }
      }
      
      // iPad Pro considered high
      if (modelName.contains('iPad') && modelName.contains('Pro')) {
        return DevicePerformanceTier.high;
      }
      
      // Regular iPads considered medium
      if (modelName.contains('iPad') && systemVersion >= 13) {
        return DevicePerformanceTier.medium;
      }
      
      // Default for older iOS devices
      return DevicePerformanceTier.low;
    } catch (_) {
      // Fallback
      return _fallbackPerformanceDetection();
    }
  }
  
  /// Assess web capabilities
  static Future<DevicePerformanceTier> _detectWebCapabilities() async {
    return _fallbackPerformanceDetection();
  }
  
  /// Fallback method when device specs can't be read
  static Future<DevicePerformanceTier> _fallbackPerformanceDetection() async {
    try {
      // A simple micro-benchmark to check performance
      final startTime = DateTime.now();
      int sum = 0;
      
      // Perform some simple calculations to measure speed
      for (int i = 0; i < 500000; i++) {
        sum += i % 1000;
      }
      
      final endTime = DateTime.now();
      final duration = endTime.difference(startTime).inMilliseconds;
      
      // Shorter processing time = faster device
      if (duration < 100) {
        return DevicePerformanceTier.high;
      } else if (duration < 300) {
        return DevicePerformanceTier.medium;
      } else {
        return DevicePerformanceTier.low;
      }
    } catch (_) {
      // Default to medium if benchmark fails
      return DevicePerformanceTier.medium;
    }
  }
  
  /// Override device performance tier (useful for testing)
  static Future<void> overridePerformanceTier(DevicePerformanceTier tier) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, tier.toString());
    await prefs.setString(_lastDetectionTimeKey, DateTime.now().toIso8601String());
    _cachedTier = tier;
  }
  
  /// Clear saved performance tier
  static Future<void> clearSavedPerformanceTier() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsKey);
    await prefs.remove(_lastDetectionTimeKey);
    _cachedTier = null;
  }
} 