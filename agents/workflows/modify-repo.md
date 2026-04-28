# Modify Repo

1. Inspect the current repository state before editing.
2. Make focused changes that match the actual scope of the task.
3. Update affected documentation in the same change when practical.
4. When changing file-writing or deployment scripts, prefer the shared
   atomic-replacement and interruption-handling helpers over duplicating custom
   logic.
5. When changing interactive CLI workflows, keep prompts concise and keep
   deployment-only choices such as install-time default-account overrides out
   of the account env files, while keeping persistent default-account behavior
   aligned with `accounts/.default-account`.
6. Run the relevant smoke tests or script-level verification for the changed
   workflows whenever feasible.
7. If the change is structurally meaningful, update
   [CHANGELOG.md](../../CHANGELOG.md).
8. Run a drift review when the change affects repository structure, workflows,
   or canonical guidance.
