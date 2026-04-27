# Secrets Guide

The secret setup docs live in [docs/secrets.md](../secrets.md).

Use that document for:

- backend-specific secret setup
- helper command usage
- validation via `make secret-check`

The repo intentionally separates secret-store provisioning from config
generation so raw secrets do not need to appear in tracked files.
