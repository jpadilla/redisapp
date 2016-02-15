#!/usr/bin/env bash

# =========================== NEW VERSION INFO =================================
# Get redis latest stable release version
VERSION=$(curl -s http://download.redis.io/redis-stable/00-RELEASENOTES | grep -o '\-\-\[ Redis .* ]' | head -n 1 | grep -o '[0-9]*\.[0-9]*\.[0-9]*')
echo "--> Current redis version: $VERSION"

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
(cd /tmp/redis-*/; make install PREFIX="../")

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
BUILD_VERSION="${VERSION}-build.$(date +%s)"

echo "--> Update Info.plist version ${BUILD_VERSION}"
/usr/libexec/PlistBuddy -c "Set :CFBundleVersion ${BUILD_VERSION}" Redis/Info.plist
/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString ${BUILD_VERSION}" Redis/Info.plist

echo "--> Clean build folder"
rm -rf build/

echo "--> Build with defaults"
xcodebuild

echo "--> Build completed!"


# =========================== RELEASE ==========================================
echo "--> Zip"
cd build/Release
zip -r -y ~/Desktop/Redis.zip Redis.app
cd ../../

# Get zip file size
FILE_SIZE=$(du ~/Desktop/Redis.zip | cut -f1)

echo "--> Create AppCast post"
rm -r ./_posts/release
mkdir -p ./_posts/release/

echo "---
version: $BUILD_VERSION
redis_version: $VERSION
package_url: https://github.com/jpadilla/redisapp/releases/download/$BUILD_VERSION/Redis.zip
package_length: $FILE_SIZE
category: release
---

- Updates redis to $VERSION
" > ./_posts/release/$(date +"%Y-%m-%d")-${BUILD_VERSION}.md


# =========================== PUBLISH ==========================================
echo ""
echo "================== Next steps =================="
echo ""
echo "git commit -am $BUILD_VERSION"
echo "git tag $BUILD_VERSION"
echo "git push origin --tags"
echo ""
echo "Upload the zip file to GitHub"
echo "https://github.com/jpadilla/redisapp/releases/tag/$BUILD_VERSION"
echo ""
echo "git co gh-pages"
echo "git add ."
echo "git commit -am 'Release $BUILD_VERSION'"
echo "git push origin gh-pages"
echo ""
echo "==> Done!"
