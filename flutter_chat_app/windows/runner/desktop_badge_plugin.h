#ifndef RUNNER_DESKTOP_BADGE_PLUGIN_H_
#define RUNNER_DESKTOP_BADGE_PLUGIN_H_

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>

#include <windows.h>
#include <shobjidl_core.h>

#include <memory>
#include <string>

// Plugin that manages the Windows taskbar overlay icon to display the total
// unread message count (similar to Slack/Teams/Zalo).
//
// Uses ITaskbarList3::SetOverlayIcon to render a small red badge with the
// count number on the app's taskbar button.
class DesktopBadgePlugin {
 public:
  // Register the plugin on the given registrar.
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows* registrar);

  DesktopBadgePlugin(flutter::PluginRegistrarWindows* registrar);
  virtual ~DesktopBadgePlugin();

 private:
  // Called when a method is invoked on the channel.
  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue>& call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);

  // Create a small icon with the given count rendered as text inside a red
  // circle.  Returns NULL on failure.
  HICON CreateBadgeIcon(int count);

  // Obtain or lazily-initialise the ITaskbarList3 COM interface.
  ITaskbarList3* GetTaskbarList();

  // Retrieve the top-level HWND that owns the taskbar button.
  HWND GetTopLevelHwnd();

  // Destroy a previously created overlay icon.
  void DestroyCurrentIcon();

  flutter::PluginRegistrarWindows* registrar_ = nullptr;
  ITaskbarList3* taskbar_list_ = nullptr;
  HICON current_icon_ = nullptr;
};

#endif  // RUNNER_DESKTOP_BADGE_PLUGIN_H_
