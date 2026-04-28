# Review Drift

Use this workflow after significant repository changes.

1. Identify what changed and which directories or instructions it affects.
2. Review [AGENTS.md](../../AGENTS.md) for stale references or missing routing
   notes.
3. Review [`agents/rules/`](../rules/), [`agents/context/`](../context/), and
   [`agents/workflows/`](./) for outdated assumptions.
4. Review [`docs/README.md`](../../docs/README.md) and major directory
   `README.md` files for mismatches and non-navigable repo references that
   should be relative Markdown links.
5. If the change affects onboarding, setup, install, restore, or verification
   flows, explicitly review [README.md](../../README.md) and
   [docs/getting-started.md](../../docs/getting-started.md) for linear,
   actionable quick-start drift.
6. If the change affects accounts or secret handling, explicitly review
   [accounts/README.md](../../accounts/README.md) and
   [docs/secrets.md](../../docs/secrets.md).
7. Update documents that drifted and note meaningful changes in
   [CHANGELOG.md](../../CHANGELOG.md).
