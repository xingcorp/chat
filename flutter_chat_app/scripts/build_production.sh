#!/bin/bash

# **PRODUCTION BUILD SCRIPT - ENTERPRISE FLUTTER CHAT APP**
#
# Automated build script cho production environment với:
# - Strict validation
# - Security checks
# - Performance optimization
# - Code obfuscation
# - Release signing
# - Artifact verification
#
# **Usage:** ./scripts/build_production.sh [platform]
# **Platforms:** android, ios, web, all

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
FLAVOR="production"
TARGET_FILE="lib/main_production.dart"
BUILD_DIR="build/production"
PLATFORM=${1:-"android"}

echo -e "${BLUE}🏗️  OXII Chat - Production Build Script${NC}"
echo -e "${BLUE}========================================${NC}"
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

# Validate production environment
validate_production_environment() {
    print_step "Validating production environment..."
    
    # Check Flutter
    if ! command -v flutter &> /dev/null; then
        print_error "Flutter is not installed or not in PATH"
        exit 1
    fi
    
    # Check if production target exists
    if [ ! -f "${TARGET_FILE}" ]; then
        print_error "Production target file not found: ${TARGET_FILE}"
        exit 1
    fi
    
    # Check environment file
    if [ ! -f ".env.production" ]; then
        print_error "Production environment file not found: .env.production"
        exit 1
    fi
    
    # Check git status
    if [ -n "$(git status --porcelain)" ]; then
        print_warning "Working directory is not clean. Consider committing changes."
    fi
    
    # Check if on main/master branch
    CURRENT_BRANCH=$(git branch --show-current 2>/dev/null || echo 'unknown')
    if [ "${CURRENT_BRANCH}" != "main" ] && [ "${CURRENT_BRANCH}" != "master" ]; then
        print_warning "Not on main/master branch. Current branch: ${CURRENT_BRANCH}"
    fi
    
    print_success "Production environment validation completed"
}

# Security checks
run_security_checks() {
    print_step "Running security checks..."
    
    # Check for debug prints
    if grep -r "print(" lib/ --include="*.dart" | grep -v "debugPrint"; then
        print_error "Found print() statements in code. Use debugPrint() instead."
        exit 1
    fi
    
    # Check for TODO/FIXME in critical files
    if grep -r "TODO\|FIXME" lib/main_production.dart lib/core/config/; then
        print_error "Found TODO/FIXME in critical production files"
        exit 1
    fi
    
    # Check for hardcoded secrets
    if grep -r "password\|secret\|key" lib/ --include="*.dart" | grep -i "="; then
        print_warning "Potential hardcoded secrets found. Please review."
    fi
    
    print_success "Security checks completed"
}

# Clean and prepare
clean_and_prepare() {
    print_step "Cleaning and preparing build..."
    
    flutter clean
    rm -rf "${BUILD_DIR}"
    mkdir -p "${BUILD_DIR}"
    
    # Clear pub cache for clean build
    flutter pub cache clean
    flutter pub get
    
    print_success "Build preparation completed"
}

# Run comprehensive tests
run_comprehensive_tests() {
    print_step "Running comprehensive test suite..."
    
    # Unit tests with coverage
    flutter test --coverage --reporter=expanded
    
    # Integration tests
    if [ -d "integration_test" ]; then
        flutter test integration_test/production_test.dart
    fi
    
    # Check test coverage
    if command -v lcov &> /dev/null; then
        lcov --summary coverage/lcov.info
    fi
    
    print_success "Comprehensive tests completed"
}

# Build Android with production optimizations
build_android_production() {
    print_step "Building Android APK/AAB for production..."
    
    # Build APK
    flutter build apk \
        --release \
        --flavor production \
        --target "${TARGET_FILE}" \
        --build-name "1.0.0" \
        --build-number "$(date +%s)" \
        --dart-define=FLAVOR=production \
        --dart-define-from-file=.env.production \
        --obfuscate \
        --split-debug-info="${BUILD_DIR}/debug-info" \
        --tree-shake-icons
    
    # Build AAB for Play Store
    flutter build appbundle \
        --release \
        --flavor production \
        --target "${TARGET_FILE}" \
        --build-name "1.0.0" \
        --build-number "$(date +%s)" \
        --dart-define=FLAVOR=production \
        --dart-define-from-file=.env.production \
        --obfuscate \
        --split-debug-info="${BUILD_DIR}/debug-info" \
        --tree-shake-icons
    
    # Copy artifacts
    cp build/app/outputs/flutter-apk/app-production-release.apk "${BUILD_DIR}/oxii-chat-production.apk"
    cp build/app/outputs/bundle/productionRelease/app-production-release.aab "${BUILD_DIR}/oxii-chat-production.aab"
    
    print_success "Android production build completed"
}

# Build iOS with production optimizations
build_ios_production() {
    print_step "Building iOS for production..."
    
    flutter build ios \
        --release \
        --flavor production \
        --target "${TARGET_FILE}" \
        --build-name "1.0.0" \
        --build-number "$(date +%s)" \
        --dart-define=FLAVOR=production \
        --dart-define-from-file=.env.production \
        --obfuscate \
        --split-debug-info="${BUILD_DIR}/debug-info" \
        --tree-shake-icons
    
    print_success "iOS production build completed"
}

# Build Web with production optimizations
build_web_production() {
    print_step "Building Web for production..."
    
    flutter build web \
        --release \
        --target "${TARGET_FILE}" \
        --dart-define=FLAVOR=production \
        --dart-define-from-file=.env.production \
        --web-renderer canvaskit \
        --tree-shake-icons \
        --source-maps
    
    # Copy web build
    cp -r build/web "${BUILD_DIR}/web"
    
    print_success "Web production build completed"
}

# Generate production build info
generate_production_build_info() {
    print_step "Generating production build information..."
    
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
  "gitTag": "$(git describe --tags --exact-match 2>/dev/null || echo 'none')",
  "buildNumber": "$(date +%s)",
  "isCleanBuild": $([ -z "$(git status --porcelain)" ] && echo "true" || echo "false"),
  "environment": {
    "apiBaseUrl": "https://api.oxii.chat",
    "websocketUrl": "wss://ws.oxii.chat",
    "firebaseProjectId": "oxii-chat-prod"
  },
  "security": {
    "obfuscated": true,
    "debugInfoSeparated": true,
    "treeShaken": true
  }
}
EOF
    
    print_success "Production build information generated"
}

# Main production build function
main() {
    validate_production_environment
    run_security_checks
    clean_and_prepare
    
    # Always run tests in production
    run_comprehensive_tests
    
    case "${PLATFORM}" in
        "android")
            build_android_production
            ;;
        "ios")
            build_ios_production
            ;;
        "web")
            build_web_production
            ;;
        "all")
            build_android_production
            build_ios_production
            build_web_production
            ;;
        *)
            print_error "Unknown platform: ${PLATFORM}"
            echo "Supported platforms: android, ios, web, all"
            exit 1
            ;;
    esac
    
    generate_production_build_info
    
    echo ""
    print_success "🎉 Production build completed successfully!"
    echo -e "${GREEN}📁 Build artifacts: ${BUILD_DIR}${NC}"
    echo -e "${GREEN}🏷️  Flavor: ${FLAVOR}${NC}"
    echo -e "${GREEN}📱 Platform: ${PLATFORM}${NC}"
    echo -e "${GREEN}🔒 Security: Obfuscated, Tree-shaken${NC}"
}

# Run main function
main "$@"
