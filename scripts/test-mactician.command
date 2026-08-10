#!/bin/zsh
set -euo pipefail
unsetopt BG_NICE

readonly PROJECT_DIR="${0:A:h:h}"
readonly LAUNCHER_DIR="$PROJECT_DIR/launcher"
readonly SPARKLE_ROOT="$("$PROJECT_DIR/scripts/prepare-sparkle.command")"
readonly TEST_BINARY="$(mktemp -t mactician-tests)"
readonly LIFECYCLE_ROOT="$(mktemp -d -t mactician-lifecycle)"
readonly HOST_ARCH="$(uname -m)"
case "$HOST_ARCH" in
    arm64|x86_64) ;;
    *)
        print -u2 "Unsupported unit-test host architecture: $HOST_ARCH"
        exit 2
        ;;
esac
readonly TEST_TARGET="$HOST_ARCH-apple-macosx12.0"
cleanup() {
    local exit_code=$?
    rm -f "$TEST_BINARY"
    rm -rf "$LIFECYCLE_ROOT"
    return "$exit_code"
}
trap cleanup EXIT

jq -e '.schemaVersion == 1 and (.components | length) == 3 and (.game.apks | length) == 4' \
    "$LAUNCHER_DIR/Resources/release-manifest.json" >/dev/null
