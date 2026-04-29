#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=./lib/common.sh
. "${script_dir}/lib/common.sh"

usage() {
  cat <<'EOF'
Usage: scripts/configure.sh [--accounts-dir PATH]
                            [--default-account NAME]
                            [--target PATH]
                            [--mode copy|symlink]
                            [--force]

Guided human workflow for account setup, secret provisioning or rotation,
secret validation, and install.
EOF
}

accounts_dir="${repo_root}/accounts"
default_account=""
target_path=""
install_mode=""
force_replace="false"

validate_account_file_name() {
  local account_name="$1"

  [ -n "$account_name" ] || die "Account file name cannot be empty"
  case "$account_name" in
    *[!A-Za-z0-9._-]*)
      die "Account file name must use only letters, numbers, dots, underscores, or dashes: $account_name"
      ;;
  esac
}

account_env_path_for_name() {
  local account_name="$1"

  printf '%s/%s.env\n' "$accounts_dir" "$account_name"
}

account_label_for_env_file() {
  local env_path="$1"
  local file_label account_label current_default_account

  file_label="$(basename "$env_path")"
  account_label="$(account_name_from_env_file "$env_path")"
  current_default_account="$(current_default_account_name_from_directory "$accounts_dir" || true)"

  if [ -n "$current_default_account" ] && [ "$account_label" = "$current_default_account" ]; then
    printf '%s (msmtp account: %s, persistent default)\n' "$file_label" "$account_label"
  else
    printf '%s (msmtp account: %s)\n' "$file_label" "$account_label"
  fi
}

choose_account_file() {
  local env_files=()
  local labels=()
  local env_path label

  while IFS= read -r env_path; do
    [ -n "$env_path" ] || continue
    env_files+=("$env_path")
    labels+=("$(account_label_for_env_file "$env_path")")
  done <<EOF
$(list_account_env_files "$accounts_dir")
EOF

  [ "${#env_files[@]}" -gt 0 ] || die "No account env files found in: $accounts_dir"

  label="$(choose_from_menu "Choose the account file to continue with:" "${labels[@]}")"
  for i in "${!labels[@]}"; do
    if [ "${labels[$i]}" = "$label" ]; then
      printf '%s\n' "${env_files[$i]}"
      return 0
    fi
  done

  die "Selected account file could not be resolved"
}

choose_workflow_action() {
  local env_count=0
  local env_path action_label

  while IFS= read -r env_path; do
    [ -n "$env_path" ] || continue
    env_count=$((env_count + 1))
  done <<EOF
$(list_account_env_files "$accounts_dir")
EOF

  printf 'Guided msmtp configuration\n' >&2
  printf 'This flow can create or edit an account, set up or rotate its secret, validate it, and install the live config.\n' >&2
  printf 'The install step applies the full account set in %s.\n\n' "$accounts_dir" >&2

  if [ "$env_count" -eq 0 ]; then
    action_label="$(choose_from_menu "No account files exist yet. Choose how to begin:" \
      "Add a new account - create a new accounts/<name>.env file and continue" \
      "Done")"
  else
    action_label="$(choose_from_menu "Choose how to begin:" \
      "Add a new account - create a new accounts/<name>.env file and continue" \
      "Edit an existing account - update one account file and continue" \
      "Use an existing account - skip editing and continue with secrets/install" \
      "Done")"
  fi

  case "$action_label" in
    "Add a new account - create a new accounts/<name>.env file and continue")
      printf 'create\n'
      ;;
    "Edit an existing account - update one account file and continue")
      printf 'edit\n'
      ;;
    "Use an existing account - skip editing and continue with secrets/install")
      printf 'use\n'
      ;;
    *)
      printf 'done\n'
      ;;
  esac
}

choose_secret_action() {
  local action_label

  action_label="$(choose_from_menu "Choose what to do with the account secret next:" \
    "Set up the secret - create the first Keychain entry, GPG file, or password file and validate it" \
    "Rotate the secret - replace the existing secret and validate it" \
    "Skip secret changes - leave the secret backend as-is")"

  case "$action_label" in
    "Set up the secret - create the first Keychain entry, GPG file, or password file and validate it")
      printf 'setup\n'
      ;;
    "Rotate the secret - replace the existing secret and validate it")
      printf 'rotate\n'
      ;;
    *)
      printf 'skip\n'
      ;;
  esac
}

