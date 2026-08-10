#!/bin/zsh
set -euo pipefail

unsetopt BG_NICE

readonly PROJECT_DIR="${0:A:h}"

export TFT_GUEST_SUBMIT_THREAD="1"

print "TFT guest-submit-thread A/B: Vulkan submission and marshalling move off RHIThread."
print "The process wrapper is scoped to TFT and is rolled back when the AVD closes."

exec "$PROJECT_DIR/run-tft-fast-quality.command"
