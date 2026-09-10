#!/bin/bash
# Builds "New File Service.app" — a resident background agent that provides
# the "New File" macOS Service. Ad-hoc signed (a plain Services app has no
# FinderSync loading restriction).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
SDK="$(xcrun --sdk macosx --show-sdk-path)"
TARGET="arm64-apple-macos13.0"
APP="$ROOT/build/New File Service.app"

echo "==> Clean"
rm -rf "$ROOT/build"
mkdir -p "$APP/Contents/MacOS"

echo "==> Compile"
swiftc -sdk "$SDK" -target "$TARGET" -O \
	-module-name NewFileService \
	"$ROOT/Sources/main.swift" \
	-framework Cocoa \
	-o "$APP/Contents/MacOS/NewFileService"

echo "==> Info.plist"
cp "$ROOT/Info.plist" "$APP/Contents/Info.plist"

echo "==> Ad-hoc sign"
codesign --force --sign - "$APP"

echo "==> Built: $APP"
