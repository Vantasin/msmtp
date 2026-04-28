# msmtp

`msmtp` is a cross-platform repository for generating, testing, and installing
reproducible `msmtp` configuration on Linux and macOS.

It uses one canonical model:

- account files live under [`accounts/`](./accounts/)
- rendered `msmtprc` output is generated from that directory
- user vs system install scope is chosen at install time, not stored in account files

It also ships with:

- a template-based `msmtprc` renderer
- guided account, password, install, and restore workflows
- a dedicated password-rotation workflow for supported secret backends
- `passwordeval` support for macOS Keychain, Linux GPG, secure password files,
  and custom commands
- helper commands for secret-backend setup and validation
- safer install flows that back up existing targets before replacement
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

3. Create or edit your account file.

```bash
make account
```

This manages files under [`accounts/`](./accounts/). One account means one file
such as `accounts/default.env`. Multiple addresses mean multiple files in the
same directory.

4. Store the SMTP password securely for that account.

```bash
make password
```

Rotate an existing password later with:

```bash
make rotate-password
```

5. Verify that the configured secret lookup works.

```bash
make secret-check
```

6. Run the repo smoke tests.

```bash
make check
```

7. Install the generated config to `~/.msmtprc`.

```bash
make install
```

`make install` guides you through:

- choosing the install target
- choosing copy vs symlink mode
- choosing a default account when needed

If the live target already exists, the install flow backs it up and asks before
replacing it. For non-interactive replacement, rerun an explicit command with
`INSTALL_FORCE=yes`.

Backups are stored next to the target as `TARGET.bak.<UTC timestamp>`, for
example `~/.msmtprc.bak.20260427T153000Z`.

For a system-wide config at `/etc/msmtprc`, use:

```bash
sudo make install-system INSTALL_FORCE=yes
```

Restore a previous live config:

```bash
make restore
```

8. Send a test email. Replace `you@example.com` with the mailbox that should
receive the message.

```bash
printf 'Subject: msmtp test\nTo: you@example.com\n\nmsmtp is working.\n' | msmtp you@example.com
```

If you want the longer walkthrough or backend-specific secret setup details,
continue with [docs/getting-started.md](./docs/getting-started.md) and
[docs/secrets.md](./docs/secrets.md).

## Account Model

This repo intentionally uses `accounts/` as the only source of account truth.

- `accounts/default.env` is the simplest single-account setup
- `accounts/work.env` and `accounts/personal.env` are typical multi-account files
- `make generate`, `make install`, and `make secret-check` operate on the whole
  directory

If you do not pass `DEFAULT_ACCOUNT=...`, set `MSMTP_SET_DEFAULT=true` on
exactly one account file.

## Credential Modes

Choose one `MSMTP_SECRET_METHOD` per account file:

- `keychain`: macOS Keychain lookup via `security find-generic-password`
- `gpg`: decrypt a GPG-encrypted password file
- `password_file`: read from a secure password file
- `command`: run a custom `passwordeval` command directly

Starter examples live in [`templates/examples/`](./templates/examples/).

## Tracking and Safety

Generated or personalized `msmtprc` files should stay untracked. The repo
ignores `accounts/*.env` and `.msmtprc*` outputs so private account details and
local secret paths do not get committed accidentally.

## Main Files

- [`accounts/README.md`](./accounts/README.md): canonical account-file model
- [`Makefile`](./Makefile): common repo entrypoints
- [`scripts/account-manager.sh`](./scripts/account-manager.sh): guided account
  management
- [`scripts/password-helper.sh`](./scripts/password-helper.sh): choose an
  account file and dispatch to the correct password helper
- [`scripts/rotate-password.sh`](./scripts/rotate-password.sh): rotate an
  existing secret safely and validate it
- [`templates/msmtprc.template`](./templates/msmtprc.template): canonical
  config template
- [`scripts/setup.sh`](./scripts/setup.sh): interactive setup that writes one
  account file
- [`scripts/render-config.sh`](./scripts/render-config.sh): generate a
  concrete config file from `accounts/`
- [`scripts/install-helper.sh`](./scripts/install-helper.sh): guided install
  flow for choosing target and install mode
- [`scripts/install.sh`](./scripts/install.sh): render and install the config
- [`scripts/restore-helper.sh`](./scripts/restore-helper.sh): guided backup
  restore flow
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
├── scripts/
├── templates/
└── tests/
```

## Documentation

- [`docs/getting-started.md`](./docs/getting-started.md): setup and usage
  walkthrough
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
