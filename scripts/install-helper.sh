#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=./lib/common.sh
. "${script_dir}/lib/common.sh"

usage() {
  cat <<'EOF'
Usage: scripts/install-helper.sh [--accounts-dir PATH]
                                 [--default-account NAME]
                                 [--output PATH]
                                 [--target PATH]
                                 [--mode copy|symlink]
                                 [--force]

Interactive wrapper around scripts/install.sh. When run in a terminal without
an explicit target or install mode, it prompts for the missing choices and
explains the deployment tradeoffs.
EOF
}

accounts_dir="${repo_root}/accounts"
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

choose_target_path() {
  local choice custom_target

  printf 'Install target guidance:\n' >&2
  printf '  1. User config    Recommended for desktop or single-user setups.\n' >&2
  printf '  2. System config  Recommended for root-managed server installs.\n' >&2
  printf '  3. Custom path    Use when another tool or user will consume the rendered file.\n' >&2
  choice="$(choose_from_menu "Choose where the live msmtp config should be installed:" \
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

  printf 'Install mode guidance:\n' >&2
  printf '  1. Copy a real file  Recommended for servers and standalone machine-local installs.\n' >&2
  printf '  2. Create a symlink  Recommended for desktops when you want the live file to point back into the repo.\n' >&2
  choice="$(choose_from_menu "Choose how the live config should be installed:" \
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

account_count() {
  local directory="$1"
  local count=0
  local env_path

  while IFS= read -r env_path; do
    [ -n "$env_path" ] || continue
    count=$((count + 1))
  done <<EOF
$(list_account_env_files "$directory")
EOF

  printf '%s\n' "$count"
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

[ -d "$accounts_dir" ] || die "Accounts directory not found: $accounts_dir"
[ -n "$(list_account_env_files "$accounts_dir")" ] || die "No account env files found in: $accounts_dir"

if ! [ -t 0 ]; then
  [ -n "$target_path" ] || target_path="${HOME}/.msmtprc"
  [ -n "$install_mode" ] || install_mode="copy"
fi

if [ -z "$target_path" ]; then
  require_tty
  show_prompt_help
  choose_target_path
fi

if [ -z "$install_mode" ]; then
  require_tty
  show_prompt_help
  choose_install_mode
fi

if [ -z "$default_account" ]; then
  detected_default="$(detect_default_account "$accounts_dir" || true)"
  if [ -n "$detected_default" ]; then
    default_account="$detected_default"
  elif [ -t 0 ] && [ "$(account_count "$accounts_dir")" -gt 1 ]; then
    show_prompt_help
    printf 'No default account is marked in %s.\n' "$accounts_dir" >&2
    printf 'Choose which account msmtp should use when no explicit account name is supplied.\n' >&2
    default_account="$(choose_from_menu "Choose the default account for this install:" $(account_names_in_dir "$accounts_dir"))"
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

install_args=(--accounts-dir "$accounts_dir")
if [ -n "$default_account" ]; then
  install_args+=(--default-account "$default_account")
fi
install_args+=(--output "$output_file" --target "$target_path" --mode "$install_mode")
if [ "$force_replace" = "true" ]; then
  install_args+=(--force)
fi

"${repo_root}/scripts/install.sh" "${install_args[@]}"
