# Current State

As of 2026-04-27, this repository contains both the governance scaffold and a
working implementation for managing `msmtp` configuration.

Present today:

- root [README.md](../../README.md), [AGENTS.md](../../AGENTS.md), and
  [CHANGELOG.md](../../CHANGELOG.md)
- linear human onboarding in [README.md](../../README.md) and
  [docs/getting-started.md](../../docs/getting-started.md), from clone through
  test email
- canonical [`agents/`](../) guidance
- human-readable [`docs/README.md`](../../docs/README.md)
- multi-account guidance in [accounts/README.md](../../accounts/README.md)
- secret-backend docs in [docs/secrets.md](../../docs/secrets.md)
- manual fallback docs in [docs/manual-setup.md](../../docs/manual-setup.md)
- [`.env.example`](../../.env.example) and mode-specific example env files
- [`templates/msmtprc.template`](../../templates/msmtprc.template)
- implementation scripts in [`scripts/`](../../scripts/) for quickstart,
  secret setup, interactive setup, multi-account render, guarded install, and
  backup restore flows
- a [`Makefile`](../../Makefile) with common repo commands, including explicit
  user and system install/restore targets
- shell-based smoke tests in [`tests/test.sh`](../../tests/test.sh)

Operational convention today:

- SMTP account values live in `.env` or `accounts/*.env`.
- User vs system install scope is selected through `make` targets and
  variables, not through env-file account data.

Not present today:

- CI automation
- package-manager bootstrap logic for installing `msmtp`
- published release artifacts or a hosted curl entrypoint

Do not assume future planned tooling already exists. Any new implementation
work should update this file if it changes the baseline repository reality.
