# Architecture Context

This repository uses a thin-wrapper architecture for agent instructions:

- [AGENTS.md](../../AGENTS.md) is the platform-facing entrypoint
- [`agents/`](../) is the canonical source of truth for long-lived guidance
- [`docs/README.md`](../../docs/README.md) is the human-readable explanation
  layer

Operational project assets live in focused directories:

- [`accounts/`](../../accounts/) for local per-account env files in
  multi-account setups
- [`templates/`](../../templates/) for `msmtp` config generation assets and
  env examples
- [`scripts/`](../../scripts/) for repeatable automation such as bootstrap,
  interactive setup, multi-account render, and install
- [`tests/`](../../tests/) for shell-based verification logic

The current implementation flow is:

1. initialize a local `.env` from [`.env.example`](../../.env.example), a
   mode-specific example, the interactive setup script, or one env file per
   account in [`accounts/`](../../accounts/)
2. render [`templates/msmtprc.template`](../../templates/msmtprc.template)
3. install the generated output to the desired `msmtp` config path, using copy
   mode by default or symlink mode as an advanced option
4. validate behavior through repository smoke tests
5. fall back to [manual docs](../../docs/manual-setup.md) when direct
   `msmtprc` setup is needed

This separation keeps policy, explanation, and implementation distinct.
