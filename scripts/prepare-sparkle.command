#!/bin/zsh
set -euo pipefail

readonly PROJECT_DIR="${0:A:h:h}"
readonly LAUNCHER_DIR="$PROJECT_DIR/launcher"
readonly SPARKLE_VERSION="2.9.4"
readonly SPARKLE_ARCHIVE="Sparkle-$SPARKLE_VERSION.tar.xz"
readonly SPARKLE_URL="https://github.com/sparkle-project/Sparkle/releases/download/$SPARKLE_VERSION/$SPARKLE_ARCHIVE"
readonly SPARKLE_SHA256="ce89daf967db1e1893ed3ebd67575ed82d3902563e3191ca92aaec9164fbdef9"
readonly DEPENDENCY_ROOT="$LAUNCHER_DIR/.build/sparkle-$SPARKLE_VERSION"
readonly FRAMEWORK="$DEPENDENCY_ROOT/Sparkle.framework"
readonly TOOLS_DIR="$DEPENDENCY_ROOT/bin"
readonly LICENSE_FILE="$DEPENDENCY_ROOT/LICENSE"
readonly CACHE_DIR="$LAUNCHER_DIR/.build/downloads"
readonly CACHED_ARCHIVE="$CACHE_DIR/$SPARKLE_ARCHIVE"

framework_is_ready() {
    [[ -d "$FRAMEWORK" ]] \
        && [[ -x "$TOOLS_DIR/generate_appcast" ]] \
        && [[ -s "$LICENSE_FILE" ]] \
        && [[ "$(plutil -extract CFBundleShortVersionString raw \
            "$FRAMEWORK/Resources/Info.plist" 2>/dev/null || true)" == "$SPARKLE_VERSION" ]] \
        && codesign --verify --deep --strict "$FRAMEWORK" >/dev/null 2>&1
}

if framework_is_ready; then
    print "$DEPENDENCY_ROOT"
    exit 0
fi

mkdir -p "$CACHE_DIR"
if [[ ! -f "$CACHED_ARCHIVE" ]] \
        || [[ "$(shasum -a 256 "$CACHED_ARCHIVE" | awk '{print $1}')" != "$SPARKLE_SHA256" ]]; then
    rm -f "$CACHED_ARCHIVE.partial"
    curl -fL --retry 3 --retry-delay 2 \
        "$SPARKLE_URL" \
        -o "$CACHED_ARCHIVE.partial"
    if [[ "$(shasum -a 256 "$CACHED_ARCHIVE.partial" | awk '{print $1}')" != "$SPARKLE_SHA256" ]]; then
        rm -f "$CACHED_ARCHIVE.partial"
        print -u2 "Sparkle $SPARKLE_VERSION archive SHA-256 mismatch."
        exit 1
    fi
    mv -f "$CACHED_ARCHIVE.partial" "$CACHED_ARCHIVE"
fi

readonly EXTRACT_ROOT="$(mktemp -d /private/tmp/tft-sparkle.XXXXXX)"
cleanup() {
    rm -rf "$EXTRACT_ROOT"
}
trap cleanup EXIT

tar -xJf "$CACHED_ARCHIVE" -C "$EXTRACT_ROOT"
codesign --verify --deep --strict "$EXTRACT_ROOT/Sparkle.framework"

rm -rf "$DEPENDENCY_ROOT"
mkdir -p "$DEPENDENCY_ROOT" "$TOOLS_DIR"
ditto "$EXTRACT_ROOT/Sparkle.framework" "$FRAMEWORK"
ditto "$EXTRACT_ROOT/LICENSE" "$LICENSE_FILE"
for tool in BinaryDelta generate_appcast generate_keys sign_update; do
    ditto "$EXTRACT_ROOT/bin/$tool" "$TOOLS_DIR/$tool"
done

framework_is_ready || {
    print -u2 "Prepared Sparkle dependency failed validation."
    exit 1
}

print "$DEPENDENCY_ROOT"
