#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=./lib/common.sh
. "${script_dir}/lib/common.sh"

usage() {
  cat <<'EOF'
Usage: scripts/rotate-password.sh [--env-file PATH | --accounts-dir PATH]
                                  [--recipient NAME]
                                  [--force]

Rotate the secret for one account file. Keychain secrets are updated in place.
Password-file and GPG backends back up the existing secret file before
replacing it and then validate the configured passwordeval command.
EOF
}

env_file=""
accounts_dir="${repo_root}/accounts"
gpg_recipient=""
force_replace="false"
tmp_secret_file=""

cleanup() {
  if [ -n "$tmp_secret_file" ] && [ -e "$tmp_secret_file" ]; then
    rm -f "$tmp_secret_file"
  fi
}

trap cleanup EXIT

choose_env_file() {
  local env_files=()
  local labels=()
  local env_path label

  while IFS= read -r env_path; do
    [ -n "$env_path" ] || continue
    env_files+=("$env_path")
    labels+=("$(basename "$env_path") (msmtp account: $(account_name_from_env_file "$env_path"))")
  done <<EOF
$(list_account_env_files "$accounts_dir")
EOF

  [ "${#env_files[@]}" -gt 0 ] || die "No account env files found. Create one under ${accounts_dir} first."

  if [ "${#env_files[@]}" -eq 1 ]; then
    printf '%s\n' "${env_files[0]}"
    return 0
  fi

  printf 'Choose the account whose secret you want to rotate.\n' >&2
  printf 'This replaces the existing secret for the configured backend and validates it afterward when supported.\n' >&2
  label="$(choose_from_menu "Choose an account file for password rotation:" "${labels[@]}")"
  for i in "${!labels[@]}"; do
    if [ "${labels[$i]}" = "$label" ]; then
      printf '%s\n' "${env_files[$i]}"
      return 0
    fi
  done

  die "Selected account file could not be resolved"
}

default_env_file_if_unambiguous() {
  local only_env=""
  local env_path

  while IFS= read -r env_path; do
    [ -n "$env_path" ] || continue
    if [ -n "$only_env" ]; then
      return 1
    fi
    only_env="$env_path"
  done <<EOF
$(list_account_env_files "$accounts_dir")
EOF

  [ -n "$only_env" ] || return 1
  printf '%s\n' "$only_env"
}

prompt_secret() {
  local prompt_text="$1"
  local secret_value

  printf '%s: ' "$prompt_text" >&2
  IFS= read -r -s secret_value
  printf '\n' >&2
  printf '%s\n' "$secret_value"
}

prompt_new_secret() {
  local first second

  first="$(prompt_secret "Enter the new SMTP password")"
  [ -n "$first" ] || die "Password cannot be empty"
  second="$(prompt_secret "Re-enter the new SMTP password")"
  [ "$first" = "$second" ] || die "Passwords did not match"
  printf '%s\n' "$first"
}

backup_existing_target_if_needed() {
  local target_path="$1"
  local backup_path=""

  if ! path_exists "$target_path"; then
    return 0
  fi

  if [ "$force_replace" != "true" ]; then
    [ -t 0 ] || die "Refusing to replace existing secret without confirmation: ${target_path}. Re-run with --force to back up and replace it."
    if [ "$(prompt_yes_no "Back up and replace the existing secret at ${target_path}?" "no")" != "yes" ]; then
      die "Secret rotation cancelled"
    fi
  fi

  backup_path="$(backup_path_for "$target_path")"
  mv "$target_path" "$backup_path"
  printf 'Backed up existing secret to %s\n' "$backup_path"
}

write_password_file_secret() {
  local target_path="$1"
  local secret_value="$2"

  mkdir -p "$(dirname "$target_path")"
  tmp_secret_file="$(mktemp "${TMPDIR:-/tmp}/msmtp-rotate-password-file.XXXXXX")"
  umask 077
  printf '%s' "$secret_value" > "$tmp_secret_file"
  chmod 600 "$tmp_secret_file"
  backup_existing_target_if_needed "$target_path"
  mv "$tmp_secret_file" "$target_path"
  chmod 600 "$target_path"
  tmp_secret_file=""
}

