# TFT PBE direct-Vulkan experiment

Source APK version: `18.1-5212127`.

This experiment changes one little-endian 32-bit field at offset `0x10` in
`assets/vkqualitydata.vkq` from `37` (`0x25`) to `36` (`0x24`). That field is
the VkQuality future Android API threshold. The expected effect on the Android
36 test AVD is a recommendation of Vulkan instead of
`GLESBecauseNoDeviceMatch`.

The APK command line also adds Unreal's supported `-vulkan` RHI selector and
command-line-priority presentation, resolution, texture-pool, and PSO-cache
CVars. This is needed because TFT's
compiled config rules separately disable Vulkan when `ro.hardware` is
`ranchu`, even after VkQuality recommends Vulkan.

No native library, game asset, account data, or anti-cheat behavior is changed.
The rebuilt base APK is intentionally unsigned and is suitable only for a
temporary root bind-mount over the already installed, original signed APK.

`Android_Codex.DeviceProfiles.ini` defines a high-memory Vulkan profile for
the rootable AVD. It inherits the game's `Android_High` profile, includes the
game's Vulkan fragment, then overrides mobile memory-conservation settings
that are counterproductive on the M1 Max host.
