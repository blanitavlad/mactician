# Changelog

The current application metadata is version 1.0.0, build 36.

## Unreleased

No changes yet.

## 1.0.0 — 2026-08-10

### Added

- Initial public version of Mactician.

### Changed

- Restyled the active game Dock icon as a distinct Mactician play variant and
  replaced the Android Emulator title with `Mactician: TFT PBE`.
- Reduced Trial benchmark preparation from roughly 20 seconds to 1–3 seconds
  by overlapping one shop decision with combat and batching reward, XP, item,
  and replay actions.
- Preserved valid measurements across same-emulator Trial retries, added a
  bounded same-combat capture retry, and repaired early-exit cleanup after a
  launcher crash.
- Updated Performance Max with the confirmed 67% effects/LOD profile and a
  16 KiB ASG write step; repeated Trial 1-8 proxies remained above 30 FPS.
