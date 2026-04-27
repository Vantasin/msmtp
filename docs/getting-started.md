# Getting Started

## Prerequisites

- install `msmtp` using your platform package manager
- ensure `bash` and `make` are available

## Initialize a Local Env File

Pick the closest starter example:

```bash
make quickstart EXAMPLE=macos-keychain
```

Available examples:

- `default`
- `macos-keychain`
- `linux-gpg`
- `password-file`

The command creates `.env` and refuses to overwrite an existing file.

## Configure Your Account

Edit `.env` and replace the placeholder values for:

- SMTP host and port
- sender address
- username
- secret method inputs

Only one `MSMTP_SECRET_METHOD` should be active at a time.

## Verify and Render

Run the smoke tests before installing:

```bash
make test
```

Render the config locally:

```bash
make render
```

Print the rendered config without writing a file:

```bash
make print-config
```

## Install

Install the rendered config to the default `msmtp` location:

```bash
make install
```

Override paths when needed:

```bash
make install ENV_FILE=.env.work OUTPUT=.msmtprc.work INSTALL_PATH=$HOME/.msmtprc
```
