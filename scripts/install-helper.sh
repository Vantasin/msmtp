#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=./lib/common.sh
. "${script_dir}/lib/common.sh"

usage() {
  cat <<'EOF'
Usage: scripts/install-helper.sh [--env-file PATH | --accounts-dir PATH]
                                 [--default-account NAME]
                                 [--output PATH]
                                 [--target PATH]
                                 [--mode copy|symlink]
                                 [--force]

Interactive wrapper around scripts/install.sh. When run in a terminal without
explicit source, target, or mode values, it prompts for the missing choices.
EOF
}

env_file=""
accounts_dir=""
default_account=""
output_file=""
target_path=""
install_mode=""
force_replace="false"

account_names_in_dir() {
  local directory="$1"
  local env_path

  while IFS= read -r env_path; do
    [ -n "$env_path" ] || continue
    account_name_from_env_file "$env_path"
  done <<EOF
$(list_account_env_files "$directory")
EOF
}

detect_default_account() {
  local directory="$1"
  local env_path default_name found_default=""

  while IFS= read -r env_path; do
    [ -n "$env_path" ] || continue
    default_name="$(default_account_name_from_env_file "$env_path")"
    if [ -n "$default_name" ]; then
      if [ -n "$found_default" ] && [ "$found_default" != "$default_name" ]; then
        printf '\n'
        return 1
      fi
      found_default="$default_name"
    fi
  done <<EOF
$(list_account_env_files "$directory")
EOF

  printf '%s\n' "$found_default"
}

choose_input_source() {
  local has_single="false"
  local has_multi="false"
  local choice

  if [ -f "${repo_root}/.env" ]; then
    has_single="true"
  fi

  if [ -n "$(list_account_env_files "${repo_root}/accounts")" ]; then
    has_multi="true"
  fi

  if [ "$has_single" = "true" ] && [ "$has_multi" != "true" ]; then
    env_file="${repo_root}/.env"
    return 0
  fi

  if [ "$has_single" != "true" ] && [ "$has_multi" = "true" ]; then
    accounts_dir="${repo_root}/accounts"
    return 0
  fi

  choice="$(choose_from_menu "Choose the config source to install:" \
    "Single account from .env" \
    "All accounts from accounts/")"

  case "$choice" in
    "Single account from .env")
      env_file="${repo_root}/.env"
      ;;
    *)
      accounts_dir="${repo_root}/accounts"
      ;;
  esac
}

choose_target_path() {
  local choice custom_target

  choice="$(choose_from_menu "Choose the install target:" \
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
      custom_target="$(prompt_required "Custom install path")"
      target_path="$custom_target"
      ;;
  esac
}

choose_install_mode() {
  local choice

  choice="$(choose_from_menu "Choose how the config should be installed:" \
    "Copy a real file" \
    "Create a symlink")"

  case "$choice" in
    "Copy a real file")
      install_mode="copy"
      ;;
    *)
      install_mode="symlink"
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
    --default-account)
      [ $# -ge 2 ] || die "--default-account requires a value"
      default_account="$2"
      shift 2
      ;;
    --output)
      [ $# -ge 2 ] || die "--output requires a value"
      output_file="$2"
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

if [ -n "$env_file" ] && [ -n "$accounts_dir" ]; then
  die "Use either --env-file or --accounts-dir, not both"
fi

if ! [ -t 0 ]; then
  [ -n "$env_file" ] || [ -n "$accounts_dir" ] || env_file="${repo_root}/.env"
  [ -n "$target_path" ] || target_path="${HOME}/.msmtprc"
  [ -n "$install_mode" ] || install_mode="copy"
fi

if [ -z "$env_file" ] && [ -z "$accounts_dir" ]; then
  require_tty
  choose_input_source
fi

if [ -t 0 ] && [ -z "$accounts_dir" ] && [ "$env_file" = "${repo_root}/.env" ] && [ -n "$(list_account_env_files "${repo_root}/accounts")" ]; then
  env_file=""
  choose_input_source
fi

if [ -z "$target_path" ]; then
  require_tty
  choose_target_path
fi

if [ -t 0 ] && [ "$target_path" = "${HOME}/.msmtprc" ]; then
  choose_target_path
fi

if [ -z "$install_mode" ]; then
  require_tty
  choose_install_mode
fi

if [ -n "$accounts_dir" ] && [ -z "$default_account" ]; then
  detected_default="$(detect_default_account "$accounts_dir" || true)"
  if [ -z "$detected_default" ] && [ -t 0 ]; then
    default_account="$(choose_from_menu "Choose the default account for this install:" $(account_names_in_dir "$accounts_dir"))"
  else
    default_account="$detected_default"
  fi
fi

if [ -z "$output_file" ]; then
  if [ "$install_mode" = "copy" ] && [ "$target_path" = "/etc/msmtprc" ]; then
    output_file="$target_path"
  else
    output_file="${repo_root}/.msmtprc.generated"
  fi
elif [ "$output_file" = "${repo_root}/.msmtprc.generated" ] && [ "$install_mode" = "copy" ] && [ "$target_path" = "/etc/msmtprc" ]; then
  output_file="$target_path"
fi

install_args=()
if [ -n "$accounts_dir" ]; then
  install_args+=(--accounts-dir "$accounts_dir")
else
  install_args+=(--env-file "$env_file")
fi
if [ -n "$default_account" ]; then
  install_args+=(--default-account "$default_account")
fi
install_args+=(--output "$output_file" --target "$target_path" --mode "$install_mode")
if [ "$force_replace" = "true" ]; then
  install_args+=(--force)
fi

"${repo_root}/scripts/install.sh" "${install_args[@]}"
