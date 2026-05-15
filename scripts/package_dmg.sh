#!/usr/bin/env bash
set -euo pipefail

VERSION="${1:-0.1.0}"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_ROOT="$ROOT_DIR/build/release"
APP_DISPLAY_NAME="MacBook Accordion"
APP_NAME="$APP_DISPLAY_NAME.app"
EXEC_NAME="MacBookAccordion"
APP_PATH="$BUILD_ROOT/$APP_NAME"
EXEC_PATH="$APP_PATH/Contents/MacOS/$EXEC_NAME"
RESOURCES_DIR="$APP_PATH/Contents/Resources"
PLIST_PATH="$APP_PATH/Contents/Info.plist"
DMG_ROOT="$BUILD_ROOT/dmg-root"
DIST_DIR="$ROOT_DIR/dist"
DMG_PATH="$DIST_DIR/MacBookAccordion-$VERSION.dmg"

set_string() {
  local key="$1"
  local value="$2"
  /usr/libexec/PlistBuddy -c "Set :$key $value" "$PLIST_PATH" 2>/dev/null \
    || /usr/libexec/PlistBuddy -c "Add :$key string $value" "$PLIST_PATH"
}

set_bool() {
  local key="$1"
  local value="$2"
  /usr/libexec/PlistBuddy -c "Set :$key $value" "$PLIST_PATH" 2>/dev/null \
    || /usr/libexec/PlistBuddy -c "Add :$key bool $value" "$PLIST_PATH"
}

rm -rf "$BUILD_ROOT"
mkdir -p "$APP_PATH/Contents/MacOS" "$RESOURCES_DIR" "$DIST_DIR"

SOURCES=()
while IFS= read -r source_file; do
  SOURCES+=("$source_file")
done < <(find "$ROOT_DIR/MacBookAccordion" -name '*.swift' -print | sort)

for arch in arm64 x86_64; do
  swiftc \
    -swift-version 6 \
    -default-isolation MainActor \
    -O \
    -target "$arch-apple-macosx14.0" \
    "${SOURCES[@]}" \
    -o "$BUILD_ROOT/$EXEC_NAME-$arch"
done

lipo -create \
  "$BUILD_ROOT/$EXEC_NAME-arm64" \
  "$BUILD_ROOT/$EXEC_NAME-x86_64" \
  -output "$EXEC_PATH"

cp "$ROOT_DIR/MacBookAccordion/Info.plist" "$PLIST_PATH"
set_string CFBundleExecutable "$EXEC_NAME"
set_string CFBundleIdentifier "com.minwoo19930301.MacBookAccordion"
set_string CFBundleName "$APP_DISPLAY_NAME"
set_string CFBundleDisplayName "$APP_DISPLAY_NAME"
set_string CFBundlePackageType "APPL"
set_string CFBundleShortVersionString "$VERSION"
set_string CFBundleVersion "$VERSION"
set_string LSMinimumSystemVersion "14.0"
set_bool NSHighResolutionCapable true

codesign --force --deep --sign - "$APP_PATH"

rm -rf "$DMG_ROOT"
mkdir -p "$DMG_ROOT"
ditto "$APP_PATH" "$DMG_ROOT/$APP_NAME"
ln -s /Applications "$DMG_ROOT/Applications"

rm -f "$DMG_PATH"
hdiutil create \
  -volname "$APP_DISPLAY_NAME" \
  -srcfolder "$DMG_ROOT" \
  -ov \
  -format UDZO \
  "$DMG_PATH"

echo "$DMG_PATH"
