#!/bin/bash
# =============================================================================
# OXII Chat — macOS Build & Distribution Script
# =============================================================================
# Builds Flutter macOS app and packages for distribution.
#
# Usage:
#   ./scripts/build_macos.sh [options]
#
# Options:
#   -f, --flavor       staging | production           (default: staging)
#   -m, --method       app | dmg | pkg | zip | all    (default: app)
#   -c, --clean        Clean build before building
#   -s, --sign         Code sign with Developer ID     (requires certs)
#   -n, --notarize     Notarize with Apple             (requires API key)
#   -h, --help         Show this help
#
# Examples:
#   ./scripts/build_macos.sh                         # Build .app (staging)
#   ./scripts/build_macos.sh -f production -m dmg    # Build DMG (production)
#   ./scripts/build_macos.sh -m all -s               # Build all formats, signed
#   ./scripts/build_macos.sh -m zip                  # Build portable ZIP
#
# Prerequisites:
#   - macOS with Xcode installed
#   - Flutter SDK
#   - create-dmg (brew install create-dmg) — for DMG method
#   - Developer ID cert — for signing
#   - App Store Connect API key — for notarization
# =============================================================================

set -euo pipefail

# ─── Colors ───────────────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# ─── Constants ────────────────────────────────────────────────────────────────
APP_NAME="OXII Chat"
APP_BUNDLE_NAME="oxii_chat"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
BUILD_DIR="$PROJECT_DIR/build/macos/Build/Products/Release"
OUTPUT_DIR="$PROJECT_DIR/build/distribution/macos"

# ─── Defaults ─────────────────────────────────────────────────────────────────
FLAVOR="staging"
METHOD="app"
CLEAN=false
SIGN=false
NOTARIZE=false

# Signing config (override via environment variables)
DEVELOPER_ID="${DEVELOPER_ID:-}"              # e.g. "Developer ID Application: OXII Co (TEAMID)"
INSTALLER_ID="${INSTALLER_ID:-}"              # e.g. "Developer ID Installer: OXII Co (TEAMID)"
APPLE_ID="${APPLE_ID:-}"                      # Apple ID email
APPLE_TEAM_ID="${APPLE_TEAM_ID:-}"            # Team ID
NOTARY_KEY_ID="${NOTARY_KEY_ID:-}"            # App Store Connect API Key ID
NOTARY_ISSUER="${NOTARY_ISSUER:-}"            # App Store Connect Issuer ID
NOTARY_KEY_PATH="${NOTARY_KEY_PATH:-}"        # Path to .p8 key file

# ─── Logging ──────────────────────────────────────────────────────────────────
log_info()    { echo -e "${BLUE}[INFO]${NC}    $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error()   { echo -e "${RED}[ERROR]${NC}   $1"; }
log_step()    { echo -e "${CYAN}${BOLD}▸ $1${NC}"; }

# ─── Help ─────────────────────────────────────────────────────────────────────
show_help() {
    head -30 "$0" | grep -E '^#' | sed 's/^# \?//'
    exit 0
}

# ─── Parse Args ───────────────────────────────────────────────────────────────
parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -f|--flavor)     FLAVOR="$2"; shift 2 ;;
            -m|--method)     METHOD="$2"; shift 2 ;;
            -c|--clean)      CLEAN=true; shift ;;
            -s|--sign)       SIGN=true; shift ;;
            -n|--notarize)   NOTARIZE=true; SIGN=true; shift ;;
            -h|--help)       show_help ;;
            *)               log_error "Unknown option: $1"; show_help ;;
        esac
    done

    # Validate
    case "$FLAVOR" in
        staging|production) ;;
        *) log_error "Invalid flavor: $FLAVOR (use: staging, production)"; exit 1 ;;
    esac

    case "$METHOD" in
        app|dmg|pkg|zip|all) ;;
        *) log_error "Invalid method: $METHOD (use: app, dmg, pkg, zip, all)"; exit 1 ;;
    esac
}

