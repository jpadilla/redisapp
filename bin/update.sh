#!/bin/bash

CURR_DIR=$(pwd)

if [ "$1" == "--force" ]; then
  FORCE=true
fi

echo "--> Getting version numbers"

CURR_VERSION=$(curl -s https://jpadilla.github.io/redisapp/ | grep -o '<div class="current-version">v.*' | grep -o '[0-9]*\.[0-9]*\.[0-9]*-build\.[0-9]*')

CURR_REDIS=$(echo $CURR_VERSION | grep -o '^[0-9]*\.[0-9]*\.[0-9]*')
CURR_BUILD=$(echo $CURR_VERSION | grep -o '[0-9]*$')

echo " -- Current Redis.app version: $CURR_VERSION"

# Get redis latest stable release version
VERSION=$(curl -s http://download.redis.io/redis-stable/00-RELEASENOTES | grep -o 'Redis .* Released' | head -n 1 | grep -o '[0-9]*\.[0-9]*\.[0-9]*')
echo "--> Current redis version: $VERSION"

if [ "$FORCE" != true ] && [ "$CURR_REDIS" == "$VERSION" ]; then
  echo " -- No need to update :)"
  echo "==> Done!"
  exit 0
fi

# Create download url
DOWNLOAD_URL="http://download.redis.io/releases/redis-$VERSION.tar.gz"

# Download latest stable release version
echo "--> Downloading: $DOWNLOAD_URL"
curl -o /tmp/redis.tar.gz "$DOWNLOAD_URL"

# Clean old redis dir
VENDOR_DIR="$(pwd)/app/vendor/redis"

echo "--> Cleaning directory $VENDOR_DIR"
rm -rf "$VENDOR_DIR"

# Create dir
echo "--> Creating directory $VENDOR_DIR"
mkdir -p "$VENDOR_DIR"

# Extract
echo "--> Unzipping..."
tar xvzf /tmp/redis.tar.gz -C /tmp

# Compile
echo "--> Compiling..."
cd /tmp/redis-*/
make install PREFIX="../"
cd "$CURR_DIR"

# move files
echo "--> Moving files to $VENDOR_DIR"
mv /tmp/redis-*/* "$VENDOR_DIR"

# cleanup
echo "--> Removing /tmp/redis.tar.gz"
rm /tmp/redis.tar.gz

echo "--> Removing /tmp/redis-*"
rm -r /tmp/redis-*

echo "--> Download completed!"

echo '--> Building'
# Use sequential build numbers
if [ "$FORCE" ]; then
  NEW_BUILD=$((CURR_BUILD + 1))
else
  NEW_BUILD=1
fi

RELEASE_VERSION="${VERSION}-build.${NEW_BUILD}"

echo " -- Update package.json version ${RELEASE_VERSION}"
jq ".version = \"$RELEASE_VERSION\"" < "$CURR_DIR/app/package.json" > "$CURR_DIR/app/package.json.latest"
mv "$CURR_DIR/app/package.json.latest" "$CURR_DIR/app/package.json"

echo " -- Build with defaults"
yarn build

echo " -- Build completed!"
