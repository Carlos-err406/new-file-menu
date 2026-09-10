#!/bin/bash
# Builds, installs, and enables the FinderSync extension for local testing.
# NOTE: on macOS 26 an ad-hoc-signed extension registers but Finder won't
# reliably load its menu (it gets miscategorized as "File Provider").
# You must also enable it in System Settings > General > Login Items &
# Extensions > (By Category) Finder > New File. See ../README.md.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")" && pwd)"
DEST="/Applications/New File Menu.app"
EXTID="dev.carlos.newfilemenu.fsext"

bash "$ROOT/build.sh"

echo "==> Reinstall to /Applications"
rm -rf "$DEST"
cp -R "$ROOT/build/New File Menu.app" "$DEST"

echo "==> Re-register + enable"
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f "$DEST"
pluginkit -a "$DEST/Contents/PlugIns/NewFileExtension.appex" 2>/dev/null || true
pluginkit -e use -i "$EXTID" 2>/dev/null || true

echo "==> Restart Finder"
killall Finder 2>/dev/null || true
sleep 1
echo "==> Status:"
pluginkit -m -v -i "$EXTID"
