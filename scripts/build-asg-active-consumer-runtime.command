#!/bin/zsh
set -euo pipefail

readonly PROJECT_DIR="${0:A:h:h}"
source "$PROJECT_DIR/scripts/android-environment.sh"
SDK_ROOT="$(tft_resolve_android_sdk_root)"
readonly SDK_ROOT
readonly SOURCE_RUNTIME="${TFT_SOURCE_EMULATOR_RUNTIME:-$SDK_ROOT/emulator}"
readonly PATCHED_RUNTIME="${TFT_PATCHED_EMULATOR_RUNTIME:-$PROJECT_DIR/runtime/android-emulator-37.1.11-asg-active-consumer}"
readonly SOURCE_DYLIB="$SOURCE_RUNTIME/lib64/libgfxstream_backend.dylib"
readonly SOURCE_QEMU="$SOURCE_RUNTIME/qemu/darwin-aarch64/qemu-system-aarch64"
readonly EXPECTED_DYLIB_SHA="3772fef215058831ea419c9281fd203d010003d5defdc195dd120bc7748e4093"
readonly EXPECTED_QEMU_SHA="eaa97a970b81f81640db73ed79e19ee173323653a0a1203217e1199d078011f3"
readonly EXPECTED_PATCHED_UNSIGNED_SHA="7d955f7f3c71fd8262d11a688c69a44f61e2032c67b782f95e7c9c13af3f90d5"
readonly PATCH_OFFSET=$(( 0x54e80 ))
readonly EXPECTED_BYTES="89008052"
readonly PATCHED_BYTES="29008052"
readonly HYPERVISOR_ENTITLEMENTS="$PROJECT_DIR/scripts/macos-hypervisor.entitlements"

if [[ -e "$PATCHED_RUNTIME" ]]; then
    print "The isolated patched runtime already exists: $PATCHED_RUNTIME"
    print "Refusing to overwrite it."
    exit 1
fi
if [[ ! -f "$SOURCE_RUNTIME/source.properties" ]] \
        || ! grep -q '^Pkg.Revision=37[.]1[.]11$' "$SOURCE_RUNTIME/source.properties" \
        || ! grep -q '^Pkg.BuildId=15917651$' "$SOURCE_RUNTIME/source.properties"; then
    print "Unsupported Android Emulator build; the ASG patch was cancelled."
    exit 1
fi
if [[ "$(shasum -a 256 "$SOURCE_DYLIB" | awk '{ print $1 }')" != "$EXPECTED_DYLIB_SHA" ]] \
        || [[ "$(shasum -a 256 "$SOURCE_QEMU" | awk '{ print $1 }')" != "$EXPECTED_QEMU_SHA" ]]; then
    print "The source runtime SHA-256 does not match the verified build; the ASG patch was cancelled."
    exit 1
fi
if [[ "$(xxd -p -l 4 -s "$PATCH_OFFSET" "$SOURCE_DYLIB")" != "$EXPECTED_BYTES" ]]; then
    print "The expected ARM64 instruction was not found at offset 0x54e80; the ASG patch was cancelled."
    exit 1
fi

readonly BUILD_ROOT="$(mktemp -d "$PROJECT_DIR/runtime/.asg-active-consumer-build.XXXXXX")"
readonly BUILD_RUNTIME="$BUILD_ROOT/android-emulator-37.1.11-asg-active-consumer"
print "Creating an APFS copy-on-write clone of the emulator runtime…"
/usr/bin/ditto --clone --noqtn "$SOURCE_RUNTIME" "$BUILD_RUNTIME"

readonly PATCHED_DYLIB="$BUILD_RUNTIME/lib64/libgfxstream_backend.dylib"
readonly PATCHED_QEMU="$BUILD_RUNTIME/qemu/darwin-aarch64/qemu-system-aarch64"
if [[ "$(stat -f %i "$SOURCE_DYLIB")" == "$(stat -f %i "$PATCHED_DYLIB")" ]]; then
    print "Clone unexpectedly shares the source inode; patch cancelled."
    exit 1
fi
if [[ "$(shasum -a 256 "$PATCHED_DYLIB" | awk '{ print $1 }')" != "$EXPECTED_DYLIB_SHA" ]]; then
    print "Clone dylib SHA-256 mismatch; patch cancelled."
    exit 1
fi

/usr/bin/printf '\051\000\200\122' \
    | /bin/dd of="$PATCHED_DYLIB" bs=1 seek="$PATCH_OFFSET" conv=notrunc status=none
if [[ "$(xxd -p -l 4 -s "$PATCH_OFFSET" "$PATCHED_DYLIB")" != "$PATCHED_BYTES" ]] \
        || [[ "$(shasum -a 256 "$PATCHED_DYLIB" | awk '{ print $1 }')" != "$EXPECTED_PATCHED_UNSIGNED_SHA" ]]; then
    print "Guarded ASG instruction patch did not produce the expected binary; signing cancelled."
    exit 1
fi

print "Applying local ad-hoc signatures only to the cloned dylib and QEMU binary…"
/usr/bin/codesign --force --sign - --timestamp=none --preserve-metadata=identifier "$PATCHED_DYLIB"
/usr/bin/codesign --force --sign - --timestamp=none --preserve-metadata=identifier \
    --entitlements "$HYPERVISOR_ENTITLEMENTS" "$PATCHED_QEMU"
/usr/bin/codesign --verify --strict --verbose=2 "$PATCHED_DYLIB"
/usr/bin/codesign --verify --strict --verbose=2 "$PATCHED_QEMU"

readonly QEMU_FLAGS="$(/usr/bin/codesign -dv --verbose=4 "$PATCHED_QEMU" 2>&1 \
    | sed -n 's/^CodeDirectory .* flags=\([^ ]*\).*/\1/p')"
if [[ "$QEMU_FLAGS" != "0x2(adhoc)" ]]; then
    print "Clone QEMU unexpectedly retains hardened-runtime flags: $QEMU_FLAGS"
    exit 1
fi
if ! /usr/bin/codesign -d --entitlements :- "$PATCHED_QEMU" 2>/dev/null \
        | grep -q 'com[.]apple[.]security[.]hypervisor'; then
    print "Clone QEMU lost the Hypervisor.framework entitlement."
    exit 1
fi
if [[ "$(shasum -a 256 "$SOURCE_DYLIB" | awk '{ print $1 }')" != "$EXPECTED_DYLIB_SHA" ]] \
        || [[ "$(xxd -p -l 4 -s "$PATCH_OFFSET" "$SOURCE_DYLIB")" != "$EXPECTED_BYTES" ]]; then
    print "The source runtime changed during the build; the patched runtime is not published."
    exit 1
fi

/bin/mv "$BUILD_RUNTIME" "$PATCHED_RUNTIME"
/bin/rmdir "$BUILD_ROOT"

print "Isolated ASG active-consumer runtime is ready: $PATCHED_RUNTIME"
print "The stable runtime is unchanged; the patch is exactly four bytes: 89008052 → 29008052 at 0x54e80."
