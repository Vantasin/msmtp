# Operating Model

The repository uses a thin-wrapper model for agent onboarding.

In practice this means:

- platform-facing agent files should stay minimal
- durable rules belong in `agents/rules/`
- durable background context belongs in `agents/context/`
- repeatable procedures belong in `agents/workflows/`
- human-oriented explanations belong in `docs/`

When the repository changes meaningfully, maintainers should:

- update affected docs
- update local directory `README.md` files when directory purpose changes
- review for drift across wrapper, canonical guidance, and human docs
- record meaningful repository changes in `CHANGELOG.md`
