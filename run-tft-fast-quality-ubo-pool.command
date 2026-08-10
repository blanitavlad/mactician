#!/bin/zsh
set -euo pipefail

unsetopt BG_NICE

readonly PROJECT_DIR="${0:A:h}"
readonly EXPERIMENT_PROFILE="$PROJECT_DIR/artifacts/tft-pbe-18.1-5212127-angle-opengl/Android_Codex.DeviceProfiles.ubo-pool-16m.ini"

export TFT_ANGLE_OPENGL_PROFILE="$EXPERIMENT_PROFILE"
export TFT_ANGLE_OPENGL_PROFILE_SHA256="b97f4c89132914bdfc3871cb819452bdad84456601a1347b433af8c15fe0422b"

print "TFT UBO-pool A/B: 16 MiB pooled OpenGL uniform-buffer storage."
print "This is an isolated high-risk profile; the stable fast-quality profile is unchanged."

exec "$PROJECT_DIR/run-tft-fast-quality.command"
