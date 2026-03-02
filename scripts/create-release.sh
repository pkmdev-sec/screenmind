#!/bin/bash
set -euo pipefail

# ScreenMind — Create a new release
# Usage: ./scripts/create-release.sh <version>
# Example: ./scripts/create-release.sh 2.1.0

VERSION="${1:-}"
if [ -z "$VERSION" ]; then
    echo "Usage: $0 <version>"
    echo "Example: $0 2.1.0"
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
TAG="v$VERSION"

echo "============================================"
echo "  ScreenMind Release v$VERSION"
echo "============================================"
echo ""

# Step 1: Update version in Info.plist
echo "[1/6] Updating version to $VERSION..."
/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $VERSION" "$PROJECT_DIR/Sources/ScreenMindApp/Resources/Info.plist"
echo "  Info.plist updated"

# Step 2: Build
echo "[2/6] Building..."
cd "$PROJECT_DIR"
./scripts/build-dmg.sh

# Step 3: Compute SHA256 for Homebrew
echo "[3/6] Computing checksums..."
SHA256=$(shasum -a 256 "$PROJECT_DIR/.build/ScreenMind.dmg" | awk '{print $1}')
echo "  SHA256: $SHA256"

# Update Homebrew formula
if [ -f "$PROJECT_DIR/homebrew/screenmind.rb" ]; then
    sed -i '' "s/PLACEHOLDER_SHA256/$SHA256/" "$PROJECT_DIR/homebrew/screenmind.rb"
    sed -i '' "s/version \".*\"/version \"$VERSION\"/" "$PROJECT_DIR/homebrew/screenmind.rb"
    echo "  Homebrew formula updated"
fi

# Step 4: Git commit + tag
echo "[4/6] Committing..."
cd "$PROJECT_DIR"
git add -A
git commit -m "Release v$VERSION" || true
git tag -a "$TAG" -m "ScreenMind v$VERSION"
echo "  Tagged: $TAG"

# Step 5: Push
echo "[5/6] Pushing..."
git push origin main --tags

# Step 6: Create GitHub Release
echo "[6/6] Creating GitHub release..."
gh release create "$TAG" \
    "$PROJECT_DIR/.build/ScreenMind.dmg" \
    "$PROJECT_DIR/.build/release/screenmind-cli" \
    --title "ScreenMind $TAG" \
    --generate-notes

echo ""
echo "============================================"
echo "  Release v$VERSION Complete!"
echo "============================================"
echo ""
echo "  GitHub: https://github.com/pkmdev-sec/screenmind/releases/tag/$TAG"
echo "  DMG:    .build/ScreenMind.dmg"
echo "  SHA256: $SHA256"
echo ""
echo "  Homebrew: brew tap pkmdev-sec/screenmind && brew install screenmind"
echo "============================================"
