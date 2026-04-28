# Repository Rules

## Purpose

These rules define the durable operating expectations for work in this
repository.

## Instruction Precedence

If instructions conflict, use this order:

1. system or platform-level instructions
2. direct user requests for the current task
3. [AGENTS.md](../../AGENTS.md)
4. files in [`agents/rules/`](./)
5. files in [`agents/workflows/`](../workflows/)
6. files in [`agents/context/`](../context/)
7. local directory `README.md` files
8. temporary or non-canonical notes

Do not silently merge contradictory instructions.

## Operating Expectations

- Treat [`agents/`](../) as the canonical source of long-lived agent guidance.
- Keep [AGENTS.md](../../AGENTS.md) thin; do not turn it into a second
  instruction system.
- Prefer current repository reality over aspirational or stale documentation.
- Do not claim files, commands, or workflows exist unless they are present.
- Keep documentation readable to humans, not only agents.
- Keep SMTP account definition in `.env` or `accounts/*.env`, and keep
  deployment choices such as user vs system install targets in command-level
  configuration rather than tracked account env files.

## Repository Truthfulness

- If implementation assets are missing, say so explicitly in docs.
- When new scripts, templates, tests, or automation are added, update the
  relevant documentation in the same change when practical.
- If a lower-precedence document is stale, update it rather than working around
  the drift silently.
