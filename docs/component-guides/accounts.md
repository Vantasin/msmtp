# Accounts Directory Guide

[`accounts/`](../../accounts/) is the canonical local workspace for `msmtp`
account files.

Use it for:

- one `*.env` file per mailing account
- local account names such as `default.env`, `work.env`, and `personal.env`
- account-specific `MSMTP_SET_DEFAULT` flags when you do not pass
  `DEFAULT_ACCOUNT=...`

These files are intentionally ignored by Git because they contain private
account details.
