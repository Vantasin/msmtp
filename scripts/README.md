# Scripts

This directory contains the repository's executable automation.

Files:

- [`secrets-help.sh`](./secrets-help.sh): print the supported secret backends
  and helper commands
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
- [`install.sh`](./install.sh): render and install the generated config to a
  target path using copy or symlink mode, with backup-and-confirm protection
  for existing live targets
- [`restore-backup.sh`](./restore-backup.sh): restore a previously backed up
  live target while backing up the current target first when needed
- [`lib/common.sh`](./lib/common.sh): shared helpers used by the executable
  scripts
