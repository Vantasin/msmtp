# Architecture Context

This repository uses a thin-wrapper architecture for agent instructions:

- `AGENTS.md` is the platform-facing entrypoint
- `agents/` is the canonical source of truth for long-lived guidance
- `docs/` is the human-readable explanation layer

Operational project assets are expected to live in focused directories such as:

- `templates/` for configuration examples and sample assets
- `scripts/` for repeatable automation
- `tests/` for verification logic

This separation keeps policy, explanation, and implementation distinct.
