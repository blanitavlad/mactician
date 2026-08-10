#!/bin/zsh
set -euo pipefail

unsetopt BG_NICE

readonly PROJECT_DIR="${0:A:h}"

# Bypass Android's guest ANGLE/Vulkan ranchu path. The root launcher verifies
# the loaded libraries and restores the original Android driver selection on
# clean exit; all emulator feature flags and host ANGLE env are process-local.
export TFT_GUEST_GL_DRIVER=native

print "TFT native-GLES A/B: guest ANGLE is disabled; gfxstream GLES encoder → host ANGLE → Metal."
print "This is a high-risk/high-upside candidate; the launcher verifies the active graphics path and rolls back settings."

exec "$PROJECT_DIR/run-tft-fast-quality.command"
