#!/bin/zsh
set -euo pipefail

readonly PROJECT_DIR="${0:A:h}"

export TFT_RENDERER=angle-opengl
export TFT_GRAPHICS_PROFILE="${TFT_GRAPHICS_PROFILE:-osft}"
export TFT_CPU_CORES="${TFT_CPU_CORES:-7}"
export TFT_MEMORY_MB="${TFT_MEMORY_MB:-8960}"
export TFT_DISPLAY_SIZE="${TFT_DISPLAY_SIZE:-2560x1440}"
export TFT_DISPLAY_DENSITY="${TFT_DISPLAY_DENSITY:-416}"
export TFT_MVK_QUEUE_MODE="${TFT_MVK_QUEUE_MODE:-async}"
export MVK_CONFIG_MAX_ACTIVE_METAL_COMMAND_BUFFERS_PER_QUEUE="${MVK_CONFIG_MAX_ACTIVE_METAL_COMMAND_BUFFERS_PER_QUEUE:-64}"
export MVK_CONFIG_FAST_MATH_ENABLED="${MVK_CONFIG_FAST_MATH_ENABLED:-1}"

print "TFT ANGLE/OpenGL A/B: temporary APK overlay plus a matching Android_Codex profile."
print "MoltenVK OSFT tuning: async submit, ${MVK_CONFIG_MAX_ACTIVE_METAL_COMMAND_BUFFERS_PER_QUEUE} active Metal command buffers, fast math."
print "When the AVD closes, the launcher will stop TFT, remove the mount, and shut down the emulator."

exec "$PROJECT_DIR/run-tft-root-affinity.command"
