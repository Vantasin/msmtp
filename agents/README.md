# Agents

This directory is the canonical source of truth for long-lived agent guidance
in this repository.

The structure is intentionally split by purpose:

- `rules/`: durable constraints, standards, and guardrails
- `context/`: durable background knowledge about the repo and domain
- `workflows/`: repeatable task procedures

Recommended reading order:

1. `rules/repo-rules.md`
2. `context/project-overview.md`
3. `context/current-state.md`
4. `workflows/onboard-new-task.md`

Platform-specific wrapper files should stay thin and reference this directory
instead of duplicating its contents.
