#!/bin/bash
# Removes the New File Service agent, its LaunchAgent, and the app.
set -euo pipefail

LABEL="dev.carlos.newfileservice"
AGENT="$HOME/Library/LaunchAgents/$LABEL.plist"

launchctl bootout "gui/$(id -u)/$LABEL" 2>/dev/null || true
pkill -f "New File Service.app/Contents/MacOS/NewFileService" 2>/dev/null || true
rm -f "$AGENT"
rm -rf "$HOME/Applications/New File Service.app"
/System/Library/CoreServices/pbs -flush 2>/dev/null || true
/System/Library/CoreServices/pbs -update 2>/dev/null || true
killall Finder 2>/dev/null || true
echo "Removed New File Service."
