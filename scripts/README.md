# Scripts

This directory contains the repository's executable automation.

Files:

- [`bootstrap.sh`](./bootstrap.sh): self-contained first-run bootstrap for
  cloning the repo, installing dependencies, and starting `make configure`
- [`account-manager.sh`](./account-manager.sh): guided account-file management
- [`configure.sh`](./configure.sh): guided human workflow for account, secret,
  validation, and install
- [`secrets-help.sh`](./secrets-help.sh): print the supported secret backends
  and helper commands
- [`password-helper.sh`](./password-helper.sh): choose an account file and
  dispatch to the matching password helper
- [`rotate-password.sh`](./rotate-password.sh): rotate an existing secret for
  one account file and validate it when supported
- [`test-email.sh`](./test-email.sh): send a real test email for one selected
  account using a temporary one-account render
- [`test-live-email.sh`](./test-live-email.sh): send a real test email using
  the installed live config path for one selected account
- [`secret-check.sh`](./secret-check.sh): validate configured `passwordeval`
  commands without printing the secret
- [`keychain-add.sh`](./keychain-add.sh): add or update a macOS Keychain secret
- [`password-file-init.sh`](./password-file-init.sh): create a strict
  permission password file
- [`gpg-file-init.sh`](./gpg-file-init.sh): create a GPG-encrypted password
  file
- [`setup.sh`](./setup.sh): interactive setup that writes one account file
  without installing the live config
- [`quickstart.sh`](./quickstart.sh): initialize an account file from a chosen
  example
- [`render-config.sh`](./render-config.sh): render
  [`templates/msmtprc.template`](../templates/msmtprc.template) into a
  concrete `msmtprc` from an accounts directory
- [`install-helper.sh`](./install-helper.sh): guided install flow for choosing
  target path and copy vs symlink mode
- [`install.sh`](./install.sh): render and install the generated config to a
  target path using copy or symlink mode, with backup-and-confirm protection
  for existing live targets
- [`restore-helper.sh`](./restore-helper.sh): guided restore umbrella for
  choosing config, account, or file-backed secret restore
- [`restore-config-helper.sh`](./restore-config-helper.sh): choose a live
  config target and backup before restoring
- [`restore-account-helper.sh`](./restore-account-helper.sh): choose an account
  backup and restore it into `accounts/`
- [`restore-secret-helper.sh`](./restore-secret-helper.sh): choose a
  file-backed secret backup and validate it after restore
- [`restore-backup.sh`](./restore-backup.sh): restore a previously backed up
  file or symlink target while backing up the current target first when needed
- [`lib/common.sh`](./lib/common.sh): shared helpers used by the executable
  scripts
