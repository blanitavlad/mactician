#!/bin/zsh
set -euo pipefail

unsetopt BG_NICE

readonly PROJECT_DIR="${0:A:h:h}"
readonly SCRIPT_NAME="${0:t}"
readonly PROFILE_DIR="$PROJECT_DIR/artifacts/tft-pbe-18.1-5212127-angle-opengl"
readonly BASE_PROFILE="$PROFILE_DIR/Android_Codex.DeviceProfiles.shader-prewarm.ini"
readonly BASE_PROFILE_SHA256="3479ffb5482b7e8d79d04627de4ffe052d9f7b9078f4107a690a575db87bea99"
readonly NO_FRAME_AHEAD_PROFILE="$PROFILE_DIR/Android_Codex.DeviceProfiles.no-frame-ahead.ini"
readonly NO_FRAME_AHEAD_PROFILE_SHA256="183d2196f3b79fdcff1d433480e803322c1b580bfaf117991e7229c2754002b5"
readonly OUTPUT_ROOT="${TFT_INPUT_LATENCY_ROOT:-$PROJECT_DIR/runtime/measurements/input-latency}"
readonly SPEC="${1:-}"
readonly DRY_RUN="${TFT_INPUT_LATENCY_DRY_RUN:-0}"

usage() {
    print "Usage: $SCRIPT_NAME baseline|combined|FACTOR[+FACTOR...]"
    print "Factors: no-frame-ahead, sync-submit, no-async-compose, native-swapchain"
}

if [[ -z "$SPEC" || "$#" != "1" ]]; then
    usage
    exit 2
fi
if [[ "$DRY_RUN" != "0" && "$DRY_RUN" != "1" ]]; then
    print "TFT_INPUT_LATENCY_DRY_RUN must be 0 or 1."
    exit 2
fi

typeset -a FACTORS
case "$SPEC" in
    baseline)
        FACTORS=()
        ;;
    combined)
        FACTORS=(no-frame-ahead sync-submit no-async-compose native-swapchain)
        ;;
    *)
        if [[ ! "$SPEC" =~ '^[a-z-]+([+][a-z-]+)*$' ]]; then
            usage
            exit 2
        fi
        FACTORS=("${(@s:+:)SPEC}")
        ;;
esac

integer NO_FRAME_AHEAD=0
integer SYNC_SUBMIT=0
integer NO_ASYNC_COMPOSE=0
integer NATIVE_SWAPCHAIN=0
typeset -A SEEN_FACTORS
typeset factor
for factor in "${FACTORS[@]}"; do
    if [[ -n "${SEEN_FACTORS[$factor]-}" ]]; then
        print "Factor specified more than once: $factor"
        exit 2
    fi
    SEEN_FACTORS[$factor]=1
    case "$factor" in
        no-frame-ahead) NO_FRAME_AHEAD=1 ;;
        sync-submit) SYNC_SUBMIT=1 ;;
        no-async-compose) NO_ASYNC_COMPOSE=1 ;;
        native-swapchain) NATIVE_SWAPCHAIN=1 ;;
        *)
            print "Unknown latency factor: $factor"
            usage
            exit 2
            ;;
    esac
done

case "${NO_ASYNC_COMPOSE}${NATIVE_SWAPCHAIN}" in
    00) export TFT_GRAPHICS_PROFILE=osft ;;
    10) export TFT_GRAPHICS_PROFILE=osft-no-async-compose ;;
    01) export TFT_GRAPHICS_PROFILE=osft-native-swapchain ;;
    11) export TFT_GRAPHICS_PROFILE=osft-low-latency ;;
esac

if (( SYNC_SUBMIT )); then
    export TFT_MVK_QUEUE_MODE=sync
else
    export TFT_MVK_QUEUE_MODE=async
fi

if (( NO_FRAME_AHEAD )); then
    export TFT_ANGLE_OPENGL_PROFILE="$NO_FRAME_AHEAD_PROFILE"
    export TFT_ANGLE_OPENGL_PROFILE_SHA256="$NO_FRAME_AHEAD_PROFILE_SHA256"
else
    export TFT_ANGLE_OPENGL_PROFILE="$BASE_PROFILE"
    export TFT_ANGLE_OPENGL_PROFILE_SHA256="$BASE_PROFILE_SHA256"
fi

if [[ "$DRY_RUN" == "1" ]]; then
    print "variant=$SPEC"
    print "graphics_profile=$TFT_GRAPHICS_PROFILE"
    print "mvk_queue_mode=$TFT_MVK_QUEUE_MODE"
    print "device_profile=${TFT_ANGLE_OPENGL_PROFILE:t}"
    exit 0
fi

readonly SAFE_SPEC="${SPEC//+/_}"
readonly UTC_STAMP="$(date -u '+%Y%m%dT%H%M%SZ')"
readonly RUN_DIR="$OUTPUT_ROOT/${UTC_STAMP}__${SAFE_SPEC}"
readonly HOST_INPUT_LOG="$RUN_DIR/host-input.jsonl"
readonly CURRENT_RUN_FILE="$OUTPUT_ROOT/current-run"
mkdir -p "$RUN_DIR"
: > "$HOST_INPUT_LOG"
print -r -- "$RUN_DIR" > "$CURRENT_RUN_FILE"

{
    print "variant=$SPEC"
    print "graphics_profile=$TFT_GRAPHICS_PROFILE"
    print "mvk_queue_mode=$TFT_MVK_QUEUE_MODE"
    print "device_profile=$TFT_ANGLE_OPENGL_PROFILE"
    print "device_profile_sha256=$TFT_ANGLE_OPENGL_PROFILE_SHA256"
    print "latency_budget_percent=10"
} > "$RUN_DIR/launcher-metadata.txt"

export TFT_INPUT_DIAGNOSTICS=1
export TFT_INPUT_DIAGNOSTICS_LOG="$HOST_INPUT_LOG"
export TFT_INPUT_LATENCY_VARIANT="$SPEC"

print "TFT input-latency A/B: $SPEC"
print "Graphics profile: $TFT_GRAPHICS_PROFILE; MoltenVK submit: $TFT_MVK_QUEUE_MODE."
print "Click marker enabled; host timestamps: $HOST_INPUT_LOG"
print "After entering a match, run this in another terminal:"
print "  $PROJECT_DIR/scripts/capture-input-latency.command"

exec "$PROJECT_DIR/run-tft-fast-quality-shader-prewarm.command"
