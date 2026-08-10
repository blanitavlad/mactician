#!/bin/zsh
set -euo pipefail

unsetopt BG_NICE

readonly PROJECT_DIR="${0:A:h}"
source "$PROJECT_DIR/scripts/android-environment.sh"

export TFT_ADB_SERVER_PORT="${TFT_ADB_SERVER_PORT:-5038}"
unset ADB_SERVER_SOCKET ANDROID_ADB_SERVER_ADDRESS
export ANDROID_ADB_SERVER_PORT="$TFT_ADB_SERVER_PORT"
export TFT_ROOT_AVD_HOME="${TFT_ROOT_AVD_HOME:-$(tft_resolve_avd_home)}"
if [[ -n "${TFT_AVD_HOME:-}" && "$TFT_AVD_HOME" != "$TFT_ROOT_AVD_HOME" ]]; then
    print "TFT_AVD_HOME and TFT_ROOT_AVD_HOME must select the same AVD home."
    exit 2
fi
export TFT_AVD_HOME="$TFT_ROOT_AVD_HOME"
export TFT_AVD_NAME="${TFT_AVD_NAME:-TftRootAffinity}"
export TFT_SERIAL="${TFT_SERIAL:-emulator-5582}"
export TFT_LAUNCHER="${TFT_LAUNCHER:-$PROJECT_DIR/run-tft-angle-opengl.command}"
export TFT_GLTRANSPORT="${TFT_GLTRANSPORT:-virtio-gpu-asg}"
export TFT_EXPECTED_GLTRANSPORT_BASELINE="${TFT_EXPECTED_GLTRANSPORT_BASELINE:-pipe}"
export TFT_DISPLAY_SIZE="${TFT_DISPLAY_SIZE:-2560x1440}"
export TFT_DISPLAY_DENSITY="${TFT_DISPLAY_DENSITY:-416}"
export TFT_UI_SCALE="${TFT_UI_SCALE:-1.0}"
export MVK_CONFIG_MAX_ACTIVE_METAL_COMMAND_BUFFERS_PER_QUEUE="${MVK_CONFIG_MAX_ACTIVE_METAL_COMMAND_BUFFERS_PER_QUEUE:-64}"

print "TFT fast-quality: ASG transport, MoltenVK-64, ${TFT_DISPLAY_SIZE}@${TFT_DISPLAY_DENSITY}, UI ${TFT_UI_SCALE}x, GPU Scene texture, and FXAA4/aniso8."
print "Isolated ADB: localhost:$TFT_ADB_SERVER_PORT; other Android tools can keep using 5037."
print "The wrapper restores the original AVD config.ini and hardware-qemu.ini on exit."

exec "$PROJECT_DIR/scripts/run-asg-experiment.command"
