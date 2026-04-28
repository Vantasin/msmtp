# Getting Started

## Prerequisites

- install `msmtp` using your platform package manager
- ensure `bash` and `make` are available

## Single-Account Quick Start

Use this path if you want one mailing address and want the repo to prompt you
for the account details.

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

### 3. Create `.env` with the Guided Setup

```bash
make setup
```

This writes a local `.env` and prompts for:

- account name
- SMTP host and port
- sender address
- username
- TLS settings
- secret method

### 4. Store the SMTP Password Securely

Choose the block that matches the `MSMTP_SECRET_METHOD` you selected during
`make setup`.

macOS Keychain:

```bash
make keychain-add SECRET_ENV_FILE=.env
```

GPG-encrypted password file:

```bash
make gpg-file-init SECRET_ENV_FILE=.env
```

Password file:

```bash
make password-file-init SECRET_ENV_FILE=.env
```

For a custom command backend such as `pass`, configure that command outside the
repo and then continue with the validation step below. See
[secrets.md](./secrets.md) for the supported command patterns.

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

If `~/.msmtprc` already exists, `make install` backs it up and asks before
replacing it. For non-interactive replacement, use:

```bash
make install INSTALL_FORCE=yes
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

Use one env file per account when you want multiple mailing addresses in the
same generated `msmtprc`:

```bash
make setup-account ACCOUNT_NAME=work
make setup-account ACCOUNT_NAME=personal
```

Create one account from a starter example:

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

Install explicitly to the user config path:

```bash
make install-user
```

Install directly to `/etc/msmtprc`:

```bash
sudo make install-system INSTALL_FORCE=yes
```

Install a symlink instead of copying the file:

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
ls -1 "$HOME"/.msmtprc.bak.*
```

Restore one user-config backup:

```bash
make restore-user BACKUP="$HOME/.msmtprc.bak.20260427T153000Z"
```

List system-config backups:

```bash
sudo ls -1 /etc/msmtprc.bak.*
```

Restore one system-config backup:

```bash
sudo make restore-system BACKUP=/etc/msmtprc.bak.20260427T153000Z INSTALL_FORCE=yes
```

Restore commands keep the chosen backup file in place. If the current target
already exists, the restore flow backs it up before replacement.

## Manual Fallback

If you do not want to use the automation layer, use
[manual-setup.md](./manual-setup.md) for a raw `msmtprc` setup guide.
