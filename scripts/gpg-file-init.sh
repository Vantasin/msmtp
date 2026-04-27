#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=./lib/common.sh
. "${script_dir}/lib/common.sh"

usage() {
  cat <<'EOF'
Usage: scripts/gpg-file-init.sh [--env-file PATH] [--gpg-file PATH] [--recipient NAME]

Create a GPG-encrypted password file. The SMTP password is read securely from
the terminal and is never accepted as a CLI argument.

If --recipient is provided, the file is encrypted to that public key. If not,
the command uses symmetric encryption and GPG will prompt for an encryption
passphrase through pinentry when available.
EOF
}

env_file="${repo_root}/.env"
gpg_file=""
recipient=""

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
    --gpg-file)
      [ $# -ge 2 ] || die "--gpg-file requires a value"
      gpg_file="$2"
      shift 2
      ;;
    --recipient)
      [ $# -ge 2 ] || die "--recipient requires a value"
      recipient="$2"
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

if [ -z "$gpg_file" ]; then
  load_env_file "$env_file"
  [ "${MSMTP_SECRET_METHOD:-}" = "gpg" ] || die "Env file is not configured for MSMTP_SECRET_METHOD=gpg: $env_file"
  gpg_file="${MSMTP_GPG_FILE:-}"
fi

[ -n "$gpg_file" ] || die "Missing GPG file path"
[ ! -e "$gpg_file" ] || die "Refusing to overwrite existing file: $gpg_file"

secret_one="$(prompt_secret "Enter the SMTP password")"
[ -n "$secret_one" ] || die "Password cannot be empty"
secret_two="$(prompt_secret "Re-enter the SMTP password")"
[ "$secret_one" = "$secret_two" ] || die "Passwords did not match"

tmp_file="$(mktemp "${TMPDIR:-/tmp}/msmtp-password-gpg.XXXXXX")"

cleanup() {
  rm -f "$tmp_file"
}

trap cleanup EXIT

mkdir -p "$(dirname "$gpg_file")"
umask 077

if [ -n "$recipient" ]; then
  printf '%s' "$secret_one" | gpg --quiet --yes --encrypt --recipient "$recipient" --output "$tmp_file"
else
  printf '%s' "$secret_one" | gpg --quiet --yes --symmetric --output "$tmp_file"
fi

chmod 600 "$tmp_file"
mv "$tmp_file" "$gpg_file"
trap - EXIT

printf 'Created %s\n' "$gpg_file"
if [ -n "$recipient" ]; then
  printf 'Encrypted to recipient %s\n' "$recipient"
else
  printf 'Created with symmetric GPG encryption. Ensure your decryption flow is available to msmtp.\n'
fi
