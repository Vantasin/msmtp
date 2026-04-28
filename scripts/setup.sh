#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=./lib/common.sh
. "${script_dir}/lib/common.sh"

usage() {
  cat <<'EOF'
Usage: scripts/setup.sh [--env-file PATH] [--overwrite]

Interactive setup for creating or editing one account file. This command only
updates account data under accounts/; it does not render or install the live
msmtp config.
EOF
}

env_file="${repo_root}/accounts/default.env"
allow_overwrite="false"

while [ $# -gt 0 ]; do
  case "$1" in
    --env-file)
      [ $# -ge 2 ] || die "--env-file requires a value"
      env_file="$2"
      shift 2
      ;;
    --overwrite)
      allow_overwrite="true"
      shift
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

default_secret_method() {
  case "$(uname -s)" in
    Darwin)
      printf 'keychain\n'
      ;;
    *)
      printf 'gpg\n'
      ;;
  esac
}

yes_no_default_from_truthy() {
  if [ -n "${1:-}" ] && is_truthy "$1"; then
    printf 'yes\n'
  else
    printf 'no\n'
  fi
}

account_file_hint() {
  local file_name

  file_name="$(basename "$env_file")"
  printf 'Account file: %s\n' "$env_file" >&2
  printf 'This step only updates account data. Use make configure for the full guided flow, or run make password / make install afterward.\n' >&2
  printf 'The account file name and the msmtp account name are separate. The file name selects a file under accounts/, and the msmtp account name is written into msmtprc.\n' >&2
  printf 'Keeping them aligned is usually clearer, but it is not required.\n' >&2
  if [ "$file_name" = "default.env" ]; then
    printf 'Examples for named accounts: work.env, personal.env, server-alerts.env.\n\n' >&2
  else
    printf 'This file name becomes part of your local account inventory under accounts/.\n\n' >&2
  fi
}

prompt_secret_method() {
  local response default_value normalized

  default_value="${1:-$(default_secret_method)}"

  printf 'Choose how msmtp should retrieve the password:\n' >&2
  printf '  1. keychain      Recommended on macOS desktops. Stores the secret in Keychain.\n' >&2
  printf '  2. gpg           Recommended on Linux desktops. Uses an encrypted file.\n' >&2
  printf '  3. password_file Recommended on unattended servers. Uses a root-owned file.\n' >&2
  printf '  4. command       Advanced mode for pass, Vault, or another external command.\n' >&2

  while true; do
    response="$(prompt_value "Secret method" "$default_value")"
    normalized="$(printf '%s' "$response" | tr '[:upper:]' '[:lower:]' | tr '-' '_')"
    case "$normalized" in
      1 | keychain)
        printf 'keychain\n'
        return 0
        ;;
      2 | gpg)
        printf 'gpg\n'
        return 0
        ;;
      3 | password_file)
        printf 'password_file\n'
        return 0
        ;;
      4 | command)
        printf 'command\n'
        return 0
        ;;
    esac

    printf 'Choose one of: keychain, gpg, password_file, command.\n' >&2
  done
}

if [ -e "$env_file" ] && [ "$allow_overwrite" != "true" ]; then
  die "Refusing to overwrite existing file: $env_file"
fi

printf 'Interactive msmtp account setup\n' >&2
if [ -e "$env_file" ]; then
  load_env_file "$env_file"
  printf 'Editing %s in place.\n\n' "$env_file" >&2
else
  printf 'Creating %s.\n\n' "$env_file" >&2
fi

account_file_hint
printf 'Press Enter to accept the bracketed value. For yes/no prompts, the capitalized choice is the default.\n\n' >&2
account_file_name="$(basename "$env_file" .env)"

printf 'Basic account settings:\n' >&2
MSMTP_ACCOUNT_NAME="$(prompt_required "msmtp account name (examples: default, work, personal)" "${MSMTP_ACCOUNT_NAME:-$account_file_name}")"
MSMTP_HOST="$(prompt_required "SMTP host (example: smtp.example.com)" "${MSMTP_HOST:-}")"
MSMTP_PORT="$(prompt_required "SMTP port (common values: 587 or 465)" "${MSMTP_PORT:-587}")"
MSMTP_FROM="$(prompt_required "From address (example: you@example.com)" "${MSMTP_FROM:-}")"
MSMTP_USER="$(prompt_required "Username (press Enter to accept the bracketed value, often the From address)" "${MSMTP_USER:-$MSMTP_FROM}")"

