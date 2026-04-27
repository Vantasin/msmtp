# Architecture Context

This repository uses a thin-wrapper architecture for agent instructions:

- `AGENTS.md` is the platform-facing entrypoint
- `agents/` is the canonical source of truth for long-lived guidance
- `docs/` is the human-readable explanation layer

Operational project assets live in focused directories:

- `templates/` for `msmtp` config generation assets and env examples
- `scripts/` for repeatable automation such as bootstrap, render, and install
- `tests/` for shell-based verification logic

The current implementation flow is:

1. initialize a local `.env` from `.env.example` or a mode-specific example
2. render `templates/msmtprc.template`
3. install the generated output to the desired `msmtp` config path
4. validate behavior through repository smoke tests

This separation keeps policy, explanation, and implementation distinct.
