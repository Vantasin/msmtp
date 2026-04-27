# Agent Governance

The repository's agent governance model is:

- thin wrapper at the edge through [AGENTS.md](../AGENTS.md)
- canonical source of truth in [`agents/`](../agents/)
- human-readable supporting documentation in [`docs/README.md`](./README.md)
- drift review after significant changes
- changelog entries for meaningful structural or operational updates

The wrapper should not become a second instruction system. If guidance becomes
durable, it belongs in [`agents/`](../agents/) and the wrapper should point to
it.
