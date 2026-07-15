#!/bin/bash
set -e

SOURCE_DIR="cdda-source"
BUILD_DIR="build-cache"
OUTPUT_DIR="web-output"

echo "Starting CDDA WebAssembly build with full configuration..."

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

# Full CMake configuration for Emscripten with proper memory settings
echo "Configuring CMake for Emscripten with full options..."
emcmake cmake "$SOURCE_ABS_PATH" \
  -DCMAKE_BUILD_TYPE="$BUILD_TYPE" \
  -DCMAKE_TOOLCHAIN_FILE="$EMSDK/upstream/emscripten/cmake/Modules/Platform/Emscripten.cmake" \
  -DTILES="$BUILD_TILES" \
  -DSOUND="$BUILD_SOUND" \
  -DLOCALIZATION="$BUILD_LOCALIZATION" \
  -DCMAKE_EXPORT_COMPILE_COMMANDS=ON \
  -DCMAKE_DISABLE_FIND_PACKAGE_Curses=TRUE \
  -DCMAKE_DISABLE_FIND_PACKAGE_PkgConfig=TRUE \
  -DBACKTRACE=OFF \
  -DUSE_HOME=OFF \
  -DCMAKE_C_FLAGS="-s ALLOW_MEMORY_GROWTH=1 -s INITIAL_MEMORY=256MB -s MAX_MEMORY=4GB" \
  -DCMAKE_CXX_FLAGS="-s ALLOW_MEMORY_GROWTH=1 -s INITIAL_MEMORY=256MB -s MAX_MEMORY=4GB"

if [ $? -ne 0 ]; then
  echo "CMake configuration failed. Trying with fewer options..."
  emcmake cmake "$SOURCE_ABS_PATH" \
    -DCMAKE_BUILD_TYPE="$BUILD_TYPE" \
    -DCMAKE_TOOLCHAIN_FILE="$EMSDK/upstream/emscripten/cmake/Modules/Platform/Emscripten.cmake" \
    -DTILES="$BUILD_TILES" \
    -DSOUND="$BUILD_SOUND" \
    -DLOCALIZATION="$BUILD_LOCALIZATION"
  
  if [ $? -ne 0 ]; then
    echo "CMake configuration failed. Trying basic configuration..."
    emcmake cmake "$SOURCE_ABS_PATH" \
      -DCMAKE_BUILD_TYPE="$BUILD_TYPE" \
      -DCMAKE_TOOLCHAIN_FILE="$EMSDK/upstream/emscripten/cmake/Modules/Platform/Emscripten.cmake"
    
    if [ $? -ne 0 ]; then
      echo "All CMake configurations failed."
      exit 1
    fi
  fi
fi

# Build with limited parallel jobs to manage memory
echo "Building CDDA with Emscripten (limited parallelism for memory management)..."
emmake make cataclysm-tiles -j2

# Create output directory
mkdir -p "$OUTPUT_DIR"

# Link with Emscripten for WebAssembly output with proper memory settings
echo "Linking with Emscripten for WebAssembly output..."
emcc cataclysm-tiles \
  -o "$OUTPUT_DIR/cataclysm-tiles.html" \
  -s USE_SDL=2 \
  -s USE_SDL_IMAGE=2 \
  -s USE_SDL_TTF=2 \
  -s USE_SDL_MIXER=2 \
  -s SDL2_IMAGE_FORMATS='["png","jpg"]' \
  -s ALLOW_MEMORY_GROWTH=1 \
  -s INITIAL_MEMORY=256MB \
  -s MAX_MEMORY=4GB \
  -s WASM=1 \
  -s EXPORTED_RUNTIME_METHODS='["ccall","cwrap","UTF8ToString","stringToUTF8"]' \
  -s MODULARIZE=1 \
  -s EXPORT_NAME="Cataclysm" \
  --embed-file "$SOURCE_ABS_PATH/data@/data" \
  --embed-file "$SOURCE_ABS_PATH/lang@/lang" \
  -lidn \
  -lpthread

# Copy the generated WebAssembly files
echo "Copying WebAssembly output files..."
if [ -f "$OUTPUT_DIR/cataclysm-tiles.html" ]; then
  mv "$OUTPUT_DIR/cataclysm-tiles.html" "$OUTPUT_DIR/index.html"
fi
if [ -f "$OUTPUT_DIR/cataclysm-tiles.js" ]; then
  cp "$OUTPUT_DIR/cataclysm-tiles.js" "$OUTPUT_DIR/"
fi
if [ -f "$OUTPUT_DIR/cataclysm-tiles.wasm" ]; then
  cp "$OUTPUT_DIR/cataclysm-tiles.wasm" "$OUTPUT_DIR/"
fi
if [ -f "$OUTPUT_DIR/cataclysm-tiles.data" ]; then
  cp "$OUTPUT_DIR/cataclysm-tiles.data" "$OUTPUT_DIR/"
fi
if [ -f "$OUTPUT_DIR/cataclysm-tiles.data.js" ]; then
  cp "$OUTPUT_DIR/cataclysm-tiles.data.js" "$OUTPUT_DIR/"
fi

# Copy data directory (fallback if embedding fails)
echo "Copying data directory..."
if [ -d "$SOURCE_ABS_PATH/data" ]; then
  cp -r "$SOURCE_ABS_PATH/data" "$OUTPUT_DIR/"
fi

# Copy required assets
echo "Copying required assets..."
if [ -d "$SOURCE_ABS_PATH/lang" ]; then
  cp -r "$SOURCE_ABS_PATH/lang" "$OUTPUT_DIR/"
fi

# Copy font files if they exist
if [ -d "$SOURCE_ABS_PATH/fonts" ]; then
  cp -r "$SOURCE_ABS_PATH/fonts" "$OUTPUT_DIR/"
fi

echo "Build completed successfully!"
echo "Output location: $BUILD_DIR"
echo "Web output prepared in: $OUTPUT_DIR"
