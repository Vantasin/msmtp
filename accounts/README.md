# Accounts

[`accounts/`](./) is the canonical workspace for local `msmtp` account files.

Use one file per mailing account, for example:

- `accounts/default.env`
- `accounts/work.env`
- `accounts/personal.env`

Recommended workflows:

- use `make configure` for the full human-oriented flow from account setup through install
- use `make account` for guided create, edit, delete, list, and set-default actions
- use `make setup ACCOUNT_NAME=work` to edit one account file directly
- use `make setup-example ACCOUNT_NAME=work EXAMPLE=macos-keychain` to start from an example
- use `make generate` and `make install` against the whole directory
- use `make secret-check` against the whole directory or `make secret-check ACCOUNT_NAME=work` for one account

These files are intentionally ignored by Git because they contain private
account details and machine-local secret paths.
