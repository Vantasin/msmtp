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
5. If the change affects onboarding, account management, password setup,
   install, restore, or verification flows, explicitly review
   [README.md](../../README.md) and
   [docs/getting-started.md](../../docs/getting-started.md) for linear,
   actionable quick-start drift. Keep the primary `make configure` path clear,
   note when it can loop through multiple accounts before one install step,
   note when it includes an optional test-email step, describe `make test-email`
   as the standalone isolated-account resend/manual path when relevant,
   describe `make test-live-email` as the deployment-level installed-config
   verification path when relevant, describe `make check` as repo automation
   verification rather than live SMTP verification when relevant, review
   [docs/makefile.md](../../docs/makefile.md) when the command surface changes,
   and review [docs/bootstrap.md](../../docs/bootstrap.md) when onboarding or
   first-run automation changes.
6. If the change affects accounts or secret handling, explicitly review
   [accounts/README.md](../../accounts/README.md) and
   [docs/secrets.md](../../docs/secrets.md). If repo-local plaintext password
   paths are involved, also review [passwords/README.md](../../passwords/README.md).
7. If the change affects guided install or default-account selection, confirm
   the docs and prompts still describe install-time default resolution
   accurately, keep the account-management vs deployment boundary clear, and
   account for `accounts/.default-account` when persistent default behavior
   changes.
8. If the change affects file-writing semantics, install/restore safety, or
   interruption handling, explicitly review
   [agents/context/current-state.md](../context/current-state.md),
   [agents/context/architecture-context.md](../context/architecture-context.md),
   [agents/rules/repo-rules.md](../rules/repo-rules.md), and
   [agents/rules/safety-rules.md](../rules/safety-rules.md).
9. Update documents that drifted and note meaningful changes in
   [CHANGELOG.md](../../CHANGELOG.md).
