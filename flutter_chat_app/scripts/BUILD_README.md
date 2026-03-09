# OXII Chat — Build & Distribution Scripts

Scripts để build Flutter app thành file cài đặt, gửi cho khách hàng.

---

## Tổng quan

| Script | Platform | File tạo ra |
|---|---|---|
| `build_macos.sh` | macOS | `.app`, `.dmg`, `.pkg`, `.zip` |
| `build_windows.ps1` | Windows | `.zip`, `.exe` (Inno Setup), `.msix` |
| `release_macos.sh` | macOS | Bump version + build + package |
| `release_windows.ps1` | Windows | Bump version + build + package |
| `build.sh` | Android/iOS/Web | `.apk`, `.aab`, `.ipa` |
| `build.bat` | Android/Web (Windows) | `.apk` |

---

## Quy trình phát hành bản mới (Release)

### Lần đầu tiên (v1.0.0)

```powershell
# Windows
.\scripts\build_windows.ps1 -Method inno -Flavor production

# macOS
./scripts/build_macos.sh -m dmg -f production
```

### Cập nhật lên bản mới (v1.0.1, v1.1.0, v2.0.0...)

```powershell
# ── Windows: bump version + build + package (1 lệnh duy nhất) ──
.\scripts\release_windows.ps1 -Bump patch                    # 1.0.0 → 1.0.1
.\scripts\release_windows.ps1 -Bump minor                    # 1.0.0 → 1.1.0
.\scripts\release_windows.ps1 -Bump major                    # 1.0.0 → 2.0.0
.\scripts\release_windows.ps1 -Version 1.5.0                 # Set chính xác version
.\scripts\release_windows.ps1 -Bump patch -Method inno       # Chỉ build Inno Setup

# ── macOS: tương tự ──
./scripts/release_macos.sh -b patch                           # 1.0.0 → 1.0.1
./scripts/release_macos.sh -b minor -m dmg                    # 1.0.0 → 1.1.0, DMG
./scripts/release_macos.sh -v 2.0.0 -m all -s                 # Set 2.0.0, all + sign
```

### Khách hàng update thế nào?

#### Windows (Inno Setup)
```
Khách hàng nhận file mới: OxiiChat_Setup_v1.0.1.exe
→ Double-click → Installer tự phát hiện bản cũ
→ Tự đóng app đang chạy → Cài đè lên bản cũ
→ Chat history + settings được giữ nguyên
→ Done!
```

#### Windows (MSIX)
```
Khách hàng nhận file mới: OxiiChat_v1.0.1_Windows.msix
→ Double-click → Windows tự cập nhật
→ Dữ liệu được giữ nguyên
```

#### macOS (DMG)
```
Khách hàng nhận file mới: OxiiChat_v1.0.1_macOS.dmg
→ Mở DMG → Kéo app vào Applications → Replace
→ Dữ liệu (trong ~/Library/Application Support) được giữ nguyên
```

### Quy trình đầy đủ (cho dev)

```
1. Code xong feature/fix bug
2. Chạy: .\scripts\release_windows.ps1 -Bump patch
   Script tự động:
   ├── pubspec.yaml: 1.0.0+1 → 1.0.1+2
   ├── msix_config:  1.0.0.0 → 1.0.1.0
   ├── flutter build windows --release
   └── Package → build/distribution/windows/
3. Test file output
4. Git commit:
   git add pubspec.yaml
   git commit -m "release: v1.0.1"
   git tag v1.0.1
5. Gửi file cho khách hàng
```

---

## Versioning

### Cách đánh số version

```
version: MAJOR.MINOR.PATCH+BUILD
         1.2.3+4
```

| | Khi nào tăng | Ví dụ |
|---|---|---|
| **MAJOR** | Breaking changes, redesign lớn | 1.0.0 → 2.0.0 |
| **MINOR** | Feature mới, không phá vỡ | 1.0.0 → 1.1.0 |
| **PATCH** | Fix bug, sửa nhỏ | 1.0.0 → 1.0.1 |
| **BUILD** | Tự tăng mỗi lần release | Nội bộ, không hiện cho user |

### Các file liên quan đến version

| File | Format | Tự động cập nhật? |
|---|---|---|
| `pubspec.yaml` | `1.2.3+4` | ✅ Bởi release script |
| `pubspec.yaml` (msix_config) | `1.2.3.0` | ✅ Bởi release script |
| `windows/runner/Runner.rc` | Đọc từ Flutter build | ✅ Tự động |
| `installer/oxii_chat_setup.iss` | Đọc từ .exe metadata | ✅ Tự động |

---

## Windows — `build_windows.ps1`

### Cài đặt cần thiết

