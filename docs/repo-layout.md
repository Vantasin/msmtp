# Repo Layout

## Root

- [README.md](../README.md): quick-start overview for humans
- [AGENTS.md](../AGENTS.md): thin entrypoint for agent platforms
- [CHANGELOG.md](../CHANGELOG.md): auditable summary of meaningful repository
  changes
- [`.env.example`](../.env.example): generic starter configuration
- [`accounts/README.md`](../accounts/README.md): multi-account env-file model
- [Makefile](../Makefile): common setup, generate, install, preview, link, and
  check commands

## Canonical Guidance

- [`agents/rules/`](../agents/rules/): constraints and standards
- [`agents/context/`](../agents/context/): durable background knowledge
- [`agents/workflows/`](../agents/workflows/): repeatable maintenance
  procedures

## Human Docs

- [`docs/README.md`](./README.md): explanation layer for humans and reviewers

## Implementation Areas

- [`accounts/`](../accounts/): local multi-account env files
- [`templates/`](../templates/): config templates and env examples
- [`scripts/`](../scripts/): repeatable automation for quickstart, interactive
  setup, multi-account render, and install
- [`tests/`](../tests/): repository verification assets
