#!/bin/bash
set -e

# Configuration
APP_NAME="AlfredMini"
SCHEME="AlfredMini"
BUILD_DIR="build"
DMG_NAME="${APP_NAME}.dmg"
BUNDLE_ID="com.alfredmini.app"
# Stable local code-signing identity. Signing every build with the same
# self-signed cert keeps macOS Accessibility permission across rebuilds, so the
# user only grants it once. Create it with: scripts/create_signing_cert.sh
SIGN_ID="AlfredMini Local Signing"

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

# 3b. Re-sign with the stable local identity (falls back to ad-hoc if missing)
APP_PATH="${BUILD_DIR}/Export/${APP_NAME}.app"
if security find-identity -p codesigning | grep -q "${SIGN_ID}"; then
  echo "🔏 Signing with '${SIGN_ID}' (stable identity → Accessibility persists)..."
  codesign --force --deep --sign "${SIGN_ID}" --identifier "${BUNDLE_ID}" "${APP_PATH}"
  codesign --verify --deep --strict "${APP_PATH}" && echo "✅ Signature verified."
else
  echo "⚠️  Signing identity '${SIGN_ID}' not found; keeping ad-hoc signature."
  echo "    Accessibility will reset every rebuild. Run scripts/create_signing_cert.sh once to fix."
fi

# 4. Create DMG
echo "💿 Creating DMG..."
rm -f "${DMG_NAME}"
hdiutil create -volname "${APP_NAME}" -srcfolder "${BUILD_DIR}/Export/${APP_NAME}.app" -ov -format UDZO "${DMG_NAME}"

echo "✅ Done! DMG is at: $(pwd)/${DMG_NAME}"

