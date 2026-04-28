# Templates

This directory contains the reusable assets that drive generated `msmtp`
configuration.

Files:

- [`msmtprc.template`](./msmtprc.template): the canonical config template used
  by the renderer
- [`examples/default.env.example`](./examples/default.env.example): starter
  account file for the canonical `accounts/default.env` flow
- [`examples/macos-keychain.env.example`](./examples/macos-keychain.env.example):
  starter account file for macOS Keychain
- [`examples/linux-gpg.env.example`](./examples/linux-gpg.env.example): starter
  account file for Linux GPG decryption
- [`examples/password-file.env.example`](./examples/password-file.env.example):
  starter account file for secure password files

Persistent default-account state now lives in `accounts/.default-account`, not
inside the example account files.
