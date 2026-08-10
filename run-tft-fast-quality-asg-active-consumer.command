#!/bin/zsh
set -euo pipefail

unsetopt BG_NICE

readonly PROJECT_DIR="${0:A:h}"
readonly PATCHED_RUNTIME="$PROJECT_DIR/runtime/android-emulator-37.1.11-asg-active-consumer"

if [[ "${TFT_ALLOW_REJECTED_ASG_PATCH:-0}" != "1" ]]; then
    print "REJECTED: the ASG active-consumer patch measured 11.2 FPS / p95 334 ms versus stable 60 FPS / p95 18.44 ms in the same lobby scene."
    print "A forensic repeat requires an explicit TFT_ALLOW_REJECTED_ASG_PATCH=1."
    exit 2
fi

if [[ ! -x "$PATCHED_RUNTIME/emulator" ]]; then
    print "The isolated patched runtime was not found. Run this first:"
    print "  $PROJECT_DIR/scripts/build-asg-active-consumer-runtime.command"
    exit 1
fi

export TFT_EMULATOR="$PATCHED_RUNTIME/emulator"
export TFT_MACOS_GAME_MODE=0

print "TFT ASG active-consumer A/B: isolated four-byte host state patch; the stable runtime is unchanged."
print "Goal: remove repeated virtio writew wakeups while RenderThread is already active."

exec "$PROJECT_DIR/run-tft-fast-quality.command"
