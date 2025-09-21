#!/bin/bash

set -e

# Configuration
FRAMEWORK_NAME="Gzip"
SCHEME_NAME="GzipSwift"
REPO_DIR="/Users/tanghungfai/Desktop/Work/react-native-fastvlm-ios/temp_spm_builds/GzipSwift"
TEMP_BUILD_DIR="/Users/tanghungfai/Desktop/Work/react-native-fastvlm-ios/temp_spm_builds"
XCFRAMEWORKS_DIR="/Users/tanghungfai/Desktop/Work/react-native-fastvlm-ios/xcframeworks"

build_for_platform() {
    local platform=$1
    local arch=$2
    local sdk_name=$3
    
    echo "Building for $platform ($arch)..."
    
    cd "$REPO_DIR"
    
    # Build using swift build
    local build_path="$TEMP_BUILD_DIR/Build_${platform}"
    rm -rf "$build_path"
    
    swift build \
        --configuration release \
        --arch "$arch" \
        --sdk "$(xcrun --sdk $sdk_name --show-sdk-path)" \
        -Xswiftc "-target" \
        -Xswiftc "$arch-apple-ios15.0" \
        --build-path "$build_path"
    
    # Create framework structure
    local archive_path="$TEMP_BUILD_DIR/${FRAMEWORK_NAME}_iOS_${platform}.xcarchive"
    local framework_path="$archive_path/Products/Library/Frameworks/${SCHEME_NAME}.framework"
    
    mkdir -p "$framework_path"
    
    # Find and copy the static library
    local products_dir="$build_path/$arch-apple-ios/release"
    
    # Look for the module build directory
    local module_dir=$(find "$products_dir" -name "*.build" | head -1)
    
    if [ -d "$module_dir" ]; then
        # Create static library from object files
        local object_files=$(find "$module_dir" -name "*.o" | tr '\n' ' ')
        if [ -n "$object_files" ]; then
            ar rcs "$framework_path/$SCHEME_NAME" $object_files
        fi
    fi
    
    # Copy Swift module files
    find "$products_dir" -name "*.swiftmodule" -exec cp {} "$framework_path/" \; 2>/dev/null || true
    find "$products_dir" -name "*.swiftdoc" -exec cp {} "$framework_path/" \; 2>/dev/null || true
    find "$products_dir" -name "*.swiftsourceinfo" -exec cp {} "$framework_path/" \; 2>/dev/null || true
    
    # Create Info.plist
    cat > "$framework_path/Info.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleIdentifier</key>
    <string>com.swiftpackage.${SCHEME_NAME}</string>
    <key>CFBundleName</key>
    <string>${SCHEME_NAME}</string>
    <key>CFBundleVersion</key>
    <string>1.0</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundlePackageType</key>
    <string>FMWK</string>
    <key>CFBundleExecutable</key>
    <string>${SCHEME_NAME}</string>
    <key>MinimumOSVersion</key>
    <string>15.0</string>
</dict>
</plist>
EOF
    
    echo "Framework created: $framework_path"
}

# Build for device and simulator
mkdir -p "$XCFRAMEWORKS_DIR"

build_for_platform "Device" "arm64" "iphoneos"
build_for_platform "Simulator" "arm64" "iphonesimulator"

# Create XCFramework
echo "Creating XCFramework..."
xcodebuild -create-xcframework \
    -framework "$TEMP_BUILD_DIR/${FRAMEWORK_NAME}_iOS_Device.xcarchive/Products/Library/Frameworks/${SCHEME_NAME}.framework" \
    -framework "$TEMP_BUILD_DIR/${FRAMEWORK_NAME}_iOS_Simulator.xcarchive/Products/Library/Frameworks/${SCHEME_NAME}.framework" \
    -output "$XCFRAMEWORKS_DIR/${FRAMEWORK_NAME}.xcframework"

echo "XCFramework created successfully: $XCFRAMEWORKS_DIR/${FRAMEWORK_NAME}.xcframework"