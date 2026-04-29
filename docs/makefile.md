# Makefile Commands

The repository's `Makefile` is the main human-facing command surface.

Use these commands by intent:

## Primary Guided Commands

- `make configure`: end-to-end guided setup for account data, secret setup or
  rotation, validation, and install
- `make account`: guided account-file CRUD only; it does not install the live
  config
- `make restore`: guided restore umbrella that first asks what kind of backup
  you want to restore

## Account Bootstrap

- `make setup`: create or edit one account file directly
- `make setup-example EXAMPLE=default`: create one account file from a starter
  example

## Secret Commands

- `make password`: choose an account file and create the first secret for its
  configured backend
- `make rotate-password`: rotate one existing secret safely
- `make secret-check`: validate the configured `passwordeval` command
- `make secrets-help`: print the supported secret backends and helper commands
- `make keychain-add`: add or update a macOS Keychain secret for one account
- `make password-file-init`: create one strict-permission password file
- `make gpg-file-init`: create one GPG-encrypted password file

## Render and Install

- `make generate`: render a concrete `msmtprc` into `OUTPUT`
- `make preview`: print the rendered `msmtprc` to stdout
- `make install`: guided install for choosing target and copy vs symlink mode
- `make install-user`: copy the rendered config into `~/.msmtprc`
- `make install-system`: copy the rendered config into `/etc/msmtprc`
- `make link`: symlink the active config path to the repo-managed rendered file
- `make link-user`: symlink `~/.msmtprc` to the repo-managed rendered file

## Restore Commands

- `make restore`: guided umbrella for restoring config, account, or file-backed
  secret backups
- `make restore-config`: restore a live `msmtp` config target from a backup
- `make restore-user-config`: restore `~/.msmtprc`
- `make restore-system-config`: restore `/etc/msmtprc`
- `make restore-account`: restore one `accounts/*.env.bak.*` backup
- `make restore-secret`: restore one `password_file` or `gpg` secret backup
  and validate it afterward

## Verification and Cleanup

- `make check`: run the repository smoke tests
- `make clean`: remove generated repo-root output files such as
  `.msmtprc.generated`

## Common Variables

- `ACCOUNTS_DIR`: directory of local account files; defaults to `accounts`
- `ACCOUNT_NAME`: account-file stem such as `work`; defaults to `default`
- `ACCOUNT_FILE`: direct path to one account file
- `DEFAULT_ACCOUNT`: one-off render/install override when you do not want to
  use `accounts/.default-account`
- `OUTPUT`: render destination for `make generate`
- `EXAMPLE`: starter example for `make setup-example`
- `BACKUP`: explicit backup path for the restore commands
- `INSTALL_PATH`: custom live config path for guided or explicit config
  install/restore flows
- `INSTALL_MODE`: `copy` or `symlink` for install flows
- `INSTALL_FORCE`: allow replacement without an interactive confirmation when a
  live target already exists
- `ROTATE_FORCE`: allow file-backed secret rotation without an interactive
  confirmation when the secret file already exists
- `PASSWORD_FILE`: explicit password-file target path for
  `make password-file-init`
- `GPG_FILE`: explicit encrypted-file target path for `make gpg-file-init`
- `GPG_RECIPIENT`: GPG recipient for `make gpg-file-init` or
  `make rotate-password`
- `KEYCHAIN_SERVICE`: explicit macOS Keychain service override
- `KEYCHAIN_ACCOUNT`: explicit macOS Keychain account override

## Examples

Render the current accounts directory:

```bash
make generate
```

Guide through the full human setup path:

```bash
make configure
```

Restore a deleted account backup for `work.env`:

```bash
make restore-account ACCOUNT_NAME=work
```

Restore a rotated file-backed secret and validate it:

```bash
make restore-secret ACCOUNT_NAME=work
```

Force a system config restore when the live target already exists:

```bash
sudo make restore-system-config BACKUP=/etc/msmtprc.bak.2026-04-27T15-30-00Z INSTALL_FORCE=yes
```

This command surface is intentional. The repo does not keep compatibility
aliases for renamed make targets.

Backup files use UTC timestamps in a human-readable format such as
`2026-04-27T15-30-00Z`.

Interactive restore menus display those backups in your local timezone when
available, such as `Apr 27, 2026 11:30 EDT` on an Eastern Time system, while
still showing the original backup filename. If local timezone conversion is
unavailable, the menu falls back to UTC.
