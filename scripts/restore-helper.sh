#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=./lib/common.sh
. "${script_dir}/lib/common.sh"

usage() {
  cat <<'EOF'
Usage: scripts/restore-helper.sh [--backup PATH]
                                 [--target PATH]
                                 [--force]

Interactive wrapper around scripts/restore-backup.sh. When run in a terminal
without a backup path, it lists matching backups for the chosen target and
prompts for a selection.
EOF
}

backup_path=""
target_path=""
force_replace="false"

choose_target_path() {
  local choice custom_target

  choice="$(choose_from_menu "Choose the target you want to restore:" \
    "User config (~/.msmtprc)" \
    "System config (/etc/msmtprc)" \
    "Custom path")"

  case "$choice" in
    "User config (~/.msmtprc)")
      target_path="${HOME}/.msmtprc"
      ;;
    "System config (/etc/msmtprc)")
      target_path="/etc/msmtprc"
      ;;
    *)
      custom_target="$(prompt_required "Custom target path")"
      target_path="$custom_target"
      ;;
  esac
}

choose_backup_for_target() {
  local backups=()
  local backup

  while IFS= read -r backup; do
    [ -n "$backup" ] || continue
    backups+=("$backup")
  done <<EOF
$(find "$(dirname "$target_path")" -maxdepth 1 \( -type f -o -type l \) -name "$(basename "$target_path").bak.*" | sort -r)
EOF

  [ "${#backups[@]}" -gt 0 ] || die "No backups found for target: $target_path"

  choose_from_menu "Choose a backup to restore into $target_path:" "${backups[@]}"
}

while [ $# -gt 0 ]; do
  case "$1" in
    --backup)
      [ $# -ge 2 ] || die "--backup requires a value"
      backup_path="$2"
      shift 2
      ;;
    --target)
      [ $# -ge 2 ] || die "--target requires a value"
      target_path="$2"
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
  "Cancelled. No restore changes were written." \
  "Cancelled. Check the live config path and any adjacent .bak.* files."

if [ -z "$target_path" ]; then
  if [ -t 0 ]; then
    choose_target_path
  else
    target_path="${HOME}/.msmtprc"
  fi
fi

if [ -z "$backup_path" ]; then
  require_tty
  backup_path="$(choose_backup_for_target)"
fi

restore_args=(--backup "$backup_path" --target "$target_path")
if [ "$force_replace" = "true" ]; then
  restore_args+=(--force)
fi

run_with_interrupt_passthrough "${repo_root}/scripts/restore-backup.sh" "${restore_args[@]}"
