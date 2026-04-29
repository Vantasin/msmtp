# Tests

[`test.sh`](./test.sh) is the shell smoke suite for the repo.

`make check` prints a numbered pass line for each logical smoke-check area so
the output explains which repository behaviors were verified.

It validates:

- quickstart and interactive account-file setup
- the guided human configure flow at the syntax level
- config rendering from `accounts/`
- secret helper syntax, password rotation, and secret validation
- guided install, guarded overwrite, symlink install, and backup restore flows
- guided account management actions
- top-level `make` commands against the accounts-only model
