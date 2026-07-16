#!/bin/bash
set -e

SOURCE_DIR="cdda-source"
OUTPUT_DIR="web-output"

echo "Starting CDDA WebAssembly build using official build scripts..."

# Build configuration
BUILD_TYPE="${BUILD_TYPE:-Release}"
BUILD_TILES="${BUILD_TILES:-true}"
BUILD_SOUND="${BUILD_SOUND:-true}"
BUILD_LOCALIZATION="${BUILD_LOCALIZATION:-false}"

echo "Build configuration:"
echo "  Type: $BUILD_TYPE"
echo "  Tiles: $BUILD_TILES"
echo "  Sound: $BUILD_SOUND"
echo "  Localization: $BUILD_LOCALIZATION"

# Use absolute path for source directory
SOURCE_ABS_PATH="$(pwd)/$SOURCE_DIR"
echo "Source directory: $SOURCE_ABS_PATH"

# Verify source directory exists
if [ ! -d "$SOURCE_ABS_PATH" ]; then
  echo "Error: Source directory not found at $SOURCE_ABS_PATH"
  exit 1
fi

# Create output directory
mkdir -p "$OUTPUT_DIR"

# Change to CDDA source directory and use official build scripts
cd "$SOURCE_ABS_PATH"

echo "Using official CDDA Emscripten build scripts..."

# Prepare web data if script exists
if [ -f "tools/emscripten/prepare-web-data.sh" ]; then
  echo "Preparing web data..."
  bash tools/emscripten/prepare-web-data.sh
else
  echo "Warning: prepare-web-data.sh not found, skipping..."
fi

# Build with Emscripten using official Makefile
echo "Building with Emscripten..."
CCACHE=0 make -j4 NATIVE=emscripten BACKTRACE=0 TILES=1 TESTS=0 RUNTESTS=0 RELEASE=1 CCACHE=0 LINTJSON=0 cataclysm-tiles.js

# Copy the generated WebAssembly files to output directory
echo "Copying WebAssembly output files..."
if [ -f "cataclysm-tiles.js" ]; then
  cp cataclysm-tiles.js "$OUTPUT_DIR/"
fi
if [ -f "cataclysm-tiles.wasm" ]; then
  cp cataclysm-tiles.wasm "$OUTPUT_DIR/"
fi
if [ -f "cataclysm-tiles.data" ]; then
  cp cataclysm-tiles.data "$OUTPUT_DIR/"
fi
if [ -f "cataclysm-tiles.data.js" ]; then
  cp cataclysm-tiles.data.js "$OUTPUT_DIR/"
fi

# Copy data directory (for runtime assets)
echo "Copying data directory..."
if [ -d "data" ]; then
  cp -r data "$OUTPUT_DIR/"
fi

# Copy lang directory if localization is enabled
if [ "$BUILD_LOCALIZATION" = "true" ] && [ -d "lang" ]; then
  cp -r lang "$OUTPUT_DIR/"
fi

# Copy sound directory if sound is enabled
if [ "$BUILD_SOUND" = "true" ] && [ -d "sound" ]; then
  cp -r sound "$OUTPUT_DIR/"
fi

echo "Build completed successfully!"
echo "Web output prepared in: $OUTPUT_DIR"
