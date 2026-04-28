# Accounts Directory Guide

[`accounts/`](../../accounts/) is the canonical local workspace for `msmtp`
account files.

Use it for:

- one `*.env` file per mailing account
- local account names such as `default.env`, `work.env`, and `personal.env`
- one ignored `accounts/.default-account` file when you want a persistent
  default without passing `DEFAULT_ACCOUNT=...`
- unique `MSMTP_ACCOUNT_NAME` values across the directory

These files are intentionally ignored by Git because they contain private
account details.
