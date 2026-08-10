#!/bin/zsh
set -euo pipefail

unsetopt BG_NICE

readonly PROJECT_DIR="${0:A:h}"

# Current upstream gfxstream's virtio renderer uses these substantially larger
# ASG batching values. Keep the proven 1 MiB write buffer: 4 MiB is incompatible
# with this Emulator ABI and is rejected by the inner wrapper.
export TFT_GL_DRAW_FLUSH_INTERVAL="${TFT_GL_DRAW_FLUSH_INTERVAL:-10000}"
export TFT_ASG_WRITE_STEP_SIZE="${TFT_ASG_WRITE_STEP_SIZE:-262144}"
export TFT_ASG_DATA_RING_SIZE="${TFT_ASG_DATA_RING_SIZE:-524288}"

print "TFT upstream-ASG A/B: flush 10000us, write step 256 KiB, data ring 512 KiB."
print "This is an aggressive fast-quality candidate; retain it only after a same-scene battle A/B."

exec "$PROJECT_DIR/run-tft-fast-quality.command"
