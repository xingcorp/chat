#!/bin/bash
# =============================================================================
# Flutter Multi-Environment Build Script
# =============================================================================
# Enterprise build automation for OXII Chat Application
#
# Usage:
#   ./build.sh <platform> <flavor> <build_type>
#
# Arguments:
#   platform:   android | ios | web | all
#   flavor:     staging | production
#   build_type: debug | release | profile
#
# Examples:
#   ./build.sh android staging debug
#   ./build.sh ios production release
#   ./build.sh all staging release
#
# Firebase Projects:
#   - Staging: common-stag (616861138934)
#   - Production: common-18e05 (159636416445)
# =============================================================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# Default values
PLATFORM="${1:-android}"
FLAVOR="${2:-staging}"
BUILD_TYPE="${3:-debug}"

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Print header
print_header() {
    echo ""
    echo "=============================================="
    echo "  OXII Chat - Multi-Environment Build"
    echo "=============================================="
    echo "  Platform:   $PLATFORM"
    echo "  Flavor:     $FLAVOR"
    echo "  Build Type: $BUILD_TYPE"
    echo "=============================================="
    echo ""
}

# Validate arguments
validate_args() {
    # Validate platform
    case $PLATFORM in
        android|ios|web|all)
            ;;
        *)
            log_error "Invalid platform: $PLATFORM"
            log_info "Valid options: android, ios, web, all"
            exit 1
            ;;
    esac

    # Validate flavor
    case $FLAVOR in
        staging|production)
            ;;
        *)
            log_error "Invalid flavor: $FLAVOR"
            log_info "Valid options: staging, production"
            exit 1
            ;;
    esac

    # Validate build type
    case $BUILD_TYPE in
        debug|release|profile)
            ;;
        *)
            log_error "Invalid build type: $BUILD_TYPE"
            log_info "Valid options: debug, release, profile"
            exit 1
            ;;
    esac
}

# Setup Firebase configuration for iOS
setup_ios_firebase() {
    log_info "Setting up Firebase configuration for iOS ($FLAVOR)..."

    local source_plist="$PROJECT_DIR/ios/config/$FLAVOR/GoogleService-Info.plist"
    local dest_plist="$PROJECT_DIR/ios/Runner/GoogleService-Info.plist"

    if [ -f "$source_plist" ]; then
        cp "$source_plist" "$dest_plist"
        log_success "Copied GoogleService-Info.plist for $FLAVOR"
    else
        log_warning "GoogleService-Info.plist not found for $FLAVOR at $source_plist"
    fi
}

# Clean build artifacts
clean_build() {
    log_info "Cleaning build artifacts..."
    cd "$PROJECT_DIR"
    flutter clean
    log_success "Build artifacts cleaned"
}

# Get Flutter dependencies
get_dependencies() {
    log_info "Getting Flutter dependencies..."
    cd "$PROJECT_DIR"
    flutter pub get
    log_success "Dependencies updated"
}

# Build Android
build_android() {
    log_info "Building Android ($FLAVOR - $BUILD_TYPE)..."
    cd "$PROJECT_DIR"

    local build_cmd="flutter build apk --flavor $FLAVOR"

    case $BUILD_TYPE in
        debug)
            build_cmd="$build_cmd --debug"
            ;;
        release)
            build_cmd="$build_cmd --release"
            ;;
        profile)
            build_cmd="$build_cmd --profile"
            ;;
    esac

    # Add dart-define for flavor
    build_cmd="$build_cmd --dart-define=FLAVOR=$FLAVOR"

    log_info "Running: $build_cmd"
    eval $build_cmd

    log_success "Android build completed"

    # Print APK location
    if [ "$BUILD_TYPE" == "release" ]; then
        log_info "APK location: $PROJECT_DIR/build/app/outputs/flutter-apk/app-$FLAVOR-release.apk"
    fi
}

# Build Android App Bundle (AAB)
build_android_bundle() {
    log_info "Building Android App Bundle ($FLAVOR - release)..."
    cd "$PROJECT_DIR"

    flutter build appbundle \
        --flavor $FLAVOR \
        --release \
        --dart-define=FLAVOR=$FLAVOR

    log_success "Android App Bundle build completed"
    log_info "AAB location: $PROJECT_DIR/build/app/outputs/bundle/${FLAVOR}Release/app-$FLAVOR-release.aab"
}

# Build iOS
build_ios() {
    log_info "Building iOS ($FLAVOR - $BUILD_TYPE)..."

    # Setup Firebase config first
    setup_ios_firebase

    cd "$PROJECT_DIR"

    local build_cmd="flutter build ios --flavor $FLAVOR"

    case $BUILD_TYPE in
        debug)
            build_cmd="$build_cmd --debug --no-codesign"
            ;;
        release)
            build_cmd="$build_cmd --release"
            ;;
        profile)
            build_cmd="$build_cmd --profile"
            ;;
    esac

    # Add dart-define for flavor
    build_cmd="$build_cmd --dart-define=FLAVOR=$FLAVOR"

    log_info "Running: $build_cmd"
    eval $build_cmd

    log_success "iOS build completed"
}

# Build iOS IPA
build_ios_ipa() {
    log_info "Building iOS IPA ($FLAVOR - release)..."

    # Setup Firebase config first
    setup_ios_firebase

    cd "$PROJECT_DIR"

    flutter build ipa \
        --flavor $FLAVOR \
        --release \
        --dart-define=FLAVOR=$FLAVOR \
        --export-options-plist=ios/ExportOptions.plist

    log_success "iOS IPA build completed"
    log_info "IPA location: $PROJECT_DIR/build/ios/ipa/"
}

# Build Web
build_web() {
    log_info "Building Web ($FLAVOR - $BUILD_TYPE)..."
    cd "$PROJECT_DIR"

    local build_cmd="flutter build web"

    case $BUILD_TYPE in
        debug)
            # Web doesn't have debug build, use profile instead
            build_cmd="$build_cmd --profile"
            ;;
        release)
            build_cmd="$build_cmd --release"
            ;;
        profile)
            build_cmd="$build_cmd --profile"
            ;;
    esac

    # Add dart-define for flavor
    build_cmd="$build_cmd --dart-define=FLAVOR=$FLAVOR"

    log_info "Running: $build_cmd"
    eval $build_cmd

    log_success "Web build completed"
    log_info "Web build location: $PROJECT_DIR/build/web"
}

# Run the build
run_build() {
    case $PLATFORM in
        android)
            build_android
            ;;
        ios)
            build_ios
            ;;
        web)
            build_web
            ;;
        all)
            build_android
            build_ios
            build_web
            ;;
    esac
}

# Main execution
main() {
    print_header
    validate_args

    log_info "Starting build process..."
    echo ""

    # Optional: Clean before build
    if [ "${CLEAN_BUILD:-false}" == "true" ]; then
        clean_build
    fi

    get_dependencies
    run_build

    echo ""
    log_success "Build process completed successfully!"
    echo ""
}

# Run main
main
