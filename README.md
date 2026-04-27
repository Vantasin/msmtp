# msmtp

`msmtp` is a cross-platform repository for generating, testing, and installing
reproducible `msmtp` configuration on Linux and macOS.

It ships with:

- `.env`-driven configuration
- a template-based `msmtprc` renderer
- `passwordeval` support for macOS Keychain, Linux GPG, secure password files,
  and custom commands
- [`Makefile`](./Makefile) targets for quickstart, render, install, update,
  and test
- smoke tests that validate rendered config without needing a live SMTP account

## Quick Start

1. Install `msmtp` on your machine using your platform package manager.
2. Initialize a local env file:

```bash
make quickstart EXAMPLE=macos-keychain
```

3. Edit `.env` and replace the placeholder values.
4. Validate the repo behavior:

```bash
make test
```

5. Render or install the config:

```bash
make render
make install
```

By default, `make install` writes to `~/.msmtprc` and keeps a rendered copy in
`.msmtprc.generated`.

## Credential Modes

Choose one `MSMTP_SECRET_METHOD` in `.env`:

- `keychain`: macOS Keychain lookup via `security find-generic-password`
- `gpg`: decrypt a GPG-encrypted password file
- `password_file`: read from a secure root-owned plaintext file
- `command`: run a custom `passwordeval` command directly

Starter examples live in [`templates/examples/`](./templates/examples/).

## Main Files

- [`.env.example`](./.env.example): generic starter env file
- [`Makefile`](./Makefile): common repo entrypoints
- [`templates/msmtprc.template`](./templates/msmtprc.template): canonical
  config template
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
- [`docs/architecture.md`](./docs/architecture.md): repository architecture
  and boundaries
- [`docs/repo-layout.md`](./docs/repo-layout.md): what each major directory is
  for
- [`docs/agent-governance.md`](./docs/agent-governance.md): source-of-truth
  and drift-review expectations
- [`agents/README.md`](./agents/README.md): canonical agent operating guidance
