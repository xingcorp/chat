#include "desktop_badge_plugin.h"

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>

#include <windows.h>
#include <shobjidl_core.h>
#include <wingdi.h>

#include <cmath>
#include <memory>
#include <string>

// static
void DesktopBadgePlugin::RegisterWithRegistrar(
    flutter::PluginRegistrarWindows* registrar) {
  auto channel = std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
      registrar->messenger(), "com.oxii.chat/desktop_badge",
      &flutter::StandardMethodCodec::GetInstance());

  auto plugin = std::make_unique<DesktopBadgePlugin>(registrar);

  channel->SetMethodCallHandler(
      [plugin_ptr = plugin.get()](const auto& call, auto result) {
        plugin_ptr->HandleMethodCall(call, std::move(result));
      });

  registrar->AddPlugin(std::move(plugin));
}

DesktopBadgePlugin::DesktopBadgePlugin(
    flutter::PluginRegistrarWindows* registrar)
    : registrar_(registrar) {}

DesktopBadgePlugin::~DesktopBadgePlugin() {
  DestroyCurrentIcon();
  if (taskbar_list_) {
    taskbar_list_->Release();
    taskbar_list_ = nullptr;
  }
}

// ---------------------------------------------------------------------------
// MethodChannel handler
// ---------------------------------------------------------------------------

