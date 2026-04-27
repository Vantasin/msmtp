# Scripts

This directory contains the repository's executable automation.

Files:

- [`quickstart.sh`](./quickstart.sh): initialize a local `.env` file from a
  chosen example
- [`render-config.sh`](./render-config.sh): render
  [`templates/msmtprc.template`](../templates/msmtprc.template) into a
  concrete `msmtprc`
- [`install.sh`](./install.sh): render and install the generated config to a
  target path
- [`lib/common.sh`](./lib/common.sh): shared helpers used by the executable
  scripts
