# Accounts

[`accounts/`](./) is the canonical workspace for local `msmtp` account files.

Use one file per mailing account, for example:

- `accounts/default.env`
- `accounts/work.env`
- `accounts/personal.env`

The persistent default account lives in `accounts/.default-account`. This file
stores one `MSMTP_ACCOUNT_NAME` value and is intentionally ignored by Git.

Each `accounts/*.env` file must use a unique `MSMTP_ACCOUNT_NAME`.

Recommended workflows:

- use `make configure` for the full human-oriented flow from account setup through install
- use `make account` for guided create, edit, delete, list, and set-default actions
- use `make setup ACCOUNT_NAME=work` to edit one account file directly
- use `make setup-example ACCOUNT_NAME=work EXAMPLE=macos-keychain` to start from an example
- use `make generate` and `make install` against the whole directory
- use `make secret-check` against the whole directory or `make secret-check ACCOUNT_NAME=work` for one account

For stable non-interactive renders, keep `accounts/.default-account` aligned
with one current account. Guided `make install` can choose a deployment-time
default when that file is missing or stale, but it does not rewrite the
account files automatically.

These files are intentionally ignored by Git because they contain private
account details and machine-local secret paths. File-backed secret paths should
be saved as absolute paths. The guided setup normalizes them automatically,
including `~` expansion. If you choose the repo-local plaintext convenience
option, it writes into the gitignored [`../passwords/`](../passwords/)
directory.
