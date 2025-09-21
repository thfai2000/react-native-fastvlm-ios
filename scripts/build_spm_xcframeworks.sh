#!/bin/bash

# Build XCFrameworks from Swift Package Manager Dependencies
# This script checkouts Git repositories with specific tags and creates xcframeworks
# from Swift packages for use as vendored frameworks in PodSpec.

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
IOS_DIR="$PROJECT_ROOT/ios"
VENDOR_DIR="$IOS_DIR/vendor"
XCFRAMEWORKS_DIR="$IOS_DIR/xcframeworks"
TEMP_BUILD_DIR="$PROJECT_ROOT/temp_spm_builds"
DERIVED_DATA_DIR="$TEMP_BUILD_DIR/DerivedData"

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

# Swift Package Dependencies Configuration
# Format: "FRAMEWORK_NAME:GIT_URL:TAG_OR_BRANCH:SCHEME_NAME"
# Only including packages that are likely to build successfully for iOS
declare -a SWIFT_PACKAGES=(
    "Gzip:https://github.com/1024jp/GzipSwift.git:6.0.1:GzipSwift"
    "Numerics:https://github.com/apple/swift-numerics.git:1.1.0:swift-numerics"
    "Jinja:https://github.com/maiqingqiang/Jinja.git:1.3.0:Jinja"
    "Transformers:https://github.com/huggingface/swift-transformers.git:0.1.24:Transformers"
    # MLX packages
    "MLX:https://github.com/ml-explore/mlx-swift.git:0.25.6:mlx-swift"
    "MLXFast:https://github.com/ml-explore/mlx-swift.git:0.25.6:mlx-swift"
    "MLXNN:https://github.com/ml-explore/mlx-swift.git:0.25.6:mlx-swift"
    "MLXRandom:https://github.com/ml-explore/mlx-swift.git:0.25.6:mlx-swift"
    "MLXLMCommon:https://github.com/ml-explore/mlx-swift-examples.git:2.25.7:mlx-swift-examples"
    "MLXVLM:https://github.com/ml-explore/mlx-swift-examples.git:2.25.7:mlx-swift-examples"
    "MLXLLM:https://github.com/ml-explore/mlx-swift-examples.git:2.25.7:mlx-swift-examples"
    "MLXEmbedders:https://github.com/ml-explore/mlx-swift-examples.git:2.25.7:mlx-swift-examples"
    # Skip packages that have iOS framework compatibility issues:
    # "Collections:https://github.com/apple/swift-collections.git:1.2.1:swift-collections" - Has UIKit dependency issues
    # "ArgumentParser:https://github.com/apple/swift-argument-parser.git:1.4.0:swift-argument-parser" - Has Process class issues
)

# iOS build configurations
IOS_DEPLOYMENT_TARGET="18.0"
SIMULATOR_SDK="iphonesimulator"
DEVICE_SDK="iphoneos"

# Cleanup function
cleanup() {
    log_info "Cleaning up temporary build files..."
    if [ -d "$DERIVED_DATA_DIR" ]; then
        rm -rf "$DERIVED_DATA_DIR"
    fi
}

# Trap cleanup on exit
trap cleanup EXIT

# Create necessary directories
create_directories() {
    log_info "Creating necessary directories..."
    mkdir -p "$TEMP_BUILD_DIR"
    mkdir -p "$XCFRAMEWORKS_DIR"
    mkdir -p "$DERIVED_DATA_DIR"
}

# Clone or update a Git repository
checkout_repository() {
    local repo_url=$1
    local tag_or_branch=$2
    local package_dir=$3
    
    log_info "Processing repository: $repo_url"
    
    if [ -d "$package_dir" ]; then
        log_info "Directory $package_dir exists, updating..."
        cd "$package_dir"
        git fetch --all --tags
        git checkout "$tag_or_branch"
        git pull origin "$tag_or_branch" 2>/dev/null || true
    else
        log_info "Cloning repository to $package_dir..."
        git clone "$repo_url" "$package_dir"
        cd "$package_dir"
        git checkout "$tag_or_branch"
    fi
    
    log_success "Repository checkout completed: $package_dir"
}

