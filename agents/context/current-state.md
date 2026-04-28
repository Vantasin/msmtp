# Current State

As of 2026-04-28, this repository contains both the governance scaffold and a
working implementation for managing `msmtp` configuration.

Present today:

- root [README.md](../../README.md), [AGENTS.md](../../AGENTS.md), and
  [CHANGELOG.md](../../CHANGELOG.md)
- linear human onboarding in [README.md](../../README.md) and
  [docs/getting-started.md](../../docs/getting-started.md), from clone through
  test email
- canonical [`agents/`](../) guidance
- human-readable [`docs/README.md`](../../docs/README.md)
- canonical account-file guidance in [accounts/README.md](../../accounts/README.md)
- secret-backend docs in [docs/secrets.md](../../docs/secrets.md)
- manual fallback docs in [docs/manual-setup.md](../../docs/manual-setup.md)
- [`templates/msmtprc.template`](../../templates/msmtprc.template)
- account-file examples in [`templates/examples/`](../../templates/examples/)
- implementation scripts in [`scripts/`](../../scripts/) for quickstart,
  guided account/configure/password/rotation/install/restore flows,
  interactive setup, render, guarded install, and backup restore flows
- a [`Makefile`](../../Makefile) with guided top-level commands plus explicit
  user/system install and restore targets
- shell-based smoke tests in [`tests/test.sh`](../../tests/test.sh)

Operational convention today:

- SMTP account values live in `accounts/*.env`.
- The persistent default account lives in `accounts/.default-account`.
- The simplest setup is `accounts/default.env`; multiple addresses add more
  files in the same directory.
- User vs system install scope is selected through `make` targets and
  variables, not through account-file data.
- The preferred human-facing commands are `make configure`, `make password`,
  `make install`, and `make restore`; `make account` remains the account-only
  CRUD entrypoint.
- Guided install prompts stay concise and only ask for target, mode, or
  default-account choices when the deployment is ambiguous.
- Install-time default-account choices can override a missing or stale
  `accounts/.default-account` entry for the current deploy without mutating the
  stored account data.
- Repo-owned file writes now prefer same-directory atomic replacement semantics
  rather than in-place mutation.
- Install, restore, and file-backed secret rotation preserve adjacent
  `.bak.*` recovery points and aim to leave either the old or new live file in
  place if interrupted.
- Interactive workflows emit clearer cancellation messaging, but external tools
  such as macOS Keychain and GPG still define part of the interruption
  behavior.

Not present today:

- CI automation
- package-manager bootstrap logic for installing `msmtp`
- published release artifacts or a hosted curl entrypoint

Do not assume future planned tooling already exists. Any new implementation
work should update this file if it changes the baseline repository reality.
