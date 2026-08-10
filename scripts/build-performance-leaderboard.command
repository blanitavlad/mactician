#!/bin/zsh
set -euo pipefail

readonly PROJECT_DIR="${0:A:h:h}"
readonly CAMPAIGN_DIR="${1:-}"
readonly JQ="${TFT_JQ:-$(command -v jq 2>/dev/null || true)}"

if [[ -z "$CAMPAIGN_DIR" || ! -d "$CAMPAIGN_DIR" ]]; then
    print "Usage: ${0:t} CAMPAIGN_DIR"
    exit 2
fi
if [[ ! -x "$JQ" ]]; then
    print "jq was not found. Set TFT_JQ or install jq on PATH."
    exit 1
fi

readonly ROWS="$CAMPAIGN_DIR/leaderboard-rows.tsv"
readonly AGGREGATES="$CAMPAIGN_DIR/leaderboard.tsv"
readonly MARKDOWN="$CAMPAIGN_DIR/leaderboard.md"
typeset RUN_CUTOFF_UTC=""
if [[ -f "$CAMPAIGN_DIR/valid-runs-after-utc.txt" ]]; then
    IFS= read -r RUN_CUTOFF_UTC < "$CAMPAIGN_DIR/valid-runs-after-utc.txt" || true
fi
print 'candidate\tstage\tfps\tp95_ms\tmax_ms\tover50\tover100\tdisplay\trollback\trun_dir' > "$ROWS.next"

typeset run_result run_dir candidate summary
while IFS= read -r run_dir; do
    [[ -n "$run_dir" ]] || continue
    run_result="$run_dir/run-result.json"
    [[ -f "$run_result" ]] || continue
    if ! "$JQ" -e '.benchmark_succeeded == true and .rollback.verified == true' \
            "$run_result" >/dev/null 2>&1; then
        continue
    fi
    candidate="$("$JQ" -r '.candidate' "$run_result")"
    for summary in "$run_dir"/result-summary-*.json(N); do
        "$JQ" -r \
            --arg candidate "$candidate" \
            --arg run_dir "$run_dir" \
            '[
                $candidate,
                .semantic_gate.stage_before,
                .pacing.fps,
                .pacing.p95_ms,
                .pacing.max_ms,
                .pacing.frames_over_ms["50"],
                .pacing.frames_over_ms["100"],
                .device.display,
                (.rollback.verified // false),
                $run_dir
            ] | @tsv' "$summary" >> "$ROWS.next"
    done
done < <(
    if [[ -f "$CAMPAIGN_DIR/runs.jsonl" ]]; then
        "$JQ" -r --arg cutoff "$RUN_CUTOFF_UTC" \
            'select(.run_dir != null and .run_dir != ""
                and ($cutoff == "" or .utc >= $cutoff)) | .run_dir' \
            "$CAMPAIGN_DIR/runs.jsonl" | sort -u
    else
        find "$CAMPAIGN_DIR" -type f -name run-result.json -print \
            | sed 's:/run-result[.]json$::' | sort -u
    fi
)
mv -f "$ROWS.next" "$ROWS"

awk -F '\t' '
    BEGIN {
        OFS = "\t"
        print "candidate", "runs", "fps_1_2", "fps_1_5", "fps_1_8", "score_heavy", "worst_p95_ms", "over50", "over100", "display"
    }
    NR > 1 {
        candidate = $1
        stage = $2
        fps[candidate, stage] += $3
        samples[candidate, stage]++
        if ($4 > worst_p95[candidate]) worst_p95[candidate] = $4
        over50[candidate] += $6
        over100[candidate] += $7
        display[candidate] = $8
        seen[candidate] = 1
    }
    END {
        for (candidate in seen) {
            f12 = samples[candidate, "1-2"] ? fps[candidate, "1-2"] / samples[candidate, "1-2"] : 0
            f15 = samples[candidate, "1-5"] ? fps[candidate, "1-5"] / samples[candidate, "1-5"] : 0
            f18 = samples[candidate, "1-8"] ? fps[candidate, "1-8"] / samples[candidate, "1-8"] : 0
            if (f15 > 0 && f18 > 0) score = f15 < f18 ? f15 : f18
            else score = 0
            run_count = samples[candidate, "1-5"]
            printf "%s\t%d\t%.2f\t%.2f\t%.2f\t%.2f\t%.3f\t%d\t%d\t%s\n", \
                candidate, run_count, f12, f15, f18, score, worst_p95[candidate], \
                over50[candidate], over100[candidate], display[candidate]
        }
    }
' "$ROWS" | { IFS= read -r header; print -r -- "$header"; sort -t $'\t' -k6,6nr; } > "$AGGREGATES.next"
mv -f "$AGGREGATES.next" "$AGGREGATES"

