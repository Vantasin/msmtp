# Current State

As of 2026-04-29, this repository contains both the governance scaffold and a
working implementation for managing `msmtp` configuration.

Present today:

- root [README.md](../../README.md), [AGENTS.md](../../AGENTS.md), and
  [CHANGELOG.md](../../CHANGELOG.md)
- linear human onboarding in [README.md](../../README.md) and
  [docs/getting-started.md](../../docs/getting-started.md), from supported
  bootstrap or manual clone through test email
- canonical [`agents/`](../) guidance
- human-readable [`docs/README.md`](../../docs/README.md)
- an optional [docs/bootstrap.md](../../docs/bootstrap.md) reference for the
  self-contained bootstrap entrypoint
- a dedicated [docs/makefile.md](../../docs/makefile.md) reference for the
  user-facing `make` command surface
- canonical account-file guidance in [accounts/README.md](../../accounts/README.md)
- secret-backend docs in [docs/secrets.md](../../docs/secrets.md)
- manual fallback docs in [docs/manual-setup.md](../../docs/manual-setup.md)
- [`templates/msmtprc.template`](../../templates/msmtprc.template)
- account-file examples in [`templates/examples/`](../../templates/examples/)
- implementation scripts in [`scripts/`](../../scripts/) for quickstart,
  self-contained bootstrap, guided account/configure/password/rotation/
  install/restore flows, interactive setup, render, guarded install, and
  backup restore flows
- a [`Makefile`](../../Makefile) with guided top-level commands plus explicit
  user/system install and restore targets
- shell-based smoke tests in [`tests/test.sh`](../../tests/test.sh)

Operational convention today:

- SMTP account values live in `accounts/*.env`.
- The persistent default account lives in `accounts/.default-account`.
- The optional repo-local plaintext password-file workspace lives in the
  gitignored `passwords/` directory.
- The simplest setup is `accounts/default.env`; multiple addresses add more
  files in the same directory. The file name `default.env` is fine, but the
  msmtp account name inside it should use a non-reserved label such as
  `primary`.
- User vs system install scope is selected through `make` targets and
  variables, not through account-file data.
- The preferred human-facing commands are `make configure`, `make password`,
  `make test-email`, `make test-live-email`, `make install`, and
  `make restore`; `make account` remains the account-only CRUD entrypoint.
- A self-contained `scripts/bootstrap.sh` entrypoint now exists for optional
  clone-plus-install onboarding, and the quick-start docs now treat the public
  GitHub raw `curl` bootstrap as a supported entry point alongside the manual
  clone-based path.
- Guided `make configure` can now add or edit multiple accounts before one
  final install/verification step, so the common human workflow no longer
  requires repeated configure runs just to prepare several accounts.
- Guided `make configure` now treats pre-existing file-backed secrets as a
  recoverable decision point, offering rotate, validate, skip, or retry
  choices instead of exiting immediately on the first existing-secret conflict.
- `make restore` is now the umbrella entrypoint; typed restore commands handle
  config, account, and file-backed secret backups explicitly.
- The quick-start path centers on `make configure`, which now offers an
  optional test-email step before exit. `make test-email` remains the
  standalone isolated-account resend/manual path, `make test-live-email`
  verifies the installed live config path, and `make check` is secondary
  verification for the repo automation itself rather than the primary live
  SMTP validation step.
- Guided install prompts stay concise and only ask for target, mode, or
  default-account choices when the deployment is ambiguous.
- Install-time default-account choices can override a missing or stale
  `accounts/.default-account` entry for the current deploy without mutating the
  stored account data.
- Repo-owned file writes now prefer same-directory atomic replacement semantics
  rather than in-place mutation.
- File-backed secret paths are normalized to absolute paths during guided
  setup, rendering, and helper execution; a leading `~` expands to the user's
  home directory instead of being treated as a literal repo-relative path.
- Repo-local file paths shown in prompts or written into account files resolve
  from the canonical repository root so macOS case-insensitive path spellings
  do not leak into Linux-facing configuration.
- When the repo-local `passwords/` option is used for plaintext `password_file`
  secrets, the helper scripts enforce mode `700` on that directory and mode
  `600` on the password file.
- Install, restore, and file-backed secret rotation preserve adjacent
  `.bak.*` recovery points and aim to leave either the old or new live file in
  place if interrupted.
- Interactive workflows emit clearer cancellation messaging, but external tools
  such as macOS Keychain and GPG still define part of the interruption
  behavior.

Not present today:

- CI automation
- published release artifacts

Do not assume future planned tooling already exists. Any new implementation
work should update this file if it changes the baseline repository reality.
