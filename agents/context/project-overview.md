# Project Overview

This repository is intended to hold portable `msmtp` configuration assets and
supporting operational material for Linux and macOS.

Its goals are:

- provide a clear place for configuration templates
- document platform-specific setup differences
- support repeatable maintenance through scripts and tests
- remain understandable to both human maintainers and AI agents

The repository now includes a working implementation built around canonical
account files under `accounts/`, a canonical `msmtprc` template, an optional
interactive setup flow, executable render, account-only management, a separate
guided human configure flow, password/install/restore helpers, safer install,
backup-restore scripts, linear human quick-start docs, secret-helper scripts
for supported backends, a Makefile reference doc, interruption-aware
workflows, and numbered smoke-test reporting for the supported setup,
rendering, secret, install, restore, test-email, and Makefile command paths.
