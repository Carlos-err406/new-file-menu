#!/bin/bash
# Installs the "New File" Quick Action into ~/Library/Services.
# After install: right-click a folder in Finder -> Quick Actions -> New File.
set -euo pipefail

SRC_DIR="$(cd "$(dirname "$0")" && pwd)"
DEST="$HOME/Library/Services/New File.workflow"

echo "Installing New File Quick Action..."
rm -rf "$DEST"
cp -R "$SRC_DIR/New File.workflow" "$DEST"

# Register the service so it appears in the contextual menu.
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f "$DEST" 2>/dev/null || true
/System/Library/CoreServices/pbs -flush 2>/dev/null || true
/System/Library/CoreServices/pbs -update 2>/dev/null || true
killall Finder 2>/dev/null || true

echo "Done. Right-click a folder in Finder -> Quick Actions -> New File."
