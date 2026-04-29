# Update Docs

1. Decide whether the change belongs in [README.md](../../README.md),
   [`docs/README.md`](../../docs/README.md), [`agents/`](../), local directory
   `README.md` files, or several of them.
2. Keep the root [README.md](../../README.md) high-level and human-first.
3. Keep quick-start and onboarding instructions linear, end-to-end, and built
   from single-purpose copy/paste blocks.
4. Keep the quick-start path centered on the primary human workflow, and make
   it clear when a command verifies repo automation rather than the live SMTP
   setup.
5. When the `Makefile` command surface changes, update
   [docs/makefile.md](../../docs/makefile.md).
6. Use relative Markdown links for repo-internal file and directory references
   when the reference should help navigation.
7. Put durable agent policy in [`agents/rules/`](../rules/).
8. Put explanatory background in [`agents/context/`](../context/).
9. Put repeatable procedures in [`agents/workflows/`](./).
10. Keep human docs and canonical agent guidance consistent.
