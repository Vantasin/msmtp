# msmtp

`msmtp` is a cross-platform repository for generating, testing, and installing
reproducible `msmtp` configuration on Linux and macOS.

It ships with:

- `.env`-driven configuration as the primary source of truth
- a template-based `msmtprc` renderer
- an optional interactive setup guide that writes `.env` step by step
- `passwordeval` support for macOS Keychain, Linux GPG, secure password files,
  and custom commands
- cleaner [`Makefile`](./Makefile) commands for setup, generate, install,
  link, preview, and check
- copy-based install by default, with optional symlink install for centralized
  repo-managed configs
- smoke tests that validate rendered config without needing a live SMTP account

## Quick Start

1. Install `msmtp` on your machine using your platform package manager.
2. Choose a setup path:

```bash
make setup-example EXAMPLE=macos-keychain
make setup
```

`make setup-example` is the non-interactive bootstrap path. `make setup` is
the interactive prompt-driven path. Both produce a local `.env` file.

3. Review `.env` and adjust any values that need to change.
4. Validate the repo behavior:

```bash
make check
```

5. Render or install the config:

```bash
make generate
make install
```

By default, `make install` writes to `~/.msmtprc` and keeps a rendered copy in
`.msmtprc.generated`. For a repo-centralized advanced setup, you can install a
symlink instead:

```bash
make link
```

The env/template layer is intentional. `msmtp` reads `~/.msmtprc`, but keeping
structured inputs in `.env` plus a template makes setup reproducible, testable,
and easier to document.

## Credential Modes

Choose one `MSMTP_SECRET_METHOD` in `.env`:

- `keychain`: macOS Keychain lookup via `security find-generic-password`
- `gpg`: decrypt a GPG-encrypted password file
- `password_file`: read from a secure root-owned plaintext file
- `command`: run a custom `passwordeval` command directly

Starter examples live in [`templates/examples/`](./templates/examples/).

## Tracking and Safety

Generated or personalized `msmtprc` files should stay untracked. The repo
ignores local `.env.*` files and `.msmtprc*` outputs so private account details
and local secret paths do not get committed accidentally.

## Main Files

- [`.env.example`](./.env.example): generic starter env file
- [`Makefile`](./Makefile): common repo entrypoints
- [`templates/msmtprc.template`](./templates/msmtprc.template): canonical
  config template
- [`scripts/setup.sh`](./scripts/setup.sh): interactive setup that writes a
  local `.env`
- [`scripts/render-config.sh`](./scripts/render-config.sh): generate a
  concrete config file
- [`scripts/install.sh`](./scripts/install.sh): render and install the config
- [`scripts/quickstart.sh`](./scripts/quickstart.sh): bootstrap `.env` from a
  chosen example
- [`tests/test.sh`](./tests/test.sh): repo smoke tests

## Repo Layout

```text
.
├── .env.example
├── Makefile
├── AGENTS.md
├── CHANGELOG.md
├── README.md
├── agents/
├── docs/
├── scripts/
├── templates/
└── tests/
```

## Documentation

- [`docs/getting-started.md`](./docs/getting-started.md): setup and usage
  walkthrough
- [`docs/manual-setup.md`](./docs/manual-setup.md): raw `msmtprc` fallback
  guide
- [`docs/architecture.md`](./docs/architecture.md): repository architecture
  and boundaries
- [`docs/repo-layout.md`](./docs/repo-layout.md): what each major directory is
  for
- [`docs/agent-governance.md`](./docs/agent-governance.md): source-of-truth
  and drift-review expectations
- [`agents/README.md`](./agents/README.md): canonical agent operating guidance
