#!/bin/zsh
set -euo pipefail

if [[ -z "${TFT_EMULATOR:-}" || ! -x "$TFT_EMULATOR" ]]; then
    print -u2 "Mactician Game Host could not find its Android Emulator executable."
    exit 1
fi

exec "$TFT_EMULATOR" "$@"
