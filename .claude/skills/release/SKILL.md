# Release & Distribution Skill

Build, version-bump, and package the Flutter app for Windows/macOS distribution.

Use this skill when:
- Building installer files to send to customers
- Bumping app version for a new release
- Packaging for Windows (ZIP, Inno Setup .exe, MSIX) or macOS (DMG, PKG, ZIP)

Do NOT use this skill for:
- Android/iOS mobile builds (use `build.sh` instead)
- Backend deployment
- Code changes or feature development

## Scripts

| Script | Purpose |
|---|---|
| `scripts/build_windows.ps1` | Build + package Windows (no version bump) |
| `scripts/build_macos.sh` | Build + package macOS (no version bump) |
| `scripts/release_windows.ps1` | Bump version + build + package Windows |
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
# Windows — patch (1.0.0 → 1.0.1)
.\scripts\release_windows.ps1 -Bump patch

# Windows — minor (1.0.0 → 1.1.0)
.\scripts\release_windows.ps1 -Bump minor

# Windows — explicit version
.\scripts\release_windows.ps1 -Version 2.0.0

# macOS
./scripts/release_macos.sh -b patch -m dmg
```

### Package methods

| Windows | macOS |
|---|---|
| `zip` — portable ZIP | `app` — just .app bundle |
| `inno` — .exe installer (recommended) | `dmg` — drag-to-install (recommended) |
| `msix` — modern Windows package | `pkg` — wizard installer |
| `all` — build all 3 | `zip` — portable ZIP |
| | `all` — build all 4 |

## Output

All packaged files go to `build/distribution/{windows,macos}/`.

## After Release

```bash
git add pubspec.yaml
git commit -m "release: v{VERSION}"
git tag v{VERSION}
```

## Constraints

- Windows build requires: Visual Studio 2022 + Flutter SDK
- Inno Setup method requires: Inno Setup 6 installed
- macOS build requires: macOS + Xcode + Flutter SDK
- DMG method requires: `brew install create-dmg`
- macOS distribution requires: Apple Developer cert + notarization for production
- Version format: `MAJOR.MINOR.PATCH+BUILD` in pubspec.yaml
- Inno Setup reads version from built .exe automatically
- MSIX version synced automatically by release scripts
