#!/bin/zsh
set -euo pipefail

unsetopt BG_NICE

readonly PROJECT_DIR="${0:A:h}"
readonly PATCHED_LIB="$PROJECT_DIR/artifacts/tft-pbe-18.1-5212127-native-gles31/libUnreal.so"

if [[ "${TFT_ALLOW_REJECTED_GLES31_GATE:-0}" != "1" ]]; then
    print "REJECTED: native gfxstream exposes GLES 3.0 on this Mac, so the strict ES 3.1 gate correctly fails."
    print "A forensic repeat requires TFT_ALLOW_REJECTED_GLES31_GATE=1."
    exit 2
fi

if [[ ! -f "$PATCHED_LIB" ]]; then
    print "The native-GLES 3.1 gate artifact was not found. Run this first:"
    print "  $PROJECT_DIR/scripts/build-native-gles31-lib.command"
    exit 1
fi

export TFT_UNREAL_LIB_OVERLAY="$PATCHED_LIB"
export TFT_UNREAL_LIB_OVERLAY_SHA256="7e074c7bb6e15ab00527a0b7e694bf9cac374b877f885a580f1e97a039daf9cd"

print "TFT native-GLES 3.1 gate A/B: temporary four-byte libUnreal overlay over native gfxstream GLES."
print "The runtime gate remains strict: ES 3.1+ is accepted and ES 3.0/2.x remains rejected."

exec "$PROJECT_DIR/run-tft-fast-quality-native-gles.command"
