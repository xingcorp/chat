import Cocoa
import FlutterMacOS
import UserNotifications

private final class MacOSNotificationPermissionPlugin: NSObject, FlutterPlugin {
  static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: "com.oxii.chat/macos_notification_permission",
      binaryMessenger: registrar.messenger
    )
    let instance = MacOSNotificationPermissionPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "getStatus":
      UNUserNotificationCenter.current().getNotificationSettings { settings in
        let authorizationStatus = self.authorizationStatusLabel(settings.authorizationStatus)
        let payload: [String: Any] = [
          "authorizationStatus": authorizationStatus,
          "alertEnabled": settings.alertSetting == .enabled,
          "badgeEnabled": settings.badgeSetting == .enabled,
          "soundEnabled": settings.soundSetting == .enabled,
          "notificationCenterEnabled": settings.notificationCenterSetting == .enabled
        ]

        NSLog(
          "[MacOSNotificationPermissionPlugin] getStatus authorization=%@ alert=%@ badge=%@ sound=%@ notificationCenter=%@",
          authorizationStatus,
          String(settings.alertSetting == .enabled),
          String(settings.badgeSetting == .enabled),
          String(settings.soundSetting == .enabled),
          String(settings.notificationCenterSetting == .enabled)
        )

        DispatchQueue.main.async {
          result(payload)
        }
      }
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func authorizationStatusLabel(_ status: UNAuthorizationStatus) -> String {
    switch status {
    case .notDetermined:
      return "notDetermined"
    case .denied:
      return "denied"
    case .authorized:
      return "authorized"
    case .provisional:
      return "provisional"
    @unknown default:
      return "unknown"
    }
  }
}

@main
class AppDelegate: FlutterAppDelegate {
  override func applicationDidFinishLaunching(_ notification: Notification) {
    // Register the desktop badge plugin for dock badge updates.
    if let controller = mainFlutterWindow?.contentViewController as? FlutterViewController {
      DesktopBadgePlugin.register(
        with: controller.registrar(forPlugin: "DesktopBadgePlugin")
      )
      MacOSNotificationPermissionPlugin.register(
        with: controller.registrar(forPlugin: "MacOSNotificationPermissionPlugin")
      )
      NSLog("[AppDelegate] Registered DesktopBadgePlugin and MacOSNotificationPermissionPlugin")
    }
    super.applicationDidFinishLaunching(notification)
  }

  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return true
  }

  override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
    return true
  }
}
