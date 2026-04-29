# Documentation Rules

- The root [README.md](../../README.md) is the human-first quick-start guide.
- Quick-start and onboarding docs should prefer a linear end-to-end flow and
  use single-purpose copy/paste blocks instead of mixing multiple options in a
  single command block.
- Quick-start docs are mandatory sync targets whenever onboarding, credential
  setup, install, restore, validation, or the human command surface changes.
- Quick-start docs should center the primary human setup path and distinguish
  clearly between live service validation and repo-self-tests.
- When the `Makefile` command surface changes, update
  [docs/makefile.md](../../docs/makefile.md) in the same change.
- [`docs/README.md`](../../docs/README.md) contains human-readable explanatory
  documentation and should not become a duplicate of every canonical rule.
- Major or non-obvious directories should include a local `README.md`.
- Use relative Markdown links for repo-internal file and directory references
  when the reference is meant to be navigable.
- Documentation should describe the current repository state accurately.
- Significant repository changes should trigger a documentation review.
- When a change affects how agents operate, update both human docs and canonical
  agent guidance as needed.
