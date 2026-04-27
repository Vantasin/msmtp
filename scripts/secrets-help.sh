#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "$0")" && pwd)"
repo_root="$(cd "${script_dir}/.." && pwd)"

cat <<EOF
Supported secret backends:

  keychain
    macOS Keychain lookup via security find-generic-password

  gpg
    GPG-encrypted password file decrypted at send time

  password_file
    Local password file with strict permissions

  command
    Custom passwordeval command such as pass show mail/msmtp

Common commands:

  make secrets-help
  make secret-check
  make keychain-add SECRET_ENV_FILE=.env
  make password-file-init SECRET_ENV_FILE=.env
  make gpg-file-init SECRET_ENV_FILE=.env GPG_RECIPIENT='<your key id>'

Multi-account usage:

  make secret-check ACCOUNTS_DIR=accounts
  make keychain-add SECRET_ENV_FILE=accounts/work.env
  make password-file-init SECRET_ENV_FILE=accounts/work.env
  make gpg-file-init SECRET_ENV_FILE=accounts/work.env

Documentation:

  ${repo_root}/docs/secrets.md
EOF
