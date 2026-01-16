#!/bin/bash

# HyperWhisper DMG Creation Script
# Creates a distributable DMG file

set -e

APP_NAME="HyperWhisper"
APP_BUNDLE="$APP_NAME.app"
DMG_NAME="$APP_NAME-Installer.dmg"
DMG_TEMP="$APP_NAME-temp.dmg"
VOLUME_NAME="$APP_NAME"
DMG_SIZE="500m"

# Check if app bundle exists
if [ ! -d "$APP_BUNDLE" ]; then
    echo "❌ Error: $APP_BUNDLE not found. Run ./build.sh first."
    exit 1
fi

echo "📀 Creating DMG for $APP_NAME..."

# Clean up any existing DMG
rm -f "$DMG_NAME" "$DMG_TEMP"

# Create temporary DMG
hdiutil create -srcfolder "$APP_BUNDLE" -volname "$VOLUME_NAME" -fs HFS+ \
    -fsargs "-c c=64,a=16,e=16" -format UDRW -size $DMG_SIZE "$DMG_TEMP"

# Mount it
MOUNT_DIR="/Volumes/$VOLUME_NAME"
hdiutil attach "$DMG_TEMP" -mountpoint "$MOUNT_DIR"

# Create Applications symlink
ln -sf /Applications "$MOUNT_DIR/Applications"

# Set background and window properties (optional - requires AppleScript)
echo '
   tell application "Finder"
     tell disk "'$VOLUME_NAME'"
           open
           set current view of container window to icon view
           set toolbar visible of container window to false
           set statusbar visible of container window to false
           set the bounds of container window to {400, 100, 900, 400}
           set theViewOptions to the icon view options of container window
           set arrangement of theViewOptions to not arranged
           set icon size of theViewOptions to 80
           set position of item "'$APP_BUNDLE'" of container window to {120, 150}
           set position of item "Applications" of container window to {380, 150}
           update without registering applications
           delay 2
     end tell
   end tell
' | osascript || echo "Note: Window styling skipped (non-critical)"

# Eject
hdiutil detach "$MOUNT_DIR"

# Convert to compressed DMG
hdiutil convert "$DMG_TEMP" -format UDZO -imagekey zlib-level=9 -o "$DMG_NAME"

# Clean up
rm -f "$DMG_TEMP"

echo ""
echo "✅ DMG created: $DMG_NAME"
echo ""
echo "Share this file to distribute HyperWhisper!"
