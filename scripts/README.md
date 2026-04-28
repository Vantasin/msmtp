# Scripts

This directory contains the repository's executable automation.

Files:

- [`account-manager.sh`](./account-manager.sh): guided single-account and
  multi-account management
- [`secrets-help.sh`](./secrets-help.sh): print the supported secret backends
  and helper commands
- [`password-helper.sh`](./password-helper.sh): choose an env file and dispatch
  to the matching password helper
- [`secret-check.sh`](./secret-check.sh): validate configured `passwordeval`
  commands without printing the secret
- [`keychain-add.sh`](./keychain-add.sh): add or update a macOS Keychain secret
- [`password-file-init.sh`](./password-file-init.sh): create a strict
  permission password file
- [`gpg-file-init.sh`](./gpg-file-init.sh): create a GPG-encrypted password
  file
- [`setup.sh`](./setup.sh): interactive setup that writes a local `.env`
- [`quickstart.sh`](./quickstart.sh): initialize a local `.env` file from a
  chosen example
- [`render-config.sh`](./render-config.sh): render
  [`templates/msmtprc.template`](../templates/msmtprc.template) into a
  concrete `msmtprc` from one env file or an account directory
- [`install-helper.sh`](./install-helper.sh): guided install flow for choosing
  the config source, target path, and copy vs symlink mode
- [`install.sh`](./install.sh): render and install the generated config to a
  target path using copy or symlink mode, with backup-and-confirm protection
  for existing live targets
- [`restore-helper.sh`](./restore-helper.sh): choose a target and backup from a
  menu before restoring
- [`restore-backup.sh`](./restore-backup.sh): restore a previously backed up
  live target while backing up the current target first when needed
- [`lib/common.sh`](./lib/common.sh): shared helpers used by the executable
  scripts
