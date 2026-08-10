#!/bin/zsh
set -euo pipefail

unsetopt BG_NICE

readonly PROJECT_DIR="${0:A:h}"
readonly DEFAULT_PROFILE="$PROJECT_DIR/artifacts/tft-pbe-18.1-5212127-angle-opengl/Android_Codex.DeviceProfiles.shader-prewarm.ini"
readonly DEFAULT_PROFILE_SHA256="3479ffb5482b7e8d79d04627de4ffe052d9f7b9078f4107a690a575db87bea99"

export TFT_ANGLE_OPENGL_PROFILE="${TFT_ANGLE_OPENGL_PROFILE:-$DEFAULT_PROFILE}"
export TFT_ANGLE_OPENGL_PROFILE_SHA256="${TFT_ANGLE_OPENGL_PROFILE_SHA256:-$DEFAULT_PROFILE_SHA256}"
export TFT_GRAPHICS_PROFILE="${TFT_GRAPHICS_PROFILE:-osft}"

print "TFT shader-prewarm: eager shader library + shader-map preload; baseline OSFT composition."
print "The first start may take longer; the goal is to remove first-use shop and effect hitches."

exec "$PROJECT_DIR/run-tft-fast-quality.command"
