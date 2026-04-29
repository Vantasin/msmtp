# Repository Rules

## Purpose

These rules define the durable operating expectations for work in this
repository.

## Instruction Precedence

If instructions conflict, use this order:

1. system or platform-level instructions
2. direct user requests for the current task
3. [AGENTS.md](../../AGENTS.md)
4. files in [`agents/rules/`](./)
5. files in [`agents/workflows/`](../workflows/)
6. files in [`agents/context/`](../context/)
7. local directory `README.md` files
8. temporary or non-canonical notes

Do not silently merge contradictory instructions.

## Operating Expectations

- Treat [`agents/`](../) as the canonical source of long-lived agent guidance.
- Keep [AGENTS.md](../../AGENTS.md) thin; do not turn it into a second
  instruction system.
- Prefer current repository reality over aspirational or stale documentation.
- Do not claim files, commands, or workflows exist unless they are present.
- Keep documentation readable to humans, not only agents.
- Keep the quick-start guides in [README.md](../../README.md) and
  [docs/getting-started.md](../../docs/getting-started.md) aligned with the
  current human setup flow at all times.
- Do not claim a hosted `curl` bootstrap URL exists unless the repository
  actually publishes one. When it does, keep the documented public URL and the
  bootstrap script behavior in sync.
- Keep SMTP account definition in `accounts/*.env`, and keep deployment choices
  such as user vs system install targets in command-level configuration rather
  than tracked account files.
- Keep the persistent default account in `accounts/.default-account`, and keep
  one-off render/install overrides in command-level configuration rather than
  rewriting account env files.
- Keep `MSMTP_ACCOUNT_NAME` unique across `accounts/*.env`, because generated
  `msmtprc` account blocks and the persistent default pointer both depend on
  that identity being unambiguous.
- Treat `MSMTP_ACCOUNT_NAME=default` as reserved by `msmtp`. The repo may use
  `accounts/default.env` as a file-name convention, but the account name
  inside that file should use another stable label such as `primary`.
- Keep deployment-time default-account resolution in install/configure flows,
  and do not silently rewrite `accounts/*.env` or `accounts/.default-account`
  just to satisfy one deploy.
- Keep interactive CLI prompts concise. Prefer one focused prompt or menu with
  recommendation text inline over separate guidance blocks that restate the
  same choices.
- Keep the `Makefile` command surface explicit and documented. Do not add
  compatibility aliases for renamed targets unless the user explicitly changes
  the no-alias policy.
- When showing or storing repo-local file paths, canonicalize them through the
  shared helpers so the saved path does not depend on shell-specific or
  case-insensitive filesystem spellings.
- When modifying repo-owned file-writing or deployment scripts, preserve the
  shared atomic-replacement patterns in [`scripts/lib/common.sh`](../../scripts/lib/common.sh)
  instead of introducing ad hoc in-place mutation.
- When changing install, restore, or file-backed secret rotation flows,
  preserve recoverable `.bak.*` behavior unless the user explicitly requests a
  different model.

## Repository Truthfulness

- If implementation assets are missing, say so explicitly in docs.
- When new scripts, templates, tests, or automation are added, update the
  relevant documentation in the same change when practical.
- If a lower-precedence document is stale, update it rather than working around
  the drift silently.
