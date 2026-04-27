# Scripts

This directory contains the repository's executable automation.

Files:

- [`setup.sh`](./setup.sh): interactive setup that writes a local `.env`
- [`quickstart.sh`](./quickstart.sh): initialize a local `.env` file from a
  chosen example
- [`render-config.sh`](./render-config.sh): render
  [`templates/msmtprc.template`](../templates/msmtprc.template) into a
  concrete `msmtprc`
- [`install.sh`](./install.sh): render and install the generated config to a
  target path using copy or symlink mode
- [`lib/common.sh`](./lib/common.sh): shared helpers used by the executable
  scripts
