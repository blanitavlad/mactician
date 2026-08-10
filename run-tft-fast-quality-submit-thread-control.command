#!/bin/zsh
set -euo pipefail

unsetopt BG_NICE

readonly PROJECT_DIR="${0:A:h}"

export TFT_GUEST_SUBMIT_THREAD="on-demand"

print "TFT guest-submit-thread control: the same /system/bin/env wrapper with Mesa's on-demand default."

exec "$PROJECT_DIR/run-tft-fast-quality.command"
