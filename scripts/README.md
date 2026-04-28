# Scripts

This directory contains the repository's executable automation.

Files:

- [`account-manager.sh`](./account-manager.sh): guided account-file management
- [`secrets-help.sh`](./secrets-help.sh): print the supported secret backends
  and helper commands
- [`password-helper.sh`](./password-helper.sh): choose an account file and
  dispatch to the matching password helper
- [`rotate-password.sh`](./rotate-password.sh): rotate an existing secret for
  one account file and validate it when supported
- [`secret-check.sh`](./secret-check.sh): validate configured `passwordeval`
  commands without printing the secret
- [`keychain-add.sh`](./keychain-add.sh): add or update a macOS Keychain secret
- [`password-file-init.sh`](./password-file-init.sh): create a strict
  permission password file
- [`gpg-file-init.sh`](./gpg-file-init.sh): create a GPG-encrypted password
  file
- [`setup.sh`](./setup.sh): interactive setup that writes one account file
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
- [`restore-helper.sh`](./restore-helper.sh): choose a target and backup from a
  menu before restoring
- [`restore-backup.sh`](./restore-backup.sh): restore a previously backed up
  live target while backing up the current target first when needed
- [`lib/common.sh`](./lib/common.sh): shared helpers used by the executable
  scripts
