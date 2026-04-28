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
  make account
  make password
  make secret-check
  make keychain-add ACCOUNT_NAME=work
  make password-file-init ACCOUNT_NAME=work
  make gpg-file-init ACCOUNT_NAME=work GPG_RECIPIENT='<your key id>'

Accounts directory usage:

  make setup
  make setup ACCOUNT_NAME=work
  make secret-check ACCOUNTS_DIR=accounts
  make keychain-add ACCOUNT_NAME=work
  make password-file-init ACCOUNT_NAME=work
  make gpg-file-init ACCOUNT_NAME=work

Documentation:

  ${repo_root}/docs/secrets.md
EOF
