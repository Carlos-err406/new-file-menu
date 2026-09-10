#!/bin/bash
# Builds + installs the "New File Service" background agent and keeps it
# resident via a LaunchAgent, so the "New File" Quick Action responds
# instantly (no per-click process launch).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
APP_SRC="$ROOT/build/New File Service.app"
APP_DEST="$HOME/Applications/New File Service.app"
LABEL="dev.carlos.newfileservice"
AGENT="$HOME/Library/LaunchAgents/$LABEL.plist"
UID_NUM="$(id -u)"

# Build if we don't already have a built app (e.g. running from a checkout).
if [ ! -d "$APP_SRC" ]; then
	bash "$ROOT/build.sh"
fi

echo "==> Stopping any running instance"
launchctl bootout "gui/$UID_NUM/$LABEL" 2>/dev/null || true
pkill -f "New File Service.app/Contents/MacOS/NewFileService" 2>/dev/null || true

echo "==> Installing app to ~/Applications"
mkdir -p "$HOME/Applications"
rm -rf "$APP_DEST"
cp -R "$APP_SRC" "$APP_DEST"

echo "==> Installing LaunchAgent (keeps it resident)"
mkdir -p "$HOME/Library/LaunchAgents"
cat > "$AGENT" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>Label</key>
	<string>$LABEL</string>
	<key>ProgramArguments</key>
	<array>
		<string>$APP_DEST/Contents/MacOS/NewFileService</string>
	</array>
	<key>RunAtLoad</key>
	<true/>
	<key>KeepAlive</key>
	<true/>
</dict>
</plist>
PLIST

echo "==> Registering Service + starting agent"
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f "$APP_DEST" 2>/dev/null || true
launchctl bootstrap "gui/$UID_NUM" "$AGENT" 2>/dev/null || launchctl load "$AGENT" 2>/dev/null || true
/System/Library/CoreServices/pbs -flush 2>/dev/null || true
/System/Library/CoreServices/pbs -update 2>/dev/null || true
killall Finder 2>/dev/null || true

echo "Done. Right-click a folder -> Quick Actions -> New File (now instant)."
