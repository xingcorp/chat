import Cocoa
import FlutterMacOS

@main
class AppDelegate: FlutterAppDelegate {
  override func applicationDidFinishLaunching(_ notification: Notification) {
    // Register the desktop badge plugin for dock badge updates.
    if let controller = mainFlutterWindow?.contentViewController as? FlutterViewController {
      DesktopBadgePlugin.register(
        with: controller.registrar(forPlugin: "DesktopBadgePlugin")
      )
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