| Tool | Bắt buộc? | Dùng cho | Download |
|---|---|---|---|
| Flutter SDK | ✅ Bắt buộc | Build app | https://flutter.dev |
| Visual Studio 2022 | ✅ Bắt buộc | C++ compiler | https://visualstudio.microsoft.com |
| Inno Setup 6 | 📦 Method `inno` | File .exe installer | https://jrsoftware.org/isinfo.php |
| MSIX (dart package) | 📦 Method `msix` | File .msix | Đã có trong `pubspec.yaml` |

### Cách dùng

```powershell
cd flutter_chat_app

# ── Cách 1: ZIP (nhanh nhất, không cần cài thêm gì) ──
.\scripts\build_windows.ps1                              # ZIP, staging
.\scripts\build_windows.ps1 -Flavor production            # ZIP, production

# ── Cách 2: Inno Setup (chuyên nghiệp nhất) ──
.\scripts\build_windows.ps1 -Method inno                  # .exe installer
.\scripts\build_windows.ps1 -Method inno -Flavor production

# ── Cách 3: MSIX (hiện đại, cho doanh nghiệp) ──
.\scripts\build_windows.ps1 -Method msix                  # .msix package

# ── Build tất cả cùng lúc ──
.\scripts\build_windows.ps1 -Method all -Flavor production

# ── Clean build ──
.\scripts\build_windows.ps1 -Method all -Clean
```

### Kết quả output

```
build/distribution/windows/
├── OxiiChat_v1.0.0_Windows.zip       # Giải nén → chạy oxii_chat.exe
├── OxiiChat_Setup_v1.0.0.exe         # Wizard cài đặt (Inno Setup)
└── OxiiChat_v1.0.0_Windows.msix      # Double-click để install
```

### So sánh 3 phương pháp

| | ZIP | Inno Setup (.exe) | MSIX |
|---|---|---|---|
| **Khách cài thế nào** | Giải nén → chạy .exe | Next → Next → Install | Double-click |
| **Khách update thế nào** | Giải nén đè | Chạy installer mới (tự đè) | Double-click file mới |
| **Shortcut Desktop** | ❌ | ✅ | ✅ |
| **Gỡ cài đặt** | Xóa thủ công | ✅ Add/Remove Programs | ✅ Add/Remove Programs |
| **Giữ data khi update** | ✅ (AppData riêng) | ✅ Tự động | ✅ Tự động |
| **Yêu cầu cài thêm** | Không | Inno Setup 6 | Không |
| **Dung lượng** | ~40 MB | ~30 MB (nén tốt hơn) | ~40 MB |
| **Khuyên dùng** | Test nhanh | ✅ Gửi khách hàng | Doanh nghiệp / Store |

---

## macOS — `build_macos.sh`

> ⚠️ Chỉ chạy được trên máy macOS có Xcode.

### Cài đặt cần thiết

| Tool | Bắt buộc? | Dùng cho | Cài đặt |
|---|---|---|---|
| Xcode | ✅ Bắt buộc | Build app | App Store |
| Flutter SDK | ✅ Bắt buộc | Build app | https://flutter.dev |
| create-dmg | 📦 Method `dmg` | File .dmg | `brew install create-dmg` |
| Developer ID cert | 🔐 Signing | Code sign | Apple Developer portal |
| API Key (.p8) | 🔐 Notarize | Apple notarization | App Store Connect |

### Cách dùng

```bash
cd flutter_chat_app
chmod +x scripts/build_macos.sh scripts/release_macos.sh

# ── Cách 1: Chỉ build .app ──
./scripts/build_macos.sh                                   # .app, staging
./scripts/build_macos.sh -f production                     # .app, production

# ── Cách 2: DMG (kéo thả vào Applications — phổ biến nhất) ──
./scripts/build_macos.sh -m dmg                            # .dmg installer
./scripts/build_macos.sh -m dmg -f production -s           # .dmg + code sign

# ── Cách 3: PKG (installer wizard) ──
./scripts/build_macos.sh -m pkg                            # .pkg installer

# ── Cách 4: ZIP (portable) ──
./scripts/build_macos.sh -m zip                            # .zip archive

# ── Build tất cả ──
./scripts/build_macos.sh -m all -f production -s           # All formats, signed

# ── Clean build ──
./scripts/build_macos.sh -m dmg -c                         # Clean trước khi build

# ── Signing + Notarization (phân phối thật) ──
export DEVELOPER_ID="Developer ID Application: OXII Co (TEAM123)"
export NOTARY_KEY_ID="ABC123"
export NOTARY_ISSUER="def-456-ghi"
export NOTARY_KEY_PATH="$HOME/.keys/AuthKey.p8"
./scripts/build_macos.sh -m dmg -f production -n           # Build + Sign + Notarize
```

