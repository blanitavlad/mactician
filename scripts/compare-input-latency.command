#!/bin/zsh
set -euo pipefail

readonly SCRIPT_NAME="${0:t}"

usage() {
    print "Usage: $SCRIPT_NAME BASELINE_SUMMARY CANDIDATE_SUMMARY..."
    print "SUMMARY is a summary.txt file from capture-input-latency.command or its containing directory."
}

if (( $# < 2 )); then
    usage
    exit 2
fi

summary_path() {
    local value="$1"
    if [[ -d "$value" ]]; then
        value="$value/summary.txt"
    fi
    if [[ ! -f "$value" ]]; then
        print "Summary not found: $value" >&2
        return 1
    fi
    print -r -- "${value:A}"
}

summary_value() {
    local file="$1"
    local key="$2"
    sed -n "s/^${key}=//p" "$file" | head -n 1
}

variant_name() {
    local summary="$1"
    local run_dir="${summary:h:h}"
    local metadata="$run_dir/launcher-metadata.txt"
    if [[ -f "$metadata" ]]; then
        sed -n 's/^variant=//p' "$metadata" | head -n 1
    else
        print -r -- "${summary:h:t}"
    fi
}

readonly BASELINE_SUMMARY="$(summary_path "$1")"
readonly BASELINE_FPS="$(summary_value "$BASELINE_SUMMARY" fps)"
if [[ -z "$BASELINE_FPS" ]] || ! awk -v value="$BASELINE_FPS" 'BEGIN { exit !(value > 0) }'; then
    print "The baseline summary does not contain a valid FPS value."
    exit 2
fi

print "variant                              fps    baseline   p95-ms   queues   result"
printf '%-35s %6s %9s %8s %8s   %s\n' \
    "$(variant_name "$BASELINE_SUMMARY")" \
    "$BASELINE_FPS" \
    "100.0%" \
    "$(summary_value "$BASELINE_SUMMARY" frame_p95_ms)" \
    "$(summary_value "$BASELINE_SUMMARY" input_queues_ok)" \
    "baseline"

shift
typeset candidate summary fps ratio p95 queues result
for candidate in "$@"; do
    summary="$(summary_path "$candidate")"
    fps="$(summary_value "$summary" fps)"
    p95="$(summary_value "$summary" frame_p95_ms)"
    queues="$(summary_value "$summary" input_queues_ok)"
    if [[ -z "$fps" ]] || ! awk -v value="$fps" 'BEGIN { exit !(value > 0) }'; then
        print "The candidate summary does not contain a valid FPS value: $summary"
        exit 2
    fi
    ratio="$(awk -v candidate="$fps" -v baseline="$BASELINE_FPS" \
        'BEGIN { printf "%.1f", candidate * 100 / baseline }')"
    result="eligible"
    if ! awk -v value="$ratio" 'BEGIN { exit !(value >= 90) }'; then
        result="reject-fps"
    elif [[ "$queues" != "1" ]]; then
        result="reject-input"
    fi
    printf '%-35s %6s %8s%% %8s %8s   %s\n' \
        "$(variant_name "$summary")" "$fps" "$ratio" "$p95" "$queues" "$result"
done

print
print "Among eligible variants, select the smallest visible trail relative to the click marker; reject-fps exceeds the 10% budget."
