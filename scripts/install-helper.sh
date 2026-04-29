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
                                 [--result-file PATH]
                                 [--force]

Interactive wrapper around scripts/install.sh. When run in a terminal without
an explicit target or install mode, it prompts for the missing choices and can
resolve default-account ambiguity for the current install without rewriting
account files.
EOF
}

accounts_dir="${repo_root}/accounts"
default_account=""
output_file=""
target_path=""
install_mode=""
force_replace="false"
result_file=""

account_choice_label_for_env_file() {
  local env_path="$1"
  local suffix="${2:-}"
  local file_label account_label

  file_label="$(basename "$env_path")"
  account_label="$(account_name_from_env_file "$env_path")"

  if [ -n "$suffix" ]; then
    printf '%s -> %s (%s)\n' "$file_label" "$account_label" "$suffix"
  else
    printf '%s -> %s\n' "$file_label" "$account_label"
  fi
}

choose_target_path() {
  local choice custom_target

  choice="$(
    choose_from_menu "Choose where the live msmtp config should be installed:" \
      "User config ~/.msmtprc (Recommended for desktop or single-user setups)" \
      "System config /etc/msmtprc (Recommended for root-managed server installs)" \
      "Custom path"
  )"

  case "$choice" in
    "User config ~/.msmtprc (Recommended for desktop or single-user setups)")
      target_path="${HOME}/.msmtprc"
      ;;
    "System config /etc/msmtprc (Recommended for root-managed server installs)")
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

  choice="$(
    choose_from_menu "Choose how the live config should be installed:" \
      "Copy a real file (Recommended for servers and standalone machine-local installs)" \
      "Create a symlink (Recommended for desktops when you want the live file to point back into the repo)"
  )"

  case "$choice" in
    "Copy a real file (Recommended for servers and standalone machine-local installs)")
      install_mode="copy"
      ;;
    *)
      install_mode="symlink"
      ;;
  esac
}

only_account_env_file() {
  local directory="$1"
  local found_env_path=""
  local env_path

  while IFS= read -r env_path; do
    [ -n "$env_path" ] || continue
    if [ -n "$found_env_path" ]; then
      return 1
    fi
    found_env_path="$env_path"
  done <<EOF
$(list_account_env_files "$directory")
EOF

  [ -n "$found_env_path" ] || return 1
  printf '%s\n' "$found_env_path"
}

use_only_account_for_install() {
  local directory="$1"
  local reason_text="$2"
  local only_env_file account_name default_file

  only_env_file="$(only_account_env_file "$directory")" || return 1
  account_name="$(account_name_from_env_file "$only_env_file")"
  default_file="$(default_account_file_for_directory "$directory")"

  printf '%s\n' "$reason_text" >&2
  printf 'Using the only account in %s for this install: %s.\n' "$directory" "$(account_choice_label_for_env_file "$only_env_file")" >&2
  printf 'Run make account if you want to save that choice persistently in %s.\n' "$default_file" >&2

  printf '%s\n' "$account_name"
}

print_marked_default_accounts() {
  local directory="$1"
  local env_path default_name

  while IFS= read -r env_path; do
    [ -n "$env_path" ] || continue
    default_name="$(default_account_name_from_env_file "$env_path")"
    [ -n "$default_name" ] || continue
    printf '  - %s\n' "$(account_choice_label_for_env_file "$env_path" "legacy default marker")" >&2
  done <<EOF
$(list_account_env_files "$directory")
EOF
}

