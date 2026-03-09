#!/bin/bash
# =============================================================================
# OXII Chat — macOS Release Script
# =============================================================================
# Bump version + build + package for distribution.
#
# Usage:
#   ./scripts/release_macos.sh -b patch                  # 1.0.0 → 1.0.1
#   ./scripts/release_macos.sh -b minor -m dmg           # 1.0.0 → 1.1.0, DMG
#   ./scripts/release_macos.sh -v 2.0.0 -m all -s        # Set 2.0.0, all + sign
#
# Options:
#   -v, --version    Explicit version (e.g. 2.0.0)
#   -b, --bump       Auto-bump: major | minor | patch
#   -m, --method     Package: app | dmg | pkg | zip | all  (default: dmg)
#   -f, --flavor     staging | production                   (default: production)
#   -s, --sign       Code sign
#   -n, --notarize   Notarize with Apple
#   -h, --help       Show help
# =============================================================================

set -euo pipefail

# ─── Colors ───────────────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# ─── Constants ────────────────────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
PUBSPEC="$PROJECT_DIR/pubspec.yaml"

# ─── Defaults ─────────────────────────────────────────────────────────────────
EXPLICIT_VERSION=""
BUMP_TYPE=""
METHOD="dmg"
FLAVOR="production"
SIGN=false
NOTARIZE=false

# ─── Logging ──────────────────────────────────────────────────────────────────
log_info()    { echo -e "${CYAN}[INFO]${NC}    $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_error()   { echo -e "${RED}[ERROR]${NC}   $1"; }
log_step()    { echo -e "${CYAN}${BOLD}▸ $1${NC}"; }

# ─── Parse Args ───────────────────────────────────────────────────────────────
while [[ $# -gt 0 ]]; do
    case "$1" in
        -v|--version)    EXPLICIT_VERSION="$2"; shift 2 ;;
        -b|--bump)       BUMP_TYPE="$2"; shift 2 ;;
        -m|--method)     METHOD="$2"; shift 2 ;;
        -f|--flavor)     FLAVOR="$2"; shift 2 ;;
        -s|--sign)       SIGN=true; shift ;;
        -n|--notarize)   NOTARIZE=true; shift ;;
        -h|--help)       head -20 "$0" | grep '^#' | sed 's/^# \?//'; exit 0 ;;
        *)               log_error "Unknown: $1"; exit 1 ;;
    esac
done

# ─── Read Current Version ────────────────────────────────────────────────────
get_current_version() {
    grep '^version:' "$PUBSPEC" | sed 's/version: //'
}

get_version_parts() {
    local ver
    ver=$(get_current_version)
    CURRENT_MAJOR=$(echo "$ver" | cut -d'.' -f1)
    CURRENT_MINOR=$(echo "$ver" | cut -d'.' -f2)
    CURRENT_PATCH=$(echo "$ver" | cut -d'.' -f3 | cut -d'+' -f1)
    CURRENT_BUILD=$(echo "$ver" | cut -d'+' -f2)
}

# ─── Calculate New Version ───────────────────────────────────────────────────
calculate_new_version() {
    get_version_parts

    if [[ -n "$EXPLICIT_VERSION" ]]; then
        if [[ ! "$EXPLICIT_VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
            log_error "Invalid version: $EXPLICIT_VERSION (expected X.Y.Z)"
            exit 1
        fi
        NEW_VERSION="$EXPLICIT_VERSION"
        NEW_BUILD=$((CURRENT_BUILD + 1))
        return
    fi

    if [[ -z "$BUMP_TYPE" ]]; then
        log_error "Specify -v VERSION or -b patch|minor|major"
        exit 1
    fi

    local major=$CURRENT_MAJOR
    local minor=$CURRENT_MINOR
    local patch=$CURRENT_PATCH
    NEW_BUILD=$((CURRENT_BUILD + 1))

    case "$BUMP_TYPE" in
        major) major=$((major + 1)); minor=0; patch=0 ;;
        minor) minor=$((minor + 1)); patch=0 ;;
        patch) patch=$((patch + 1)) ;;
        *) log_error "Invalid bump: $BUMP_TYPE"; exit 1 ;;
    esac

    NEW_VERSION="${major}.${minor}.${patch}"
}

# ─── Update pubspec.yaml ─────────────────────────────────────────────────────
update_pubspec() {
    log_step "Updating pubspec.yaml: $(get_current_version) → ${NEW_VERSION}+${NEW_BUILD}"

    # Update main version
    sed -i.bak "s/^version: .*/version: ${NEW_VERSION}+${NEW_BUILD}/" "$PUBSPEC"

    # Update msix_config version
    local msix_ver="${NEW_VERSION}.0"
    sed -i.bak "s/msix_version: .*/msix_version: ${msix_ver}/" "$PUBSPEC"

    # Cleanup backup
    rm -f "${PUBSPEC}.bak"

    log_success "Version updated to ${NEW_VERSION}+${NEW_BUILD}"
}

# ─── Build & Package ─────────────────────────────────────────────────────────
run_build() {
    local build_script="$SCRIPT_DIR/build_macos.sh"

    if [[ ! -x "$build_script" ]]; then
        log_error "build_macos.sh not found or not executable"
        exit 1
    fi

    local args=(-f "$FLAVOR" -m "$METHOD")
    [[ "$SIGN" == true ]] && args+=(-s)
    [[ "$NOTARIZE" == true ]] && args+=(-n)

    "$build_script" "${args[@]}"
}

# ─── Main ─────────────────────────────────────────────────────────────────────
main() {
    calculate_new_version
    local old_ver
    old_ver=$(get_current_version)

    echo ""
    echo -e "${BOLD}╔══════════════════════════════════════════════╗${NC}"
    echo -e "${BOLD}║       OXII Chat — macOS Release              ║${NC}"
    echo -e "${BOLD}╠══════════════════════════════════════════════╣${NC}"
    echo -e "${BOLD}║${NC}  Current: ${YELLOW}$old_ver${NC}"
    echo -e "${BOLD}║${NC}  New:     ${GREEN}${NEW_VERSION}+${NEW_BUILD}${NC}"
    echo -e "${BOLD}║${NC}  Flavor:  ${CYAN}$FLAVOR${NC}"
    echo -e "${BOLD}║${NC}  Method:  ${CYAN}$METHOD${NC}"
    echo -e "${BOLD}╚══════════════════════════════════════════════╝${NC}"
    echo ""

    read -rp "Proceed with version bump $old_ver → ${NEW_VERSION}+${NEW_BUILD}? (y/N) " confirm
    if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
        log_info "Cancelled."
        exit 0
    fi

    # 1. Bump
    update_pubspec

    # 2. Build
    run_build

    # 3. Summary
    echo ""
    echo -e "${GREEN}════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}  Release v${NEW_VERSION} ready!${NC}"
    echo -e "${GREEN}════════════════════════════════════════════════${NC}"
    echo ""
    echo "  Next steps:"
    echo "  1. Test the output from build/distribution/macos/"
    echo "  2. Send to customer"
    echo "  3. Git commit & tag:"
    echo -e "     ${CYAN}git add pubspec.yaml${NC}"
    echo -e "     ${CYAN}git commit -m 'release: v${NEW_VERSION}'${NC}"
    echo -e "     ${CYAN}git tag v${NEW_VERSION}${NC}"
    echo ""
}

main
