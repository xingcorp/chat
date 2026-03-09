You are releasing a new version of the OXII Chat app for desktop distribution.

## What to ask first

Ask the user:
1. Which platform? (Windows / macOS / both)
2. Version bump type? (patch / minor / major / specific version)
3. Which packaging method? (For Windows: zip, inno, msix, all. For macOS: dmg, pkg, zip, all)
4. Flavor? (staging / production)

## Steps

### 1. Bump Version
Run the appropriate release script which auto-bumps `pubspec.yaml` + `msix_config`:

```powershell
# Windows
.\scripts\release_windows.ps1 -Bump <type> -Method <method> -Flavor <flavor>

# macOS
./scripts/release_macos.sh -b <type> -m <method> -f <flavor>
```

### 2. Verify Output
Check files in `build/distribution/{windows,macos}/`:
- Windows: `.zip`, `OxiiChat_Setup_vX.Y.Z.exe`, `.msix`
- macOS: `.dmg`, `.pkg`, `.zip`

### 3. Post-Release
```bash
git add pubspec.yaml
git commit -m "release: vX.Y.Z"
git tag vX.Y.Z
```

## Key Files
- `scripts/release_windows.ps1` — Windows release automation
- `scripts/release_macos.sh` — macOS release automation
- `scripts/build_windows.ps1` — Windows build (no version bump)
- `scripts/build_macos.sh` — macOS build (no version bump)
- `installer/oxii_chat_setup.iss` — Inno Setup config (auto-reads version, supports update-in-place)
- `pubspec.yaml` — version + msix_config