prompt_install_decision() {
  printf 'The install step renders the full config from %s and updates the live msmtp path.\n' "$accounts_dir" >&2
  prompt_yes_no "Install the live msmtp config now" "yes"
}

while [ $# -gt 0 ]; do
  case "$1" in
    --accounts-dir)
      [ $# -ge 2 ] || die "--accounts-dir requires a value"
      accounts_dir="$2"
      shift 2
      ;;
    --default-account)
      [ $# -ge 2 ] || die "--default-account requires a value"
      default_account="$2"
      shift 2
      ;;
    --target)
      [ $# -ge 2 ] || die "--target requires a value"
      target_path="$2"
      shift 2
      ;;
    --mode)
      [ $# -ge 2 ] || die "--mode requires a value"
      install_mode="$2"
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

install_interrupt_handler \
  "Cancelled. No configuration changes were completed." \
  "Cancelled. Check the account files, secret backends, and live config paths for partial changes or adjacent .bak.* files."

require_tty
mkdir -p "$accounts_dir"

workflow_action="$(choose_workflow_action)"
[ "$workflow_action" != "done" ] || exit 0

env_file=""

case "$workflow_action" in
  create)
    printf 'Examples for account file names: default, work, personal, server-alerts\n' >&2
    account_file_name="$(prompt_required "Account file name" "default")"
    validate_account_file_name "$account_file_name"
    env_file="$(account_env_path_for_name "$account_file_name")"
    [ ! -e "$env_file" ] || die "Account file already exists: $env_file"
    run_with_interrupt_passthrough "${repo_root}/scripts/setup.sh" --env-file "$env_file"
    mark_interrupt_dirty
    ;;
  edit)
    env_file="$(choose_account_file)"
    run_with_interrupt_passthrough "${repo_root}/scripts/setup.sh" --env-file "$env_file" --overwrite
    mark_interrupt_dirty
    ;;
  use)
    env_file="$(choose_account_file)"
    ;;
esac

require_file "$env_file"
load_env_file "$env_file"
account_file_name="$(basename "$env_file" .env)"
account_name="${MSMTP_ACCOUNT_NAME:-}"

printf '\nSelected account file %s (msmtp account name: %s).\n' "$env_file" "$account_name" >&2

secret_action="$(choose_secret_action)"
case "$secret_action" in
  setup)
    run_with_interrupt_passthrough "${repo_root}/scripts/password-helper.sh" --env-file "$env_file" --check
    mark_interrupt_dirty
    ;;
  rotate)
    rotate_args=(--env-file "$env_file")
    if [ -n "$force_replace" ]; then
      rotate_args+=(--force)
    fi
    run_with_interrupt_passthrough "${repo_root}/scripts/rotate-password.sh" "${rotate_args[@]}"
    mark_interrupt_dirty
    ;;
  skip)
    if [ "$(prompt_yes_no "Run secret validation now" "yes")" = "yes" ]; then
      "${repo_root}/scripts/secret-check.sh" --env-file "$env_file"
    fi
    ;;
esac

if [ "$(prompt_install_decision)" = "yes" ]; then
  install_args=(--accounts-dir "$accounts_dir")
  if [ -n "$default_account" ]; then
    install_args+=(--default-account "$default_account")
  fi
  if [ -n "$target_path" ]; then
    install_args+=(--target "$target_path")
  fi
  if [ -n "$install_mode" ]; then
    install_args+=(--mode "$install_mode")
  fi
  if [ "$force_replace" = "true" ]; then
    install_args+=(--force)
  fi
  run_with_interrupt_passthrough "${repo_root}/scripts/install-helper.sh" "${install_args[@]}"
  mark_interrupt_dirty
  printf '\nNext steps:\n' >&2
  printf '  1. Run make test-email ACCOUNT_NAME=%s to send a live test email.\n' "$account_file_name" >&2
  printf '  2. Use make rotate-password ACCOUNT_NAME=%s when this secret changes.\n' "$account_file_name" >&2
  exit 0
fi

printf '\nNext steps:\n' >&2
printf '  1. Run make install to deploy the current account set.\n' >&2
printf '  2. Run make secret-check ACCOUNT_NAME=%s if you want to revalidate this account later.\n' "$account_file_name" >&2
printf '  3. Use make rotate-password ACCOUNT_NAME=%s when this secret changes.\n' "$account_file_name" >&2
