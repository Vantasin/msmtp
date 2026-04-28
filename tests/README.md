# Tests

[`test.sh`](./test.sh) is the shell smoke suite for the repo.

It validates:

- quickstart and interactive account-file setup
- config rendering from `accounts/`
- secret helper syntax and secret validation
- guided install, guarded overwrite, symlink install, and backup restore flows
- guided account management actions
- top-level `make` commands against the accounts-only model
