# Secret Setup

This repository supports four secret backends for `passwordeval`:

- macOS Keychain
- GPG-encrypted password files
- local password files with strict permissions
- custom commands such as `pass`

The repo does not store raw passwords in tracked files. Helper commands prompt
securely when they need a password and avoid accepting plaintext secrets via
Make variables or normal CLI arguments.

## Common Commands

```bash
make password
make rotate-password
make secrets-help
make secret-check
```

`make password` chooses an account file from [`accounts/`](../accounts/) and
dispatches to the matching helper based on `MSMTP_SECRET_METHOD`.

`make rotate-password` targets one account file, rotates the backing secret,
and then validates the configured `passwordeval` command when the backend
supports in-repo rotation.

`make secret-check` executes the configured `passwordeval` command and verifies
that it returns a non-empty secret, but it never prints the secret value.

Check every account in the canonical directory:

```bash
make secret-check ACCOUNTS_DIR=accounts
```

Check one named account:

```bash
make secret-check ACCOUNT_NAME=work
```

## macOS Keychain

Use this when `MSMTP_SECRET_METHOD=keychain`.

Create or update the secret for the default account:

```bash
make keychain-add
```

Create or update the secret for a named account:

```bash
make keychain-add ACCOUNT_NAME=work
```

Rotate an existing Keychain-backed password:

```bash
make rotate-password ACCOUNT_NAME=work
```

Notes:

- this helper is macOS-only
- it uses `security add-generic-password -w` in prompt mode, not plaintext args
- the password prompt appears in the current terminal, not a separate GUI dialog
- the service and account values come from the account file unless you override
  `KEYCHAIN_SERVICE` or `KEYCHAIN_ACCOUNT`

## GPG-Encrypted Password File

Use this when `MSMTP_SECRET_METHOD=gpg`.

Create the encrypted file:

```bash
make gpg-file-init
```

Encrypt to a specific public key:

```bash
make gpg-file-init ACCOUNT_NAME=work GPG_RECIPIENT='your-key-id'
```

Rotate an existing GPG-backed password in place:

```bash
make rotate-password ACCOUNT_NAME=work GPG_RECIPIENT='your-key-id'
```

Notes:

- if `GPG_RECIPIENT` is omitted, the helper uses symmetric encryption
- symmetric mode requires a GPG passphrase flow that is usable at decrypt time
- recipient mode requires the matching private key to be available at decrypt
  time
- the helper prompts for the SMTP password securely and never accepts it as a
  Make variable
- rotation backs up the existing encrypted file next to it before replacement
- when you use recipient mode, pass the recipient again during rotation so the
  encryption mode stays explicit

## Password File

Use this when `MSMTP_SECRET_METHOD=password_file`.

Create the file with mode `600`:

```bash
make password-file-init
```

When you choose `password_file` from `make account` or `make configure`, the
guided setup offers these path presets:

- user-state path under `$HOME/.local/state/msmtp/` for typical user-owned
  local secrets
- repo-local gitignored path under [`../passwords/`](../passwords/) as a
  convenience option
- system path under `/etc/msmtp/` for root-managed server installs
- custom path for anything else

The saved value is normalized to an absolute path. A leading `~` expands to
your home directory before the account file is written.

Override the target path explicitly:

```bash
make password-file-init ACCOUNT_NAME=work PASSWORD_FILE=/path/to/password-file
```

Rotate an existing password-file secret in place:

```bash
make rotate-password ACCOUNT_NAME=work
```

Notes:

- the helper refuses to overwrite an existing file
- it writes the password without a trailing newline
- the recommended default for user-owned plaintext secrets is outside the repo
  under `$HOME/.local/state/msmtp/`
- the repo-local [`../passwords/`](../passwords/) option is intentionally a
  convenience path, not the preferred secure default
- if you need a root-owned file, create it in a writable location first and
  move or `chown` it in a separate step
- rotation backs up the existing file next to it before replacement

## Custom Command

Use this when `MSMTP_SECRET_METHOD=command`.

This repo does not try to provision arbitrary command backends. That is
intentional. The safe boundary is:

- document the expected command
- keep the repo free of raw secrets
- validate the command with `make secret-check`

For example, with `pass`:

```text
MSMTP_PASSWORDEVAL_COMMAND='pass show mail/msmtp'
```

For this backend, `make rotate-password` does not modify the store. It prints
the configured command and lets you validate it after you rotate the secret in
the external system.

## Manual Fallback

If you do not want to use the helper commands, the raw `passwordeval` examples
are also documented in [manual-setup.md](./manual-setup.md).
