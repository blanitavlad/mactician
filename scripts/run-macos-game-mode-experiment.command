#!/bin/zsh
set -euo pipefail

readonly PROJECT_DIR="${0:A:h:h}"

print "One-factor A/B: macOS Game Mode for the TFT emulator."
print "After launch, enter native fullscreen and confirm Cmd-Esc → Game Mode: On."

TFT_MACOS_GAME_MODE=1 exec "$PROJECT_DIR/run-tft-root-affinity.command"
