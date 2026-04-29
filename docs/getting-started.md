# Getting Started

## Prerequisites

- install `msmtp` using your platform package manager
- ensure `bash` and `make` are available

## Guided Quick Start

### 1. Clone the Repo

```bash
git clone ssh://git@gitea.vantasin.duckdns.org:2222/Vantasin/msmtp.git
cd msmtp
```

### 2. Install `msmtp`

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

### 3. Run the Guided Configure Flow

```bash
make configure
```

This walks through account creation or editing, secret setup or rotation,
validation, and install.

Common choices:

- use `keychain` on macOS desktops, `gpg` on Linux desktops, and
  `password_file` on unattended servers
- use user config installs for desktops and single-user setups, and system
  installs for root-managed servers

If you only want account-file CRUD without deployment, use:

```bash
make account
```

### 4. Send a Test Email

```bash
make test-email
```

This prompts for the account to test, defaults the recipient to that account's
`from` address, and sends a real email using a temporary one-account render.

### Optional: Verify the Repo Automation

```bash
make check
```

`make check` validates the repository scripts and generated-config behavior. It
does not send mail or verify your live SMTP credentials.

## Account-Only Workflow

Use this when you want to update `accounts/*.env` without changing the live
config yet.

```bash
make account
```

That flow can:

- add an account
- edit an account
- delete an account
- set the persistent default account
- list accounts

It does not render or install the live config.

## Direct Secret and Install Commands

Set up the first secret for one account:

```bash
make password ACCOUNT_NAME=work
```

Rotate the secret for one account:

```bash
make rotate-password ACCOUNT_NAME=work
```

Send a live test email for one account:

```bash
make test-email ACCOUNT_NAME=work TEST_RECIPIENT=you@example.com
```

Validate the whole directory:

```bash
make secret-check
```

Validate one named account:

```bash
make secret-check ACCOUNT_NAME=work
```

Install the rendered config:

```bash
make install
```

Restore from backups through the guided umbrella:

```bash
make restore
```

## Setup Model

The primary workflow in this repository is:

1. create one or more account files under [`accounts/`](../accounts/)
2. render [`templates/msmtprc.template`](../templates/msmtprc.template)
3. install the generated config to the desired `msmtp` config path

`msmtp` still consumes `~/.msmtprc`, but the account-file plus template layer
keeps the setup reproducible and scriptable.

Keep SMTP account data in `accounts/*.env`. Choose user vs system install scope
with `make` targets and variables, not in the account files.

## Direct Account Bootstrap

Create the default account file interactively:

```bash
make setup
```

Create a named account file interactively:

```bash
make setup ACCOUNT_NAME=work
```

Start from an example instead:

```bash
make setup-example EXAMPLE=default
```

```bash
make setup-example ACCOUNT_NAME=work EXAMPLE=macos-keychain
```

Each command creates one account file and refuses to overwrite an existing
file.

## Multiple Accounts

Use the account-only manager:

```bash
make account
```

From there, you can add, edit, delete, list, and set the persistent default
account.

Explicit combined render:

```bash
make generate ACCOUNTS_DIR=accounts DEFAULT_ACCOUNT=work
```

Explicit combined install:

```bash
make install-user ACCOUNTS_DIR=accounts DEFAULT_ACCOUNT=work
```

If you do not pass `DEFAULT_ACCOUNT=...`, keep the persistent default account
in `accounts/.default-account`.

The guided setup flows create `accounts/.default-account` automatically when
you create the first account. Use `make account` to change it later.

If the persistent default is missing or stale, guided `make install` can
choose one for the current deploy without rewriting the stored account data.

## Secret Storage Details

After choosing a secret backend, use the dedicated helpers or the configure
flow:

```bash
make configure
make password
make rotate-password
make secrets-help
make secret-check
```

See [secrets.md](./secrets.md) for backend-specific setup commands.

When you choose `password_file` in `make account` or `make configure`, the
setup flow offers:

- a user-state path under `$HOME/.local/state/msmtp/`
- a repo-local gitignored path under [`../passwords/`](../passwords/)
- a system path under `/etc/msmtp/`
- a custom path

Saved file-backed secret paths are normalized to absolute paths. A leading `~`
expands to your home directory before the path is written into
`accounts/*.env`.

## Verify and Render

Render the config locally:

```bash
make generate
```

Print the rendered config without writing a file:

```bash
make preview
```

Run the smoke tests before installing:

```bash
make check
```

## Install Modes

Install the rendered config to the default `msmtp` location:

```bash
make install
```

`make configure` can hand you into this install flow automatically. The direct
install commands remain useful for repeatable re-deploys.

The guided install prompts are intentionally concise. They only ask for target,
mode, or default-account choices when the install is ambiguous. When no single
default account is available, the guided flow can choose one for the current
deploy without editing `accounts/*.env` or `accounts/.default-account`.

Use the explicit user install command:

```bash
make install-user
```

Use the explicit system install command:

```bash
sudo make install-system INSTALL_FORCE=yes
```

Use the explicit symlink command:

```bash
make link
```

`copy` is the default and is the safer choice. `symlink` is an advanced mode
for users who want `~/.msmtprc` to stay linked to the repo-managed rendered
file. When the target file already exists, install and link modes back it up
before replacement. Interactive runs ask for confirmation; automation should
set `INSTALL_FORCE=yes`.

Override paths when needed:

```bash
make install INSTALL_PATH=$HOME/.config/msmtp/config INSTALL_MODE=copy INSTALL_FORCE=yes
```

## Restore From Backup

Start with the restore umbrella when you want the repo to ask what kind of
backup you want to restore:

```bash
make restore
```

Use the explicit config restore commands when you already know the backup path:

```bash
make restore-user-config BACKUP="$HOME/.msmtprc.bak.2026-04-27T15-30-00Z"
```

```bash
sudo make restore-system-config BACKUP=/etc/msmtprc.bak.2026-04-27T15-30-00Z INSTALL_FORCE=yes
```

Restore one deleted account backup:

```bash
make restore-account ACCOUNT_NAME=work
```

Restore one file-backed secret backup and validate it afterward:

```bash
make restore-secret ACCOUNT_NAME=work
```

Config, account, and file-backed secret restore commands keep the chosen
backup file in place. If the current target already exists, the restore flow
backs it up before replacement.

Backup names use UTC timestamps in a human-readable format such as
`2026-04-27T15-30-00Z`.

Interactive restore menus also show those backups with friendlier labels in
your local timezone when available, such as `Apr 27, 2026 11:30 EDT` on an
Eastern Time system, while keeping the original backup filename in the menu
for clarity. If local timezone conversion is unavailable, the menu falls back
to UTC.

If you want a command-by-command reference for the whole `Makefile`, see
[makefile.md](./makefile.md).

## Manual Fallback

If you do not want to use the automation layer, use
[manual-setup.md](./manual-setup.md) for a raw `msmtprc` setup guide.
