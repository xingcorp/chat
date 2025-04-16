import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:flutter_chat_app/core/services/media_processing_service.dart';

/// Factory class to create the appropriate MediaProcessingService implementation
/// based on the current platform (web, mobile, desktop)
@lazySingleton
class MediaProcessingServiceFactory {
  /// Creates the appropriate MediaProcessingService implementation
  /// based on the current platform
  static IMediaProcessingService create() {
    if (kIsWeb) {
      return WebMediaProcessingService();
    } else if (Platform.isIOS || Platform.isAndroid) {
      return MobileMediaProcessingService();
    } else {
      return DesktopMediaProcessingService();
    }
  }
  
  /// Creates and initializes the appropriate MediaProcessingService
  /// This is a convenience method that creates and initializes the service in one call
  static Future<IMediaProcessingService> createInitialized() async {
    final service = create();
    await service.initialize();
    return service;
  }
} 