# ─── Header ───────────────────────────────────────────────────────────────────
print_header() {
    echo ""
    echo -e "${BOLD}╔══════════════════════════════════════════════╗${NC}"
    echo -e "${BOLD}║       OXII Chat — macOS Build Script        ║${NC}"
    echo -e "${BOLD}╠══════════════════════════════════════════════╣${NC}"
    echo -e "${BOLD}║${NC}  Flavor:    ${CYAN}$FLAVOR${NC}"
    echo -e "${BOLD}║${NC}  Method:    ${CYAN}$METHOD${NC}"
    echo -e "${BOLD}║${NC}  Sign:      ${CYAN}$SIGN${NC}"
    echo -e "${BOLD}║${NC}  Notarize:  ${CYAN}$NOTARIZE${NC}"
    echo -e "${BOLD}╚══════════════════════════════════════════════╝${NC}"
    echo ""
}

# ─── Preflight Checks ────────────────────────────────────────────────────────
preflight_checks() {
    log_step "Running preflight checks..."

    # Check macOS
    if [[ "$(uname)" != "Darwin" ]]; then
        log_error "This script must run on macOS"
        exit 1
    fi

    # Check Flutter
    if ! command -v flutter &>/dev/null; then
        log_error "Flutter not found. Install Flutter SDK first."
        exit 1
    fi

    # Check Xcode
    if ! command -v xcodebuild &>/dev/null; then
        log_error "Xcode not found. Install Xcode from App Store."
        exit 1
    fi

    # Check create-dmg (for DMG method)
    if [[ "$METHOD" == "dmg" || "$METHOD" == "all" ]]; then
        if ! command -v create-dmg &>/dev/null; then
            log_warning "create-dmg not found. Installing via Homebrew..."
            if command -v brew &>/dev/null; then
                brew install create-dmg
            else
                log_error "Homebrew not found. Install create-dmg manually: brew install create-dmg"
                exit 1
            fi
        fi
    fi

    # Check signing certs
    if [[ "$SIGN" == true && -z "$DEVELOPER_ID" ]]; then
        log_warning "DEVELOPER_ID not set. Attempting to find a Developer ID cert..."
        DEVELOPER_ID=$(security find-identity -v -p codesigning | grep "Developer ID Application" | head -1 | sed 's/.*"\(.*\)".*/\1/' || true)
        if [[ -z "$DEVELOPER_ID" ]]; then
            log_error "No Developer ID Application certificate found."
            log_info "Install from Apple Developer portal or set DEVELOPER_ID env var."
            exit 1
        fi
        log_info "Found: $DEVELOPER_ID"
    fi

    log_success "Preflight checks passed"
}

# ─── Extract Version ─────────────────────────────────────────────────────────
get_version() {
    local version
    version=$(grep '^version:' "$PROJECT_DIR/pubspec.yaml" | sed 's/version: //' | cut -d'+' -f1)
    echo "$version"
}

# ─── Clean ────────────────────────────────────────────────────────────────────
clean_build() {
    log_step "Cleaning build artifacts..."
    cd "$PROJECT_DIR"
    flutter clean
    flutter pub get
    log_success "Clean complete"
}

# ─── Build Flutter macOS ─────────────────────────────────────────────────────
build_flutter_macos() {
    log_step "Building Flutter macOS app (release)..."
    cd "$PROJECT_DIR"

    flutter pub get

    flutter build macos \
        --release \
        --dart-define=FLAVOR="$FLAVOR"

    # Verify build
    local app_path="$BUILD_DIR/${APP_BUNDLE_NAME}.app"
    if [[ ! -d "$app_path" ]]; then
        # Flutter may use different naming
        app_path=$(find "$BUILD_DIR" -name "*.app" -maxdepth 1 | head -1)
    fi

    if [[ -z "$app_path" || ! -d "$app_path" ]]; then
        log_error "Build failed — .app not found in $BUILD_DIR"
        exit 1
    fi

    APP_PATH="$app_path"
    log_success "Build complete: $APP_PATH"
}

# ─── Code Signing ────────────────────────────────────────────────────────────
sign_app() {
    if [[ "$SIGN" != true ]]; then
        log_warning "Skipping code signing (use -s to enable)"
        return
    fi

    log_step "Code signing with: $DEVELOPER_ID"

    # Sign all frameworks and dylibs first
    find "$APP_PATH" -name "*.framework" -o -name "*.dylib" | while read -r item; do
        codesign --force --deep --options runtime \
            --sign "$DEVELOPER_ID" \
            --timestamp \
            "$item" 2>/dev/null || true
    done

    # Sign the main app
    codesign --force --deep --options runtime \
        --sign "$DEVELOPER_ID" \
        --timestamp \
        --entitlements "$PROJECT_DIR/macos/Runner/Release.entitlements" \
        "$APP_PATH"

    # Verify
    codesign --verify --verbose=2 "$APP_PATH"
    log_success "Code signing verified"
}

