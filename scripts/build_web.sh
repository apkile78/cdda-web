#!/bin/bash  
set -e  
  
SOURCE_DIR="cdda-source"  
OUTPUT_DIR="web-output"  
  
echo "Starting CDDA WebAssembly build using official 0.I build scripts..."  
  
# Capture the repo checkout root BEFORE we cd into the source tree, so we can  
# reliably find the vendored coi-serviceworker.min.js later.  
REPO_ROOT="$(pwd)"  
  
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
if [ ! -f "build-scripts/build-emscripten.sh" ]; then  
  echo "ERROR: build-scripts/build-emscripten.sh not found in this source tree."  
  echo "The build layout has changed again - listing build-scripts/ for reference:"  
  ls -la build-scripts/  
  exit 1  
fi  
  
echo "Compiling cataclysm-tiles.js via build-scripts/build-emscripten.sh..."  
bash build-scripts/build-emscripten.sh  
  
# --- Step 2: Package data + assemble the real web bundle ---  
if [ ! -f "build-scripts/prepare-web.sh" ]; then  
  echo "ERROR: build-scripts/prepare-web.sh not found in this source tree."  
  exit 1  
fi  
  
echo "Packaging data and assembling web bundle via build-scripts/prepare-web.sh..."  
bash build-scripts/prepare-web.sh  
  
# --- Step 3: Copy the official build/ output straight to OUTPUT_DIR ---  
if [ ! -d "build" ]; then  
  echo "ERROR: prepare-web.sh did not produce a build/ directory as expected."  
  exit 1  
fi  
  
echo "Copying official web bundle to output..."  
cp -r build/. "$OUTPUT_ABS_PATH/"  
  
# --- Sanity check ---  
for f in cataclysm-tiles.js cataclysm-tiles.wasm cataclysm-tiles.data cataclysm-tiles.data.js index.html coi-serviceworker.min.js; do  
  if [ ! -f "$OUTPUT_ABS_PATH/$f" ] && [ "$f" != "coi-serviceworker.min.js" ]; then  
    echo "WARNING: expected file missing from output: $f"  
  fi  
done  
  
# --- Post-processing on the official generated index.html ---  
echo "Post-processing index.html..."  
if [ -f "$OUTPUT_ABS_PATH/index.html" ]; then  
  
  # 1) Cross-origin isolation for SharedArrayBuffer/pthreads (world gen).  
  if [ ! -f "$REPO_ROOT/coi-serviceworker.min.js" ]; then  
    echo "ERROR: coi-serviceworker.min.js not found at repo root ($REPO_ROOT)."  
    exit 1  
  fi  
  cp "$REPO_ROOT/coi-serviceworker.min.js" "$OUTPUT_ABS_PATH/"  
  sed -i 's#<head>#<head><script src="coi-serviceworker.min.js"></script>#' "$OUTPUT_ABS_PATH/index.html"  
  
  # 2) Visible error console so exceptions show ON THE PAGE (no DevTools).  
  #    Vendored as a real file to avoid sed-escaping bugs (previous inline  
  #    version emitted a broken \&\& and a literal \n -> SyntaxError).  
  if [ ! -f "$REPO_ROOT/error-overlay.js" ]; then  
    echo "ERROR: error-overlay.js not found at repo root ($REPO_ROOT)."  
    exit 1  
  fi  
  cp "$REPO_ROOT/error-overlay.js" "$OUTPUT_ABS_PATH/"  
  sed -i 's#<head>#<head><script src="error-overlay.js"></script>#' "$OUTPUT_ABS_PATH/index.html"
  
  echo "index.html post-processed (coi + error overlay + probe)"  
else  
  echo "Warning: index.html not found in output"  
fi  
  
echo "Build completed successfully!"  
echo "Web output prepared in: $OUTPUT_ABS_PATH"
