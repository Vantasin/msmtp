# Agent Entrypoint

This repository uses a thin-wrapper model.

Canonical instructions live in:

- [`agents/rules/`](./agents/rules/)
- [`agents/context/`](./agents/context/)
- [`agents/workflows/`](./agents/workflows/)

Start with:

- [`agents/README.md`](./agents/README.md)
- [`agents/rules/repo-rules.md`](./agents/rules/repo-rules.md)
- [`agents/context/project-overview.md`](./agents/context/project-overview.md)
- [`agents/context/current-state.md`](./agents/context/current-state.md)
- [`agents/workflows/onboard-new-task.md`](./agents/workflows/onboard-new-task.md)

Instruction precedence for this repository is:

1. system or platform-level instructions
2. direct user requests for the current task
3. this wrapper file
4. [`agents/rules/`](./agents/rules/)
5. [`agents/workflows/`](./agents/workflows/)
6. [`agents/context/`](./agents/context/)
7. local directory `README.md` files
8. temporary or non-canonical working notes

When making significant repository changes:

- review for documentation and instruction drift
- update affected directory `README.md` files
- record meaningful changes in [CHANGELOG.md](./CHANGELOG.md)