plutil -lint "$LAUNCHER_DIR/Info.plist" >/dev/null
plutil -lint "$LAUNCHER_DIR/Resources/EmulatorHost-Info.plist" >/dev/null
plutil -lint "$LAUNCHER_DIR/Resources/QEMU-Hypervisor.entitlements" >/dev/null
plutil -lint "$LAUNCHER_DIR/Resources/en.lproj/Localizable.strings" >/dev/null
plutil -lint "$LAUNCHER_DIR/Resources/ru.lproj/Localizable.strings" >/dev/null
typeset -a launcher_localizations
launcher_localizations=("$LAUNCHER_DIR"/Resources/*.lproj(N:t))
if (( ${#launcher_localizations} != 2 )) \
        || [[ "$launcher_localizations[1]" != "en.lproj" ]] \
        || [[ "$launcher_localizations[2]" != "ru.lproj" ]]; then
    print -u2 "Mactician must ship the English and Russian localization resources."
    exit 1
fi
zsh -o NO_BG_NICE -n \
    "$LAUNCHER_DIR/Resources/launcher-runtime.command" \
    "$LAUNCHER_DIR/Resources/emulator-host.command" \
    "$PROJECT_DIR/run-tft-root-affinity.command" \
    "$PROJECT_DIR/run-tft-angle-opengl.command" \
    "$PROJECT_DIR/scripts/run-asg-experiment.command" \
    "$PROJECT_DIR/scripts/watch-root-pso.command" \
    "$PROJECT_DIR/scripts/android-environment.sh" \
    "$PROJECT_DIR/scripts/prepare-sparkle.command" \
    "$PROJECT_DIR/scripts/publish-mactician-update.command" \
    "$PROJECT_DIR/scripts/build-mactician.command" \
    "$PROJECT_DIR/scripts/integration-test-mactician.command"

if rg -n '[А-Яа-яЁё]' \
        "$LAUNCHER_DIR/Resources/launcher-runtime.command" \
        "$LAUNCHER_DIR/Resources/emulator-host.command" \
        "$PROJECT_DIR/run-tft-root-affinity.command" \
        "$PROJECT_DIR/run-tft-angle-opengl.command" \
        "$PROJECT_DIR/scripts/run-asg-experiment.command" \
        "$PROJECT_DIR/scripts/watch-root-pso.command"; then
    print -u2 "Bundled launcher logs must be in English."
    exit 1
fi
xcrun clang \
    -target arm64-apple-macosx12.0 \
    -fsyntax-only \
    "$LAUNCHER_DIR/EmulatorHost/main.c"

if ! grep -Fq -- '--options runtime' "$PROJECT_DIR/scripts/build-mactician.command" \
        || ! grep -Fq 'notarytool submit' "$PROJECT_DIR/scripts/build-mactician.command" \
        || ! grep -Fq 'stapler staple' "$PROJECT_DIR/scripts/build-mactician.command" \
        || ! grep -Fq 'Sparkle.framework' "$PROJECT_DIR/scripts/build-mactician.command"; then
    print -u2 "Public release signing and notarization workflow is incomplete."
    exit 1
fi

if ! grep -Fq -- '--allow-adhoc' "$PROJECT_DIR/scripts/publish-mactician-update.command" \
        || ! grep -Fq 'Signature=adhoc' "$PROJECT_DIR/scripts/publish-mactician-update.command" \
        || ! grep -Fq 'hdiutil verify' "$PROJECT_DIR/scripts/publish-mactician-update.command"; then
    print -u2 "Ad-hoc publication safeguards are incomplete."
    exit 1
fi

if ! grep -Fq 'field__input--animate' \
        "$LAUNCHER_DIR/Sources/RiotLoginAnimationRepairService.swift" \
        || ! grep -Fq 'animation: none !important' \
        "$LAUNCHER_DIR/Sources/RiotLoginAnimationRepairService.swift" \
        || ! grep -Fq 'remainingAnimations == 0' \
        "$LAUNCHER_DIR/Sources/RiotLoginAnimationRepairService.swift" \
        || rg -n 'shell input (tap|keyevent)|KEYCODE_TAB|becomeFirstResponder' \
        "$LAUNCHER_DIR/Sources/RiotLoginAnimationRepairService.swift"; then
    print -u2 "Scoped Riot login animation repair is incomplete or uses synthetic focus."
    exit 1
fi

# A user-requested STOP sends TERM while the runtime child is still alive.
# Reproduce that lifecycle with caffeinate as a harmless long-running child and
# verify that it produces a normal stopped event, not a Repair error.
mkdir -p "$LIFECYCLE_ROOT/runtime/scripts"
ln -s /usr/bin/caffeinate "$LIFECYCLE_ROOT/runtime/scripts/run-asg-experiment.command"
env \
    TFT_RUNTIME_PROJECT="$LIFECYCLE_ROOT/runtime" \
    TFT_LAUNCH_LOG="$LIFECYCLE_ROOT/runtime.log" \
    TFT_ADB=/usr/bin/false \
    TFT_AVD_HOME="$LIFECYCLE_ROOT/avd" \
    TFT_AVD_NAME=TftPBE \
    TFT_SERIAL=emulator-5582 \
    TFT_DISPLAY_SIZE=1920x1080 \
    TFT_DISPLAY_DENSITY=320 \
    TFT_GAME_LANGUAGE=en-US \
    TFT_CPU_CORES=6 \
    TFT_MEMORY_MB=6144 \
    TFT_UI_SCALE=1.0 \
    "$LAUNCHER_DIR/Resources/launcher-runtime.command" \
    >"$LIFECYCLE_ROOT/events.jsonl" &
readonly LIFECYCLE_PID=$!
typeset lifecycle_ready=0
for lifecycle_attempt in {1..100}; do
    if grep -q '"event":"booting"' "$LIFECYCLE_ROOT/events.jsonl" 2>/dev/null; then
        lifecycle_ready=1
        break
    fi
    if ! kill -0 "$LIFECYCLE_PID" >/dev/null 2>&1; then
        break
    fi
    sleep 0.05
done
if (( lifecycle_ready == 0 )); then
    print -u2 "Launcher runtime did not reach the booting state."
    cat "$LIFECYCLE_ROOT/events.jsonl" >&2 2>/dev/null || true
    exit 1
fi
kill -TERM "$LIFECYCLE_PID"
if wait "$LIFECYCLE_PID"; then
    readonly LIFECYCLE_STATUS=0
else
    readonly LIFECYCLE_STATUS=$?
fi
if (( LIFECYCLE_STATUS != 0 )) \
        || ! grep -q '"event":"stopped"' "$LIFECYCLE_ROOT/events.jsonl" \
        || grep -q '"event":"error"' "$LIFECYCLE_ROOT/events.jsonl"; then
    print -u2 "Launcher runtime STOP was not classified as a normal shutdown."
    cat "$LIFECYCLE_ROOT/events.jsonl" >&2
    exit 1
fi

# After TFT has started, three consecutive missing package-PID checks represent
# a real game close. Verify that the runtime emits game_stopped before cleanup.
readonly GAME_EXIT_ADB="$LIFECYCLE_ROOT/fake-adb.command"
readonly GAME_EXIT_STATE="$LIFECYCLE_ROOT/fake-adb-state"
cat >"$GAME_EXIT_ADB" <<'FAKE_ADB_EOF'
#!/bin/zsh
set -eu
if [[ "$*" == *" get-state" ]]; then
    exit 0
fi
if [[ "$*" == *" getprop sys.boot_completed" ]]; then
    print 1
    exit 0
fi
if [[ "$*" == *" cmd locale set-app-locales"* ]]; then
    exit 0
fi
if [[ "$*" == *" pidof com.riotgames.league.teamfighttactics.pbe" ]]; then
    typeset -i count=0
    [[ -f "$TFT_FAKE_ADB_STATE" ]] && count="$(<"$TFT_FAKE_ADB_STATE")"
    (( count += 1 ))
    print "$count" >"$TFT_FAKE_ADB_STATE"
    (( count <= 2 )) && print 4242
    exit 0
fi
exit 0
FAKE_ADB_EOF
chmod 755 "$GAME_EXIT_ADB"
env \
    TFT_RUNTIME_PROJECT="$LIFECYCLE_ROOT/runtime" \
    TFT_LAUNCH_LOG="$LIFECYCLE_ROOT/game-exit-runtime.log" \
    TFT_ADB="$GAME_EXIT_ADB" \
    TFT_FAKE_ADB_STATE="$GAME_EXIT_STATE" \
    TFT_AVD_HOME="$LIFECYCLE_ROOT/avd" \
    TFT_AVD_NAME=TftPBE \
    TFT_SERIAL=emulator-5582 \
    TFT_DISPLAY_SIZE=1920x1080 \
    TFT_DISPLAY_DENSITY=320 \
    TFT_GAME_LANGUAGE=en-US \
    TFT_CPU_CORES=6 \
    TFT_MEMORY_MB=6144 \
    TFT_UI_SCALE=1.0 \
    "$LAUNCHER_DIR/Resources/launcher-runtime.command" \
    >"$LIFECYCLE_ROOT/game-exit-events.jsonl" &
readonly GAME_EXIT_PID=$!
typeset game_exit_detected=0
for game_exit_attempt in {1..200}; do
    if grep -q '"event":"game_stopped"' \
            "$LIFECYCLE_ROOT/game-exit-events.jsonl" 2>/dev/null; then
        game_exit_detected=1
        break
    fi
    if ! kill -0 "$GAME_EXIT_PID" >/dev/null 2>&1; then
        break
    fi
    sleep 0.05
done
kill -TERM "$GAME_EXIT_PID" >/dev/null 2>&1 || true
wait "$GAME_EXIT_PID" || true
if (( game_exit_detected == 0 )) \
        || [[ "$(grep -c '"event":"game_stopped"' "$LIFECYCLE_ROOT/game-exit-events.jsonl")" != 1 ]] \
        || grep -q '"event":"error"' "$LIFECYCLE_ROOT/game-exit-events.jsonl"; then
    print -u2 "Launcher runtime did not classify a closed TFT process."
    cat "$LIFECYCLE_ROOT/game-exit-events.jsonl" >&2
    exit 1
fi

mkdir -p "$LAUNCHER_DIR/.build/module-cache"
xcrun swiftc \
    -target "$TEST_TARGET" \
    -module-cache-path "$LAUNCHER_DIR/.build/module-cache" \
    "$LAUNCHER_DIR/Sources/CoreModels.swift" \
    "$LAUNCHER_DIR/Sources/LauncherPresentation.swift" \
    "$LAUNCHER_DIR/Sources/LauncherTelemetryService.swift" \
    "$LAUNCHER_DIR/Sources/LauncherPaths.swift" \
    "$LAUNCHER_DIR/Sources/SystemServices.swift" \
    "$LAUNCHER_DIR/Sources/EmulatorBrandingPatch.swift" \
    "$LAUNCHER_DIR/Sources/EmulatorAudioRecoveryService.swift" \
    "$LAUNCHER_DIR/Sources/FPSOverlayService.swift" \
    "$LAUNCHER_DIR/Sources/InputBridgeService.swift" \
    "$LAUNCHER_DIR/Sources/InstallerService.swift" \
    "$LAUNCHER_DIR/Tests/LauncherTests.swift" \
    -o "$TEST_BINARY"

"$TEST_BINARY" \
    "$LAUNCHER_DIR/Resources/release-manifest.json" \
    "$LAUNCHER_DIR"

typeset -a ALL_SOURCES
ALL_SOURCES=("$LAUNCHER_DIR"/Sources/*.swift)
xcrun swiftc \
    -typecheck \
    -parse-as-library \
    -target arm64-apple-macosx12.0 \
    -module-cache-path "$LAUNCHER_DIR/.build/module-cache" \
    -F "$SPARKLE_ROOT" \
    "${ALL_SOURCES[@]}"

print "Mactician typecheck: OK"
