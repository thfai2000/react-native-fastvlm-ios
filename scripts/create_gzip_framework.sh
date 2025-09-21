#!/bin/bash

set -e

# Configuration
FRAMEWORK_NAME="Gzip"
SCHEME_NAME="GzipSwift"  
TEMP_BUILD_DIR="/Users/tanghungfai/Desktop/Work/react-native-fastvlm-ios/temp_spm_builds"
XCFRAMEWORKS_DIR="/Users/tanghungfai/Desktop/Work/react-native-fastvlm-ios/xcframeworks"

create_framework_from_build_products() {
    local platform=$1
    local build_products_dir="$TEMP_BUILD_DIR/Products_${SCHEME_NAME}_${platform}"
    local archive_path="$TEMP_BUILD_DIR/${FRAMEWORK_NAME}_iOS_${platform}.xcarchive"
    local framework_path="$archive_path/Products/Library/Frameworks/${SCHEME_NAME}.framework"
    
    echo "Creating framework for $platform..."
    
    # Clean and create framework directory
    rm -rf "$archive_path"
    mkdir -p "$framework_path"
    
    # Find the build products directory - handle different architectures
    local products_dir
    if [ "$platform" = "iphoneos" ]; then
        products_dir="$build_products_dir/arm64-apple-ios/release"
    else
        products_dir="$build_products_dir/arm64-apple-ios-simulator/release"
    fi
    
    if [ ! -d "$products_dir" ]; then
        echo "Build products not found: $products_dir"
        return 1
    fi
    
    # Create static library from object files
    local object_files=$(find "$products_dir" -name "*.o" | grep -v Test | tr '\n' ' ')
    if [ -n "$object_files" ]; then
        echo "Creating static library from object files..."
        ar rcs "$framework_path/$SCHEME_NAME" $object_files
    else
        echo "No object files found"
        return 1
    fi
    
    # Copy Swift module files for the main module only
    echo "Copying Swift module files..."
    mkdir -p "$framework_path/Modules"
    
    # Copy only the main module files (Gzip in this case)
    if [ -d "$products_dir/Modules" ]; then
        cp "$products_dir/Modules/Gzip.swiftmodule" "$framework_path/Modules/" 2>/dev/null || true
        cp "$products_dir/Modules/Gzip.swiftdoc" "$framework_path/Modules/" 2>/dev/null || true
        cp "$products_dir/Modules/Gzip.swiftsourceinfo" "$framework_path/Modules/" 2>/dev/null || true
        cp "$products_dir/Modules/Gzip.abi.json" "$framework_path/Modules/" 2>/dev/null || true
        cp "$products_dir/Modules/Gzip.swiftinterface" "$framework_path/Modules/" 2>/dev/null || true
        cp "$products_dir/Modules/Gzip.private.swiftinterface" "$framework_path/Modules/" 2>/dev/null || true
    fi
    
    # Create module.modulemap
    cat > "$framework_path/Modules/module.modulemap" << EOF
framework module $SCHEME_NAME {
    umbrella header "$SCHEME_NAME.h"
    export *
    module * { export * }
}
EOF
    
    # Create umbrella header
    mkdir -p "$framework_path/Headers"
    cat > "$framework_path/Headers/$SCHEME_NAME.h" << EOF
//
//  $SCHEME_NAME.h
//  $SCHEME_NAME
//

#ifndef ${SCHEME_NAME}_h
#define ${SCHEME_NAME}_h

#import <Foundation/Foundation.h>

FOUNDATION_EXPORT double ${SCHEME_NAME}VersionNumber;
FOUNDATION_EXPORT const unsigned char ${SCHEME_NAME}VersionString[];

#endif /* ${SCHEME_NAME}_h */
EOF
    
    # Create Info.plist with proper platform information
    local supported_platforms
    if [ "$platform" = "iphoneos" ]; then
        supported_platforms="iPhoneOS"
    else
        supported_platforms="iPhoneSimulator"
    fi
    
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
    <key>CFBundleSupportedPlatforms</key>
    <array>
        <string>${supported_platforms}</string>
    </array>
</dict>
</plist>
EOF
    
    echo "Framework created: $framework_path"
}

# Create frameworks from existing build products
mkdir -p "$XCFRAMEWORKS_DIR"

create_framework_from_build_products "iphoneos"
create_framework_from_build_products "iphonesimulator"

# Create XCFramework
echo "Creating XCFramework..."
xcodebuild -create-xcframework \
    -framework "$TEMP_BUILD_DIR/${FRAMEWORK_NAME}_iOS_iphoneos.xcarchive/Products/Library/Frameworks/${SCHEME_NAME}.framework" \
    -framework "$TEMP_BUILD_DIR/${FRAMEWORK_NAME}_iOS_iphonesimulator.xcarchive/Products/Library/Frameworks/${SCHEME_NAME}.framework" \
    -output "$XCFRAMEWORKS_DIR/${FRAMEWORK_NAME}.xcframework"

if [ $? -eq 0 ]; then
    echo "SUCCESS: XCFramework created at $XCFRAMEWORKS_DIR/${FRAMEWORK_NAME}.xcframework"
    ls -la "$XCFRAMEWORKS_DIR/${FRAMEWORK_NAME}.xcframework"
else
    echo "ERROR: Failed to create XCFramework"
    exit 1
fi