# ─── Notarization ────────────────────────────────────────────────────────────
notarize_file() {
    local file_path="$1"

    if [[ "$NOTARIZE" != true ]]; then
        log_warning "Skipping notarization (use -n to enable)"
        return
    fi

    log_step "Notarizing: $(basename "$file_path")"

    if [[ -n "$NOTARY_KEY_ID" && -n "$NOTARY_ISSUER" && -n "$NOTARY_KEY_PATH" ]]; then
        # API Key method (recommended)
        xcrun notarytool submit "$file_path" \
            --key "$NOTARY_KEY_PATH" \
            --key-id "$NOTARY_KEY_ID" \
            --issuer "$NOTARY_ISSUER" \
            --wait
    elif [[ -n "$APPLE_ID" && -n "$APPLE_TEAM_ID" ]]; then
        # Apple ID method (legacy)
        xcrun notarytool submit "$file_path" \
            --apple-id "$APPLE_ID" \
            --team-id "$APPLE_TEAM_ID" \
            --wait
    else
        log_error "Notarization requires either:"
        log_info "  1. NOTARY_KEY_ID + NOTARY_ISSUER + NOTARY_KEY_PATH (API Key)"
        log_info "  2. APPLE_ID + APPLE_TEAM_ID (Apple ID)"
        exit 1
    fi

    # Staple the notarization ticket
    xcrun stapler staple "$file_path"
    log_success "Notarization complete"
}

# ─── Method: ZIP ──────────────────────────────────────────────────────────────
package_zip() {
    local version
    version=$(get_version)
    local zip_name="OxiiChat_v${version}_macOS.zip"
    local zip_path="$OUTPUT_DIR/$zip_name"

    log_step "Creating ZIP archive..."
    mkdir -p "$OUTPUT_DIR"

    cd "$(dirname "$APP_PATH")"
    ditto -c -k --sequesterRsrc --keepParent "$(basename "$APP_PATH")" "$zip_path"

    notarize_file "$zip_path"

    local size
    size=$(du -h "$zip_path" | cut -f1)
    log_success "ZIP created: $zip_path ($size)"
}

# ─── Method: DMG ──────────────────────────────────────────────────────────────
package_dmg() {
    local version
    version=$(get_version)
    local dmg_name="OxiiChat_v${version}_macOS.dmg"
    local dmg_path="$OUTPUT_DIR/$dmg_name"

    log_step "Creating DMG installer..."
    mkdir -p "$OUTPUT_DIR"

    # Remove old DMG if exists
    rm -f "$dmg_path"

    # Check for custom background
    local bg_args=()
    local bg_path="$PROJECT_DIR/installer/macos/dmg_background.png"
    if [[ -f "$bg_path" ]]; then
        bg_args=(--background "$bg_path")
    fi

    # Check for custom volume icon
    local icon_args=()
    local icon_path="$PROJECT_DIR/macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_512.png"
    if [[ -f "$icon_path" ]]; then
        icon_args=(--icon "$APP_NAME" 140 160)
    fi

    create-dmg \
        --volname "$APP_NAME" \
        --volicon "$PROJECT_DIR/macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_128.png" \
        --window-pos 200 120 \
        --window-size 660 400 \
        --icon-size 80 \
        "${icon_args[@]}" \
        --app-drop-link 500 160 \
        --hide-extension "$(basename "$APP_PATH")" \
        "${bg_args[@]}" \
        "$dmg_path" \
        "$APP_PATH" \
    || true  # create-dmg returns 2 on "no custom icon", which is OK

    if [[ ! -f "$dmg_path" ]]; then
        log_error "DMG creation failed"
        exit 1
    fi

    # Sign DMG
    if [[ "$SIGN" == true ]]; then
        codesign --force --sign "$DEVELOPER_ID" "$dmg_path"
    fi

    notarize_file "$dmg_path"

    local size
    size=$(du -h "$dmg_path" | cut -f1)
    log_success "DMG created: $dmg_path ($size)"
}

