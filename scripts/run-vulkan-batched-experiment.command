#!/bin/zsh
set -euo pipefail

readonly PROJECT_DIR="${0:A:h:h}"

print "One-factor A/B: stable pipe plus VulkanBatchedDescriptorSetUpdate."
print "Close the current TFT AVD first. The flag applies only to this launch."

TFT_VULKAN_BATCHED_DESCRIPTORS=1 exec "$PROJECT_DIR/run-tft-root-affinity.command"
