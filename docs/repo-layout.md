# Repo Layout

## Root

- [README.md](../README.md): quick-start overview for humans
- [AGENTS.md](../AGENTS.md): thin entrypoint for agent platforms
- [CHANGELOG.md](../CHANGELOG.md): auditable summary of meaningful repository
  changes
- [Makefile](../Makefile): common setup, generate, install, preview, link, and
  check commands plus secret helper commands

## Canonical Guidance

- [`agents/rules/`](../agents/rules/): constraints and standards
- [`agents/context/`](../agents/context/): durable background knowledge
- [`agents/workflows/`](../agents/workflows/): repeatable maintenance
  procedures

## Human Docs

- [`docs/README.md`](./README.md): explanation layer for humans and reviewers

## Implementation Areas

- [`accounts/`](../accounts/): the canonical local account-file workspace
- [`templates/`](../templates/): config templates and account-file examples
- [`scripts/`](../scripts/): repeatable automation for quickstart, interactive
  setup, render, install, restore, and secret workflows
- [`tests/`](../tests/): repository verification assets
