#!/bin/bash
set -euo pipefail

# ScreenMind — Build .app bundle and create DMG installer
# Usage: ./scripts/build-dmg.sh

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
BUILD_DIR="$PROJECT_DIR/.build"
APP_NAME="ScreenMind"
APP_BUNDLE="$BUILD_DIR/$APP_NAME.app"
DMG_DIR="$BUILD_DIR/dmg"
DMG_OUTPUT="$BUILD_DIR/$APP_NAME.dmg"
BUNDLE_ID="com.screenmind.app"

echo "============================================"
echo "  ScreenMind — Build & Package"
echo "============================================"
echo ""

# Step 1: Build in release mode
echo "[1/6] Building $APP_NAME in release mode..."
cd "$PROJECT_DIR"
swift build -c release 2>&1
EXECUTABLE="$BUILD_DIR/release/$APP_NAME"

if [ ! -f "$EXECUTABLE" ]; then
    # SPM may name the executable after the product name
    EXECUTABLE="$(find "$BUILD_DIR/release" -name "$APP_NAME" -type f -perm +111 | head -1)"
fi

if [ ! -f "$EXECUTABLE" ]; then
    echo "ERROR: Could not find built executable"
    exit 1
fi

echo "  Built: $EXECUTABLE"
echo ""

# Step 2: Create .app bundle structure
echo "[2/6] Creating $APP_NAME.app bundle..."
rm -rf "$APP_BUNDLE"
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"

# Copy executable
cp "$EXECUTABLE" "$APP_BUNDLE/Contents/MacOS/$APP_NAME"

# Copy Info.plist
cp "$PROJECT_DIR/Sources/ScreenMindApp/Resources/Info.plist" "$APP_BUNDLE/Contents/Info.plist"

# Create PkgInfo
echo -n "APPL????" > "$APP_BUNDLE/Contents/PkgInfo"

echo "  Bundle: $APP_BUNDLE"
echo ""

# Step 3: Create app icon (using iconutil if .iconset exists, otherwise skip)
echo "[3/6] Setting up app icon..."
ICONSET_DIR="$PROJECT_DIR/Sources/ScreenMindApp/Resources/AppIcon.iconset"
if [ -d "$ICONSET_DIR" ]; then
    iconutil -c icns "$ICONSET_DIR" -o "$APP_BUNDLE/Contents/Resources/AppIcon.icns"
    # Add icon reference to Info.plist
    /usr/libexec/PlistBuddy -c "Add :CFBundleIconFile string AppIcon" "$APP_BUNDLE/Contents/Info.plist" 2>/dev/null || \
    /usr/libexec/PlistBuddy -c "Set :CFBundleIconFile AppIcon" "$APP_BUNDLE/Contents/Info.plist"
    echo "  Icon: AppIcon.icns created"
else
    echo "  Skipped (no .iconset found — using default icon)"
fi
echo ""

# Step 4: Ad-hoc code signing
echo "[4/6] Code signing (ad-hoc)..."
codesign --force --deep --sign - \
    --entitlements "$PROJECT_DIR/ScreenMind.entitlements" \
    "$APP_BUNDLE" 2>&1
echo "  Signed: ad-hoc"

# Verify
codesign --verify --verbose "$APP_BUNDLE" 2>&1 || echo "  Warning: verification returned non-zero (expected for ad-hoc)"
echo ""

# Step 5: Create DMG
echo "[5/6] Creating DMG installer..."
rm -rf "$DMG_DIR"
rm -f "$DMG_OUTPUT"
mkdir -p "$DMG_DIR"

# Copy .app to DMG staging
cp -R "$APP_BUNDLE" "$DMG_DIR/"

# Create symbolic link to /Applications for drag-to-install
ln -s /Applications "$DMG_DIR/Applications"

# Create DMG
hdiutil create -volname "$APP_NAME" \
    -srcfolder "$DMG_DIR" \
    -ov -format UDZO \
    "$DMG_OUTPUT" 2>&1

echo "  DMG: $DMG_OUTPUT"
echo ""

# Step 6: Cleanup staging
echo "[6/6] Cleanup..."
rm -rf "$DMG_DIR"
echo "  Done"
echo ""

# Summary
echo "============================================"
echo "  Build Complete!"
echo "============================================"
echo ""
echo "  App Bundle: $APP_BUNDLE"
echo "  DMG:        $DMG_OUTPUT"
echo ""
echo "  To install:"
echo "    1. Open $DMG_OUTPUT"
echo "    2. Drag ScreenMind to Applications"
echo "    3. Launch from Applications or Spotlight"
echo ""
echo "  To run directly:"
echo "    open \"$APP_BUNDLE\""
echo "============================================"
