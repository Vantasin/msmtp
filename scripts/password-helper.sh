#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=./lib/common.sh
. "${script_dir}/lib/common.sh"

usage() {
  cat <<'EOF'
Usage: scripts/password-helper.sh [--env-file PATH]
                                  [--accounts-dir PATH]
                                  [--check]

Choose an account file and dispatch to the matching password helper based on
MSMTP_SECRET_METHOD.
EOF
}

env_file=""
accounts_dir="${repo_root}/accounts"
run_check_after="false"

choose_env_file() {
  local env_files=()
  local labels=()
  local env_path label

  while IFS= read -r env_path; do
    [ -n "$env_path" ] || continue
    env_files+=("$env_path")
    labels+=("$(basename "$env_path") ($(account_name_from_env_file "$env_path"))")
  done <<EOF
$(list_account_env_files "$accounts_dir")
EOF

  [ "${#env_files[@]}" -gt 0 ] || die "No account env files found. Create one under ${accounts_dir} first."

  if [ "${#env_files[@]}" -eq 1 ]; then
    printf '%s\n' "${env_files[0]}"
    return 0
  fi

  printf 'Choose the account whose secret you want to set up.\n' >&2
  printf 'This creates the first secret for the backend configured in the account file.\n' >&2
  label="$(choose_from_menu "Choose an account file for password setup:" "${labels[@]}")"
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
    --check)
      run_check_after="true"
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
secret_method="$(secret_method_from_env_file "$env_file")"
account_name="$(account_name_from_env_file "$env_file")"

printf 'Selected %s for account %s.\n' "$env_file" "$account_name"

case "$secret_method" in
  keychain)
    "${repo_root}/scripts/keychain-add.sh" --env-file "$env_file"
    ;;
  gpg)
    "${repo_root}/scripts/gpg-file-init.sh" --env-file "$env_file"
    ;;
  password_file)
    "${repo_root}/scripts/password-file-init.sh" --env-file "$env_file"
    ;;
  command)
    printf 'This account file uses MSMTP_SECRET_METHOD=command.\n'
    printf 'No provisioning helper is available for arbitrary command backends.\n'
    printf 'Current command: %s\n' "$(passwordeval_command_from_env_file "$env_file")"
    run_check_after="true"
    ;;
  *)
    die "Unsupported MSMTP_SECRET_METHOD in $env_file: $secret_method"
    ;;
esac

if [ "$run_check_after" = "true" ]; then
  "${repo_root}/scripts/secret-check.sh" --env-file "$env_file"
elif [ -t 0 ] && [ "$(prompt_yes_no "Run secret validation now" "yes")" = "yes" ]; then
  "${repo_root}/scripts/secret-check.sh" --env-file "$env_file"
fi
