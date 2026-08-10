# TFT PBE ANGLE/OpenGL A/B experiment

Source APK version: `18.1-5212127`.

This overlay is rebuilt from the untouched original `base.apk`. Its only APK
payload change is `assets/UECommandLine.txt`, which keeps the original project
selector and adds Unreal's `-opengl` RHI selector together with the same
presentation, resolution, and `Android_Codex` profile arguments used by the
direct-Vulkan experiment.

`Android_Codex.DeviceProfiles.ini` is deliberately identical to the aggressive
direct-Vulkan profile except for `r.Android.DisableVulkanSupport=1`. The Vulkan
CVars remain in the file as inert controls so renderer selection is the intended
A/B variable rather than an unrelated profile rewrite.

The rebuilt base APK is intentionally unsigned. It must only be used as a
temporary root bind-mount over the already installed original signed APK in the
separate userdebug AVD; it is not suitable for normal package installation.
