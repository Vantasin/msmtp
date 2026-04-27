# Templates Directory Guide

`templates/` contains the canonical config template plus env examples for the
supported secret modes.

Current files:

- `msmtprc.template`
- `examples/macos-keychain.env.example`
- `examples/linux-gpg.env.example`
- `examples/password-file.env.example`

Template rules:

- avoid real secrets
- document placeholder values clearly
- explain platform-specific differences where relevant
