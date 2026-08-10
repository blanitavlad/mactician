#!/bin/zsh
set -euo pipefail

unsetopt BG_NICE

readonly PROJECT_DIR="${0:A:h}"
readonly EXPERIMENT_PROFILE="$PROJECT_DIR/artifacts/tft-pbe-18.1-5212127-angle-opengl/Android_Codex.DeviceProfiles.ubo-direct-write.ini"

export TFT_ANGLE_OPENGL_PROFILE="$EXPERIMENT_PROFILE"
export TFT_ANGLE_OPENGL_PROFILE_SHA256="30e4933054e9b5b15549b90f1e0147e4ace1148d265b05fb4d5114af60166777"

print "TFT UBO-direct-write A/B: direct writes into mapped OpenGL uniform buffers."
print "This is an isolated high-risk profile; the stable fast-quality profile is unchanged."

exec "$PROJECT_DIR/run-tft-fast-quality.command"
