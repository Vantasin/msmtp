# Passwords

`passwords/` is an optional local-only convenience directory for plaintext
`password_file` secrets.

Guidelines:

- this directory is intentionally ignored by Git
- use it only when you intentionally want repo-local plaintext password files
- prefer user-state paths or stronger secret backends when practical
- keep password files mode `600`
- keep this directory mode `700` when possible

The setup flow can offer paths under this directory, but it stores absolute
paths in account files so `msmtp` does not depend on the current working
directory.
