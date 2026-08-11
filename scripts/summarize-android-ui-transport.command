#!/bin/zsh
set -euo pipefail

readonly PROJECT_DIR="${0:A:h:h}"
readonly MEASUREMENT_ROOT="${TFT_UI_TRANSPORT_ROOT:-$PROJECT_DIR/runtime/measurements/android-ui-transport}"
readonly LABEL_PATTERN="${1:-^flush-[0-9]+-[A-Za-z0-9]+$}"
readonly JQ="${TFT_JQ:-$(command -v jq 2>/dev/null || true)}"

if [[ -z "$JQ" || ! -x "$JQ" ]]; then
    print -u2 "jq is required to summarize Android UI transport probes."
    exit 1
fi
typeset -a summaries
summaries=("$MEASUREMENT_ROOT"/*/summary.json(N))
if (( ${#summaries} == 0 )); then
    print -u2 "No transport-probe summaries were found under $MEASUREMENT_ROOT."
    exit 1
fi

"$JQ" -s \
    --arg label_pattern "$LABEL_PATTERN" '
    def median:
      sort as $sorted
      | ($sorted | length) as $count
      | if ($count % 2) == 1 then $sorted[($count / 2 | floor)]
        else (($sorted[$count / 2 - 1] + $sorted[$count / 2]) / 2)
        end;
    def group_name: .label | sub("-[A-Za-z0-9]+$"; "");
    def minimum_frames: (.minimum_frames_per_round // ((.swipe_pairs // 15) * 8));
    def valid_run:
      . as $run
      | (($run.rounds | type) == "array")
        and (($run.rounds | length) > 0)
        and (($run.rejected_reason // null) == null)
        and ([$run.rounds[].total_frames] | all(. >= ($run | minimum_frames)));
    def warm_rounds:
      if (.rounds | length) > 3 then .rounds[3:][] else .rounds[] end;
    map(select(.label | test($label_pattern)))
    | map(. + {group: group_name,
               graphics_profile: (.graphics_profile // "legacy-unattested"),
               display: (.display // "legacy-unknown"),
               display_density: (.display_density // "legacy-unknown"),
               transport: (.transport // "legacy-unknown"),
               hwui_renderer: (.hwui_renderer // "legacy-unknown"),
               valid_run: valid_run})
    | group_by([.group, .graphics_profile, .display, .display_density,
                .transport, .hwui_renderer])
    | map(
        . as $runs
        | [$runs[] | select(.valid_run) | warm_rounds] as $warm
        | ($warm | length) as $warm_count
        | {group: $runs[0].group,
           graphics_profile: $runs[0].graphics_profile,
           display: $runs[0].display,
           display_density: $runs[0].display_density,
           transport: $runs[0].transport,
           hwui_renderer: $runs[0].hwui_renderer,
           valid_runs: ($runs | map(select(.valid_run)) | length),
           rejected_runs: ($runs | map(select(.valid_run | not)) | length),
           warm_rounds: $warm_count,
           warm_mean_elapsed_ms:
             (if $warm_count == 0 then null
              else (($warm | map(.elapsed_ns) | add) / $warm_count / 1000000) end),
           warm_median_elapsed_ms:
             (if $warm_count == 0 then null
              else (($warm | map(.elapsed_ns) | median) / 1000000) end),
           warm_max_elapsed_ms:
             (if $warm_count == 0 then null
              else (($warm | map(.elapsed_ns) | max) / 1000000) end),
           warm_max_p95_ms:
             (if $warm_count == 0 then null else ($warm | map(.p95_ms) | max) end),
           warm_max_p99_ms:
             (if $warm_count == 0 then null else ($warm | map(.p99_ms) | max) end),
           warm_total_janky_frames:
             (if $warm_count == 0 then null else ($warm | map(.janky_frames) | add) end)}
      )
    | sort_by([.group, .graphics_profile, .display, .display_density,
               .transport, .hwui_renderer])' \
    "${summaries[@]}"
