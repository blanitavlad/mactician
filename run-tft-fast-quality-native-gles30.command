#!/bin/zsh
set -euo pipefail

unsetopt BG_NICE

readonly PROJECT_DIR="${0:A:h}"
readonly PATCHED_LIB="$PROJECT_DIR/artifacts/tft-pbe-18.1-5212127-native-gles30/libUnreal.so"

if [[ "${TFT_ALLOW_REJECTED_GLES30_GATE:-0}" != "1" ]]; then
    print "REJECTED: the ES 3.0 gate passes, but missing GLES APIs cause a GameThread SIGSEGV before the first frame."
    print "A forensic repeat requires TFT_ALLOW_REJECTED_GLES30_GATE=1."
    exit 2
fi

if [[ ! -f "$PATCHED_LIB" ]]; then
    print "The native-GLES 3.0 gate artifact was not found. Run this first:"
    print "  $PROJECT_DIR/scripts/build-native-gles30-lib.command"
    exit 1
fi

export TFT_UNREAL_LIB_OVERLAY="$PATCHED_LIB"
export TFT_UNREAL_LIB_OVERLAY_SHA256="5500b8cd407161b62c1dcf55c4ac47e75ac4b32cc88f735578f8c0e12e30d437"

print "TFT native-GLES 3.0 last-chance A/B: temporary one-instruction libUnreal gate overlay."
print "ES 2 remains rejected; validate real shaders and APIs, not only process startup."

exec "$PROJECT_DIR/run-tft-fast-quality-native-gles.command"
