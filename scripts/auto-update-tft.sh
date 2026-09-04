#!/bin/zsh
set -euo pipefail

export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:$PATH"

CACHE_DIR="$HOME/Library/Application Support/Mactician/game/tft-live"
VERSION_FILE="$CACHE_DIR/version.txt"
mkdir -p "$CACHE_DIR"

CURRENT_VERSION=""
if [[ -f "$VERSION_FILE" ]]; then
    CURRENT_VERSION="$(cat "$VERSION_FILE" | tr -d '[:space:]')"
fi

# Check if apkeep is available
if ! command -v apkeep >/dev/null 2>&1; then
    print "apkeep not found, skipping update check."
    exit 0
fi

# Quick version query (under 1s)
LATEST_VERSION="$(apkeep -a com.riotgames.league.teamfighttactics -d apk-pure --list-versions 2>/dev/null | tr ',' '\n' | tr '|' '\n' | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' | grep -v '^$' | grep -v 'Versions available' | tail -n 1 || true)"

if [[ -z "$LATEST_VERSION" ]]; then
    print "Could not reach update server, continuing with local version..."
    exit 0
fi

if [[ -n "$CURRENT_VERSION" && "$LATEST_VERSION" == "$CURRENT_VERSION" ]]; then
    print "TFT Live is already up to date ($CURRENT_VERSION)."
    exit 0
fi

print "New TFT version detected: $LATEST_VERSION (Current: ${CURRENT_VERSION:-none})"
osascript -e "display notification \"New TFT patch ($LATEST_VERSION) detected! Downloading update...\" with title \"TFT Auto-Updater\"" 2>/dev/null || true

TMP_DIR="/tmp/tft-auto-update-$$"
rm -rf "$TMP_DIR"
mkdir -p "$TMP_DIR"

if apkeep -a com.riotgames.league.teamfighttactics -d apk-pure "$TMP_DIR"; then
    if [[ -f "$TMP_DIR/com.riotgames.league.teamfighttactics.xapk" ]]; then
        cd "$TMP_DIR"
        unzip -o -q com.riotgames.league.teamfighttactics.xapk
        rm -f "$CACHE_DIR"/*.apk
        cp "$TMP_DIR"/*.apk "$CACHE_DIR/" 2>/dev/null || true
        echo "$LATEST_VERSION" > "$VERSION_FILE"
        print "TFT Live updated successfully to $LATEST_VERSION."
        osascript -e "display notification \"TFT updated to $LATEST_VERSION! Starting game...\" with title \"TFT Auto-Updater\"" 2>/dev/null || true
    fi
else
    print "Failed to download update, continuing with local version."
fi

rm -rf "$TMP_DIR"
exit 0
