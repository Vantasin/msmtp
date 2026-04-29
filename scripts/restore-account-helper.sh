#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=./lib/common.sh
. "${script_dir}/lib/common.sh"

usage() {
  cat <<'EOF'
Usage: scripts/restore-account-helper.sh [--accounts-dir PATH]
                                         [--account NAME]
                                         [--backup PATH]
                                         [--force]

Restore a backed-up account file from accounts/*.env.bak.*.
EOF
}

accounts_dir="${repo_root}/accounts"
account_name_arg=""
backup_path=""
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

account_target_path_for_name() {
  local account_name="$1"

  printf '%s/%s.env\n' "$accounts_dir" "$account_name"
}

choose_backup_for_target() {
  local target_path="$1"
  local backups=()
  local backup

  while IFS= read -r backup; do
    [ -n "$backup" ] || continue
    backups+=("$backup")
  done <<EOF
$(backups_for_target "$target_path")
EOF

  [ "${#backups[@]}" -gt 0 ] || die "No backups found for account target: $target_path"

  choose_from_menu "Choose an account backup to restore into $target_path:" "${backups[@]}"
}

account_backup_label() {
  local backup="$1"
  local target_path

  target_path="$(restore_target_path_from_backup_path "$backup")"
  printf '%s -> %s\n' "$(basename "$backup")" "$(basename "$target_path")"
}

choose_backup_in_accounts_dir() {
  local backups=()
  local labels=()
  local backup label

  while IFS= read -r backup; do
    [ -n "$backup" ] || continue
    backups+=("$backup")
    labels+=("$(account_backup_label "$backup")")
  done <<EOF
$(find "$accounts_dir" -maxdepth 1 -type f -name '*.env.bak.*' | sort -r)
EOF

  [ "${#backups[@]}" -gt 0 ] || die "No account backups found in: $accounts_dir"

  label="$(choose_from_menu "Choose an account backup to restore:" "${labels[@]}")"
  for i in "${!labels[@]}"; do
    if [ "${labels[$i]}" = "$label" ]; then
      printf '%s\n' "${backups[$i]}"
      return 0
    fi
  done

  die "Selected account backup could not be resolved"
}

while [ $# -gt 0 ]; do
  case "$1" in
    --accounts-dir)
      [ $# -ge 2 ] || die "--accounts-dir requires a value"
      accounts_dir="$2"
      shift 2
      ;;
    --account)
      [ $# -ge 2 ] || die "--account requires a value"
      account_name_arg="$2"
      shift 2
      ;;
    --backup)
      [ $# -ge 2 ] || die "--backup requires a value"
      backup_path="$2"
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
  "Cancelled. No account restore changes were written." \
  "Cancelled. Check the account files and any adjacent .bak.* backups."

accounts_dir="$(normalize_managed_path "$accounts_dir")"
mkdir -p "$accounts_dir"

target_path=""
if [ -n "$backup_path" ]; then
  target_path="$(restore_target_path_from_backup_path "$backup_path")"
  case "$target_path" in
    "$accounts_dir"/*.env)
      ;;
    *)
      die "Account backup must restore into ${accounts_dir}/*.env: $backup_path"
      ;;
  esac
  if [ -n "$account_name_arg" ]; then
    validate_account_file_name "$account_name_arg"
    expected_target_path="$(account_target_path_for_name "$account_name_arg")"
    [ "$target_path" = "$expected_target_path" ] || die "Backup $backup_path does not match requested account $account_name_arg"
  fi
elif [ -n "$account_name_arg" ]; then
  require_tty
  validate_account_file_name "$account_name_arg"
  target_path="$(account_target_path_for_name "$account_name_arg")"
  backup_path="$(choose_backup_for_target "$target_path")"
else
  require_tty
  backup_path="$(choose_backup_in_accounts_dir)"
  target_path="$(restore_target_path_from_backup_path "$backup_path")"
fi

restore_args=(--backup "$backup_path" --target "$target_path")
if [ "$force_replace" = "true" ]; then
  restore_args+=(--force)
fi

run_with_interrupt_passthrough "${repo_root}/scripts/restore-backup.sh" "${restore_args[@]}"
printf 'Next steps:\n' >&2
printf '  1. Review %s.\n' "$target_path" >&2
printf '  2. Run make configure if you want guided secret or install follow-up.\n' >&2