write_gpg_secret() {
  local target_path="$1"
  local secret_value="$2"
  local recipient_value="$3"

  mkdir -p "$(dirname "$target_path")"
  tmp_secret_file="$(mktemp "${TMPDIR:-/tmp}/msmtp-rotate-gpg.XXXXXX")"
  umask 077

  if [ -n "$recipient_value" ]; then
    printf '%s' "$secret_value" | gpg --quiet --yes --encrypt --recipient "$recipient_value" --output "$tmp_secret_file"
  else
    printf '%s' "$secret_value" | gpg --quiet --yes --symmetric --output "$tmp_secret_file"
  fi

  chmod 600 "$tmp_secret_file"
  backup_existing_target_if_needed "$target_path"
  mv "$tmp_secret_file" "$target_path"
  chmod 600 "$target_path"
  tmp_secret_file=""
}

while [ $# -gt 0 ]; do
  case "$1" in
    --env-file)
      [ $# -ge 2 ] || die "--env-file requires a value"
      env_file="$2"
      shift 2
      ;;
    --accounts-dir)
      [ $# -ge 2 ] || die "--accounts-dir requires a value"
      accounts_dir="$2"
      shift 2
      ;;
    --recipient)
      [ $# -ge 2 ] || die "--recipient requires a value"
      gpg_recipient="$2"
      shift 2
      ;;
    --force)
      force_replace="true"
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

if [ -z "$env_file" ]; then
  if [ -t 0 ]; then
    env_file="$(choose_env_file)"
  else
    env_file="$(default_env_file_if_unambiguous)" || die "This command requires --env-file or a single account file in ${accounts_dir} when run non-interactively"
  fi
fi

require_file "$env_file"
load_env_file "$env_file"

account_name="${MSMTP_ACCOUNT_NAME:-}"
[ -n "$account_name" ] || die "Missing MSMTP_ACCOUNT_NAME in $env_file"
secret_method="${MSMTP_SECRET_METHOD:-command}"

printf 'Selected account file %s (msmtp account name: %s).\n' "$env_file" "$account_name" >&2

case "$secret_method" in
  keychain)
    "${repo_root}/scripts/keychain-add.sh" --env-file "$env_file"
    "${repo_root}/scripts/secret-check.sh" --env-file "$env_file"
    ;;
  password_file)
    require_var MSMTP_PASSWORD_FILE
    new_secret="$(prompt_new_secret)"
    write_password_file_secret "$MSMTP_PASSWORD_FILE" "$new_secret"
    printf 'Rotated password file secret at %s\n' "$MSMTP_PASSWORD_FILE"
    "${repo_root}/scripts/secret-check.sh" --env-file "$env_file"
    ;;
  gpg)
    require_var MSMTP_GPG_FILE
    if [ -z "$gpg_recipient" ] && [ -t 0 ]; then
      gpg_recipient="$(prompt_value "GPG recipient (leave blank for symmetric encryption)" "")"
    elif [ -z "$gpg_recipient" ] && path_exists "$MSMTP_GPG_FILE"; then
      die "Non-interactive GPG rotation requires --recipient or an interactive choice so the encryption mode is explicit"
    fi
    new_secret="$(prompt_new_secret)"
    write_gpg_secret "$MSMTP_GPG_FILE" "$new_secret" "$gpg_recipient"
    printf 'Rotated GPG secret at %s\n' "$MSMTP_GPG_FILE"
    if [ -n "$gpg_recipient" ]; then
      printf 'Encrypted to recipient %s\n' "$gpg_recipient"
    else
      printf 'Encrypted with symmetric GPG mode\n'
    fi
    "${repo_root}/scripts/secret-check.sh" --env-file "$env_file"
    ;;
  command)
    printf 'This account file uses MSMTP_SECRET_METHOD=command.\n'
    printf 'Rotate the secret in the external store referenced by this command:\n'
    printf '  %s\n' "$(passwordeval_command_from_env_file "$env_file")"
    if [ -t 0 ] && [ "$(prompt_yes_no "Run secret validation now" "yes")" = "yes" ]; then
      "${repo_root}/scripts/secret-check.sh" --env-file "$env_file"
    fi
    ;;
  *)
    die "Unsupported MSMTP_SECRET_METHOD in $env_file: $secret_method"
    ;;
esac
