#!/bin/bash
set -e

SOURCE_DIR="cdda-source"
BUILD_DIR="build-cache"
OUTPUT_DIR="web-output"

echo "Starting CDDA WebAssembly build with simplified configuration..."

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

# Clean and create build directory
if [ -d "$BUILD_DIR" ]; then
  echo "Cleaning previous build..."
  rm -rf "$BUILD_DIR"
fi
mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR"

# Try basic CMake configuration first
echo "Attempting basic CMake configuration..."
emcmake cmake "$SOURCE_ABS_PATH" \
  -DCMAKE_BUILD_TYPE="$BUILD_TYPE" \
  -DCMAKE_TOOLCHAIN_FILE="$EMSDK/upstream/emscripten/cmake/Modules/Platform/Emscripten.cmake"

if [ $? -ne 0 ]; then
  echo "Basic CMake failed. Trying with minimal options..."
  emcmake cmake "$SOURCE_ABS_PATH" \
    -DCMAKE_BUILD_TYPE="$BUILD_TYPE" \
    -DCMAKE_TOOLCHAIN_FILE="$EMSDK/upstream/emscripten/cmake/Modules/Platform/Emscripten.cmake" \
    -DBUILD_TESTS=OFF \
    -DCMAKE_INSTALL_PREFIX="$OUTPUT_DIR"
fi

if [ $? -ne 0 ]; then
  echo "CMake configuration failed. This may indicate CDDA doesn't support Emscripten builds in this version."
  echo "Checking if CDDA has WebAssembly build scripts..."
  if [ -f "$SOURCE_ABS_PATH/build-scripts/build-emscripten.sh" ]; then
    echo "Official Emscripten build script found, but may be disabled due to resource constraints."
    echo "See PR #81827: 'Disable huge uncacheable emscripten builds'"
  fi
  exit 1
fi

# Try to build
echo "Attempting to build..."
emmake make -j$(nproc)

# Check if build produced any executables
if [ -f "cataclysm-tiles" ] || [ -f "cataclysm" ]; then
  echo "Build successful, preparing WebAssembly output..."
  
  # Create output directory
  mkdir -p "$OUTPUT_DIR"
  
  # If we got a regular executable, try to convert it to WebAssembly
  EXECUTABLE=$(find . -name "cataclysm-tiles" -o -name "cataclysm" | head -n1)
  if [ -n "$EXECUTABLE" ]; then
    echo "Converting $EXECUTABLE to WebAssembly..."
    emcc "$EXECUTABLE" \
      -o "$OUTPUT_DIR/index.html" \
      -s USE_SDL=2 \
      -s ALLOW_MEMORY_GROWTH=1 \
      -s WASM=1 \
      -s MODULARIZE=1 \
      -s EXPORT_NAME="Cataclysm"
  fi
else
  echo "No executable found after build. CDDA may not support Emscripten builds."
  exit 1
fi

echo "Build completed successfully!"
echo "Web output prepared in: $OUTPUT_DIR"
