# Domain Context

`msmtp` is a lightweight SMTP client commonly used as a sendmail-compatible
mailer on Unix-like systems.

Repository work in this space often involves:

- template-driven configuration
- secure credential lookup
- platform-specific differences between Linux and macOS
- careful handling of example files so secrets are never committed

Typical credential strategies may include:

- `passwordeval` commands
- macOS Keychain lookup
- Linux GPG-backed secret retrieval
- secure root-owned password files

Those mechanisms should be documented explicitly if they are introduced here.
