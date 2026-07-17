#!/bin/bash
set -e

SOURCE_DIR="cdda-source"
OUTPUT_DIR="web-output"

echo "Starting CDDA WebAssembly build using official 0.I build scripts..."

SOURCE_ABS_PATH="$(pwd)/$SOURCE_DIR"
OUTPUT_ABS_PATH="$(pwd)/$OUTPUT_DIR"
echo "Source directory: $SOURCE_ABS_PATH"
echo "Output directory: $OUTPUT_ABS_PATH"

if [ ! -d "$SOURCE_ABS_PATH" ]; then
  echo "Error: Source directory not found at $SOURCE_ABS_PATH"
  exit 1
fi

mkdir -p "$OUTPUT_ABS_PATH"
cd "$SOURCE_ABS_PATH"

# --- Step 1: Compile with Emscripten ---
# As of 0.I, this script itself calls emsdk install/activate, so we don't
# need to do that separately in the Action.
if [ ! -f "build-scripts/build-emscripten.sh" ]; then
  echo "ERROR: build-scripts/build-emscripten.sh not found in this source tree."
  echo "The build layout has changed again - listing build-scripts/ for reference:"
  ls -la build-scripts/
  exit 1
fi

echo "Compiling cataclysm-tiles.js via build-scripts/build-emscripten.sh..."
bash build-scripts/build-emscripten.sh

# --- Step 2: Package data + assemble the real web bundle ---
# As of 0.I this single script handles EVERYTHING that used to be split
# across prepare-web-data.sh / prepare-web.sh in the 2024 version:
#   - stages data/gfx into web_bundle/, stripping obsolete mods
#   - runs emscripten's file_packager to produce cataclysm-tiles.data(.js)
#   - copies the OFFICIAL build-data/web/index.html, font, and favicon
#   - drops everything into a "build/" folder
if [ ! -f "build-scripts/prepare-web.sh" ]; then
  echo "ERROR: build-scripts/prepare-web.sh not found in this source tree."
  exit 1
fi

echo "Packaging data and assembling web bundle via build-scripts/prepare-web.sh..."
bash build-scripts/prepare-web.sh

# --- Step 3: Copy the official build/ output straight to OUTPUT_DIR ---
# We deliberately do NOT use a custom index.html or manually copy data/ here -
# prepare-web.sh already produced the correct, complete, official bundle.
if [ ! -d "build" ]; then
  echo "ERROR: prepare-web.sh did not produce a build/ directory as expected."
  exit 1
fi

echo "Copying official web bundle to output..."
cp -r build/. "$OUTPUT_ABS_PATH/"

# --- Sanity check ---
for f in cataclysm-tiles.js cataclysm-tiles.wasm cataclysm-tiles.data cataclysm-tiles.data.js index.html; do
  if [ ! -f "$OUTPUT_ABS_PATH/$f" ]; then
    echo "WARNING: expected file missing from output: $f"
  fi
done

echo "Build completed successfully!"
echo "Web output prepared in: $OUTPUT_ABS_PATH"
