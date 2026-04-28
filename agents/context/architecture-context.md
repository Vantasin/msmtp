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
  secret setup, interactive setup, render, and install
- [`tests/`](../../tests/) for shell-based verification logic

The current implementation flow is:

1. create one or more account files under [`accounts/`](../../accounts/) using
   an example, the interactive setup script, or the guided account manager
2. provision or verify the chosen secret backend using
   [docs/secrets.md](../../docs/secrets.md)
3. render [`templates/msmtprc.template`](../../templates/msmtprc.template)
4. install the generated output to the desired `msmtp` config path, using copy
   mode by default or symlink mode as an advanced option
5. validate behavior through repository smoke tests
6. fall back to [manual docs](../../docs/manual-setup.md) when direct
   `msmtprc` setup is needed

This separation keeps policy, explanation, and implementation distinct.
