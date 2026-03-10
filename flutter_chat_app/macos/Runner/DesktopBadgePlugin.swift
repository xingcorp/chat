import Cocoa
import FlutterMacOS

/// Handles the `com.oxii.chat/desktop_badge` MethodChannel on macOS.
///
/// Sets / clears the dock tile badge label to show the total unread count.
class DesktopBadgePlugin: NSObject, FlutterPlugin {

    static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
            name: "com.oxii.chat/desktop_badge",
            binaryMessenger: registrar.messenger
        )
        let instance = DesktopBadgePlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "updateBadge":
            guard let args = call.arguments as? [String: Any],
                  let count = args["count"] as? Int else {
                result(FlutterError(
                    code: "INVALID_ARGS",
                    message: "Expected {count: int}",
                    details: nil
                ))
                return
            }
            if count > 0 {
                NSApp.dockTile.badgeLabel = count > 99 ? "99+" : "\(count)"
            } else {
                NSApp.dockTile.badgeLabel = nil
            }
            result(nil)

        case "clearBadge":
            NSApp.dockTile.badgeLabel = nil
            result(nil)

        default:
            result(FlutterMethodNotImplemented)
        }
    }
}
