# Architecture

The repository is organized around three distinct layers:

1. `AGENTS.md` as the thin platform-facing wrapper
2. `agents/` as the canonical operating core for agent guidance
3. `docs/` as the human-readable explanation layer

Implementation-oriented directories provide the working repository surface:

- `templates/` for env examples and `msmtprc` generation
- `scripts/` for bootstrap, render, and install automation
- `tests/` for shell-based smoke tests
- the root `Makefile` as a stable human entrypoint

This keeps repository policy, documentation, and implementation concerns
separated from each other.
