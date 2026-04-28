# Getting Started

## Prerequisites

- install `msmtp` using your platform package manager
- ensure `bash` and `make` are available

## Guided Quick Start

Use this path when you want the repo to guide you through account setup,
password setup, install, and restore choices.

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

### 3. Create or Edit Your Account Config

```bash
make account
```

For a single account, this manages `.env`. For multiple accounts, it can:

- add an account
- edit an account
- delete an account
- set the default account
- list existing accounts

### 4. Store the SMTP Password Securely

```bash
make password
```

`make password` lets you choose the env file and then dispatches to the
matching helper based on `MSMTP_SECRET_METHOD`. For a custom command backend
such as `pass`, it shows the configured command and can validate it. See
[secrets.md](./secrets.md) for the supported backends.

### 5. Verify the Secret Lookup

```bash
make secret-check
```

### 6. Run the Repo Smoke Tests

```bash
make check
```

### 7. Install `~/.msmtprc`

```bash
make install
```

By default, `make install` writes to `~/.msmtprc` and keeps a rendered copy in
`.msmtprc.generated`.

`make install` guides you through:

- choosing `.env` or `accounts/` when both exist
- choosing user, system, or custom install targets
- choosing copy vs symlink install mode

If the live target already exists, `make install` backs it up and asks before
replacing it. For non-interactive replacement, use an explicit install command:

```bash
make install-user INSTALL_FORCE=yes
```

Backups are stored next to the target as `TARGET.bak.<UTC timestamp>`.

### 8. Send a Test Email

Replace `you@example.com` with the mailbox that should receive the test
message.

```bash
printf 'Subject: msmtp test\nTo: you@example.com\n\nmsmtp is working.\n' | msmtp you@example.com
```

## Setup Model

The primary workflow in this repository is:

1. create a local `.env` or one env file per account under `accounts/`
2. render [`templates/msmtprc.template`](../templates/msmtprc.template)
3. install the generated config to `~/.msmtprc`

`msmtp` still consumes `~/.msmtprc`, but the env/template layer keeps the setup
reproducible and scriptable.

Keep SMTP account data in `.env` or `accounts/*.env`. Choose user vs system
install scope with `make` targets and variables, not in the env files.

## Non-Interactive Bootstrap

Pick the closest starter example:

Default example:

```bash
make setup-example EXAMPLE=default
```

macOS Keychain example:

```bash
make setup-example EXAMPLE=macos-keychain
```

Linux GPG example:

```bash
make setup-example EXAMPLE=linux-gpg
```

Password-file example:

```bash
make setup-example EXAMPLE=password-file
```

Each command creates `.env` and refuses to overwrite an existing file.

## Multiple Accounts

Use the guided account manager:

```bash
make account
```

From there, choose the multi-account workflow to add, edit, delete, or set the
default account.

If you want the older explicit commands, they still exist. Create one account
from a starter example:

```bash
make setup-account-example ACCOUNT_NAME=work EXAMPLE=macos-keychain
```

Render the combined config from the account directory:

```bash
make generate ACCOUNTS_DIR=accounts DEFAULT_ACCOUNT=work
```

Install the combined config:

```bash
make install ACCOUNTS_DIR=accounts DEFAULT_ACCOUNT=work
```

If you do not pass `DEFAULT_ACCOUNT=...`, set `MSMTP_SET_DEFAULT=true` on
exactly one account file.

## Secret Storage Details

After choosing a secret backend, use the dedicated secret helpers or follow the
backend docs:

```bash
make password
make secrets-help
make secret-check
```

See [secrets.md](./secrets.md) for backend-specific setup commands.

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
make install ENV_FILE=.env.work OUTPUT=.msmtprc.work INSTALL_PATH=$HOME/.msmtprc
```

## Restore From Backup

List user-config backups:

```bash
make restore
```

`make restore` lists matching backups for the chosen target and lets you pick
one by number.

Use the explicit restore commands when you already know the backup path:

```bash
make restore-user BACKUP="$HOME/.msmtprc.bak.20260427T153000Z"
```

```bash
sudo make restore-system BACKUP=/etc/msmtprc.bak.20260427T153000Z INSTALL_FORCE=yes
```

Restore commands keep the chosen backup file in place. If the current target
already exists, the restore flow backs it up before replacement.

## Manual Fallback

If you do not want to use the automation layer, use
[manual-setup.md](./manual-setup.md) for a raw `msmtprc` setup guide.
