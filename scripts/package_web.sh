#!/bin/bash
set -e

OUTPUT_DIR="web-output"
DEPLOY_DIR="deploy"

echo "Packaging web build for GitHub Pages deployment..."

# Clean previous deployment directory
if [ -d "$DEPLOY_DIR" ]; then
  echo "Cleaning previous deployment directory..."
  rm -rf "$DEPLOY_DIR"
fi

# Create deployment directory
mkdir -p "$DEPLOY_DIR"

# Copy all web output files
echo "Copying web output files..."
if [ -d "$OUTPUT_DIR" ]; then
  cp -r "$OUTPUT_DIR"/* "$DEPLOY_DIR/"
else
  echo "Error: web-output directory not found!"
  exit 1
fi

# Use custom index.html if it exists in the root
if [ -f "index.html" ]; then
  echo "Using custom index.html launcher..."
  cp index.html "$DEPLOY_DIR/"
  # Remove the auto-generated HTML file if it exists
  rm -f "$DEPLOY_DIR/cataclysm-tiles.html"
fi

# Create a nojekyll file to prevent GitHub Pages from processing
touch "$DEPLOY_DIR/.nojekyll"

# Create a simple README for the deployment
cat > "$DEPLOY_DIR/README.md" << 'EOF'
# CDDA WebAssembly Build

This is the WebAssembly build of Cataclysm: Dark Days Ahead, deployed via GitHub Actions.

## How to Play

Simply open index.html in a modern web browser that supports WebAssembly.

## Controls

The game supports keyboard and mouse controls similar to the desktop version.

## Build Information

Built automatically via GitHub Actions from the CleverRaven/cataclysm-dda repository.
EOF

# Generate build info file
if [ -f "BUILD_VERSION" ]; then
  cp BUILD_VERSION "$DEPLOY_DIR/"
fi

# Create a manifest file with build information
cat > "$DEPLOY_DIR/BUILD_INFO.json" << EOF
{
  "build_date": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "build_type": "${BUILD_TYPE:-Release}",
  "tiles": "${BUILD_TILES:-true}",
  "sound": "${BUILD_SOUND:-true}",
  "localization": "${BUILD_LOCALIZATION:-false}",
  "emscripten_version": "${EMSCRIPTEN_VERSION:-3.1.58}"
}
EOF

# Verify critical files exist
echo "Verifying critical files..."
CRITICAL_FILES=("index.html" "cataclysm-tiles.js" "cataclysm-tiles.wasm")
for file in "${CRITICAL_FILES[@]}"; do
  if [ ! -f "$DEPLOY_DIR/$file" ]; then
    echo "Warning: Critical file $file not found in deployment directory"
  fi
done

# Additional check for data directory
if [ ! -d "$DEPLOY_DIR/data" ]; then
  echo "Warning: data directory not found in deployment directory"
fi

# Display directory structure
echo "Deployment directory structure:"
ls -la "$DEPLOY_DIR/"

echo "Packaging completed successfully!"
echo "Deployment directory: $DEPLOY_DIR"
echo "Files ready for GitHub Pages deployment"