void DesktopBadgePlugin::HandleMethodCall(
    const flutter::MethodCall<flutter::EncodableValue>& call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {

  if (call.method_name() == "updateBadge") {
    const auto* args = std::get_if<flutter::EncodableMap>(call.arguments());
    if (!args) {
      result->Error("INVALID_ARGS", "Expected map with 'count' key");
      return;
    }

    auto it = args->find(flutter::EncodableValue("count"));
    if (it == args->end()) {
      result->Error("INVALID_ARGS", "Missing 'count' key");
      return;
    }

    int count = 0;
    if (auto* v = std::get_if<int32_t>(&it->second)) {
      count = *v;
    } else if (auto* v64 = std::get_if<int64_t>(&it->second)) {
      count = static_cast<int>(*v64);
    }

    auto* tbl = GetTaskbarList();
    HWND hwnd = GetTopLevelHwnd();
    if (tbl && hwnd) {
      DestroyCurrentIcon();
      if (count > 0) {
        current_icon_ = CreateBadgeIcon(count);
        if (current_icon_) {
          tbl->SetOverlayIcon(hwnd, current_icon_, L"Unread messages");
        }
      } else {
        tbl->SetOverlayIcon(hwnd, NULL, NULL);
      }
    }
    result->Success();

  } else if (call.method_name() == "clearBadge") {
    auto* tbl = GetTaskbarList();
    HWND hwnd = GetTopLevelHwnd();
    if (tbl && hwnd) {
      DestroyCurrentIcon();
      tbl->SetOverlayIcon(hwnd, NULL, NULL);
    }
    result->Success();

  } else {
    result->NotImplemented();
  }
}

// ---------------------------------------------------------------------------
// Badge icon rendering (pure GDI — no GDI+ dependency)
// ---------------------------------------------------------------------------

HICON DesktopBadgePlugin::CreateBadgeIcon(int count) {
  // Icon dimensions (16x16 is the standard overlay icon size).
  const int kSize = 16;

  // Prepare the display string.
  std::wstring text = count > 99 ? L"99+" : std::to_wstring(count);

  // Create a 32-bit ARGB DIB section so the alpha channel is honoured.
  BITMAPINFO bmi = {};
  bmi.bmiHeader.biSize = sizeof(BITMAPINFOHEADER);
  bmi.bmiHeader.biWidth = kSize;
  bmi.bmiHeader.biHeight = -kSize;  // top-down
  bmi.bmiHeader.biPlanes = 1;
  bmi.bmiHeader.biBitCount = 32;
  bmi.bmiHeader.biCompression = BI_RGB;

  void* bits = nullptr;
  HDC screen_dc = GetDC(NULL);
  HDC mem_dc = CreateCompatibleDC(screen_dc);
  HBITMAP color_bmp = CreateDIBSection(mem_dc, &bmi, DIB_RGB_COLORS, &bits, NULL, 0);
  if (!color_bmp) {
    DeleteDC(mem_dc);
    ReleaseDC(NULL, screen_dc);
    return NULL;
  }

  HBITMAP old_bmp = (HBITMAP)SelectObject(mem_dc, color_bmp);

  // Clear to fully transparent.
  memset(bits, 0, kSize * kSize * 4);

  // --- Draw a filled red circle ---
  // Walk every pixel; if inside the circle, set red with full alpha.
  const float cx = kSize / 2.0f;
  const float cy = kSize / 2.0f;
  const float radius = (kSize / 2.0f) - 0.5f;
  BYTE* pixels = static_cast<BYTE*>(bits);
  for (int y = 0; y < kSize; ++y) {
    for (int x = 0; x < kSize; ++x) {
      float dx = x + 0.5f - cx;
      float dy = y + 0.5f - cy;
      if (dx * dx + dy * dy <= radius * radius) {
        int offset = (y * kSize + x) * 4;
        // BGRA pre-multiplied
        pixels[offset + 0] = 0x33;  // B (red = #E53935 → B=0x35, but pre-mult ≈ 0x33)
        pixels[offset + 1] = 0x39;  // G
        pixels[offset + 2] = 0xE5;  // R
        pixels[offset + 3] = 0xFF;  // A
      }
    }
  }

  // --- Draw text ---
  // Pick a font size that fits inside the circle.
  int fontSize = count > 99 ? 7 : (count > 9 ? 8 : 9);
  HFONT font = CreateFontW(
      fontSize,           // height
      0, 0, 0,
      FW_BOLD,            // bold
      FALSE, FALSE, FALSE,
      DEFAULT_CHARSET, OUT_DEFAULT_PRECIS, CLIP_DEFAULT_PRECIS,
      ANTIALIASED_QUALITY, DEFAULT_PITCH | FF_SWISS, L"Segoe UI");
  HFONT old_font = (HFONT)SelectObject(mem_dc, font);

  SetTextColor(mem_dc, RGB(255, 255, 255));
  SetBkMode(mem_dc, TRANSPARENT);

  RECT text_rect = {0, 0, kSize, kSize};
  DrawTextW(mem_dc, text.c_str(), -1, &text_rect,
            DT_CENTER | DT_VCENTER | DT_SINGLELINE | DT_NOCLIP);

  SelectObject(mem_dc, old_font);
  DeleteObject(font);
  SelectObject(mem_dc, old_bmp);

  // Create a monochrome mask bitmap (all zeros = fully opaque).
  HBITMAP mask_bmp = CreateBitmap(kSize, kSize, 1, 1, NULL);

  // Build the icon from color + mask.
  ICONINFO ii = {};
  ii.fIcon = TRUE;
  ii.hbmColor = color_bmp;
  ii.hbmMask = mask_bmp;
  HICON icon = CreateIconIndirect(&ii);

  // Cleanup GDI objects.
  DeleteObject(mask_bmp);
  DeleteObject(color_bmp);
  DeleteDC(mem_dc);
  ReleaseDC(NULL, screen_dc);

  return icon;
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

ITaskbarList3* DesktopBadgePlugin::GetTaskbarList() {
  if (!taskbar_list_) {
    HRESULT hr = CoCreateInstance(
        CLSID_TaskbarList, NULL, CLSCTX_INPROC_SERVER,
        IID_ITaskbarList3, reinterpret_cast<void**>(&taskbar_list_));
    if (SUCCEEDED(hr)) {
      taskbar_list_->HrInit();
    } else {
      taskbar_list_ = nullptr;
    }
  }
  return taskbar_list_;
}

HWND DesktopBadgePlugin::GetTopLevelHwnd() {
  HWND flutter_view = registrar_->GetView()->GetNativeWindow();
  return GetAncestor(flutter_view, GA_ROOT);
}

void DesktopBadgePlugin::DestroyCurrentIcon() {
  if (current_icon_) {
    DestroyIcon(current_icon_);
    current_icon_ = nullptr;
  }
}
