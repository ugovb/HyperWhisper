#!/bin/bash
set -e

APP_NAME="HyperWhisper"
BUNDLE_ID="com.hyperwhisper.app"
BUILD_DIR=".build/debug"
# using debug build for faster iteration, change to release if needed
# swift build -c release -> .build/release
APP_BUNDLE="${APP_NAME}.app"

echo "🔨 Building..."
swift build

echo "📦 Creating app bundle..."
rm -rf "${APP_BUNDLE}"
mkdir -p "${APP_BUNDLE}/Contents/MacOS"
mkdir -p "${APP_BUNDLE}/Contents/Resources"

# Copy executable
cp "${BUILD_DIR}/${APP_NAME}" "${APP_BUNDLE}/Contents/MacOS/"

# Create Info.plist (Merging logical content from source Info.plist if possible, but here we generate a clean one as per instructions)
cat > "${APP_BUNDLE}/Contents/Info.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>${APP_NAME}</string>
    <key>CFBundleIdentifier</key>
    <string>${BUNDLE_ID}</string>
    <key>CFBundleName</key>
    <string>${APP_NAME}</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>15.0</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSMicrophoneUsageDescription</key>
    <string>HyperWhisper needs microphone access to transcribe your voice.</string>
    <key>NSAccessibilityUsageDescription</key>
    <string>HyperWhisper needs accessibility access to insert text into other applications.</string>
    <key>NSAppleEventsUsageDescription</key>
    <string>HyperWhisper needs to control other applications to paste text directly.</string>
</dict>
</plist>
EOF

echo "🔐 Signing with entitlements..."
# Use ad-hoc signing with entitlements
codesign --force --deep --sign - \
    --entitlements Entitlements.plist \
    --options runtime \
    "${APP_BUNDLE}"

echo "✅ Verifying signature..."
codesign --verify --verbose "${APP_BUNDLE}"
codesign -d --entitlements - "${APP_BUNDLE}"

echo ""
echo "🎉 Build complete: ${APP_BUNDLE}"
echo ""
echo "To run and test permissions, use:"
echo "open ${APP_BUNDLE}"
