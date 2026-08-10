#!/bin/zsh
set -euo pipefail

readonly PROJECT_DIR="${0:A:h:h}"

print "One-factor A/B: asynchronous MoltenVK queue submissions."
print "Close the current TFT AVD first. The mode applies only to this launch."

TFT_MVK_QUEUE_MODE=async exec "$PROJECT_DIR/run-tft-root-affinity.command"