control_score="$(awk -F '\t' '$1 == "control" { print $6; exit }' "$AGGREGATES")"
control_p95="$(awk -F '\t' '$1 == "control" { print $7; exit }' "$AGGREGATES")"
{
    print "# TFT Trial performance leaderboard"
    print
    print "Only successful Trial runs with verified rollback are included. Heavy-scene score is min(mean stage 1-5 FPS, mean stage 1-8 FPS)."
    print
    print "## Confirmed in Trial"
    print
    print '| candidate | runs | 1-2 FPS | 1-5 FPS | 1-8 FPS | heavy score | worst p95 | >50 ms | >100 ms | display | verdict |'
    print '| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | --- | --- |'
    tail -n +2 "$AGGREGATES" | while IFS=$'\t' read -r id runs f12 f15 f18 score p95 over50 over100 display; do
        verdict=insufficient
        if (( runs >= 2 )) \
                && awk -v score="$score" -v p95="$p95" 'BEGIN { exit !(score >= 57 && p95 <= 20) }'; then
            verdict=near-60
        elif (( runs >= 2 )) && [[ -n "$control_score" && "$control_score" != "0.00" ]] \
                && awk -v score="$score" -v baseline="$control_score" -v p95="$p95" -v bp95="$control_p95" \
                    'BEGIN { exit !(score >= baseline * 1.03 && p95 <= bp95 * 1.05) }'; then
            verdict=eligible
        elif [[ -n "$control_score" && "$control_score" != "0.00" ]] \
                && awk -v score="$score" -v baseline="$control_score" -v p95="$p95" -v bp95="$control_p95" \
                    'BEGIN { exit !(score < baseline * 0.95 || p95 > bp95 * 1.10) }'; then
            verdict=rejected
        elif (( runs < 2 )); then
            verdict=provisional
        else
            verdict=neutral
        fi
        print "| $id | $runs | $f12 | $f15 | $f18 | $score | $p95 ms | $over50 | $over100 | $display | $verdict |"
    done

    print
    print "## Rejected or incomplete Trial runs"
    print
    print '| candidate | attempt | state | run |'
    print '| --- | ---: | --- | --- |'
    rejected_count=0
    if [[ -f "$CAMPAIGN_DIR/runs.jsonl" ]]; then
        while IFS=$'\t' read -r rejected_candidate rejected_attempt rejected_state rejected_run; do
            [[ -n "$rejected_candidate" ]] || continue
            print "| $rejected_candidate | $rejected_attempt | $rejected_state | \`$rejected_run\` |"
            (( rejected_count += 1 ))
        done < <(
            "$JQ" -r --arg cutoff "$RUN_CUTOFF_UTC" '
                select(($cutoff == "" or .utc >= $cutoff)
                    and .state != "success" and .state != "login_blocked")
                | [.candidate, .attempt, .state, .run_dir] | @tsv
            ' "$CAMPAIGN_DIR/runs.jsonl"
        )
    fi
    (( rejected_count == 0 )) && print '| — | — | none | — |'

    print
    print "## Prepared but blocked by Riot"
    print
    print '| candidate | attempt | state | run |'
    print '| --- | ---: | --- | --- |'
    blocked_count=0
    if [[ -f "$CAMPAIGN_DIR/runs.jsonl" ]]; then
        while IFS=$'\t' read -r blocked_candidate blocked_attempt blocked_state blocked_run; do
            [[ -n "$blocked_candidate" ]] || continue
            print "| $blocked_candidate | $blocked_attempt | $blocked_state | \`$blocked_run\` |"
            (( blocked_count += 1 ))
        done < <(
            "$JQ" -r --arg cutoff "$RUN_CUTOFF_UTC" '
                select(($cutoff == "" or .utc >= $cutoff) and .state == "login_blocked")
                | [.candidate, .attempt, .state, .run_dir] | @tsv
            ' "$CAMPAIGN_DIR/runs.jsonl"
        )
    fi
    (( blocked_count == 0 )) && print '| — | — | none | — |'

    print
    print "## Prepared but skipped by campaign gates"
    print
    print '| candidate | reason |'
    print '| --- | --- |'
    skipped_count=0
    if [[ -f "$CAMPAIGN_DIR/events.jsonl" ]]; then
        while IFS=$'\t' read -r skipped_candidate skipped_reason; do
            [[ -n "$skipped_candidate" ]] || continue
            print "| $skipped_candidate | $skipped_reason |"
            (( skipped_count += 1 ))
        done < <(
            "$JQ" -r --arg cutoff "$RUN_CUTOFF_UTC" '
                select(($cutoff == "" or .utc >= $cutoff) and .event == "candidate_skipped")
                | [.candidate, .detail] | @tsv
            ' "$CAMPAIGN_DIR/events.jsonl"
        )
    fi
    (( skipped_count == 0 )) && print '| — | none |'
} > "$MARKDOWN.next"
mv -f "$MARKDOWN.next" "$MARKDOWN"

print "$MARKDOWN"
