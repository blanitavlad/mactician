## Summary

Describe the problem, the change, and its scope.

## Motivation

Explain why this change is needed and why this scope is appropriate.

## Validation

- [ ] `./scripts/verify-repository.command`
- [ ] `./scripts/test-mactician.command`
- [ ] Relevant manual or integration checks are described below, or are not applicable.

## Screenshots

Attach before/after screenshots for UI changes, or write “Not applicable.”

## Contributor checklist

- [ ] I did not add game APKs, Android images, private runtime state, credentials, logs, or generated build products.
- [ ] Developer-facing output and documentation are in English.
- [ ] New machine paths are resolved from environment variables, standard locations, or `PATH`.
- [ ] Behavior changes include tests or a concrete reason why a test is impractical.
- [ ] Performance claims include reproducible evidence and avoid overstating noisy results.
- [ ] Documentation, changelog, and release notes are updated when applicable.
- [ ] Existing rollback, Repair, Reset, and fail-closed behavior is preserved or the deliberate change is explained.
