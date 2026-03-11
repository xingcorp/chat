# Release & Distribution Skill

Build, version-bump, package, and publish the Flutter app for Windows/macOS distribution.

Use this skill when:
- Building installer files to send to customers
- Bumping app version for a new release
- Packaging for Windows (ZIP, Inno Setup .exe, MSIX) or macOS (DMG, PKG, ZIP)
- Publishing releases to GitHub (auto-update source)
- Creating GitHub Releases with installer assets

Do NOT use this skill for:
- Android/iOS mobile builds (use `build.sh` instead)
- Backend deployment
- Code changes or feature development

## Scripts

| Script | Purpose |
|---|---|
| `scripts/build_windows.ps1` | Build + package Windows + SHA-256 checksums (no version bump) |
| `scripts/build_macos.sh` | Build + package macOS (no version bump) |
| `scripts/release_windows.ps1` | Bump version + build + package + (optional) publish to GitHub |
| `scripts/release_macos.sh` | Bump version + build + package macOS |

## Quick Reference

### First-time build (current version)

```powershell
# Windows
.\scripts\build_windows.ps1 -Method inno -Flavor production

# macOS
./scripts/build_macos.sh -m dmg -f production
```

### Release new version

```powershell
# Windows - patch (1.0.0 -> 1.0.1)
.\scripts\release_windows.ps1 -Bump patch

# Windows - minor (1.0.0 -> 1.1.0)
.\scripts\release_windows.ps1 -Bump minor

# Windows - explicit version
.\scripts\release_windows.ps1 -Version 2.0.0

# macOS
./scripts/release_macos.sh -b patch -m dmg
```

### Release + Publish to GitHub (auto-update)

```powershell
# Full flow: bump + build + publish GitHub Release
.\scripts\release_windows.ps1 -Bump patch -Method inno -Publish

# Non-interactive (CI/automation): skip confirmation prompt
.\scripts\release_windows.ps1 -Bump patch -Method inno -Publish -NoConfirm

# Publish as draft (review before making public)
.\scripts\release_windows.ps1 -Bump patch -Publish -Draft

# Custom release notes
.\scripts\release_windows.ps1 -Bump patch -Publish -ReleaseNotes "## Bugfix`n- Fixed login"

# Publish existing build (skip rebuild)
.\scripts\release_windows.ps1 -Bump patch -Publish -SkipBuild
```

### Package methods

| Windows | macOS |
|---|---|
| `zip` - portable ZIP | `app` - just .app bundle |
| `inno` - .exe installer (recommended) | `dmg` - drag-to-install (recommended) |
| `msix` - modern Windows package | `pkg` - wizard installer |
| `all` - build all 3 | `zip` - portable ZIP |
| | `all` - build all 4 |

## Output

All packaged files go to `build/distribution/{windows,macos}/`.

Each build artifact gets a `.sha256` checksum file for auto-update verification:
```
build/distribution/windows/
  OxiiChat_Setup_v2.0.1+89.exe          # Installer
  OxiiChat_Setup_v2.0.1+89.exe.sha256   # SHA-256 checksum
```

## GitHub Release (Auto-Update Source)

The desktop app's auto-update system checks GitHub Releases API for new versions:
`https://api.github.com/repos/xingcorp/chat/releases/latest`

### Prerequisites
- **gh CLI**: Install from https://cli.github.com (or `winget install GitHub.cli`)
- **Auth**: Run `gh auth login` (one-time, browser-based)
- gh CLI location on dev machine: `C:\Program Files\GitHub CLI\gh.exe`

### Release Convention
For auto-update to detect releases correctly:

