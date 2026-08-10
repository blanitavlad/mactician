#!/bin/zsh
set -euo pipefail

readonly PROJECT_DIR="${0:A:h:h}"
readonly SOURCE_LIB="${TFT_UNREAL_SOURCE_LIB:-}"
readonly OUTPUT_DIR="$PROJECT_DIR/artifacts/tft-pbe-18.1-5212127-native-gles31"
readonly OUTPUT_LIB="$OUTPUT_DIR/libUnreal.so"
readonly SOURCE_SHA="dd59c46a07d6f7394add255a1f11ede357489a7f1b6f2f925bd87c878c16ec08"
readonly PATCHED_SHA="7e074c7bb6e15ab00527a0b7e694bf9cac374b877f885a580f1e97a039daf9cd"
readonly PATCH_OFFSET=$(( 0x3c72f48 ))
readonly EXPECTED_CONTEXT="881643b91f080071a01a03b9c9fa0390"

if [[ -z "$SOURCE_LIB" ]]; then
    print "TFT_UNREAL_SOURCE_LIB must point to the pinned original ARM64 libUnreal.so."
    exit 1
fi

if [[ ! -f "$SOURCE_LIB" ]] \
        || [[ "$(shasum -a 256 "$SOURCE_LIB" | awk '{ print $1 }')" != "$SOURCE_SHA" ]] \
        || [[ "$(xxd -p -l 16 -s $(( PATCH_OFFSET - 4 )) "$SOURCE_LIB")" != "$EXPECTED_CONTEXT" ]]; then
    print "The source libUnreal.so does not match the verified TFT PBE 18.1 build."
    exit 1
fi
if [[ -f "$OUTPUT_LIB" ]]; then
    if [[ "$(shasum -a 256 "$OUTPUT_LIB" | awk '{ print $1 }')" == "$PATCHED_SHA" ]] \
            && [[ "$(xxd -p -l 4 -s "$PATCH_OFFSET" "$OUTPUT_LIB")" == "1f040071" ]]; then
        print "The verified native-GLES 3.1 libUnreal.so is already available: $OUTPUT_LIB"
        exit 0
    fi
    print "The existing output does not match the expected patched libUnreal.so; refusing to overwrite it."
    exit 1
fi

/bin/mkdir -p "$OUTPUT_DIR"
readonly NEXT_LIB="$OUTPUT_LIB.next.$$"
/bin/cp -c "$SOURCE_LIB" "$NEXT_LIB"
/usr/bin/printf '\037\004\000\161' \
    | /bin/dd of="$NEXT_LIB" bs=1 seek="$PATCH_OFFSET" conv=notrunc status=none
if [[ "$(xxd -p -l 4 -s "$PATCH_OFFSET" "$NEXT_LIB")" != "1f040071" ]] \
        || [[ "$(shasum -a 256 "$NEXT_LIB" | awk '{ print $1 }')" != "$PATCHED_SHA" ]]; then
    print "The ES 3.2→3.1 gate patch did not produce the expected binary; no output is published."
    exit 1
fi
/bin/mv "$NEXT_LIB" "$OUTPUT_LIB"

print "Temporary libUnreal.so ES 3.1 gate patch is ready: $OUTPUT_LIB"
print "One four-byte ARM64 instruction at 0x3c72f48: cmp minor,#2 → cmp minor,#1."
