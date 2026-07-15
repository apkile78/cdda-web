#!/bin/bash
set -e

RELEASE_TAG="${1:-latest}"
CDDA_REPO="CleverRaven/cataclysm-dda"
SOURCE_DIR="cdda-source"

echo "Fetching CDDA release: $RELEASE_TAG"

# Clean up previous source
if [ -d "$SOURCE_DIR" ]; then
  echo "Removing previous source directory..."
  rm -rf "$SOURCE_DIR"
fi

# Create source directory
mkdir -p "$SOURCE_DIR"
cd "$SOURCE_DIR"

if [ "$RELEASE_TAG" = "latest" ]; then
  echo "Fetching latest stable Ito release..."
  # Get the latest stable Ito tag
  LATEST_TAG=$(git ls-remote --tags https://github.com/${CDDA_REPO}.git | grep -E 'refs/tags/cdda-0\.I-[0-9]{4}-[0-9]{2}-[0-9]{2}$' | sort -V | tail -n1 | sed 's/.*\///')
  echo "Latest stable Ito tag: $LATEST_TAG"
  RELEASE_TAG="$LATEST_TAG"
fi

# Download the release tarball
echo "Downloading $RELEASE_TAG from GitHub..."
wget -O "cataclysm-dda-${RELEASE_TAG}.tar.gz" "https://github.com/${CDDA_REPO}/archive/refs/tags/${RELEASE_TAG}.tar.gz"

# Extract the tarball
echo "Extracting tarball..."
tar -xzf "cataclysm-dda-${RELEASE_TAG}.tar.gz"
mv "cataclysm-dda-${RELEASE_TAG#v}"/* .
rm -rf "cataclysm-dda-${RELEASE_TAG#v}"
rm "cataclysm-dda-${RELEASE_TAG}.tar.gz"

echo "Source fetched successfully to: $SOURCE_DIR"
echo "Release tag: $RELEASE_TAG"
