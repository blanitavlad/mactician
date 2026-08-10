# Contributing

Contributions are welcome when they are narrowly scoped, testable, and preserve
the launcher's recovery guarantees.

## Development setup

Use an Apple Silicon Mac with macOS 12 or later, Xcode Command Line Tools, zsh,
`jq`, Node.js for the optional login helper, and the local private APK build
inputs described in [docs/building.md](docs/building.md). Runtime and game data
must remain outside Git.

Run the fast validation before opening a pull request:

```sh
./scripts/verify-repository.command
./scripts/test-mactician.command
```

The provisioning integration test downloads large pinned Android archives and
is intentionally local/manual:

```sh
./scripts/integration-test-mactician.command
```

## Pull requests

- Keep changes small and explain their motivation and failure mode.
- Update documentation whenever commands, manifests, behavior, or recovery
  steps change.
- Preserve transactional rollback, checksum verification, and fail-closed
  behavior around unknown UI states and unsupported game versions.
- Do not weaken update signing, bundle identity, appcast trust, or manifest
  validation.
- Add benchmark claims only with reproducible, same-scene evidence and recorded
  hashes. Label single runs provisional.
- Keep shell scripts compatible with zsh, derive the project root from
  `${0:A:h}`, quote paths, validate required tools, and emit English output.
- Keep the Mactician interface localized in English and Russian, update both
  `.strings` files for user-visible changes, and never translate the brand name.
  Game-language support is independent.
- Do not commit secrets, credentials, APKs, runtime state, AVD userdata, logs,
  crash dumps, build output, or developer-specific absolute paths.

Use the pull request template and include screenshots for UI changes. A change
that affects install, Repair, Reset, launch, stop, or update behavior must state
how rollback and recovery were verified.
