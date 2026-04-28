#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=./lib/common.sh
. "${script_dir}/lib/common.sh"

usage() {
  cat <<'EOF'
Usage: scripts/account-manager.sh [--accounts-dir PATH]
                                  [--action create|edit|delete|set-default|list]
                                  [--account NAME]
                                  [--force]

Manage account files in one accounts directory. Single-account and
multi-account setups use the same model: one file per account.
EOF
}

accounts_dir="${repo_root}/accounts"
action=""
account_name_arg=""
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
  local file_label account_label default_label

  file_label="$(basename "$env_path")"
  account_label="$(account_name_from_env_file "$env_path")"
  default_label="$(default_account_name_from_env_file "$env_path")"

  if [ -n "$default_label" ]; then
    printf '%s (%s, default)\n' "$file_label" "$account_label"
  else
    printf '%s (%s)\n' "$file_label" "$account_label"
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

  label="$(choose_from_menu "Choose an account:" "${labels[@]}")"
  for i in "${!labels[@]}"; do
    if [ "${labels[$i]}" = "$label" ]; then
      printf '%s\n' "${env_files[$i]}"
      return 0
    fi
  done

  die "Selected account could not be resolved"
}

set_default_account() {
  local selected_env_file="$1"
  local env_path

  while IFS= read -r env_path; do
    [ -n "$env_path" ] || continue
    load_env_file "$env_path"
    if [ "$env_path" = "$selected_env_file" ]; then
      MSMTP_SET_DEFAULT="true"
    else
      MSMTP_SET_DEFAULT="false"
    fi
    write_msmtp_env_file "$env_path"
  done <<EOF
$(list_account_env_files "$accounts_dir")
EOF

  printf 'Set %s as the default account.\n' "$(account_name_from_env_file "$selected_env_file")"
}

delete_account_file() {
  local env_path="$1"
  local backup_path

  [ -f "$env_path" ] || die "Account file not found: $env_path"
  backup_path="$(backup_path_for "$env_path")"

  if [ "$force_replace" != "true" ]; then
    if [ "$(prompt_yes_no "Move $(basename "$env_path") to backup ${backup_path##*/}?" "no")" != "yes" ]; then
      die "Account deletion cancelled"
    fi
  fi

  mv "$env_path" "$backup_path"
  printf 'Moved %s to %s\n' "$env_path" "$backup_path"
}

create_account() {
  local account_name env_path

  mkdir -p "$accounts_dir"
  account_name="${account_name_arg:-$(prompt_required "Account file name" "default")}"
  validate_account_file_name "$account_name"
  env_path="$(account_env_path_for_name "$account_name")"
  [ ! -e "$env_path" ] || die "Account file already exists: $env_path"
  "${repo_root}/scripts/setup.sh" --env-file "$env_path"
}

edit_account() {
  local env_path

  if [ -n "$account_name_arg" ]; then
    validate_account_file_name "$account_name_arg"
    env_path="$(account_env_path_for_name "$account_name_arg")"
  else
    env_path="$(choose_account_file)"
  fi

  [ -f "$env_path" ] || die "Account file not found: $env_path"
  "${repo_root}/scripts/setup.sh" --env-file "$env_path" --overwrite
}

set_default_from_arg_or_prompt() {
  local env_path

  if [ -n "$account_name_arg" ]; then
    validate_account_file_name "$account_name_arg"
    env_path="$(account_env_path_for_name "$account_name_arg")"
  else
    env_path="$(choose_account_file)"
  fi

  [ -f "$env_path" ] || die "Account file not found: $env_path"
  set_default_account "$env_path"
}

delete_from_arg_or_prompt() {
  local env_path

  if [ -n "$account_name_arg" ]; then
    validate_account_file_name "$account_name_arg"
    env_path="$(account_env_path_for_name "$account_name_arg")"
  else
    env_path="$(choose_account_file)"
  fi

  delete_account_file "$env_path"
}

list_accounts() {
  local env_path found_any="false"

  while IFS= read -r env_path; do
    [ -n "$env_path" ] || continue
    found_any="true"
    printf '%s\n' "$(account_label_for_env_file "$env_path")"
  done <<EOF
$(list_account_env_files "$accounts_dir")
EOF

  [ "$found_any" = "true" ] || die "No account env files found in: $accounts_dir"
}

run_action() {
  case "$1" in
    create)
      create_account
      ;;
    edit)
      edit_account
      ;;
    delete)
      delete_from_arg_or_prompt
      ;;
    set-default)
      set_default_from_arg_or_prompt
      ;;
    list)
      list_accounts
      ;;
    *)
      die "Unsupported action: $1"
      ;;
  esac
}

choose_action() {
  local env_count=0
  local env_path action_label

  while IFS= read -r env_path; do
    [ -n "$env_path" ] || continue
    env_count=$((env_count + 1))
  done <<EOF
$(list_account_env_files "$accounts_dir")
EOF

  if [ "$env_count" -eq 0 ]; then
    action_label="$(choose_from_menu "No account files exist yet. Choose an action:" \
      "Add an account" \
      "Done")"
  else
    action_label="$(choose_from_menu "Choose an account action:" \
      "Add an account" \
      "Edit an account" \
      "Delete an account" \
      "Set the default account" \
      "List accounts" \
      "Done")"
  fi

  case "$action_label" in
    "Add an account")
      printf 'create\n'
      ;;
    "Edit an account")
      printf 'edit\n'
      ;;
    "Delete an account")
      printf 'delete\n'
      ;;
    "Set the default account")
      printf 'set-default\n'
      ;;
    "List accounts")
      printf 'list\n'
      ;;
    *)
      printf 'done\n'
      ;;
  esac
}

while [ $# -gt 0 ]; do
  case "$1" in
    --accounts-dir)
      [ $# -ge 2 ] || die "--accounts-dir requires a value"
      accounts_dir="$2"
      shift 2
      ;;
    --action)
      [ $# -ge 2 ] || die "--action requires a value"
      action="$2"
      shift 2
      ;;
    --account)
      [ $# -ge 2 ] || die "--account requires a value"
      account_name_arg="$2"
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

if [ -n "$action" ]; then
  run_action "$action"
  exit 0
fi

require_tty
while true; do
  next_action="$(choose_action)"
  if [ "$next_action" = "done" ]; then
    exit 0
  fi

  run_action "$next_action"
  printf '\n' >&2
done
