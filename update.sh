#!/usr/bin/env bash

CURR_DIR=$(pwd)

# =========================== CHECK FORCE FLAG =================================
if [ "$1" == "--force" ]; then
  FORCE=true
fi

# =========================== CURRENT VERSION INFO =============================
echo "--> Getting version numbers"

CURR_VERSION=$(curl -s https://jpadilla.github.io/redisapp/ | grep -o '<div class="current-version">v.*' | grep -o '[0-9]*\.[0-9]*\.[0-9]*-build\.[0-9]*')

CURR_REDIS=$(echo $CURR_VERSION | grep -o '^[0-9]*\.[0-9]*\.[0-9]*')
CURR_BUILD=$(echo $CURR_VERSION | grep -o '[0-9]*$')

echo " -- Current Redis.app version: $CURR_BUILD"

# =========================== LATEST VERSION INFO ==============================
# Get redis latest stable release version
VERSION=$(curl -s http://download.redis.io/redis-stable/00-RELEASENOTES | grep -o '\-\-\[ Redis .* ]' | head -n 1 | grep -o '[0-9]*\.[0-9]*\.[0-9]*')
echo "--> Current redis version: $VERSION"

# =========================== COMPARE VERSIONS =================================
if [ "$FORCE" != true ] && [ "$CURR_REDIS" == "$VERSION" ]; then
  echo " -- No need to update :)"
  echo "==> Done!"
  exit 0
fi

# =========================== DOWNLOAD =========================================
# Create download url
DOWNLOAD_URL="http://download.redis.io/releases/redis-$VERSION.tar.gz"

# Download latest stable release version
echo "--> Downloading: $DOWNLOAD_URL"
curl -o /tmp/redis.tar.gz $DOWNLOAD_URL

# Clean old redis dir
VENDOR_DIR="$(pwd)/Vendor/redis"

echo "--> Cleaning directory $VENDOR_DIR"
rm -rf $VENDOR_DIR

# Create dir
echo "--> Creating directory $VENDOR_DIR"
mkdir -p $VENDOR_DIR

# Extract
echo "--> Unzipping..."
tar xvzf /tmp/redis.tar.gz -C /tmp

# Compile
echo "--> Compiling..."
cd /tmp/redis-*/
make install PREFIX="../"
cd $CURR_DIR

# move files
echo "--> Moving files to $VENDOR_DIR"
mv /tmp/redis-*/* $VENDOR_DIR

# cleanup
echo "--> Removing /tmp/redis.tar.gz"
rm /tmp/redis.tar.gz

echo "--> Removing /tmp/redis-*"
rm -r /tmp/redis-*

echo "--> Download completed!"


# =========================== BUILD ============================================
echo '--> Building'
# Use sequential build numbers
if [ "$FORCE" ]; then
  NEW_BUILD=$((CURR_BUILD + 1))
else
  NEW_BUILD=1
fi

export RELEASE_VERSION="${VERSION}-build.${NEW_BUILD}"

echo " -- Update Info.plist version ${RELEASE_VERSION}"
/usr/libexec/PlistBuddy -c "Set :CFBundleVersion ${RELEASE_VERSION}" Redis/Info.plist
/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString ${RELEASE_VERSION}" Redis/Info.plist

echo " -- Clean build folder"
rm -rf build/

echo " -- Build with defaults"
xcodebuild

echo " -- Build completed!"

# =========================== RELEASE ==========================================
echo '--> Release'
echo " -- Zip"
cd build/Release
zip -r -y "$CURR_DIR/Redis.zip" Redis.app
cd ../../

# Get zip file size
FILE_SIZE=$(du "$CURR_DIR/Redis.zip" | cut -f1)

echo " -- Create AppCast post"
rm -rf ./_posts/release
mkdir -p ./_posts/release/

echo "---
version: $RELEASE_VERSION
redis_version: $VERSION
package_url: https://github.com/jpadilla/redisapp/releases/download/$RELEASE_VERSION/Redis.zip
package_length: $FILE_SIZE
category: release
---
- Updates redis to $VERSION
" > ./_posts/release/$(date +"%Y-%m-%d")-${RELEASE_VERSION}.md

# =========================== PUBLISH ==========================================
echo ""
echo "================== Next steps =================="
echo ""
echo "git commit -am $RELEASE_VERSION"
echo "git tag $RELEASE_VERSION"
echo "git push origin --tags"
echo ""
echo "Upload the zip file to GitHub"
echo "https://github.com/jpadilla/redisapp/releases/tag/$RELEASE_VERSION"
echo ""
echo "git co gh-pages"
echo "git add ."
echo "git commit -am 'Release $RELEASE_VERSION'"
echo "git push origin gh-pages"
echo ""
echo "==> Done!"
