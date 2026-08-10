# Notices and attribution

The source code and documentation authored for Mactician are available
under the repository's [MIT License](LICENSE). Third-party software, services,
names, and artwork retain their own terms; they are not relicensed by this
repository.

## Sparkle

The launcher integrates [Sparkle 2](https://github.com/sparkle-project/Sparkle)
version 2.9.4 for signed updates. The build downloads Sparkle's upstream binary
release and verifies its pinned SHA-256 before use. See the
[Sparkle license](https://github.com/sparkle-project/Sparkle/blob/2.x/LICENSE)
for its terms. Release builds also include the complete upstream license at
`Mactician.app/Contents/Resources/ThirdPartyLicenses/Sparkle-LICENSE.txt`.

## Android components and graphics stack

The installer downloads pinned Apple Silicon builds of Android Platform Tools,
Android Emulator, and the Google APIs Android 36 system image from Google's
Android repository. These packages are not stored in this repository. Their
archives carry upstream license and notice material; review that material after
download and the [Android SDK terms](https://developer.android.com/studio/terms)
before redistribution.

The Android Emulator distribution used by this project contains or interacts
with upstream components including
[ANGLE](https://chromium.googlesource.com/angle/angle/),
[gfxstream](https://android.googlesource.com/platform/hardware/google/gfxstream/),
and [MoltenVK](https://github.com/KhronosGroup/MoltenVK). Exact component
notices are supplied by the pinned Emulator package; no single license is
asserted here for the combined distribution.

## Riot Games and Teamfight Tactics

Teamfight Tactics, TFT, Riot Games, and related names and artwork belong to
their respective owners. The launcher artwork in
`launcher/Resources/MacticianHero.png`, icons, and any game packages
provided locally for a build are not covered by this repository's MIT grant.
This independent community project is not endorsed by or affiliated with Riot
Games.

## Apple platforms

Apple, macOS, Apple Silicon, Metal, and related platform names are trademarks
of Apple Inc. Building and distributing a signed app requires the applicable
Apple developer tools and agreements.
