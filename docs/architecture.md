# Architecture

The repository is organized around three distinct layers:

1. [AGENTS.md](../AGENTS.md) as the thin platform-facing wrapper
2. [`agents/`](../agents/) as the canonical operating core for agent guidance
3. [`docs/README.md`](./README.md) as the human-readable explanation layer

Implementation-oriented directories provide the working repository surface:

- [`accounts/`](../accounts/) for local per-account env files in multi-account
  setups
- [`templates/`](../templates/) for env examples and `msmtprc` generation
- [`scripts/`](../scripts/) for bootstrap, render, multi-account generation,
  and install automation
- [`tests/`](../tests/) for shell-based smoke tests
- the root [`Makefile`](../Makefile) as a stable human entrypoint

This keeps repository policy, documentation, and implementation concerns
separated from each other.