# Build framework archive for a specific platform
build_archive() {
    local package_dir=$1
    local scheme_name_hint=$2
    local sdk=$3
    local archive_path=$4
    
    log_info "Building archive for $scheme_name_hint on $sdk..."
    
    cd "$package_dir"
    
    # Determine architecture and platform based on SDK
    local arch=""
    local destination=""
    local swift_triple=""
    if [ "$sdk" = "$SIMULATOR_SDK" ]; then
        arch="arm64"
        destination="generic/platform=iOS Simulator"
        swift_triple="arm64-apple-ios$IOS_DEPLOYMENT_TARGET-simulator"
    else
        arch="arm64"
        destination="generic/platform=iOS"
        swift_triple="arm64-apple-ios$IOS_DEPLOYMENT_TARGET"
    fi
    
    # Create a temporary directory for this build
    local temp_products_dir="$TEMP_BUILD_DIR/Products_${scheme_name_hint}_$(basename $sdk)"
    mkdir -p "$temp_products_dir"
    
    # Use swift build instead of xcodebuild for better SPM support
    log_info "Using swift build for $scheme_name_hint on $sdk..."
    swift build \
        --triple "$swift_triple" \
        --configuration release \
        --build-path "$temp_products_dir" \
        -Xswiftc "-sdk" \
        -Xswiftc "$(xcrun --sdk $sdk --show-sdk-path)" \
        -Xswiftc "-target" \
        -Xswiftc "$swift_triple" \
        -Xswiftc "-enable-library-evolution" \
        -Xswiftc "-emit-module-interface" \
        -Xswiftc "-no-verify-emitted-module-interface"
        
    if [ $? -ne 0 ]; then
        log_error "Swift build failed for $scheme_name_hint on $sdk"
        return 1
    fi
    
    # Create archive structure manually
    mkdir -p "$(dirname "$archive_path")"
    rm -rf "$archive_path"
    mkdir -p "$archive_path/Products/Library/Frameworks"
    
    # Find the built products and create a framework structure
    local built_lib_dir="$temp_products_dir/release"
    local framework_dir="$archive_path/Products/Library/Frameworks/$scheme_name_hint.framework"
    
    if [ -d "$built_lib_dir" ]; then
        mkdir -p "$framework_dir"
        
        # Copy the static library if it exists
        if [ -f "$built_lib_dir/lib$scheme_name_hint.a" ]; then
            cp "$built_lib_dir/lib$scheme_name_hint.a" "$framework_dir/$scheme_name_hint"
        else
            log_warning "Static library not found, looking for other products..."
            # Look for any built products
            find "$built_lib_dir" -name "*$scheme_name_hint*" -exec cp {} "$framework_dir/$scheme_name_hint" \;
        fi
        
        # Copy Swift module files if they exist
        if [ -d "$built_lib_dir/$scheme_name_hint.swiftmodule" ]; then
            cp -r "$built_lib_dir/$scheme_name_hint.swiftmodule" "$framework_dir/Modules/"
        fi
        
        # Create a basic Info.plist
        cat > "$framework_dir/Info.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>$scheme_name_hint</string>
    <key>CFBundleIdentifier</key>
    <string>com.spm.$scheme_name_hint</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>$scheme_name_hint</string>
    <key>CFBundlePackageType</key>
    <string>FMWK</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
</dict>
</plist>
EOF
        
        log_success "Archive built successfully: $archive_path"
        return 0
    else
        log_error "Build products not found in $built_lib_dir"
        return 1
    fi
}

