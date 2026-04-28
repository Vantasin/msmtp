#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=./lib/common.sh
. "${script_dir}/lib/common.sh"

usage() {
  cat <<'EOF'
Usage: scripts/keychain-add.sh [--env-file PATH] [--service NAME] [--account NAME]

Add or update a macOS Keychain entry for the configured msmtp account. This
command uses the secure interactive prompt built into `security` and never
accepts the password as a CLI argument.
EOF
}

env_file="${repo_root}/accounts/default.env"
service_name=""
account_name=""

while [ $# -gt 0 ]; do
  case "$1" in
    --env-file)
      [ $# -ge 2 ] || die "--env-file requires a value"
      env_file="$2"
      shift 2
      ;;
    --service)
      [ $# -ge 2 ] || die "--service requires a value"
      service_name="$2"
      shift 2
      ;;
    --account)
      [ $# -ge 2 ] || die "--account requires a value"
      account_name="$2"
      shift 2
      ;;
    -h | --help)
      usage
      exit 0
      ;;
    *)
      die "Unknown argument: $1"
      ;;
  esac
done

install_interrupt_handler \
  "Cancelled. No Keychain changes were written." \
  "Cancelled. The Keychain item may already have been updated."

require_tty
[ "$(uname -s)" = "Darwin" ] || die "keychain-add is only available on macOS"

if [ -z "$service_name" ] || [ -z "$account_name" ]; then
  load_env_file "$env_file"
  [ "${MSMTP_SECRET_METHOD:-}" = "keychain" ] || die "Env file is not configured for MSMTP_SECRET_METHOD=keychain: $env_file"
  service_name="${service_name:-${MSMTP_KEYCHAIN_SERVICE:-}}"
  account_name="${account_name:-${MSMTP_KEYCHAIN_ACCOUNT:-}}"
fi

[ -n "$service_name" ] || die "Missing keychain service name"
[ -n "$account_name" ] || die "Missing keychain account name"

printf 'Adding or updating the Keychain password for service "%s" and account "%s".\n' "$service_name" "$account_name"
printf 'The macOS security tool will now prompt in this terminal.\n'
printf 'Your input will not be echoed. When you see "password data for new item:", type the SMTP password and press Enter.\n'
security add-generic-password -U -s "$service_name" -a "$account_name" -w

mark_interrupt_dirty
printf 'Stored Keychain secret for %s / %s\n' "$service_name" "$account_name"