printf '\nSecret settings:\n' >&2
MSMTP_SECRET_METHOD="$(prompt_secret_method "${MSMTP_SECRET_METHOD:-$(default_secret_method)}")"

existing_keychain_service="${MSMTP_KEYCHAIN_SERVICE:-}"
existing_keychain_account="${MSMTP_KEYCHAIN_ACCOUNT:-}"
existing_gpg_file="${MSMTP_GPG_FILE:-}"
existing_password_file="${MSMTP_PASSWORD_FILE:-}"
existing_passwordeval_command="${MSMTP_PASSWORDEVAL_COMMAND:-}"

MSMTP_KEYCHAIN_SERVICE=""
MSMTP_KEYCHAIN_ACCOUNT=""
MSMTP_GPG_FILE=""
MSMTP_PASSWORD_FILE=""
MSMTP_PASSWORDEVAL_COMMAND=""

case "$MSMTP_SECRET_METHOD" in
  keychain)
    MSMTP_KEYCHAIN_SERVICE="$(prompt_required "Keychain service (usually the SMTP host)" "${existing_keychain_service:-$MSMTP_HOST}")"
    MSMTP_KEYCHAIN_ACCOUNT="$(prompt_required "Keychain account (usually the SMTP username)" "${existing_keychain_account:-$MSMTP_USER}")"
    ;;
  gpg)
    MSMTP_GPG_FILE="$(prompt_required "Path to the GPG-encrypted password file (example: ~/.local/state/msmtp/work.gpg)" "$existing_gpg_file")"
    ;;
  password_file)
    MSMTP_PASSWORD_FILE="$(prompt_required "Path to the password file (server example: /etc/msmtp/work.password)" "$existing_password_file")"
    ;;
  command)
    MSMTP_PASSWORDEVAL_COMMAND="$(prompt_required "Custom passwordeval command (example: pass show mail/work)" "$existing_passwordeval_command")"
    ;;
esac

printf '\nSMTP behavior:\n' >&2
if [ "$(prompt_yes_no "Enable SMTP auth for this account" "$(yes_no_default_from_truthy "${MSMTP_AUTH:-on}")")" = "yes" ]; then
  MSMTP_AUTH="on"
else
  MSMTP_AUTH="off"
fi

if [ "$(prompt_yes_no "Enable TLS encryption" "$(yes_no_default_from_truthy "${MSMTP_TLS:-on}")")" = "yes" ]; then
  MSMTP_TLS="on"
else
  MSMTP_TLS="off"
fi

if [ "$(prompt_yes_no "Enable STARTTLS (recommended for port 587)" "$(yes_no_default_from_truthy "${MSMTP_TLS_STARTTLS:-on}")")" = "yes" ]; then
  MSMTP_TLS_STARTTLS="on"
else
  MSMTP_TLS_STARTTLS="off"
fi

if [ "$(prompt_yes_no "Verify TLS certificates" "$(yes_no_default_from_truthy "${MSMTP_TLS_CERTCHECK:-on}")")" = "yes" ]; then
  MSMTP_TLS_CERTCHECK="on"
else
  MSMTP_TLS_CERTCHECK="off"
fi

if [ "$(prompt_yes_no "Set this as the default account when msmtp does not receive an explicit account" "$(yes_no_default_from_truthy "${MSMTP_SET_DEFAULT:-true}")")" = "yes" ]; then
  MSMTP_SET_DEFAULT="true"
else
  MSMTP_SET_DEFAULT="false"
fi

printf '\nOptional advanced settings:\n' >&2
MSMTP_LOGFILE="$(prompt_value "Log file path (optional, example: ~/.local/state/msmtp.log)" "${MSMTP_LOGFILE:-}")"
MSMTP_TLS_TRUST_FILE="$(prompt_value "TLS trust file path (optional, example: /etc/ssl/certs/ca-certificates.crt)" "${MSMTP_TLS_TRUST_FILE:-}")"
MSMTP_TLS_FINGERPRINT="$(prompt_value "TLS fingerprint (optional, example: AA:BB:CC:DD...)" "${MSMTP_TLS_FINGERPRINT:-}")"

write_msmtp_env_file "$env_file"

printf 'Saved %s\n' "$env_file"
printf 'Next steps:\n' >&2
printf '  1. Run make password ACCOUNT_NAME=%s to provision the secret.\n' "$account_file_name" >&2
printf '  2. Run make secret-check ACCOUNT_NAME=%s to validate the secret lookup.\n' "$account_file_name" >&2
printf '  3. Run make configure for the full guided flow, or make install when you are ready to deploy.\n' >&2
