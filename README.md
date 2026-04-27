# msmtp

`msmtp` is a cross-platform repository for managing reproducible `msmtp`
configuration assets for Linux and macOS.

This repository now follows a thin-wrapper agent model:

- root platform wrapper in `AGENTS.md`
- canonical agent guidance in `agents/`
- human-oriented documentation in `docs/`
- auditable change tracking in `CHANGELOG.md`

## Who This Repo Is For

This repo is for:

- maintainers building out portable `msmtp` configuration assets
- humans onboarding into the repository structure
- AI agents operating against a documented, auditable repository contract

## Current Status

The repository currently contains the operating scaffold and documentation
baseline. Implementation assets such as templates, scripts, tests, or a
`Makefile` have not been added yet and should not be assumed to exist.

## Agent Platform Adapter

The current platform-facing adapter is:

- `AGENTS.md`

That file is intentionally thin and routes into the canonical instruction set
under `agents/`.

## Directory Layout

```text
.
├── AGENTS.md
├── CHANGELOG.md
├── README.md
├── agents/
│   ├── context/
│   ├── rules/
│   └── workflows/
├── docs/
│   └── component-guides/
├── scripts/
├── templates/
└── tests/
```

## Start Here

1. Read `README.md` for the quick-start repository overview.
2. Read `docs/README.md` for the human documentation index.
3. Read `agents/README.md` for the canonical agent operating model.
4. Use `agents/context/current-state.md` before planning implementation work.

## Documentation Map

- `docs/architecture.md`: repository architecture and boundaries
- `docs/operating-model.md`: how humans and agents should work in this repo
- `docs/repo-layout.md`: what each major directory is for
- `docs/agent-governance.md`: source-of-truth and drift-review expectations
- `docs/component-guides/README.md`: focused notes on major repository areas
