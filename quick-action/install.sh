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

# Enable it in the Finder context menu automatically, so there's no manual
# "System Settings -> Extensions -> Finder" toggle. This writes the same
# enable flags that toggle would, into the pbs services database.
KEY="(null) - New File - runWorkflowAsService"
ENABLED_JSON='{"enabled_context_menu":1,"enabled_services_menu":1,"presentation_modes":{"ContextMenu":1,"ServicesMenu":1,"FinderPreview":1}}'
pbs_tmp="$(mktemp)"
if defaults export pbs "$pbs_tmp" 2>/dev/null; then
	# ensure the container dict exists (never wipes existing entries)
	plutil -extract NSServicesStatus xml1 -o /dev/null "$pbs_tmp" 2>/dev/null \
		|| plutil -replace NSServicesStatus -json '{}' "$pbs_tmp" 2>/dev/null || true
	if plutil -replace "NSServicesStatus.${KEY}" -json "$ENABLED_JSON" "$pbs_tmp" 2>/dev/null; then
		defaults import pbs "$pbs_tmp" 2>/dev/null || true
	fi
fi
rm -f "$pbs_tmp"
/System/Library/CoreServices/pbs -flush 2>/dev/null || true
/System/Library/CoreServices/pbs -update 2>/dev/null || true

killall Finder 2>/dev/null || true

echo "Done. Right-click a folder in Finder -> Quick Actions -> New File."
echo "(If it doesn't appear, enable \"New File\" in System Settings -> Extensions -> Finder.)"
