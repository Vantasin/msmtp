# Agent Governance

The repository's agent governance model is:

- thin wrapper at the edge
- canonical source of truth in `agents/`
- human-readable supporting documentation in `docs/`
- drift review after significant changes
- changelog entries for meaningful structural or operational updates

The wrapper should not become a second instruction system. If guidance becomes
durable, it belongs in `agents/` and the wrapper should point to it.
