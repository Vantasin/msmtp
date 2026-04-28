# Scripts Directory Guide

[`scripts/`](../../scripts/) contains the repo's repeatable shell automation.

Current files:

- [`account-manager.sh`](../../scripts/account-manager.sh): guided account-file
  management
- [`secrets-help.sh`](../../scripts/secrets-help.sh): print the supported
  secret helpers and docs
- [`password-helper.sh`](../../scripts/password-helper.sh): choose an account
  file and dispatch to the matching password helper
- [`secret-check.sh`](../../scripts/secret-check.sh): validate configured
  `passwordeval` commands without printing secrets
- [`keychain-add.sh`](../../scripts/keychain-add.sh): add or update a macOS
  Keychain secret
- [`password-file-init.sh`](../../scripts/password-file-init.sh): create a
  strict-permission password file
- [`gpg-file-init.sh`](../../scripts/gpg-file-init.sh): create a GPG-encrypted
  password file
- [`setup.sh`](../../scripts/setup.sh): interactive setup that writes one
  account file
- [`quickstart.sh`](../../scripts/quickstart.sh): create an account file from a
  chosen example
- [`render-config.sh`](../../scripts/render-config.sh): render the canonical
  `msmtprc` template from an accounts directory
- [`install-helper.sh`](../../scripts/install-helper.sh): guided install flow
  for choosing target and install mode
- [`install.sh`](../../scripts/install.sh): render and install the generated
  config from an accounts directory, backing up existing live targets before
  replacement
- [`restore-helper.sh`](../../scripts/restore-helper.sh): guided backup
  selection and restore
- [`restore-backup.sh`](../../scripts/restore-backup.sh): restore a chosen
  backup into the live target path while protecting any current target first
- [`lib/common.sh`](../../scripts/lib/common.sh): shared helper functions

The scripts assume `bash` and standard Unix utilities available on macOS and
Linux.
