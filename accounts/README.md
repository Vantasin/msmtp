# Accounts

This directory is reserved for local multi-account env files.

Use one `.env` file per mailing account, for example:

- `accounts/work.env`
- `accounts/personal.env`

These files are ignored by Git because they contain private account details.

Recommended workflows:

- create them interactively with `make setup-account ACCOUNT_NAME=work`
- create them from an example with
  `make setup-account-example ACCOUNT_NAME=work EXAMPLE=macos-keychain`
- render all accounts together with
  `make generate ACCOUNTS_DIR=accounts DEFAULT_ACCOUNT=work`
