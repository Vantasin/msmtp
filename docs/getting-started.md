# Getting Started

## Prerequisites

- install `msmtp` using your platform package manager
- ensure `bash` and `make` are available

## Setup Model

The primary workflow in this repository is:

1. create a local `.env`
2. render [`templates/msmtprc.template`](../templates/msmtprc.template)
3. install the generated config to `~/.msmtprc`

`msmtp` still consumes `~/.msmtprc`, but the env/template layer keeps the setup
reproducible and scriptable.

## Option 1: Non-Interactive Bootstrap

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

## Option 2: Interactive Setup

Use the prompt-driven setup flow when you want the repo to ask for values one
step at a time:

```bash
make setup
```

This writes `.env` and can optionally install `~/.msmtprc` immediately.

## Configure Your Account

Review `.env` and confirm the values for:

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

## Install Modes

Install the rendered config to the default `msmtp` location:

```bash
make install
```

Install a symlink instead of copying the file:

```bash
make install INSTALL_MODE=symlink
```

`copy` is the default and is the safer choice. `symlink` is an advanced mode
for users who want `~/.msmtprc` to stay linked to the repo-managed rendered
file.

Override paths when needed:

```bash
make install ENV_FILE=.env.work OUTPUT=.msmtprc.work INSTALL_PATH=$HOME/.msmtprc INSTALL_MODE=copy
```

## Manual Fallback

If you do not want to use the automation layer, use
[manual-setup.md](./manual-setup.md) for a raw `msmtprc` setup guide.
