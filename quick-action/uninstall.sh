#!/bin/bash
# Removes the "New File" Quick Action.
set -euo pipefail

DEST="$HOME/Library/Services/New File.workflow"
rm -rf "$DEST"
/System/Library/CoreServices/pbs -flush 2>/dev/null || true
/System/Library/CoreServices/pbs -update 2>/dev/null || true
killall Finder 2>/dev/null || true
echo "Removed New File Quick Action."
