# Scripts Directory Guide

[`scripts/`](../../scripts/) contains the repo's repeatable shell automation.

Current files:

- [`secrets-help.sh`](../../scripts/secrets-help.sh): print the supported
  secret helpers and docs
- [`secret-check.sh`](../../scripts/secret-check.sh): validate configured
  `passwordeval` commands without printing secrets
- [`keychain-add.sh`](../../scripts/keychain-add.sh): add or update a macOS
  Keychain secret
- [`password-file-init.sh`](../../scripts/password-file-init.sh): create a
  strict-permission password file
- [`gpg-file-init.sh`](../../scripts/gpg-file-init.sh): create a GPG-encrypted
  password file
- [`setup.sh`](../../scripts/setup.sh): interactive setup that writes a local
  `.env`
- [`quickstart.sh`](../../scripts/quickstart.sh): create a local env file from
  a chosen example
- [`render-config.sh`](../../scripts/render-config.sh): render the canonical
  `msmtprc` template from one env file or an account directory
- [`install.sh`](../../scripts/install.sh): render and install the generated
  config from one env file or an account directory, backing up existing live
  targets before replacement
- [`restore-backup.sh`](../../scripts/restore-backup.sh): restore a chosen
  backup into the live target path while protecting any current target first
- [`lib/common.sh`](../../scripts/lib/common.sh): shared helper functions

The scripts assume `bash` and standard Unix utilities available on macOS and
Linux.
