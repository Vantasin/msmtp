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

### 3. Create or Edit Your Account File

```bash
make account
```

This manages the canonical [`accounts/`](../accounts/) directory. Use one file
per mailing address.

### 4. Store the SMTP Password Securely

```bash
make password
```

`make password` chooses an account file and dispatches to the matching helper
based on `MSMTP_SECRET_METHOD`. For a custom command backend such as `pass`, it
shows the configured command and can validate it. See
[secrets.md](./secrets.md) for backend-specific details.

Rotate an existing password later with:

```bash
make rotate-password
```

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

- choosing user, system, or custom install targets
- choosing copy vs symlink install mode
- choosing a default account when more than one exists and none is already set

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

Use the guided account manager:

```bash
make account
```

From there, you can add, edit, delete, list, and set the default account.

Explicit combined render:

```bash
make generate ACCOUNTS_DIR=accounts DEFAULT_ACCOUNT=work
```

Explicit combined install:

```bash
make install-user ACCOUNTS_DIR=accounts DEFAULT_ACCOUNT=work
```

If you do not pass `DEFAULT_ACCOUNT=...`, set `MSMTP_SET_DEFAULT=true` on
exactly one account file.

## Secret Storage Details

After choosing a secret backend, use the dedicated helpers or the guided
password flow:

```bash
make password
make rotate-password
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
make install INSTALL_PATH=$HOME/.config/msmtp/config INSTALL_MODE=copy INSTALL_FORCE=yes
```

## Restore From Backup

List backups and choose one interactively:

```bash
make restore
```

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
