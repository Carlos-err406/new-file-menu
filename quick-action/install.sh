#!/bin/bash
# Installs the "New File" Quick Action into ~/Library/Services.
# After install: right-click a folder in Finder -> Quick Actions -> New File.
#
# Run from a local checkout:   ./quick-action/install.sh
# Or straight from GitHub:
#   curl -fsSL https://raw.githubusercontent.com/Carlos-err406/new-file-menu/main/quick-action/install.sh | bash
set -euo pipefail

TARBALL="https://github.com/Carlos-err406/new-file-menu/archive/refs/heads/main.tar.gz"
DEST="$HOME/Library/Services/New File.workflow"

# Find a local copy if we're running from a checkout (not via curl | bash).
SRC_DIR=""
if [ -n "${BASH_SOURCE:-}" ]; then
	SRC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd || true)"
fi

echo "Installing New File Quick Action..."
rm -rf "$DEST"

if [ -n "$SRC_DIR" ] && [ -d "$SRC_DIR/New File.workflow" ]; then
	echo "  (from local checkout)"
	cp -R "$SRC_DIR/New File.workflow" "$DEST"
else
	echo "  (downloading from GitHub)"
	tmp="$(mktemp -d)"
	trap 'rm -rf "$tmp"' EXIT
	curl -fsSL "$TARBALL" | tar xz -C "$tmp"
	cp -R "$tmp"/new-file-menu-*/quick-action/"New File.workflow" "$DEST"
fi

# Register the service so it appears in the contextual menu.
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f "$DEST" 2>/dev/null || true
/System/Library/CoreServices/pbs -flush 2>/dev/null || true
/System/Library/CoreServices/pbs -update 2>/dev/null || true
killall Finder 2>/dev/null || true

echo "Done. Right-click a folder in Finder -> Quick Actions -> New File."
