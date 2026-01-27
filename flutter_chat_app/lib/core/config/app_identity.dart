/// **APP IDENTITY CONFIGURATION**
///
/// Manages app identity per flavor với:
/// - App names và display names
/// - Bundle IDs và package names
/// - Version information
/// - Branding assets
/// - Platform-specific configurations
///
/// **Architecture:** Factory Pattern + Flavor Abstraction + Enterprise Standards

import 'package:flutter/foundation.dart';
import 'package:flutter_chat_app/core/config/flavor_config.dart';

/// **App Identity Manager**
/// 
/// Provides flavor-specific app identity information
class AppIdentity {
  AppIdentity._();
  
  /// Get app display name based on current flavor
  static String get appName {
    final config = FlavorConfig.instance;
    return config.appName;
  }
  
  /// Get app package name based on current flavor
  static String get packageName {
    final config = FlavorConfig.instance;
    const basePackage = 'com.oxii.chat';
    return FlavorUtils.getPackageName(basePackage);
  }
  
  /// Get app version
  static String get version => '1.0.0';
  
  /// Get build number
  static String get buildNumber => '1';
  
  /// Get full version string
  static String get fullVersion => '$version+$buildNumber';
  
  /// Get app description
  static String get description {
    final config = FlavorConfig.instance;
    if (config.isProduction) {
      return 'Enterprise messaging app cho doanh nghiệp Việt Nam';
    } else {
      return 'OXII Chat ${config.flavor.shortName} - Development version';
    }
  }
  
  /// Get app store URL
  static String get appStoreUrl {
    final config = FlavorConfig.instance;
    if (config.isProduction) {
      return 'https://apps.apple.com/app/oxii-chat/id123456789';
    } else {
      return 'https://testflight.apple.com/join/staging123';
    }
  }
  
  /// Get Play Store URL
  static String get playStoreUrl {
    final config = FlavorConfig.instance;
    if (config.isProduction) {
      return 'https://play.google.com/store/apps/details?id=com.oxii.chat';
    } else {
      return 'https://play.google.com/apps/internaltest/staging123';
    }
  }
  
  /// Get support email
  static String get supportEmail {
    final config = FlavorConfig.instance;
    if (config.isProduction) {
      return 'support@oxii.chat';
    } else {
      return 'staging-support@oxii.chat';
    }
  }
  
  /// Get privacy policy URL
  static String get privacyPolicyUrl {
    final config = FlavorConfig.instance;
    if (config.isProduction) {
      return 'https://oxii.chat/privacy';
    } else {
      return 'https://staging.oxii.chat/privacy';
    }
  }
  
  /// Get terms of service URL
  static String get termsOfServiceUrl {
    final config = FlavorConfig.instance;
    if (config.isProduction) {
      return 'https://oxii.chat/terms';
    } else {
      return 'https://staging.oxii.chat/terms';
    }
  }
  
  /// Get website URL
  static String get websiteUrl {
    final config = FlavorConfig.instance;
    if (config.isProduction) {
      return 'https://oxii.chat';
    } else {
      return 'https://staging.oxii.chat';
    }
  }
  
  /// Get company name
  static String get companyName => 'OXII Technology';
  
  /// Get copyright text
  static String get copyright {
    final year = DateTime.now().year;
    return '© $year $companyName. All rights reserved.';
  }
  
  /// Get app icon path based on flavor
  static String get appIconPath {
    final config = FlavorConfig.instance;
    if (config.isProduction) {
      return 'assets/icons/app_icon_production.png';
    } else {
      return 'assets/icons/app_icon_staging.png';
    }
  }
  
  /// Get splash screen path based on flavor
  static String get splashScreenPath {
    final config = FlavorConfig.instance;
    if (config.isProduction) {
      return 'assets/splash/splash_production.png';
    } else {
      return 'assets/splash/splash_staging.png';
    }
  }
  
  /// Get logo path based on flavor
  static String get logoPath {
    final config = FlavorConfig.instance;
    if (config.isProduction) {
      return 'assets/images/logo_production.png';
    } else {
      return 'assets/images/logo_staging.png';
    }
  }
  
  /// Get primary brand color
  static int get primaryColor {
    final config = FlavorConfig.instance;
    final colors = FlavorUtils.getFlavorColors();
    return colors['primary'] as int;
  }
  
  /// Get accent brand color
  static int get accentColor {
    final config = FlavorConfig.instance;
    final colors = FlavorUtils.getFlavorColors();
    return colors['accent'] as int;
  }
  
  /// Get background brand color
  static int get backgroundColor {
    final config = FlavorConfig.instance;
    final colors = FlavorUtils.getFlavorColors();
    return colors['background'] as int;
  }
  
  /// Get flavor-specific deep link scheme
  static String get deepLinkScheme {
    final config = FlavorConfig.instance;
    if (config.isProduction) {
      return 'oxiichat';
    } else {
      return 'oxiichat-staging';
    }
  }
  
  /// Get flavor-specific URL scheme
  static String get urlScheme {
    final config = FlavorConfig.instance;
    if (config.isProduction) {
      return 'com.oxii.chat';
    } else {
      return 'com.oxii.chat.staging';
    }
  }
  
  /// Get app info for about screen
  static Map<String, dynamic> getAppInfo() {
    return {
      'appName': appName,
      'packageName': packageName,
      'version': version,
      'buildNumber': buildNumber,
      'fullVersion': fullVersion,
      'description': description,
      'companyName': companyName,
      'copyright': copyright,
      'supportEmail': supportEmail,
      'websiteUrl': websiteUrl,
      'privacyPolicyUrl': privacyPolicyUrl,
      'termsOfServiceUrl': termsOfServiceUrl,
      'flavor': FlavorConfig.instance.flavor.name,
      'environment': FlavorConfig.instance.environment.apiBaseUrl,
    };
  }
  
  /// Get platform-specific app info
  static Map<String, dynamic> getPlatformInfo() {
    return {
      'platform': defaultTargetPlatform.name,
      'isWeb': kIsWeb,
      'isDebugMode': kDebugMode,
      'isReleaseMode': kReleaseMode,
      'isProfileMode': kProfileMode,
    };
  }
  
  /// Get social media links
  static Map<String, String> getSocialMediaLinks() {
    return {
      'facebook': 'https://facebook.com/oxiichat',
      'twitter': 'https://twitter.com/oxiichat',
      'linkedin': 'https://linkedin.com/company/oxii-technology',
      'youtube': 'https://youtube.com/c/oxiitechnology',
      'instagram': 'https://instagram.com/oxiichat',
    };
  }
  
  /// Get contact information
  static Map<String, String> getContactInfo() {
    return {
      'email': supportEmail,
      'phone': '+84 123 456 789',
      'address': 'Ho Chi Minh City, Vietnam',
      'website': websiteUrl,
    };
  }
}
