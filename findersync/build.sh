#!/bin/bash
# Builds the (experimental) FinderSync extension host app + appex, ad-hoc signed.
# NOTE: ad-hoc signing does NOT reliably load on macOS 26 — see ../README.md.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
SDK="$(xcrun --sdk macosx --show-sdk-path)"
TARGET="arm64-apple-macos13.0"

APP="$ROOT/build/New File Menu.app"
APPEX="$APP/Contents/PlugIns/NewFileExtension.appex"

echo "==> Clean"
rm -rf "$ROOT/build"
mkdir -p "$APP/Contents/MacOS"
mkdir -p "$APPEX/Contents/MacOS"

echo "==> Compile host app"
swiftc -sdk "$SDK" -target "$TARGET" \
    -module-name NewFileMenuHost \
    "$ROOT/Sources/HostMain.swift" \
    -framework Cocoa \
    -o "$APP/Contents/MacOS/NewFileMenu"

echo "==> Compile FinderSync extension"
swiftc -sdk "$SDK" -target "$TARGET" \
    -module-name NewFileExt \
    -application-extension \
    "$ROOT/Sources/FinderSyncExt.swift" \
    -framework Cocoa -framework FinderSync \
    -o "$APPEX/Contents/MacOS/NewFileExtension"

echo "==> Install Info.plists"
cp "$ROOT/host-Info.plist" "$APP/Contents/Info.plist"
cp "$ROOT/ext-Info.plist"  "$APPEX/Contents/Info.plist"

echo "==> Code sign (ad-hoc)"
# Sign the extension first (inner), then the app (outer).
codesign --force --sign - --entitlements "$ROOT/ext.entitlements" "$APPEX"
codesign --force --sign - "$APP"

echo "==> Verify"
codesign -dv --entitlements - "$APPEX" 2>&1 | sed -n '1,4p' || true
echo "==> Built: $APP"
