#!/bin/bash
set -e

SOURCE_DIR="cdda-source"
BUILD_DIR="build-cache"
OUTPUT_DIR="web-output"

echo "Starting CDDA WebAssembly build..."

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

# Clean and create build directory
if [ -d "$BUILD_DIR" ]; then
  echo "Cleaning previous build..."
  rm -rf "$BUILD_DIR"
fi
mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR"

# Configure with CMake for Emscripten
echo "Configuring CMake for Emscripten..."
emcmake cmake "$SOURCE_DIR" \
  -DCMAKE_BUILD_TYPE="$BUILD_TYPE" \
  -DCMAKE_TOOLCHAIN_FILE="$EMSDK/upstream/emscripten/cmake/Modules/Platform/Emscripten.cmake" \
  -DTILES="$BUILD_TILES" \
  -DSOUND="$BUILD_SOUND" \
  -DLOCALIZATION="$BUILD_LOCALIZATION" \
  -DCMAKE_EXPORT_COMPILE_COMMANDS=ON \
  -DCMAKE_DISABLE_FIND_PACKAGE_Curses=TRUE \
  -DCMAKE_DISABLE_FIND_PACKAGE_PkgConfig=TRUE \
  -DBACKTRACE=OFF \
  -DUSE_HOME=OFF

# Build the project
echo "Building CDDA with Emscripten..."
emmake make cataclysm-tiles -j$(nproc)

# Create output directory
mkdir -p "$OUTPUT_DIR"

# Link with Emscripten to create WebAssembly output
echo "Linking with Emscripten for WebAssembly output..."
emcc -o "$OUTPUT_DIR/cataclysm-tiles.html" \
  cataclysm-tiles \
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
  --embed-file "$SOURCE_DIR/data@/data" \
  --embed-file "$SOURCE_DIR/lang@/lang" \
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
if [ -d "$SOURCE_DIR/data" ]; then
  cp -r "$SOURCE_DIR/data" "$OUTPUT_DIR/"
fi

# Copy required assets
echo "Copying required assets..."
if [ -d "$SOURCE_DIR/lang" ]; then
  cp -r "$SOURCE_DIR/lang" "$OUTPUT_DIR/"
fi

# Copy font files if they exist
if [ -d "$SOURCE_DIR/fonts" ]; then
  cp -r "$SOURCE_DIR/fonts" "$OUTPUT_DIR/"
fi

echo "Build completed successfully!"
echo "Output location: $BUILD_DIR"
echo "Web output prepared in: $OUTPUT_DIR"
