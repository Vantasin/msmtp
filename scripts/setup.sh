#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=./lib/common.sh
. "${script_dir}/lib/common.sh"

usage() {
  cat <<'EOF'
Usage: scripts/setup.sh [--env-file PATH] [--output PATH] [--target PATH]
                       [--overwrite]

Interactive setup for creating or editing one account file. The account-file
workflow remains the source of truth; this script is a convenience layer that
collects values step by step and writes them into a file under accounts/.
Use --overwrite to edit an existing file in place.
EOF
}

env_file="${repo_root}/accounts/default.env"
output_file="${repo_root}/.msmtprc.generated"
target_path="${HOME}/.msmtprc"
allow_overwrite="false"

while [ $# -gt 0 ]; do
  case "$1" in
    --env-file)
      [ $# -ge 2 ] || die "--env-file requires a value"
      env_file="$2"
      shift 2
      ;;
    --output)
      [ $# -ge 2 ] || die "--output requires a value"
      output_file="$2"
      shift 2
      ;;
    --target)
      [ $# -ge 2 ] || die "--target requires a value"
      target_path="$2"
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

prompt_secret_method() {
  local response default_value normalized

  default_value="${1:-$(default_secret_method)}"

  printf 'Setup profiles:\n' >&2
  printf '  1. keychain\n' >&2
  printf '  2. gpg\n' >&2
  printf '  3. password_file\n' >&2
  printf '  4. command\n' >&2

  while true; do
    response="$(prompt_value "Choose a secret method" "$default_value")"
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

prompt_install_mode() {
  local response normalized

  while true; do
    response="$(prompt_value "Install mode" "copy")"
    normalized="$(printf '%s' "$response" | tr '[:upper:]' '[:lower:]')"
    case "$normalized" in
      copy | symlink)
        printf '%s\n' "$normalized"
        return 0
        ;;
    esac

    printf 'Choose one of: copy, symlink.\n' >&2
  done
}

if [ -e "$env_file" ] && [ "$allow_overwrite" != "true" ]; then
  die "Refusing to overwrite existing file: $env_file"
fi

if [ -e "$env_file" ]; then
  load_env_file "$env_file"
  printf 'Interactive msmtp setup\n' >&2
  printf 'Editing %s in place.\n\n' "$env_file" >&2
else
  printf 'Interactive msmtp setup\n' >&2
  printf 'This writes %s and keeps the account-file workflow as the source of truth.\n\n' "$env_file" >&2
fi

MSMTP_ACCOUNT_NAME="$(prompt_required "Account name" "${MSMTP_ACCOUNT_NAME:-default}")"
MSMTP_HOST="$(prompt_required "SMTP host" "${MSMTP_HOST:-}")"
MSMTP_PORT="$(prompt_required "SMTP port" "${MSMTP_PORT:-587}")"
MSMTP_FROM="$(prompt_required "From address" "${MSMTP_FROM:-}")"
MSMTP_USER="$(prompt_required "Username" "${MSMTP_USER:-$MSMTP_FROM}")"
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
    MSMTP_KEYCHAIN_SERVICE="$(prompt_required "Keychain service" "${existing_keychain_service:-$MSMTP_HOST}")"
    MSMTP_KEYCHAIN_ACCOUNT="$(prompt_required "Keychain account" "${existing_keychain_account:-$MSMTP_USER}")"
    ;;
  gpg)
    MSMTP_GPG_FILE="$(prompt_required "Path to the GPG-encrypted password file" "$existing_gpg_file")"
    ;;
  password_file)
    MSMTP_PASSWORD_FILE="$(prompt_required "Path to the password file" "$existing_password_file")"
    ;;
  command)
    MSMTP_PASSWORDEVAL_COMMAND="$(prompt_required "Custom passwordeval command" "$existing_passwordeval_command")"
    ;;
esac

if [ "$(prompt_yes_no "Enable SMTP auth" "$(yes_no_default_from_truthy "${MSMTP_AUTH:-on}")")" = "yes" ]; then
  MSMTP_AUTH="on"
else
  MSMTP_AUTH="off"
fi

if [ "$(prompt_yes_no "Enable TLS" "$(yes_no_default_from_truthy "${MSMTP_TLS:-on}")")" = "yes" ]; then
  MSMTP_TLS="on"
else
  MSMTP_TLS="off"
fi

if [ "$(prompt_yes_no "Enable STARTTLS" "$(yes_no_default_from_truthy "${MSMTP_TLS_STARTTLS:-on}")")" = "yes" ]; then
  MSMTP_TLS_STARTTLS="on"
else
  MSMTP_TLS_STARTTLS="off"
fi

if [ "$(prompt_yes_no "Verify TLS certificates" "$(yes_no_default_from_truthy "${MSMTP_TLS_CERTCHECK:-on}")")" = "yes" ]; then
  MSMTP_TLS_CERTCHECK="on"
else
  MSMTP_TLS_CERTCHECK="off"
fi

if [ "$(prompt_yes_no "Set this as the default account" "$(yes_no_default_from_truthy "${MSMTP_SET_DEFAULT:-true}")")" = "yes" ]; then
  MSMTP_SET_DEFAULT="true"
else
  MSMTP_SET_DEFAULT="false"
fi

MSMTP_LOGFILE="$(prompt_value "Log file path (optional)" "${MSMTP_LOGFILE:-}")"
MSMTP_TLS_TRUST_FILE="$(prompt_value "TLS trust file path (optional)" "${MSMTP_TLS_TRUST_FILE:-}")"
MSMTP_TLS_FINGERPRINT="$(prompt_value "TLS fingerprint (optional)" "${MSMTP_TLS_FINGERPRINT:-}")"

write_msmtp_env_file "$env_file"

printf 'Created %s\n' "$env_file"

if [ "$(prompt_yes_no "Render and install ~/.msmtprc now" "no")" = "yes" ]; then
  install_mode="$(prompt_install_mode)"
  accounts_dir_for_install="$(dirname "$env_file")"
  "${repo_root}/scripts/install.sh" \
    --accounts-dir "$accounts_dir_for_install" \
    --output "$output_file" \
    --target "$target_path" \
    --mode "$install_mode"
  exit 0
fi

printf 'Next steps:\n'
printf '  1. Review %s.\n' "$env_file"
printf '  2. Run make check.\n'
printf '  3. Run make install.\n'