| Item | Format | Example |
|---|---|---|
| Tag | `v{MAJOR}.{MINOR}.{PATCH}+{BUILD}` | `v2.0.1+89` |
| Title | `OXII Chat v{MAJOR}.{MINOR}.{PATCH}` | `OXII Chat v2.0.1` |
| Windows asset | `OxiiChat_Setup_v{VERSION}.exe` | `OxiiChat_Setup_v2.0.1+89.exe` |
| Checksum | `{asset_name}.sha256` | `OxiiChat_Setup_v2.0.1+89.exe.sha256` |
| macOS asset | `OxiiChat_v{VERSION}_macOS.dmg` | `OxiiChat_v2.0.1+89_macOS.dmg` |

### Release Notes Metadata
The release body supports metadata comments for force-update control:
```markdown
## What's New in v2.0.1
- Feature A
- Bug fix B

<!-- force_update: false -->
<!-- min_supported_version: 1.8.0 -->
```

## Claude Code Usage (via Bash tool)

Since Bash tool strips `$` from inline PowerShell, **always call script files directly**:

```bash
# Build only (no version bump)
powershell -ExecutionPolicy Bypass -File "scripts/build_windows.ps1" -Method inno -Flavor production

# Non-interactive release (no Read-Host prompt)
powershell -ExecutionPolicy Bypass -File "scripts/release_windows.ps1" -Bump patch -Method inno -NoConfirm

# Full release + publish to GitHub
powershell -ExecutionPolicy Bypass -File "scripts/release_windows.ps1" -Bump patch -Method inno -Publish -NoConfirm
```

**Important**: Never use inline `powershell -Command "..."` with `$` variables - Bash tool strips them.

## After Release

```bash
git add pubspec.yaml
git commit -m "release: v{VERSION}"
git tag v{VERSION}+{BUILD}
```

## Constraints

- Windows build requires: Visual Studio 2022 + Flutter SDK
- Inno Setup method requires: Inno Setup 6 installed (already installed on dev machine)
- macOS build requires: macOS + Xcode + Flutter SDK
- DMG method requires: `brew install create-dmg`
- macOS distribution requires: Apple Developer cert + notarization for production
- Version format: `MAJOR.MINOR.PATCH+BUILD` in pubspec.yaml
- Inno Setup reads version from built .exe automatically
- MSIX version synced automatically by release scripts
- GitHub publish requires: gh CLI installed + authenticated (`gh auth login`)

## Troubleshooting

### PowerShell scripts via Bash tool
Bash tool strips `$` from inline PowerShell commands. **Always** use script files:
```
# WRONG - $ variables get stripped
powershell -Command "$var = 'value'; Write-Host $var"

# CORRECT - write to temp .ps1 file, then execute
powershell -ExecutionPolicy Bypass -File "scripts\_temp.ps1"
```
PowerShell scripts with Unicode characters (box-drawing, em dash) must have **UTF-8 BOM** encoding or PowerShell will fail to parse them.

### Firebase C++ SDK extraction corrupt
If build fails with `cmake -E tar: error: ZIP decompression failed (-5)`:
1. The `build/windows/x64/extracted/` directory exists but is incomplete
2. CMake sees it exists and skips re-extraction ("Using cached extracted Firebase SDK")
3. **Fix**: Delete `build/windows/x64/extracted/` directory, keep the .zip file, and re-extract using .NET:
```powershell
Add-Type -Assembly System.IO.Compression.FileSystem
[IO.Compression.ZipFile]::ExtractToDirectory($zipPath, $extractPath)
```
4. Then re-run `flutter build windows`

### C++/WinRT header mismatch
If build fails with `Mismatched C++/WinRT headers`:
- Stale build cache from a previous Flutter/VS version
- **Fix**: `flutter clean` then delete `build/windows/` entirely, rebuild

### gh CLI not found
- Installed at: `C:\Program Files\GitHub CLI\gh.exe`
- If not in PATH, the release script auto-searches common locations
- Install: `winget install GitHub.cli` or download from https://cli.github.com

### gh auth failed
- Run `gh auth login` interactively (opens browser)
- Need `repo` scope for creating releases on private repos
- For public repos (xingcorp/chat), default scopes work fine
