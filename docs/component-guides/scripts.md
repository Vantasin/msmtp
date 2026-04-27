# Scripts Directory Guide

[`scripts/`](../../scripts/) contains the repo's repeatable shell automation.

Current files:

- [`quickstart.sh`](../../scripts/quickstart.sh): create a local env file from
  a chosen example
- [`render-config.sh`](../../scripts/render-config.sh): render the canonical
  `msmtprc` template
- [`install.sh`](../../scripts/install.sh): render and install the generated
  config
- [`lib/common.sh`](../../scripts/lib/common.sh): shared helper functions

The scripts assume `bash` and standard Unix utilities available on macOS and
Linux.
