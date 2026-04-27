# Review Drift

Use this workflow after significant repository changes.

1. Identify what changed and which directories or instructions it affects.
2. Review [AGENTS.md](../../AGENTS.md) for stale references or missing routing
   notes.
3. Review [`agents/rules/`](../rules/), [`agents/context/`](../context/), and
   [`agents/workflows/`](./) for outdated assumptions.
4. Review [`docs/README.md`](../../docs/README.md) and major directory
   `README.md` files for mismatches.
5. Update documents that drifted and note meaningful changes in
   [CHANGELOG.md](../../CHANGELOG.md).
