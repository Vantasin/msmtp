#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=./lib/common.sh
. "${script_dir}/lib/common.sh"

usage() {
  cat <<'EOF'
Usage: scripts/password-file-init.sh [--env-file PATH] [--password-file PATH]

Create a password file with strict permissions. The password is read securely
from the terminal and is never accepted as a CLI argument.
EOF
}

env_file="${repo_root}/accounts/default.env"
password_file=""

prompt_secret() {
  local prompt_text="$1"
  local secret_value

  printf '%s: ' "$prompt_text" >&2
  IFS= read -r -s secret_value
  printf '\n' >&2
  printf '%s\n' "$secret_value"
}

while [ $# -gt 0 ]; do
  case "$1" in
    --env-file)
      [ $# -ge 2 ] || die "--env-file requires a value"
      env_file="$2"
      shift 2
      ;;
    --password-file)
      [ $# -ge 2 ] || die "--password-file requires a value"
      password_file="$2"
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

if [ -z "$password_file" ]; then
  load_env_file "$env_file"
  [ "${MSMTP_SECRET_METHOD:-}" = "password_file" ] || die "Env file is not configured for MSMTP_SECRET_METHOD=password_file: $env_file"
  password_file="${MSMTP_PASSWORD_FILE:-}"
fi

password_file="$(normalize_managed_path "$password_file")"
[ -n "$password_file" ] || die "Missing password file path"
[ ! -e "$password_file" ] || die "Refusing to overwrite existing file: $password_file"

install_interrupt_handler \
  "Cancelled. No password file was written." \
  "Cancelled. Check ${password_file} for partial changes."

password_one="$(prompt_secret "Enter the SMTP password")"
[ -n "$password_one" ] || die "Password cannot be empty"
password_two="$(prompt_secret "Re-enter the SMTP password")"
[ "$password_one" = "$password_two" ] || die "Passwords did not match"

umask 077
ensure_repo_local_passwords_dir_permissions_for_path "$password_file"
atomic_write_raw_file "$password_file" 600 "$password_one"

printf 'Created %s with mode 600\n' "$password_file"
printf 'If you require a root-owned file, move or chown it in a separate step.\n'
