#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=./lib/common.sh
. "${script_dir}/lib/common.sh"

usage() {
  cat <<'EOF'
Usage: scripts/account-manager.sh [--env-file PATH]
                                  [--accounts-dir PATH]
                                  [--mode single|multi]
                                  [--action create|edit|add|delete|set-default|list]
                                  [--account NAME]
                                  [--force]

Manage single-account and multi-account msmtp env files from one workflow.
Interactive runs prompt for any missing choices. Non-interactive delete
operations require --force.
EOF
}

env_file="${repo_root}/.env"
accounts_dir="${repo_root}/accounts"
mode=""
action=""
account_name_arg=""
force_replace="false"

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

validate_account_file_name() {
  local account_name="$1"

  [ -n "$account_name" ] || die "Account file name cannot be empty"
  case "$account_name" in
    *[!A-Za-z0-9._-]*)
      die "Account file name must use only letters, numbers, dots, underscores, or dashes: $account_name"
      ;;
  esac
}

choose_mode() {
  local has_single="false"
  local has_multi="false"

  if [ -f "$env_file" ]; then
    has_single="true"
  fi

  if [ -n "$(list_account_env_files "$accounts_dir")" ]; then
    has_multi="true"
  fi

  if [ "$has_single" = "true" ] && [ "$has_multi" != "true" ]; then
    printf 'single\n'
    return 0
  fi

  if [ "$has_single" != "true" ] && [ "$has_multi" = "true" ]; then
    printf 'multi\n'
    return 0
  fi

  choice="$(choose_from_menu "Choose an account workflow:" \
    "Single account in $(basename "$env_file")" \
    "Multiple accounts in $(basename "$accounts_dir")/")"

  case "$choice" in
    "Single account in $(basename "$env_file")")
      printf 'single\n'
      ;;
    *)
      printf 'multi\n'
      ;;
  esac
}

choose_account_file() {
  local env_files=()
  local labels=()
  local label

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

run_single_workflow() {
  local setup_args=(--env-file "$env_file")

  if [ -f "$env_file" ]; then
    setup_args+=(--overwrite)
  fi

  "${repo_root}/scripts/setup.sh" "${setup_args[@]}"
}

run_multi_action() {
  local selected_env_file account_file_name setup_args

  case "$1" in
    add)
      mkdir -p "$accounts_dir"
      account_file_name="${account_name_arg:-$(prompt_required "Account file name" "account")}"
      validate_account_file_name "$account_file_name"
      selected_env_file="$(account_env_path_for_name "$account_file_name")"
      [ ! -e "$selected_env_file" ] || die "Account file already exists: $selected_env_file"
      "${repo_root}/scripts/setup.sh" --env-file "$selected_env_file"
      ;;
    edit)
      if [ -n "$account_name_arg" ]; then
        validate_account_file_name "$account_name_arg"
        selected_env_file="$(account_env_path_for_name "$account_name_arg")"
      else
        selected_env_file="$(choose_account_file)"
      fi
      [ -f "$selected_env_file" ] || die "Account file not found: $selected_env_file"
      "${repo_root}/scripts/setup.sh" --env-file "$selected_env_file" --overwrite
      ;;
    delete)
      if [ -n "$account_name_arg" ]; then
        validate_account_file_name "$account_name_arg"
        selected_env_file="$(account_env_path_for_name "$account_name_arg")"
      else
        selected_env_file="$(choose_account_file)"
      fi
      delete_account_file "$selected_env_file"
      ;;
    set-default)
      if [ -n "$account_name_arg" ]; then
        validate_account_file_name "$account_name_arg"
        selected_env_file="$(account_env_path_for_name "$account_name_arg")"
      else
        selected_env_file="$(choose_account_file)"
      fi
      [ -f "$selected_env_file" ] || die "Account file not found: $selected_env_file"
      set_default_account "$selected_env_file"
      ;;
    list)
      while IFS= read -r env_path; do
        [ -n "$env_path" ] || continue
        printf '%s\n' "$(account_label_for_env_file "$env_path")"
      done <<EOF
$(list_account_env_files "$accounts_dir")
EOF
      ;;
    *)
      die "Unsupported multi-account action: $1"
      ;;
  esac
}

choose_multi_action() {
  local action_label

  action_label="$(choose_from_menu "Choose an account action:" \
    "Add an account" \
    "Edit an account" \
    "Delete an account" \
    "Set the default account" \
    "List accounts" \
    "Done")"

  case "$action_label" in
    "Add an account")
      printf 'add\n'
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
    --mode)
      [ $# -ge 2 ] || die "--mode requires a value"
      mode="$2"
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

case "$mode" in
  "" )
    require_tty
    mode="$(choose_mode)"
    ;;
  single | multi)
    ;;
  *)
    die "Unsupported mode: $mode"
    ;;
esac

if [ "$mode" = "single" ]; then
  run_single_workflow
  exit 0
fi

if [ -n "$action" ]; then
  run_multi_action "$action"
  exit 0
fi

require_tty
while true; do
  next_action="$(choose_multi_action)"
  if [ "$next_action" = "done" ]; then
    exit 0
  fi

  run_multi_action "$next_action"
  printf '\n' >&2
done