### Kết quả output

```
build/distribution/macos/
├── OxiiChat_v1.0.0_macOS.zip         # Giải nén → kéo vào Applications
├── OxiiChat_v1.0.0_macOS.dmg         # Mở → kéo thả vào Applications
└── OxiiChat_v1.0.0_macOS.pkg         # Wizard cài đặt
```

### So sánh phương pháp macOS

| | .app (ZIP) | DMG | PKG |
|---|---|---|---|
| **Khách cài thế nào** | Giải nén → kéo vào Applications | Mở → kéo thả | Wizard installer |
| **Khách update thế nào** | Kéo đè app cũ | Kéo đè → Replace | Chạy installer mới |
| **Chuyên nghiệp** | ⭐ | ⭐⭐⭐ | ⭐⭐ |
| **Gỡ cài đặt** | Kéo vào Trash | Kéo vào Trash | Kéo vào Trash |
| **Phổ biến** | Ít | ✅ Phổ biến nhất | Enterprise |
| **Khuyên dùng** | Test nhanh | ✅ Gửi khách hàng | IT deploy |

### Code Signing & Notarization (macOS)

Từ macOS Catalina trở đi, Apple yêu cầu **notarization** cho app phân phối ngoài App Store.
Nếu không notarize, khách hàng sẽ thấy cảnh báo **"App is damaged"** hoặc **"unidentified developer"**.

**Cách tạm bỏ qua (cho testing):**
```bash
# Khách hàng chạy lệnh này 1 lần:
xattr -cr "/Applications/OXII Chat.app"
```

**Cách làm đúng (cho production):**
1. Đăng ký Apple Developer ($99/năm)
2. Tạo Developer ID Application certificate
3. Tạo App Store Connect API Key
4. Chạy build với flag `-n` (notarize)

---

## Cấu trúc file

```
flutter_chat_app/
├── scripts/
│   ├── build_windows.ps1       # 🪟 Windows build (ZIP, Inno, MSIX)
│   ├── build_macos.sh          # 🍎 macOS build (APP, DMG, PKG, ZIP)
│   ├── release_windows.ps1     # 🪟 Bump version + build Windows
│   ├── release_macos.sh        # 🍎 Bump version + build macOS
│   ├── build.sh                # 📱 Android/iOS/Web build
│   ├── build.bat               # 📱 Android/Web build (Windows host)
│   └── BUILD_README.md         # 📖 File này
├── installer/
│   └── oxii_chat_setup.iss     # Inno Setup script (Windows, hỗ trợ update)
├── build/
│   └── distribution/           # ← Output folder (tạo tự động)
│       ├── windows/
│       └── macos/
└── pubspec.yaml                # version + msix_config
```

---

## Troubleshooting

### Windows

| Lỗi | Nguyên nhân | Cách fix |
|---|---|---|
| `flutter build windows` fails | Thiếu Visual Studio C++ | Cài VS 2022 với workload "Desktop development with C++" |
| Inno Setup not found | Chưa cài Inno Setup | Download: https://jrsoftware.org/isinfo.php |
| MSIX fails | Thiếu config | Kiểm tra `msix_config` trong `pubspec.yaml` |
| `Execution Policy` error | PowerShell block scripts | `Set-ExecutionPolicy -Scope CurrentUser RemoteSigned` |

### macOS

| Lỗi | Nguyên nhân | Cách fix |
|---|---|---|
| `create-dmg` not found | Chưa cài | `brew install create-dmg` |
| Code sign fails | Không có cert | Đăng ký Apple Developer → tạo cert |
| "App is damaged" (trên máy khách) | Chưa notarize | `xattr -cr /path/to/app` hoặc notarize |
| `flutter build macos` fails | Chưa có macOS platform | `flutter create --platforms=macos .` |

---

## Environment Variables (tùy chọn)

### macOS Signing

```bash
export DEVELOPER_ID="Developer ID Application: Company (TEAMID)"
export INSTALLER_ID="Developer ID Installer: Company (TEAMID)"
export APPLE_ID="dev@company.com"
export APPLE_TEAM_ID="TEAMID"
export NOTARY_KEY_ID="KEY123"
export NOTARY_ISSUER="ISSUER-UUID"
export NOTARY_KEY_PATH="/path/to/AuthKey.p8"
```

### Windows Inno Setup

```powershell
# Nếu Inno Setup không ở vị trí mặc định:
.\scripts\build_windows.ps1 -InnoSetupPath "D:\Tools\InnoSetup6\ISCC.exe"
```
