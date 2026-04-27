# Changelog

## 2026-04-27

- added a thin root `AGENTS.md` wrapper that routes into canonical repo
  guidance
- added canonical `agents/rules/`, `agents/context/`, and
  `agents/workflows/` directories with baseline repository operating documents
- added human-oriented `docs/` content and major directory `README.md` files
- rewrote the root `README.md` to reflect the repository's actual current state
- added `.env.example`, credential-mode example env files, and the canonical
  `templates/msmtprc.template`
- added shell automation for quickstart, rendering, and install flows plus a
  `Makefile` entrypoint
- added smoke tests covering the supported `passwordeval` modes and install path
- updated docs and agent context to reflect the repo's first implementation
  slice
- converted Markdown file references to relative links for better repo
  navigation
- added canonical rule and workflow guidance for using relative Markdown links
  in repo documents
- added an interactive setup script, optional symlink install mode, and manual
  `msmtprc` fallback documentation
- renamed the primary `make` targets to cleaner user-facing commands while
  keeping compatibility aliases
- added multi-account rendering via `accounts/*.env` files and shared
  generate/install flows
