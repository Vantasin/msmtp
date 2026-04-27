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
make secrets-help
make secret-check
```

`make secret-check` executes the configured `passwordeval` command and verifies
that it returns a non-empty secret, but it never prints the secret value.

For multi-account setups:

```bash
make secret-check ACCOUNTS_DIR=accounts
```

## macOS Keychain

Use this when `MSMTP_SECRET_METHOD=keychain`.

Create or update the secret:

```bash
make keychain-add SECRET_ENV_FILE=.env
```

For a multi-account setup:

```bash
make keychain-add SECRET_ENV_FILE=accounts/work.env
```

Notes:

- this helper is macOS-only
- it uses `security add-generic-password -w` in prompt mode, not plaintext args
- the service and account values come from the env file unless you override
  `KEYCHAIN_SERVICE` or `KEYCHAIN_ACCOUNT`

## GPG-Encrypted Password File

Use this when `MSMTP_SECRET_METHOD=gpg`.

Create the encrypted file:

```bash
make gpg-file-init SECRET_ENV_FILE=.env
```

Encrypt to a specific public key:

```bash
make gpg-file-init SECRET_ENV_FILE=.env GPG_RECIPIENT='your-key-id'
```

Notes:

- if `GPG_RECIPIENT` is omitted, the helper uses symmetric encryption
- symmetric mode requires a GPG passphrase flow that is usable at decrypt time
- recipient mode requires the matching private key to be available at decrypt
  time
- the helper prompts for the SMTP password securely and never accepts it as a
  Make variable

## Password File

Use this when `MSMTP_SECRET_METHOD=password_file`.

Create the file with mode `600`:

```bash
make password-file-init SECRET_ENV_FILE=.env
```

Override the target path explicitly:

```bash
make password-file-init PASSWORD_FILE=/path/to/password-file
```

Notes:

- the helper refuses to overwrite an existing file
- it writes the password without a trailing newline
- if you need a root-owned file, create it in a writable location first and
  move or `chown` it in a separate step

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

## Manual Fallback

If you do not want to use the helper commands, the raw `passwordeval` examples
are also documented in [manual-setup.md](./manual-setup.md).
