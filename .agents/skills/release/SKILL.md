---
name: release
description: Build macOS release artifacts for the Flutter chat app, including unsigned internal DMG builds and signed/notarized public releases using scripts/build_macos.sh
---

# macOS Release Workflow

Use this skill when the user wants a macOS release artifact for `flutter_chat_app/`.

This repo has two valid release outcomes:
- **Internal/Test artifact**: unsigned and unnotarized `.dmg` + `.app` for manual install and `Open Anyway`
- **Public distribution artifact**: signed and notarized `.dmg` + `.app` for normal Gatekeeper-safe distribution

Prefer `scripts/build_macos.sh`. Use `scripts/release_macos.sh` only when the user explicitly wants version bumping.

## 1. Preflight

- Work from `flutter_chat_app/`
- Confirm the target flavor with the user request. Production flavor uses `lib/main_production.dart`
- Do not switch Xcode Release signing back to `Apple Development`
- If the build breaks on `DesktopBadgePlugin`, verify `macos/Runner/DesktopBadgePlugin.swift` is included in `macos/Runner.xcodeproj/project.pbxproj`

## 2. Internal/Test Artifact

Use this when the user needs a build they can send to another Mac for manual install:

```bash
cd flutter_chat_app
bash ./scripts/build_macos.sh -f production -m dmg
```

Report both artifacts if the build succeeds:
- `build/distribution/macos/*.dmg`
- `build/macos/Build/Products/Release/OXII Chat.app`

State clearly that this output is:
- unsigned
- unnotarized
- suitable for internal testing only
- likely to require `Privacy & Security > Open Anyway` on another Mac

## 3. Public Distribution Artifact

Use this when the user needs a macOS release that should pass Gatekeeper normally:

```bash
cd flutter_chat_app
bash ./scripts/build_macos.sh -f production -m dmg -s -n
```

Before running, verify both requirements:

### Signing

Run:

```bash
security find-identity -v -p codesigning
```

Require a `Developer ID Application` identity with private key.

`Apple Development` is for local run/debug.
`Apple Distribution` is for App Store / related distribution workflows.
Neither replaces `Developer ID Application` for direct `.dmg` distribution outside the App Store.

### Notarization

Require one configured notarization path:
- `NOTARY_PROFILE`
- or `NOTARY_KEY_ID`, `NOTARY_ISSUER`, `NOTARY_KEY_PATH`
- or `APPLE_ID`, `APPLE_TEAM_ID`, `APPLE_APP_SPECIFIC_PASSWORD`

If the certificate or notary configuration is missing, stop and report the blocker clearly.

## 4. Verification

After a successful build, verify the executable architecture:

```bash
file build/macos/Build/Products/Release/OXII\ Chat.app/Contents/MacOS/OXII\ Chat
```

Smoke test the release binary directly if possible:

```bash
build/macos/Build/Products/Release/OXII\ Chat.app/Contents/MacOS/OXII\ Chat
```

For signed/notarized artifacts, also run:

```bash
codesign --verify --deep --strict build/macos/Build/Products/Release/OXII\ Chat.app
spctl -a -vv build/macos/Build/Products/Release/OXII\ Chat.app
xcrun stapler validate build/distribution/macos/*.dmg
```

## 5. Reporting

In the final response, include:
- the exact command used
- whether the artifact is unsigned/unnotarized or signed/notarized
- the absolute path to the `.dmg`
- the absolute path to the `.app`
- whether a smoke test was performed
- whether the result is suitable for internal testing only or for public distribution

If the signed flow fails, explicitly separate:
- what already works (`unsigned` internal build)
- what is blocked (`Developer ID Application`, notarization credentials, or verification failure)
