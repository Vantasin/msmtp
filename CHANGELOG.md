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
