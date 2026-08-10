#!/bin/zsh
set -euo pipefail

readonly PROJECT_DIR="${0:A:h:h}"
readonly BRAND_DIR="$PROJECT_DIR/branding"
readonly GENERATED_DIR="$BRAND_DIR/generated"
readonly LAUNCHER_ICONSET="$GENERATED_DIR/Mactician.iconset"
readonly GAME_HOST_ICONSET="$GENERATED_DIR/EmulatorIcon.iconset"
readonly APP_ICON_SVG="$BRAND_DIR/mactician-app-icon.svg"
readonly GAME_HOST_ICON_SVG="$BRAND_DIR/mactician-game-host-icon.svg"

for command_name in rsvg-convert iconutil magick perl; do
    command -v "$command_name" >/dev/null 2>&1 || {
        print -u2 "Required asset tool is unavailable: $command_name"
        exit 1
    }
done

rm -rf "$GENERATED_DIR"
mkdir -p "$LAUNCHER_ICONSET" "$GAME_HOST_ICONSET"

render_png() {
    local source="$1"
    local width="$2"
    local height="$3"
    local destination="$4"
    rsvg-convert --width "$width" --height "$height" "$source" --output "$destination"
}

render_iconset() {
    local source="$1"
    local iconset="$2"
    render_png "$source" 16 16 "$iconset/icon_16x16.png"
    render_png "$source" 32 32 "$iconset/icon_16x16@2x.png"
    render_png "$source" 32 32 "$iconset/icon_32x32.png"
    render_png "$source" 64 64 "$iconset/icon_32x32@2x.png"
    render_png "$source" 128 128 "$iconset/icon_128x128.png"
    render_png "$source" 256 256 "$iconset/icon_128x128@2x.png"
    render_png "$source" 256 256 "$iconset/icon_256x256.png"
    render_png "$source" 512 512 "$iconset/icon_256x256@2x.png"
    render_png "$source" 512 512 "$iconset/icon_512x512.png"
    render_png "$source" 1024 1024 "$iconset/icon_512x512@2x.png"
}

render_iconset "$APP_ICON_SVG" "$LAUNCHER_ICONSET"
render_iconset "$GAME_HOST_ICON_SVG" "$GAME_HOST_ICONSET"

perl "$PROJECT_DIR/scripts/build-mactician-icns.pl" \
    "$LAUNCHER_ICONSET" "$GENERATED_DIR/Mactician.icns"
perl "$PROJECT_DIR/scripts/build-mactician-icns.pl" \
    "$GAME_HOST_ICONSET" "$GENERATED_DIR/EmulatorIcon.icns"
readonly LAUNCHER_VALIDATION_ICONSET="$GENERATED_DIR/.launcher-validation.iconset"
readonly GAME_HOST_VALIDATION_ICONSET="$GENERATED_DIR/.game-host-validation.iconset"
iconutil -c iconset "$GENERATED_DIR/Mactician.icns" -o "$LAUNCHER_VALIDATION_ICONSET"
iconutil -c iconset "$GENERATED_DIR/EmulatorIcon.icns" -o "$GAME_HOST_VALIDATION_ICONSET"
rm -rf "$LAUNCHER_VALIDATION_ICONSET" "$GAME_HOST_VALIDATION_ICONSET"
render_png "$APP_ICON_SVG" 1024 1024 "$GENERATED_DIR/Mactician-1024.png"
render_png "$GAME_HOST_ICON_SVG" 1024 1024 "$GENERATED_DIR/EmulatorIcon-1024.png"
render_png "$BRAND_DIR/mactician-favicon.svg" 64 64 "$GENERATED_DIR/mactician-favicon-64.png"
magick "$GENERATED_DIR/mactician-favicon-64.png" -define icon:auto-resize=64,32,16 \
    "$GENERATED_DIR/mactician-favicon.ico"
render_png "$BRAND_DIR/mactician-social-preview.svg" 1280 640 \
    "$GENERATED_DIR/mactician-social-preview.png"
render_png "$BRAND_DIR/mactician-open-graph.svg" 1200 630 \
    "$GENERATED_DIR/mactician-open-graph.png"
render_png "$BRAND_DIR/mactician-small-size-test.svg" 1120 420 \
    "$GENERATED_DIR/mactician-small-size-test.png"
render_png "$BRAND_DIR/mactician-product-hero.svg" 1600 900 \
    "$GENERATED_DIR/mactician-product-hero.png"

cp -f "$GENERATED_DIR/Mactician.icns" "$PROJECT_DIR/launcher/Resources/Mactician.icns"
cp -f "$GENERATED_DIR/Mactician-1024.png" "$PROJECT_DIR/launcher/Resources/Mactician-1024.png"
cp -f "$GENERATED_DIR/EmulatorIcon.icns" "$PROJECT_DIR/launcher/Resources/EmulatorIcon.icns"
cp -f "$GENERATED_DIR/EmulatorIcon-1024.png" \
    "$PROJECT_DIR/launcher/Resources/EmulatorIcon-1024.png"
cp -f "$GENERATED_DIR/mactician-product-hero.png" \
    "$PROJECT_DIR/launcher/Resources/MacticianHero.png"

print "Generated Mactician assets in $GENERATED_DIR"
