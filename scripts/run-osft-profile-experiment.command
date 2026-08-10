#!/bin/zsh
set -euo pipefail

readonly PROJECT_DIR="${0:A:h:h}"

print "A/B profile: the exact OSFT graphics feature set on the rootable AVD."
print "The APK, TFT data, and persistent AVD configuration are unchanged."

TFT_GRAPHICS_PROFILE=osft exec "$PROJECT_DIR/run-tft-root-affinity.command"
