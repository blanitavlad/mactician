# Reproducibility

This project distinguishes source declarations, release inputs, and mutable
runtime state. A reproducible source checkout does not contain the game
packages, downloaded Android runtime, AVD userdata, or signing credentials.

## Pinned release inputs

| Input | Version/build | SHA-256 |
| --- | --- | --- |
| Android Platform Tools | 36.0.2 | `106a5d31fad8c1c0c5a180d06f5779767d129d7d5edbe629005c11a85eec5b4b` |
| Android Emulator | 37.1.11 / 15917651 | `22530de9363f34ea945ecb5cad74523abd4b615f27f3c1a9899efb183ea9e144` |
| Google APIs ARM64 system image | Android 36 revision 7 | `fb47d861d6f87230ee0fe70f610d579935ca77f41a0eefbf391595d3dc4b5ee2` |
| Sparkle | 2.9.4 | `ce89daf967db1e1893ed3ebd67575ed82d3902563e3191ca92aaec9164fbdef9` |

The game release is `18.1-5212127`, package
`com.riotgames.league.teamfighttactics.pbe`. The four split names, sizes, and
SHA-256 values are in `launcher/Resources/release-manifest.json`; the APK bytes
are deliberately absent from Git.

The current release manifest itself hashes to:

```text
02cf1042cdc119ed22f8ee4ea3ab5fb5448e600445f176c787e98770dc96470e  launcher/Resources/release-manifest.json
```

## Active profile hashes

The retained profile identifiers are compatibility-sensitive because the
Shipping game command line selects `DeviceProfile=Android_Codex`.

```text
c9c84bec09e60d2ee965f91ef0b7b1eb687521527e478e3df5054f779137c42b  artifacts/tft-pbe-18.1-5212127-angle-opengl/Android_Codex.DeviceProfiles.ini
3479ffb5482b7e8d79d04627de4ffe052d9f7b9078f4107a690a575db87bea99  artifacts/tft-pbe-18.1-5212127-angle-opengl/Android_Codex.DeviceProfiles.shader-prewarm.ini
5ab532b82e2706898d66b4325f880e0ab52982be36e70577a7a6f4aa12d2f8fa  artifacts/tft-pbe-18.1-5212127-angle-opengl/Android_Codex.DeviceProfiles.performance-max.ini
183d2196f3b79fdcff1d433480e803322c1b580bfaf117991e7229c2754002b5  artifacts/tft-pbe-18.1-5212127-angle-opengl/Android_Codex.DeviceProfiles.no-frame-ahead.ini
e92e08b1f1f62b463cdbb43a522929a1cee66145b1abcf7380749e16f93ff451  artifacts/tft-pbe-18.1-5212127-direct-vulkan/Android_Codex.DeviceProfiles.ini
```

Other experiment profiles remain in `artifacts/` and can be hashed directly
with `shasum -a 256`; documentation does not pin hashes for inactive files.

## Three manifests/states

- **Source manifest:** the committed JSON records downloadable Android
  components, game split metadata, disk requirement, and UI launch profiles.
- **Release manifest:** the copy embedded in a built app. The build copies it
  byte-for-byte and verifies every private game input before packaging.
- **Runtime state:** `install-state.json` in Application Support records what was
  successfully installed on one Mac. It is mutable, private, and never a source
  of release hashes.

The runtime also generates effective AVD configuration, downloaded package
`source.properties`, overlay hashes, and rollback sidecars. Those values prove a
specific run; they are not committed build inputs.

## Verify an environment

```sh
./scripts/verify-repository.command
./scripts/test-mactician.command
./scripts/verify-environment.sh
./run-tft-best-verified.command --print-config
```

For an accepted benchmark, retain the effective display/density, graphics flags,
APK/profile/runtime hashes, power/thermal state, semantic before/after gates,
frame summary, and cleanup/rollback result. `--print-config` is read-only and
shows the recommended source profile without starting the emulator.

## Release verification

After building, compare the embedded manifest to the source, verify nested code
signatures, and hash the DMG:

```sh
cmp launcher/Resources/release-manifest.json \
  "dist/Mactician.app/Contents/Resources/release-manifest.json"
codesign --verify --deep --strict --verbose=2 "dist/Mactician.app"
shasum -a 256 "dist/Mactician-1.0.0.dmg"
```

A public build additionally requires the Developer ID authority, notarization
acceptance, and a stapled ticket. Rebuilding a DMG can change container bytes;
published versioned artifacts are therefore immutable rather than assumed to be
bit-for-bit reproducible across machines.
