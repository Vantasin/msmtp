# Architecture

The repository is organized around three distinct layers:

1. `AGENTS.md` as the thin platform-facing wrapper
2. `agents/` as the canonical operating core for agent guidance
3. `docs/` as the human-readable explanation layer

Implementation-oriented directories exist as placeholders so future work lands
in predictable locations:

- `templates/`
- `scripts/`
- `tests/`

This keeps repository policy, documentation, and implementation concerns
separated from each other.
