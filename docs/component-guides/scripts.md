# Scripts Directory Guide

`scripts/` contains the repo's repeatable shell automation.

Current files:

- `quickstart.sh`: create a local env file from a chosen example
- `render-config.sh`: render the canonical `msmtprc` template
- `install.sh`: render and install the generated config
- `lib/common.sh`: shared helper functions

The scripts assume `bash` and standard Unix utilities available on macOS and
Linux.
