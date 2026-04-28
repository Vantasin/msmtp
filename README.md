# msmtp

`msmtp` is a cross-platform repository for generating, testing, and installing
reproducible `msmtp` configuration on Linux and macOS.

It ships with:

- `.env`-driven configuration as the primary source of truth, with support for
  either one account or multiple account env files
- a template-based `msmtprc` renderer
- interactive account, password, install, and restore workflows for day-to-day
  use
- `passwordeval` support for macOS Keychain, Linux GPG, secure password files,
  and custom commands
- helper commands for secret-backend setup and validation
- cleaner [`Makefile`](./Makefile) commands for setup, generate, install,
  link, restore, preview, and check
- safer install flows that back up existing targets before replacement
- copy-based install by default, with optional symlink install for centralized
  repo-managed configs, explicit user/system install targets, and backup
  restores
- smoke tests that validate rendered config without needing a live SMTP account

## Quick Start

This path uses the guided interactive workflow.

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

3. Create or edit your account config.

```bash
make account
```

For a single account, this manages `.env`. If you want multiple addresses, the
same command can add, edit, delete, and set the default account under
[`accounts/`](./accounts/).

4. Set up the SMTP password for the chosen account.

```bash
make password
```

5. Verify that `msmtp` can read the configured secret.

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

- choosing `.env` or `accounts/` when both exist
- choosing user, system, or custom install targets
- choosing copy vs symlink install mode

If the live target already exists, the install flow backs it up and asks before
replacing it. For non-interactive replacement, rerun an explicit command with
`INSTALL_FORCE=yes`.

Backups are stored next to the target as `TARGET.bak.<UTC timestamp>`, for
example `~/.msmtprc.bak.20260427T153000Z`.

For a system-wide config at `/etc/msmtprc`, use:

```bash
sudo make install-system INSTALL_FORCE=yes
```

Restore a user backup:

```bash
make restore
```

`make restore` lists matching backups and lets you choose one by number. The
explicit commands `make restore-user` and `make restore-system` are still
available when you want to pass a `BACKUP=...` path directly.

8. Send a test email. Replace `you@example.com` with the mailbox that should
receive the message.

```bash
printf 'Subject: msmtp test\nTo: you@example.com\n\nmsmtp is working.\n' | msmtp you@example.com
```

If you want non-interactive bootstrap examples, multi-account setup, or an
advanced secret backend such as `pass`, continue with
[`docs/getting-started.md`](./docs/getting-started.md) and
[`docs/secrets.md`](./docs/secrets.md).

The env/template layer is intentional. `msmtp` reads `~/.msmtprc`, but keeping
structured inputs in `.env` plus a template makes setup reproducible, testable,
and easier to document.

The account env files describe SMTP account settings. Choose user vs system
install scope with `make` targets and variables, not in `.env`.

## Multiple Mailing Addresses

The repo also supports multi-account `msmtprc` generation.

Use the guided account manager:

```bash
make account
```

From there, choose the multi-account workflow to add, edit, delete, list, or
set the default account under [`accounts/`](./accounts/).

You can still use explicit commands when you want direct control:

```bash
make generate ACCOUNTS_DIR=accounts DEFAULT_ACCOUNT=work
make install ACCOUNTS_DIR=accounts DEFAULT_ACCOUNT=work
```

If you prefer, you can set `MSMTP_SET_DEFAULT=true` on exactly one account file
instead of passing `DEFAULT_ACCOUNT=...`.

## Credential Modes

Choose one `MSMTP_SECRET_METHOD` in `.env`:

- `keychain`: macOS Keychain lookup via `security find-generic-password`
- `gpg`: decrypt a GPG-encrypted password file
- `password_file`: read from a secure root-owned plaintext file
- `command`: run a custom `passwordeval` command directly

Starter examples live in [`templates/examples/`](./templates/examples/).

## Tracking and Safety

Generated or personalized `msmtprc` files should stay untracked. The repo
ignores local `.env.*` files, `accounts/*.env`, and `.msmtprc*` outputs so
private account details and local secret paths do not get committed
accidentally.

## Main Files

- [`.env.example`](./.env.example): generic starter env file
- [`accounts/README.md`](./accounts/README.md): multi-account env-file model
- [`Makefile`](./Makefile): common repo entrypoints
- [`scripts/account-manager.sh`](./scripts/account-manager.sh): guided single
  and multi-account management
- [`scripts/password-helper.sh`](./scripts/password-helper.sh): choose an env
  file and dispatch to the correct password helper
- [`templates/msmtprc.template`](./templates/msmtprc.template): canonical
  config template
- [`scripts/setup.sh`](./scripts/setup.sh): interactive setup that writes a
  local `.env`
- [`scripts/render-config.sh`](./scripts/render-config.sh): generate a
  concrete config file
- [`scripts/install-helper.sh`](./scripts/install-helper.sh): guided install
  flow for choosing source, target, and install mode
- [`scripts/install.sh`](./scripts/install.sh): render and install the config
- [`scripts/restore-helper.sh`](./scripts/restore-helper.sh): guided backup
  restore flow
- [`scripts/restore-backup.sh`](./scripts/restore-backup.sh): restore a
  backed-up live config target
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
