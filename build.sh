#!/bin/bash

# HyperWhisper Build Script
# Creates a proper .app bundle with icon

set -e

APP_NAME="HyperWhisper"
BUILD_DIR=".build/release"
APP_BUNDLE="$APP_NAME.app"
CONTENTS_DIR="$APP_BUNDLE/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"

echo "🔨 Building HyperWhisper (Release)..."
swift build -c release

echo "📦 Creating app bundle..."

# Create bundle structure
rm -rf "$APP_BUNDLE"
mkdir -p "$MACOS_DIR"
mkdir -p "$RESOURCES_DIR"

# Copy executable
cp "$BUILD_DIR/$APP_NAME" "$MACOS_DIR/"

# Copy Info.plist
cp "Sources/HyperWhisper/Info.plist" "$CONTENTS_DIR/"

# Copy icon
cp "Sources/HyperWhisper/Resources/AppIcon.icns" "$RESOURCES_DIR/"

# Create PkgInfo
echo -n "APPL????" > "$CONTENTS_DIR/PkgInfo"

echo "✅ App bundle created: $APP_BUNDLE"
echo ""
echo "To run: open $APP_BUNDLE"
echo "To install: cp -R $APP_BUNDLE /Applications/"
