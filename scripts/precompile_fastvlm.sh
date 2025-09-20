#!/usr/bin/env bash
set -euo pipefail

# Script to precompile FastVLM and Video schemes into frameworks under ios/compiled
# Outputs:
#   ios/compiled/FastVLM.framework
#   ios/compiled/Video.framework

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
IOS_DIR="$ROOT_DIR/ios"
OUT_DIR="$IOS_DIR/compiled"
PROJECT="$IOS_DIR/FastVLM.xcodeproj"

mkdir -p "$OUT_DIR"

build_framework() {
  local scheme="$1"
  local dest="$OUT_DIR/${scheme}.framework"

  echo "Building scheme: $scheme"

  # Use a dedicated derived data path instead of OBJROOT/SYMROOT which can
  # cause unexpected build setting interactions (like different SWIFT_OPTIMIZATION_LEVEL
  # or previews being disabled). Also disable code signing and enable library
  # distribution flags for building frameworks suitable for packaging.
  DERIVED_DATA_PATH="$OUT_DIR/derived/$scheme"

  xcodebuild -project "$PROJECT" \
    -scheme "$scheme" \
    -configuration Release \
    -derivedDataPath "$DERIVED_DATA_PATH" \
    -sdk iphoneos \
    CODE_SIGNING_ALLOWED=NO \
    BUILD_LIBRARIES_FOR_DISTRIBUTION=YES \
    clean build

  # Search for the built .framework in the build products
  # Frameworks are placed under the Products directory inside the derived data
  FRAMEWORK_PATH=$(find "$DERIVED_DATA_PATH/Build/Products" -name "${scheme}.framework" -print -quit || true)
  if [ -z "$FRAMEWORK_PATH" ]; then
    echo "Failed to locate ${scheme}.framework in build products"
    exit 1
  fi

  echo "Copying framework from $FRAMEWORK_PATH to $dest"
  rm -rf "$dest"
  cp -R "$FRAMEWORK_PATH" "$dest"
}

# Build both schemes
build_framework "FastVLM"
build_framework "Video"

echo "Precompile finished. Frameworks are in: $OUT_DIR"
