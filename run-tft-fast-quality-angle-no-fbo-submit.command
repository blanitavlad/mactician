#!/bin/zsh
set -euo pipefail

unsetopt BG_NICE

readonly PROJECT_DIR="${0:A:h}"

export TFT_ANGLE_DISABLED_FEATURES="${TFT_ANGLE_DISABLED_FEATURES:-preferSubmitAtFBOBoundary}"

print "TFT ANGLE no-FBO-submit A/B: disables TBR-specific deferred submission at framebuffer boundaries."
print "Goal: reduce unnecessary guest-to-host flushes/submissions and click-to-next-frame stalls."

exec "$PROJECT_DIR/run-tft-fast-quality.command"
