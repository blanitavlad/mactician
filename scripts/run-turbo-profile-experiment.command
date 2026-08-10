#!/bin/zsh
set -euo pipefail

readonly PROJECT_DIR="${0:A:h:h}"

print "Aggressive profile: OSFT feature set plus native swapchain and asynchronous Metal submissions."
print "If artifacts or a hang appear, close the emulator window."

TFT_GRAPHICS_PROFILE=turbo \
TFT_MVK_QUEUE_MODE=async \
exec "$PROJECT_DIR/run-tft-root-affinity.command"
