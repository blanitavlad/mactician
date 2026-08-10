#!/bin/zsh
set -euo pipefail

unsetopt BG_NICE

readonly PROJECT_DIR="${0:A:h}"

export MVK_CONFIG_MAX_ACTIVE_METAL_COMMAND_BUFFERS_PER_QUEUE="${MVK_CONFIG_MAX_ACTIVE_METAL_COMMAND_BUFFERS_PER_QUEUE:-128}"
export TFT_DISPLAY_SIZE="${TFT_DISPLAY_SIZE:-2560x1440}"
export TFT_DISPLAY_DENSITY="${TFT_DISPLAY_DENSITY:-416}"

print "TFT experimental MVK128: not promoted after cold Trial confirmation."
print "Recommended launcher remains run-tft-best-verified.command (MoltenVK-64)."

exec "$PROJECT_DIR/run-tft-fast-quality.command"
