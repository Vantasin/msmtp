#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=./lib/common.sh
. "${script_dir}/lib/common.sh"

usage() {
  cat <<'EOF'
Usage: scripts/restore-secret-helper.sh [--env-file PATH]
                                        [--accounts-dir PATH]
                                        [--backup PATH]
                                        [--force]

Restore a backed-up file-backed secret for an account and validate it.
EOF
}

env_file=""
accounts_dir="${repo_root}/accounts"
backup_path=""
force_replace="false"

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

  label="$(choose_from_menu "Choose an account file for secret restore:" "${labels[@]}")"
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

choose_backup_for_target() {
  local target_path="$1"
  local backups=()
  local labels=()
  local backup
  local label

  while IFS= read -r backup; do
    [ -n "$backup" ] || continue
    backups+=("$backup")
    labels+=("$(backup_label_for_path "$backup")")
  done <<EOF
$(backups_for_target "$target_path")
EOF

  [ "${#backups[@]}" -gt 0 ] || die "No backups found for secret target: $target_path"

  label="$(choose_from_menu "Choose a secret backup to restore into $target_path:" "${labels[@]}")"
  for i in "${!labels[@]}"; do
    if [ "${labels[$i]}" = "$label" ]; then
      printf '%s\n' "${backups[$i]}"
      return 0
    fi
  done

  die "Selected secret backup could not be resolved"
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
  "Cancelled. No secret restore changes were written." \
  "Cancelled. Check the secret backend and any adjacent .bak.* files."

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

case "$secret_method" in
  password_file)
    require_var MSMTP_PASSWORD_FILE
    target_path="$(normalize_managed_path "$MSMTP_PASSWORD_FILE")"
    ;;
  gpg)
    require_var MSMTP_GPG_FILE
    target_path="$(normalize_managed_path "$MSMTP_GPG_FILE")"
    ;;
  *)
    die "Secret restore only supports MSMTP_SECRET_METHOD=password_file or gpg in $env_file"
    ;;
esac

if [ -z "$backup_path" ]; then
  require_tty
  backup_path="$(choose_backup_for_target "$target_path")"
else
  expected_target_path="$(restore_target_path_from_backup_path "$backup_path")"
  [ "$expected_target_path" = "$target_path" ] || die "Backup $backup_path does not match the current secret target $target_path for $env_file"
fi

restore_args=(--backup "$backup_path" --target "$target_path")
if [ "$force_replace" = "true" ]; then
  restore_args+=(--force)
fi

run_with_interrupt_passthrough "${repo_root}/scripts/restore-backup.sh" "${restore_args[@]}"
"${repo_root}/scripts/secret-check.sh" --env-file "$env_file"
printf 'Next steps:\n' >&2
printf '  1. Confirm the restored secret still matches the SMTP service for %s.\n' "$account_name" >&2
printf '  2. Run make configure if you also need account or install follow-up.\n' >&2
