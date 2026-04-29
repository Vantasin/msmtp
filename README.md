# msmtp

`msmtp` is a cross-platform repository for generating, testing, and installing
reproducible `msmtp` configuration on Linux and macOS.

It uses one canonical model:

- account files live under [`accounts/`](./accounts/)
- rendered `msmtprc` output is generated from that directory
- user vs system install scope is chosen at install time, not stored in account files

It also ships with:

- a template-based `msmtprc` renderer
- an account-only management workflow plus a separate guided human configure flow
- a dedicated password-rotation workflow for supported secret backends
- `passwordeval` support for macOS Keychain, Linux GPG, secure password files,
  and custom commands
- helper commands for secret-backend setup and validation
- safer install flows that back up existing targets before replacement
- absolute-path normalization for file-backed secret paths, including `~`
  expansion and an optional gitignored [`passwords/`](./passwords/) workspace
- smoke tests that validate the generated config without needing a live SMTP
  account

## Quick Start

1. Clone the repo.

```bash
git clone ssh://git@gitea.vantasin.duckdns.org:2222/Vantasin/msmtp.git
cd msmtp
```

2. Install `msmtp`.

macOS with Homebrew:

```bash
brew install msmtp
```

Debian or Ubuntu:

```bash
sudo apt update
sudo apt install msmtp
```

Fedora:

```bash
sudo dnf install msmtp
```

3. Run the guided configure flow.

```bash
make configure
```

This guides you through account setup, secret setup or rotation, validation,
and install. It applies the full account set in [`accounts/`](./accounts/).

Common choices:

- use `keychain` on macOS desktops, `gpg` on Linux desktops, and
  `password_file` on unattended servers
- use user config installs for desktops and single-user setups, and system
  installs for root-managed servers

If you only want to manage account files without deploying anything, use:

```bash
make account
```

Other direct commands remain available:

```bash
make password
make rotate-password
make test-email
make secret-check
make install
make restore
```

4. Send a test email.

```bash
make test-email
```

This command prompts for the account to test, defaults the recipient to that
account's `from` address, and sends a real email using a temporary one-account
render.

If you want to verify the repo automation itself, run:

```bash
make check
```

`make check` validates the repository scripts and generated-config behavior. It
does not send mail or verify your live SMTP credentials.

If you want the longer walkthrough or backend-specific secret setup details,
continue with [docs/getting-started.md](./docs/getting-started.md) and
[docs/secrets.md](./docs/secrets.md).

## Account Model

This repo intentionally uses `accounts/` as the only source of account truth.

- `accounts/default.env` is the simplest single-account setup
- `accounts/work.env` and `accounts/personal.env` are typical multi-account files
- `make generate` and `make install` operate on the whole directory
- `make secret-check` can validate the whole directory or one account when you pass `ACCOUNT_NAME=...`
- `accounts/.default-account` stores the persistent default account when you do not pass `DEFAULT_ACCOUNT=...`
- each account file must use a unique `MSMTP_ACCOUNT_NAME`

When you create the first account through the guided setup flows, the repo
initializes [`accounts/.default-account`](./accounts/) automatically. Use
`make account` to review or change that persistent default later, or pass
`DEFAULT_ACCOUNT=...` for a one-off render or install override.

If the persistent default is missing or stale, guided `make install` can choose
one for the current deploy without rewriting the stored account data.

## Credential Modes

Choose one `MSMTP_SECRET_METHOD` per account file:

- `keychain`: macOS Keychain lookup via `security find-generic-password`
- `gpg`: decrypt a GPG-encrypted password file
- `password_file`: read from a secure password file
- `command`: run a custom `passwordeval` command directly

Starter examples live in [`templates/examples/`](./templates/examples/).

For file-backed secrets:

- `make account` and `make configure` now offer clear path choices for
  `password_file`
- user-owned password files default to `$HOME/.local/state/msmtp/<account>.password`
- a repo-local gitignored [`passwords/`](./passwords/) option is available for
  convenience
- system installs can use `/etc/msmtp/<account>.password`
- custom paths are normalized to absolute paths, and a leading `~` expands to
  your home directory before the path is saved or rendered

## Tracking and Safety

Generated or personalized `msmtprc` files should stay untracked. The repo
ignores `accounts/*.env` and `.msmtprc*` outputs so private account details and
local secret paths do not get committed accidentally. The optional
[`passwords/`](./passwords/) directory is also ignored so repo-local plaintext
password files stay out of Git.

## Main Files

- [`accounts/README.md`](./accounts/README.md): canonical account-file model
- [`Makefile`](./Makefile): common repo entrypoints
- [`scripts/account-manager.sh`](./scripts/account-manager.sh): guided account
  management without deployment
- [`scripts/configure.sh`](./scripts/configure.sh): guided human workflow for
  account, secret, validation, and install
- [`scripts/password-helper.sh`](./scripts/password-helper.sh): choose an
  account file and dispatch to the correct password helper
- [`scripts/rotate-password.sh`](./scripts/rotate-password.sh): rotate an
  existing secret safely and validate it
- [`scripts/test-email.sh`](./scripts/test-email.sh): send a real test email
  for one selected account using a temporary one-account render
- [`templates/msmtprc.template`](./templates/msmtprc.template): canonical
  config template
- [`scripts/setup.sh`](./scripts/setup.sh): interactive setup that writes one
  account file
- [`scripts/render-config.sh`](./scripts/render-config.sh): generate a
  concrete config file from `accounts/`
- [`scripts/install-helper.sh`](./scripts/install-helper.sh): guided install
  flow for choosing target and install mode
- [`scripts/install.sh`](./scripts/install.sh): render and install the config
- [`scripts/restore-helper.sh`](./scripts/restore-helper.sh): guided restore
  umbrella for choosing backup type
- [`scripts/restore-config-helper.sh`](./scripts/restore-config-helper.sh):
  guided restore flow for live config targets
- [`scripts/restore-account-helper.sh`](./scripts/restore-account-helper.sh):
  guided restore flow for `accounts/*.env` backups
- [`scripts/restore-secret-helper.sh`](./scripts/restore-secret-helper.sh):
  guided restore flow for file-backed secret backups
- [`scripts/restore-backup.sh`](./scripts/restore-backup.sh): restore a
  backed-up live config target
- [`scripts/quickstart.sh`](./scripts/quickstart.sh): bootstrap one account
  file from a chosen example
- [`tests/test.sh`](./tests/test.sh): repo smoke tests

## Repo Layout

```text
.
├── Makefile
├── AGENTS.md
├── CHANGELOG.md
├── README.md
├── accounts/
├── agents/
├── docs/
├── passwords/
├── scripts/
├── templates/
└── tests/
```

## Documentation

- [`docs/getting-started.md`](./docs/getting-started.md): setup and usage
  walkthrough
- [`docs/makefile.md`](./docs/makefile.md): explanation of the `make` command
  surface and variables
- [`docs/secrets.md`](./docs/secrets.md): secure secret-backend setup and
  validation
- [`docs/manual-setup.md`](./docs/manual-setup.md): raw `msmtprc` fallback
  guide
- [`docs/architecture.md`](./docs/architecture.md): repository architecture
  and boundaries
- [`docs/repo-layout.md`](./docs/repo-layout.md): what each major directory is
  for
- [`docs/agent-governance.md`](./docs/agent-governance.md): source-of-truth
  and drift-review expectations
- [`agents/README.md`](./agents/README.md): canonical agent operating guidance
