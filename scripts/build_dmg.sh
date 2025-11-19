#!/bin/bash
set -e

# Configuration
APP_NAME="AlfredMini"
SCHEME="AlfredMini"
BUILD_DIR="build"
DMG_NAME="${APP_NAME}.dmg"

echo "🚀 Starting build for ${APP_NAME}..."

# 1. Regenerate project to ensure latest settings
echo "🛠  Generating Xcode project..."
xcodegen generate

# 2. Clean and Archive
echo "📦 Archiving..."
xcodebuild archive \
  -project "${APP_NAME}.xcodeproj" \
  -scheme "${SCHEME}" \
  -configuration Release \
  -archivePath "${BUILD_DIR}/${APP_NAME}.xcarchive" \
  CODE_SIGN_IDENTITY="-" \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGN_ALLOW_ENTITLEMENTS_MODIFICATION=YES \
  -quiet

# 3. Export .app
echo "📂 Exporting .app..."
xcodebuild -exportArchive \
  -archivePath "${BUILD_DIR}/${APP_NAME}.xcarchive" \
  -exportOptionsPlist "scripts/exportOptions.plist" \
  -exportPath "${BUILD_DIR}/Export" \
  -quiet

# 4. Create DMG
echo "💿 Creating DMG..."
rm -f "${DMG_NAME}"
hdiutil create -volname "${APP_NAME}" -srcfolder "${BUILD_DIR}/Export/${APP_NAME}.app" -ov -format UDZO "${DMG_NAME}"

echo "✅ Done! DMG is at: $(pwd)/${DMG_NAME}"