choose_default_account_for_install() {
  local directory="$1"
  local intro_text="$2"
  local env_files=()
  local labels=()
  local env_path default_name label

  while IFS= read -r env_path; do
    [ -n "$env_path" ] || continue
    env_files+=("$env_path")
    default_name="$(default_account_name_from_env_file "$env_path")"
    if [ -n "$default_name" ]; then
      labels+=("$(account_choice_label_for_env_file "$env_path" "legacy default marker")")
    else
      labels+=("$(account_choice_label_for_env_file "$env_path")")
    fi
  done <<EOF
$(list_account_env_files "$directory")
EOF

  [ "${#env_files[@]}" -gt 0 ] || die "No account env files found in: $directory"

  printf '%s\n' "$intro_text" >&2
  printf 'This choice applies only to this install. It does not modify the files in %s.\n' "$directory" >&2

  label="$(choose_from_menu "Choose the default account for this install:" "${labels[@]}")"
  for i in "${!labels[@]}"; do
    if [ "${labels[$i]}" = "$label" ]; then
      account_name_from_env_file "${env_files[$i]}"
      return 0
    fi
  done

  die "Selected default account could not be resolved"
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
    --result-file)
      [ $# -ge 2 ] || die "--result-file requires a value"
      result_file="$2"
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
  "Cancelled. No install changes were written." \
  "Cancelled. Check the live config path and any adjacent .bak.* files."

[ -d "$accounts_dir" ] || die "Accounts directory not found: $accounts_dir"
[ -n "$(list_account_env_files "$accounts_dir")" ] || die "No account env files found in: $accounts_dir"

if ! [ -t 0 ]; then
  [ -n "$target_path" ] || target_path="${HOME}/.msmtprc"
  [ -n "$install_mode" ] || install_mode="copy"
fi

if [ -z "$target_path" ]; then
  require_tty
  choose_target_path
fi

if [ -z "$install_mode" ]; then
  require_tty
  choose_install_mode
fi

if [ -z "$default_account" ]; then
  detected_default_state="$(detect_default_account_state_from_directory "$accounts_dir")"
  case "$detected_default_state" in
    single:*)
      default_account="${detected_default_state#single:}"
      ;;
    none)
      if [ "$(account_count_in_directory "$accounts_dir")" -eq 1 ]; then
        default_account="$(use_only_account_for_install \
          "$accounts_dir" \
          "No persistent default account is configured.")"
      elif [ -t 0 ] && [ "$(account_count_in_directory "$accounts_dir")" -gt 1 ]; then
        default_account="$(choose_default_account_for_install \
          "$accounts_dir" \
          "No persistent default account is configured in $(default_account_file_for_directory "$accounts_dir"). msmtp still needs one default account when no explicit account name is supplied.")"
      fi
      ;;
    stale:*)
      if [ "$(account_count_in_directory "$accounts_dir")" -eq 1 ]; then
        default_account="$(use_only_account_for_install \
          "$accounts_dir" \
          "The persistent default file $(default_account_file_for_directory "$accounts_dir") points to missing account ${detected_default_state#stale:}.")"
      elif [ -t 0 ]; then
        printf 'The persistent default file %s points to missing account %s.\n' "$(default_account_file_for_directory "$accounts_dir")" "${detected_default_state#stale:}" >&2
        default_account="$(choose_default_account_for_install \
          "$accounts_dir" \
          "Choose which account msmtp should use for this install while you decide whether to update the persistent default.")"
      fi
      ;;
    multiple)
      if [ -t 0 ]; then
        printf 'Multiple account files in %s still contain legacy default markers:\n' "$accounts_dir" >&2
        print_marked_default_accounts "$accounts_dir"
        default_account="$(choose_default_account_for_install \
          "$accounts_dir" \
          "Choose which account msmtp should use for this install when no explicit account name is supplied.")"
      fi
      ;;
  esac
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

run_with_interrupt_passthrough "${repo_root}/scripts/install.sh" "${install_args[@]}"
if [ -n "$result_file" ]; then
  mkdir -p "$(dirname "$result_file")"
  {
    write_env_assignment INSTALL_TARGET_PATH "$target_path"
    write_env_assignment INSTALL_MODE "$install_mode"
    write_env_assignment INSTALL_OUTPUT_FILE "$output_file"
    write_env_assignment INSTALL_DEFAULT_ACCOUNT "$default_account"
  } > "$result_file"
  chmod 600 "$result_file"
fi
