# Current State

As of 2026-04-27, this repository contains both the governance scaffold and a
first-pass implementation for managing `msmtp` configuration.

Present today:

- root [README.md](../../README.md), [AGENTS.md](../../AGENTS.md), and
  [CHANGELOG.md](../../CHANGELOG.md)
- canonical [`agents/`](../) guidance
- human-readable [`docs/README.md`](../../docs/README.md)
- manual fallback docs in [docs/manual-setup.md](../../docs/manual-setup.md)
- [`.env.example`](../../.env.example) and mode-specific example env files
- [`templates/msmtprc.template`](../../templates/msmtprc.template)
- implementation scripts in [`scripts/`](../../scripts/) for quickstart,
  interactive setup, render, and install flows
- a [`Makefile`](../../Makefile) with common repo commands
- shell-based smoke tests in [`tests/test.sh`](../../tests/test.sh)

Not present today:

- CI automation
- package-manager bootstrap logic for installing `msmtp`
- published release artifacts or a hosted curl entrypoint

Do not assume future planned tooling already exists. Any new implementation
work should update this file if it changes the baseline repository reality.
