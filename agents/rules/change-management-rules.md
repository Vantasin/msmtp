# Change Management Rules

## Changelog

- Record meaningful repository changes in [CHANGELOG.md](../../CHANGELOG.md).
- Focus on structural, operational, documentation, or workflow changes rather
  than mirroring every commit.

## Drift Review

Run a drift review after significant changes, including:

- repository restructuring
- new workflows or automation
- major documentation changes
- additions that invalidate existing assumptions

The review should check:

- [AGENTS.md](../../AGENTS.md)
- [`agents/rules/`](./)
- [`agents/context/`](../context/)
- [`agents/workflows/`](../workflows/)
- [`docs/README.md`](../../docs/README.md)
- major directory `README.md` files
