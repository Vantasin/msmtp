# Changelog

## 2026-04-28

- split account-only editing from deployment, removed install prompts from
  `make account` / `setup.sh`, and added a new `make configure` guided flow
  with richer prompts and clearer next-step guidance
- clarified interactive defaults, optional-field behavior, and cancellation
  messaging, and moved the remaining write/install/restore paths toward
  same-directory atomic replacement semantics
- simplified guided install prompts, made explicit default-account choices win
  over conflicting `MSMTP_SET_DEFAULT=true` markers for the current deploy,
  and documented that install-time default resolution does not rewrite account
  files
- moved the persistent default account out of `accounts/*.env` and into
  `accounts/.default-account`, updated the guided flows to manage that file,
  and kept `DEFAULT_ACCOUNT=...` as a one-off render/install override
- added clearer `password_file` path choices in guided account setup, plus
  absolute-path normalization, `~` expansion, and an optional gitignored
  `passwords/` convenience directory for repo-local plaintext password files
- clarified the quick-start docs around the primary `make configure` plus live
  test-email path, moved `make check` into secondary repo-automation
  verification, and aligned the agent guidance with canonical repo-root path
  handling and current onboarding behavior
- fixed generated `msmtprc` ordering so the default-account alias is rendered
  after the account blocks, reserved `MSMTP_ACCOUNT_NAME=default`, and updated
  starter examples plus guided setup to use non-reserved names such as
  `primary` for `accounts/default.env`
- updated `make configure` to offer an optional live `test-email` step before
  exit, and clarified in the docs that standalone `make test-email` is the
  manual resend path
- added `make test-live-email` as a separate deployment-level verification
  command that uses the actual installed live config path, and wired
  `make configure` to use that path-aware test after install
- updated `make configure` so existing file-backed secrets no longer eject the
  workflow immediately; it now offers guided rotate, validate, skip, or retry
  choices when a configured password or GPG file already exists
- updated `make configure` so it can add or edit multiple accounts before one
  final install step, and aligned the quick-start, command reference, and
  agent drift guidance with that multi-account human workflow
- added a self-contained `scripts/bootstrap.sh` entrypoint for optional
  clone-plus-install onboarding, documented the supported package managers and
  current no-hosted-URL limitation, and aligned the quick-start plus agent
  guidance with that optional bootstrap path
- switched the canonical clone and bootstrap repository URL to the public
  GitHub remote
- promoted the GitHub raw bootstrap command to a supported quick-start entry
  point and aligned the bootstrap docs plus agent guidance with that public
  onboarding path
- refined the guided configure flow so post-account menus default to deploy,
  secret handling can return to the account menu, GPG setup can return to
  secret-method selection, live-config tests reuse the install target, and
  successful configuration ends with an explicit completion message
- condensed the root README into a focused quick-start guide and moved detailed
  command, account, secret, and layout references to the existing docs
- hardened the repo-local `passwords/` plaintext-secret option so password-file
  init and rotation enforce mode `700` on the directory automatically while
  keeping secret files at mode `600`
- added a dedicated `make test-email` workflow that prompts for one account,
  defaults the recipient to that account's `from` address, sends a real test
  email from a temporary one-account render, and replaced raw `msmtp` test
  commands in the quick-start docs with that guided path
- renamed the restore command surface around a new `make restore` umbrella,
  added typed config/account/secret restore commands, documented the `Makefile`
  command surface in `docs/makefile.md`, and tightened agent rules so quick-
  start and command-reference docs stay in sync with workflow changes
- changed generated backup filenames to use a more human-readable UTC timestamp
  format such as `2026-04-27T15-30-00Z`
- updated interactive restore menus to show friendlier backup labels in the
  user's local timezone when available, while still including the original
  backup filename and falling back to UTC if local conversion is unavailable

## 2026-04-27

- added a thin root `AGENTS.md` wrapper that routes into canonical repo
  guidance
- added canonical `agents/rules/`, `agents/context/`, and
  `agents/workflows/` directories with baseline repository operating documents
- added human-oriented `docs/` content and major directory `README.md` files
- rewrote the root `README.md` to reflect the repository's actual current state
- added `.env.example`, credential-mode example env files, and the canonical
  `templates/msmtprc.template`
- added shell automation for quickstart, rendering, and install flows plus a
  `Makefile` entrypoint
- added smoke tests covering the supported `passwordeval` modes and install path
- updated docs and agent context to reflect the repo's first implementation
  slice
- converted Markdown file references to relative links for better repo
  navigation
- added canonical rule and workflow guidance for using relative Markdown links
  in repo documents
- added an interactive setup script, optional symlink install mode, and manual
  `msmtprc` fallback documentation
- renamed the primary `make` targets to cleaner user-facing commands while
  keeping compatibility aliases
- added multi-account rendering via `accounts/*.env` files and shared
  generate/install flows
- added secret-backend setup docs plus safe helper commands for validation,
  Keychain, password files, and GPG files
- tightened agent context/workflow guidance for current repo maturity and
  account/secret drift review
- rewrote the quick-start docs into a linear clone-to-test-email flow with
  single-purpose copy/paste command blocks
- added backup-and-confirm install safety, an explicit system install target,
  and aligned agent guidance for quick-start/install drift
- added backup restore commands and documented that install scope lives in
  `make` targets and variables rather than account env files
- added guided `make account`, `make password`, `make install`, and
  `make restore` flows on top of the explicit low-level commands
- simplified the repository to an accounts-only model, removed root `.env`
  as a first-class source, added a canonical default example under
  `templates/examples/`, and aligned docs/tests/agent context with the new
  workflow
- added a dedicated `make rotate-password` flow that safely rotates supported
  secret backends and validates them after replacement
