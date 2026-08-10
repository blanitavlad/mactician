#!/bin/zsh
set -euo pipefail

readonly PROJECT_DIR="${0:A:h}"

export TFT_RENDERER=direct-vulkan
export TFT_GRAPHICS_PROFILE="${TFT_GRAPHICS_PROFILE:-osft}"

print "TFT direct Vulkan: temporary verified APK overlay plus the Android_Codex profile."
print "When the AVD closes, the launcher stops TFT, unmounts the overlay, and shuts down the emulator."

exec "$PROJECT_DIR/run-tft-root-affinity.command"