# Create XCFramework from device and simulator archives
create_xcframework() {
    local framework_name=$1
    local device_archive=$2
    local simulator_archive=$3
    local xcframework_path=$4
    local scheme_name=$5  # Add scheme name parameter
    
    log_info "Creating XCFramework: $framework_name"
    
    # Remove existing xcframework if it exists
    if [ -d "$xcframework_path" ]; then
        rm -rf "$xcframework_path"
    fi
    
    # Find framework paths in archives using scheme name
    local device_framework="$device_archive/Products/Library/Frameworks/$scheme_name.framework"
    local simulator_framework="$simulator_archive/Products/Library/Frameworks/$scheme_name.framework"
    
    # Check if frameworks exist in archives
    if [ ! -d "$device_framework" ]; then
        log_error "Device framework not found: $device_framework"
        return 1
    fi
    
    if [ ! -d "$simulator_framework" ]; then
        log_error "Simulator framework not found: $simulator_framework"
        return 1
    fi
    
    # Create XCFramework
    xcodebuild -create-xcframework \
        -framework "$device_framework" \
        -framework "$simulator_framework" \
        -output "$xcframework_path"
        
    if [ $? -eq 0 ]; then
        log_success "XCFramework created: $xcframework_path"
    else
        echo "message: $?"
        log_error "Failed to create XCFramework: $framework_name"
        return 1
    fi
}

# Process a single Swift package
process_package() {
    local package_config=$1
    
    # Parse package configuration - handle URLs with colons properly
    local framework_name=$(echo "$package_config" | cut -d':' -f1)
    local remaining=$(echo "$package_config" | cut -d':' -f2-)
    local git_url=$(echo "$remaining" | sed 's|\(.*\):[^:]*:[^:]*$|\1|')
    local tag_or_branch=$(echo "$remaining" | sed 's|.*:\([^:]*\):[^:]*$|\1|')
    local scheme_name=$(echo "$remaining" | sed 's|.*:\([^:]*\)$|\1|')
    
    log_info "Processing package: $framework_name"
    log_info "Git URL: $git_url"
    log_info "Tag/Branch: $tag_or_branch"
    log_info "Scheme: $scheme_name"
    
    # Create package directory path
    local package_name=$(basename "$git_url" .git)
    local package_dir="$TEMP_BUILD_DIR/$package_name"
    
    # Checkout repository
    checkout_repository "$git_url" "$tag_or_branch" "$package_dir"
    
    # Check if Package.swift exists
    if [ ! -f "$package_dir/Package.swift" ]; then
        log_error "Package.swift not found in $package_dir"
        return 1
    fi
    
    # Define archive paths
    local device_archive="$TEMP_BUILD_DIR/${framework_name}_iOS_Device.xcarchive"
    local simulator_archive="$TEMP_BUILD_DIR/${framework_name}_iOS_Simulator.xcarchive"
    local xcframework_path="$XCFRAMEWORKS_DIR/${framework_name}.xcframework"
    
    # Build archives
    build_archive "$package_dir" "$scheme_name" "$DEVICE_SDK" "$device_archive" || return 1
    build_archive "$package_dir" "$scheme_name" "$SIMULATOR_SDK" "$simulator_archive" || return 1
    
    # Create XCFramework
    create_xcframework "$framework_name" "$device_archive" "$simulator_archive" "$xcframework_path" "$scheme_name" || return 1
    
    # Cleanup archives
    rm -rf "$device_archive" "$simulator_archive"
    
    log_success "Package processed successfully: $framework_name"
}

# Main execution function
main() {
    log_info "Starting XCFramework build process..."
    log_info "Project root: $PROJECT_ROOT"
    log_info "XCFrameworks output directory: $XCFRAMEWORKS_DIR"
    
    # Create necessary directories
    create_directories
    
    # Process each Swift package
    local failed_packages=()
    for package_config in "${SWIFT_PACKAGES[@]}"; do
        if ! process_package "$package_config"; then
            IFS=':' read -r framework_name _ _ _ <<< "$package_config"
            failed_packages+=("$framework_name")
            log_warning "Failed to process package: $framework_name"
        fi
    done
    
    # Report results
    echo ""
    log_info "Build process completed!"
    
    if [ ${#failed_packages[@]} -eq 0 ]; then
        log_success "All XCFrameworks built successfully!"
        log_info "Generated XCFrameworks:"
        ls -la "$XCFRAMEWORKS_DIR"
    else
        log_warning "Some packages failed to build:"
        for failed in "${failed_packages[@]}"; do
            log_error "  - $failed"
        done
        exit 1
    fi
}

# Script entry point
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
