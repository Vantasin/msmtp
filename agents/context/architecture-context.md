# Architecture Context

This repository uses a thin-wrapper architecture for agent instructions:

- [AGENTS.md](../../AGENTS.md) is the platform-facing entrypoint
- [`agents/`](../) is the canonical source of truth for long-lived guidance
- [`docs/README.md`](../../docs/README.md) is the human-readable explanation
  layer

Operational project assets live in focused directories:

- [`accounts/`](../../accounts/) for local per-account account files
- [`templates/`](../../templates/) for `msmtp` config generation assets and
  account-file examples
- [`scripts/`](../../scripts/) for repeatable automation such as bootstrap,
  secret setup, interactive setup, account-only management, guided configure,
  render, install, and typed restore flows
- [`tests/`](../../tests/) for shell-based verification logic with
  human-readable smoke-check output

The current implementation flow is:

1. create one or more account files under [`accounts/`](../../accounts/) using
   an example, the interactive setup script, the guided account manager, or the
   end-to-end configure flow
2. provision or verify the chosen secret backend using
   [docs/secrets.md](../../docs/secrets.md)
3. render [`templates/msmtprc.template`](../../templates/msmtprc.template)
4. install the generated output to the desired `msmtp` config path, using copy
   mode by default or symlink mode as an advanced option, while resolving the
   effective default account from `accounts/.default-account` or an explicit
   install-time override when needed
5. validate the live SMTP setup with a test email, and optionally run the
   repository smoke tests when you want a numbered report of the automation
   behaviors that still pass
6. fall back to [manual docs](../../docs/manual-setup.md) when direct
   `msmtprc` setup is needed

The `make` command surface is documented in [docs/makefile.md](../../docs/makefile.md).

Implementation safety expectations now include:

- repo-owned file writes should prefer same-directory temp-and-rename
  replacement
- install, restore, and file-backed secret rotation should preserve adjacent
  backup files rather than leaving a missing live target window
- interactive interruption handling should distinguish between prompt-only
  cancellation and cancellation after state-changing steps
- deployment-time default-account choices should resolve install ambiguity
  without silently rewriting account files or the persistent default pointer
- repo-local file paths that are shown to users or saved into account files
  should be normalized through shared helpers so they stay canonical across
  macOS and Linux

This separation keeps policy, explanation, and implementation distinct.