# ─── Method: PKG ──────────────────────────────────────────────────────────────
package_pkg() {
    local version
    version=$(get_version)
    local pkg_name="OxiiChat_v${version}_macOS.pkg"
    local pkg_path="$OUTPUT_DIR/$pkg_name"

    log_step "Creating PKG installer..."
    mkdir -p "$OUTPUT_DIR"

    # Build component package
    local component_pkg="$OUTPUT_DIR/_component.pkg"
    pkgbuild \
        --root "$(dirname "$APP_PATH")" \
        --filter ".DS_Store" \
        --component-plist "$PROJECT_DIR/installer/macos/component.plist" \
        --install-location "/Applications" \
        "$component_pkg" \
    2>/dev/null || {
        # Fallback without component plist
        pkgbuild \
            --root "$(dirname "$APP_PATH")" \
            --filter ".DS_Store" \
            --install-location "/Applications" \
            "$component_pkg"
    }

    # Build product archive (if distribution.xml exists)
    local dist_xml="$PROJECT_DIR/installer/macos/distribution.xml"
    if [[ -f "$dist_xml" ]]; then
        productbuild \
            --distribution "$dist_xml" \
            --package-path "$OUTPUT_DIR" \
            "$pkg_path"
    else
        # Simple: just rename component pkg
        mv "$component_pkg" "$pkg_path"
    fi

    # Clean up temp
    rm -f "$component_pkg"

    # Sign PKG
    if [[ "$SIGN" == true && -n "$INSTALLER_ID" ]]; then
        local signed_pkg="${pkg_path%.pkg}_signed.pkg"
        productsign --sign "$INSTALLER_ID" "$pkg_path" "$signed_pkg"
        mv "$signed_pkg" "$pkg_path"
    fi

    notarize_file "$pkg_path"

    local size
    size=$(du -h "$pkg_path" | cut -f1)
    log_success "PKG created: $pkg_path ($size)"
}

# ─── Run Methods ──────────────────────────────────────────────────────────────
run_packaging() {
    case "$METHOD" in
        app)
            log_success "Build-only complete. App at: $APP_PATH"
            ;;
        zip)
            package_zip
            ;;
        dmg)
            package_dmg
            ;;
        pkg)
            package_pkg
            ;;
        all)
            package_zip
            package_dmg
            package_pkg
            ;;
    esac
}

# ─── Summary ──────────────────────────────────────────────────────────────────
print_summary() {
    local version
    version=$(get_version)

    echo ""
    echo -e "${BOLD}╔══════════════════════════════════════════════╗${NC}"
    echo -e "${BOLD}║              Build Complete!                 ║${NC}"
    echo -e "${BOLD}╠══════════════════════════════════════════════╣${NC}"
    echo -e "${BOLD}║${NC}  App:      ${GREEN}$APP_NAME v$version${NC}"
    echo -e "${BOLD}║${NC}  Flavor:   ${CYAN}$FLAVOR${NC}"
    echo -e "${BOLD}║${NC}  Signed:   $([ "$SIGN" == true ] && echo "${GREEN}Yes${NC}" || echo "${YELLOW}No${NC}")"
    echo -e "${BOLD}║${NC}  Notarize: $([ "$NOTARIZE" == true ] && echo "${GREEN}Yes${NC}" || echo "${YELLOW}No${NC}")"
    echo -e "${BOLD}╠══════════════════════════════════════════════╣${NC}"
    echo -e "${BOLD}║${NC}  Output:"

    if [[ "$METHOD" == "app" ]]; then
        echo -e "${BOLD}║${NC}    .app  → $APP_PATH"
    fi

    if [[ -d "$OUTPUT_DIR" ]]; then
        for f in "$OUTPUT_DIR"/OxiiChat_*; do
            if [[ -f "$f" ]]; then
                local size
                size=$(du -h "$f" | cut -f1)
                echo -e "${BOLD}║${NC}    $(basename "$f") ${CYAN}($size)${NC}"
            fi
        done
    fi

    echo -e "${BOLD}╚══════════════════════════════════════════════╝${NC}"
    echo ""
}

# ─── Main ─────────────────────────────────────────────────────────────────────
main() {
    parse_args "$@"
    print_header
    preflight_checks

    if [[ "$CLEAN" == true ]]; then
        clean_build
    fi

    build_flutter_macos
    sign_app
    run_packaging
    print_summary
}

main "$@"
