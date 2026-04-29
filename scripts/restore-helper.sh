#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=./lib/common.sh
. "${script_dir}/lib/common.sh"

usage() {
  cat <<'EOF'
Usage: scripts/restore-helper.sh [--type config|account|secret]
                                 [--backup PATH]
                                 [--target PATH]
                                 [--accounts-dir PATH]
                                 [--env-file PATH]
                                 [--account NAME]
                                 [--force]

Interactive restore umbrella. It can delegate to config, account, or file-
backed secret restore flows.
EOF
}

restore_type=""
backup_path=""
target_path=""
accounts_dir="${repo_root}/accounts"
env_file=""
account_name_arg=""
force_replace="false"

choose_restore_type() {
  local choice

  choice="$(
    choose_from_menu "Choose what you want to restore:" \
      "Live config - restore ~/.msmtprc, /etc/msmtprc, or another live msmtp target" \
      "Account file - restore one accounts/*.env backup" \
      "File-backed secret - restore one password_file or gpg secret backup"
  )"

  case "$choice" in
    "Live config - restore ~/.msmtprc, /etc/msmtprc, or another live msmtp target")
      printf 'config\n'
      ;;
    "Account file - restore one accounts/*.env backup")
      printf 'account\n'
      ;;
    *)
      printf 'secret\n'
      ;;
  esac
}

while [ $# -gt 0 ]; do
  case "$1" in
    --type)
      [ $# -ge 2 ] || die "--type requires a value"
      restore_type="$2"
      shift 2
      ;;
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
    --accounts-dir)
      [ $# -ge 2 ] || die "--accounts-dir requires a value"
      accounts_dir="$2"
      shift 2
      ;;
    --env-file)
      [ $# -ge 2 ] || die "--env-file requires a value"
      env_file="$2"
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

install_interrupt_handler \
  "Cancelled. No restore changes were written." \
  "Cancelled. Check the affected target and any adjacent .bak.* files."

if [ -z "$restore_type" ]; then
  if [ -t 0 ]; then
    restore_type="$(choose_restore_type)"
  else
    die "Non-interactive restore requires --type config|account|secret. Use the explicit typed restore command from the Makefile."
  fi
fi

case "$restore_type" in
  config)
    restore_args=()
    if [ -n "$backup_path" ]; then
      restore_args+=(--backup "$backup_path")
    fi
    if [ -n "$target_path" ]; then
      restore_args+=(--target "$target_path")
    fi
    if [ "$force_replace" = "true" ]; then
      restore_args+=(--force)
    fi
    run_with_interrupt_passthrough "${repo_root}/scripts/restore-config-helper.sh" "${restore_args[@]}"
    ;;
  account)
    [ -z "$target_path" ] || die "--target is only supported for config restore"
    [ -z "$env_file" ] || die "--env-file is only supported for secret restore"
    restore_args=(--accounts-dir "$accounts_dir")
    if [ -n "$account_name_arg" ]; then
      restore_args+=(--account "$account_name_arg")
    fi
    if [ -n "$backup_path" ]; then
      restore_args+=(--backup "$backup_path")
    fi
    if [ "$force_replace" = "true" ]; then
      restore_args+=(--force)
    fi
    run_with_interrupt_passthrough "${repo_root}/scripts/restore-account-helper.sh" "${restore_args[@]}"
    ;;
  secret)
    [ -z "$target_path" ] || die "--target is only supported for config restore"
    [ -z "$account_name_arg" ] || die "--account is only supported for account restore"
    restore_args=()
    if [ -n "$env_file" ]; then
      restore_args+=(--env-file "$env_file")
    else
      restore_args+=(--accounts-dir "$accounts_dir")
    fi
    if [ -n "$backup_path" ]; then
      restore_args+=(--backup "$backup_path")
    fi
    if [ "$force_replace" = "true" ]; then
      restore_args+=(--force)
    fi
    run_with_interrupt_passthrough "${repo_root}/scripts/restore-secret-helper.sh" "${restore_args[@]}"
    ;;
  *)
    die "Unsupported restore type: $restore_type"
    ;;
esac
