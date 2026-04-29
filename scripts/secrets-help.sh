#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "$0")" && pwd -P)"
if repo_root="$(git -C "${script_dir}/.." rev-parse --show-toplevel 2>/dev/null)"; then
  repo_root="$(cd "$repo_root" && pwd -P)"
else
  repo_root="$(cd "${script_dir}/.." && pwd -P)"
fi

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
  make configure
  make account
  make password
  make rotate-password
  make restore-secret
  make secret-check
  make keychain-add ACCOUNT_NAME=work
  make password-file-init ACCOUNT_NAME=work
  make gpg-file-init ACCOUNT_NAME=work GPG_RECIPIENT='<your key id>'
  make rotate-password ACCOUNT_NAME=work
  make restore-secret ACCOUNT_NAME=work

Accounts directory usage:

  make setup
  make setup ACCOUNT_NAME=work
  make configure
  make secret-check ACCOUNTS_DIR=accounts
  make secret-check ACCOUNT_NAME=work
  make keychain-add ACCOUNT_NAME=work
  make password-file-init ACCOUNT_NAME=work
  make gpg-file-init ACCOUNT_NAME=work

Documentation:

  ${repo_root}/docs/secrets.md
EOF
