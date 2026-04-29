# msmtp

Portable `msmtp` configuration for Linux and macOS.

This repo generates an `msmtprc` from account files under
[`accounts/`](./accounts/), helps provision secrets without committing them,
installs the live config, and sends a real test email to verify the result.

## Quick Start

### 1. Fast Bootstrap

```bash
curl -fsSL https://raw.githubusercontent.com/Vantasin/msmtp/main/scripts/bootstrap.sh | bash
```

This clones the repo into `~/Git/msmtp`, installs basic dependencies with
Homebrew, `apt-get`, or `dnf`, then starts `make configure`.

On macOS, install Homebrew first. The script expects `make` from Apple's
Command Line Tools.

### 2. Manual Setup

Use this path if you do not want to run the bootstrap script.

```bash
git clone https://github.com/Vantasin/msmtp.git
cd msmtp
```

Install `msmtp`.

```bash
brew install msmtp
```

```bash
sudo apt update
sudo apt install msmtp
```

```bash
sudo dnf install msmtp
```

Run the guided setup.

```bash
make configure
```

`make configure` guides you through account setup, secret setup or rotation,
validation, install, and an optional live test email.

## Common Commands

```bash
make configure
```

Guided end-to-end setup.

```bash
make account
```

Manage account files without installing the live config.

```bash
make test-email
```

Test one account using a temporary config.

```bash
make test-live-email
```

Test the installed live config.

```bash
make restore
```

Restore config, account, or file-backed secret backups.

```bash
make check
```

Run repo smoke tests. This does not send mail or verify SMTP credentials.

## Secrets

Use one secret method per account:

- `keychain` for macOS desktops
- `gpg` for Linux desktops
- `password_file` for unattended servers
- `command` for external tools such as `pass` or Vault

Generated account files, rendered configs, and repo-local plaintext passwords
are gitignored. The committed repo stores templates and automation, not live
credentials.

## More Docs

- [docs/getting-started.md](./docs/getting-started.md): full setup walkthrough
- [docs/bootstrap.md](./docs/bootstrap.md): bootstrap details and overrides
- [docs/secrets.md](./docs/secrets.md): secret backend setup and rotation
- [docs/makefile.md](./docs/makefile.md): full command reference
- [docs/manual-setup.md](./docs/manual-setup.md): manual `msmtprc` fallback
