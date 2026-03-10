#!/bin/bash

# **STAGING BUILD SCRIPT - ENTERPRISE FLUTTER CHAT APP**
#
# Automated build script cho staging environment với:
# - Environment validation
# - Dependency management
# - Code generation
# - Testing
# - Build optimization
# - Artifact management
#
# **Usage:** ./scripts/build_staging.sh [platform]
# **Platforms:** android, ios, web, all

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
FLAVOR="staging"
TARGET_FILE="lib/main_staging.dart"
BUILD_DIR="build/staging"
PLATFORM=${1:-"android"}

echo -e "${BLUE}🏗️  OXII Chat - Staging Build Script${NC}"
echo -e "${BLUE}======================================${NC}"
echo -e "📱 Platform: ${PLATFORM}"
echo -e "🏷️  Flavor: ${FLAVOR}"
echo -e "🎯 Target: ${TARGET_FILE}"
echo -e "📁 Build Dir: ${BUILD_DIR}"
echo ""

# Function to print step
print_step() {
    echo -e "${BLUE}🔄 $1${NC}"
}

# Function to print success
print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

# Function to print warning
print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

# Function to print error
print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Validate environment
validate_environment() {
    print_step "Validating environment..."
    
    # Check Flutter
    if ! command -v flutter &> /dev/null; then
        print_error "Flutter is not installed or not in PATH"
        exit 1
    fi
    
    # Check Flutter version
    FLUTTER_VERSION=$(flutter --version | head -n 1 | cut -d ' ' -f 2)
    print_success "Flutter version: ${FLUTTER_VERSION}"
    
    # Check if staging target exists
    if [ ! -f "${TARGET_FILE}" ]; then
        print_error "Staging target file not found: ${TARGET_FILE}"
        exit 1
    fi
    
    # Check environment file
    if [ ! -f ".env.staging" ]; then
        print_warning "Staging environment file not found: .env.staging"
    fi
    
    print_success "Environment validation completed"
}

# Clean previous builds
clean_build() {
    print_step "Cleaning previous builds..."
    
    flutter clean
    rm -rf "${BUILD_DIR}"
    mkdir -p "${BUILD_DIR}"
    
    print_success "Build cleanup completed"
}

# Get dependencies
get_dependencies() {
    print_step "Getting dependencies..."
    
    flutter pub get
    
    print_success "Dependencies updated"
}

# Run code generation
run_codegen() {
    print_step "Running code generation..."
    
    # Generate localization files
    flutter gen-l10n
    
    # Generate build runner files
    flutter packages pub run build_runner build --delete-conflicting-outputs
    
    print_success "Code generation completed"
}

# Run tests
run_tests() {
    print_step "Running tests..."
    
    # Run unit tests
    flutter test --coverage
    
    # Run integration tests for staging
    if [ -d "integration_test" ]; then
        flutter test integration_test/staging_test.dart
    fi
    
    print_success "Tests completed"
}

# Build Android
build_android() {
    print_step "Building Android APK for staging..."
    
    flutter build apk \
        --flavor staging \
        --target "${TARGET_FILE}" \
        --build-name "1.0.0-staging" \
        --build-number "$(date +%s)" \
        --dart-define=FLAVOR=staging \
        --dart-define-from-file=.env.staging
    
    # Copy APK to build directory
    cp build/app/outputs/flutter-apk/app-staging-release.apk "${BUILD_DIR}/oxii-chat-staging.apk"
    
    print_success "Android APK built successfully"
}

# Build iOS
build_ios() {
    print_step "Building iOS IPA for staging..."
    
    flutter build ios \
        --flavor staging \
        --target "${TARGET_FILE}" \
        --build-name "1.0.0-staging" \
        --build-number "$(date +%s)" \
        --dart-define=FLAVOR=staging \
        --dart-define-from-file=.env.staging
    
    print_success "iOS build completed"
}

# Build Web
build_web() {
    print_step "Building Web for staging..."
    
    flutter build web \
        --target "${TARGET_FILE}" \
        --dart-define=FLAVOR=staging \
        --dart-define-from-file=.env.staging \
        --web-renderer canvaskit
    
    # Copy web build to staging directory
    cp -r build/web "${BUILD_DIR}/web"
    
    print_success "Web build completed"
}

# Generate build info
generate_build_info() {
    print_step "Generating build information..."
    
    BUILD_INFO_FILE="${BUILD_DIR}/build_info.json"
    
    cat > "${BUILD_INFO_FILE}" << EOF
{
  "flavor": "${FLAVOR}",
  "platform": "${PLATFORM}",
  "buildTime": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "flutterVersion": "$(flutter --version | head -n 1 | cut -d ' ' -f 2)",
  "dartVersion": "$(dart --version | cut -d ' ' -f 4)",
  "gitCommit": "$(git rev-parse HEAD 2>/dev/null || echo 'unknown')",
  "gitBranch": "$(git branch --show-current 2>/dev/null || echo 'unknown')",
  "buildNumber": "$(date +%s)",
  "environment": {
    "apiBaseUrl": "https://api-staging.oxii.chat",
    "websocketUrl": "wss://ws-staging.oxii.chat",
    "firebaseProjectId": "oxii-chat-staging"
  }
}
EOF
    
    print_success "Build information generated"
}

# Main build function
main() {
    validate_environment
    clean_build
    get_dependencies
    run_codegen
    
    # Skip tests in CI if needed
    if [ "${SKIP_TESTS}" != "true" ]; then
        run_tests
    fi
    
    case "${PLATFORM}" in
        "android")
            build_android
            ;;
        "ios")
            build_ios
            ;;
        "web")
            build_web
            ;;
        "all")
            build_android
            build_ios
            build_web
            ;;
        *)
            print_error "Unknown platform: ${PLATFORM}"
            echo "Supported platforms: android, ios, web, all"
            exit 1
            ;;
    esac
    
    generate_build_info
    
    echo ""
    print_success "🎉 Staging build completed successfully!"
    echo -e "${GREEN}📁 Build artifacts: ${BUILD_DIR}${NC}"
    echo -e "${GREEN}🏷️  Flavor: ${FLAVOR}${NC}"
    echo -e "${GREEN}📱 Platform: ${PLATFORM}${NC}"
}

# Run main function
main "$@"
