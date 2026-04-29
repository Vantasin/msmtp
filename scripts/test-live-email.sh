#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=./lib/common.sh
. "${script_dir}/lib/common.sh"

usage() {
  cat <<'EOF'
Usage: scripts/test-live-email.sh [--env-file PATH]
                                  [--accounts-dir PATH]
                                  [--target PATH]
                                  [--recipient ADDRESS]
                                  [--subject TEXT]
                                  [--body TEXT]
                                  [--yes]

Send a real test email using the installed live msmtp config path instead of a
temporary one-account render.
EOF
}

env_file=""
accounts_dir="${repo_root}/accounts"
target_path=""
recipient=""
subject=""
body=""
auto_confirm="false"

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

choose_env_file() {
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

  [ "${#env_files[@]}" -gt 0 ] || die "No account env files found. Create one under ${accounts_dir} first."

  if [ "${#env_files[@]}" -eq 1 ]; then
    printf 'Using the only account file in %s: %s (msmtp account: %s).\n' \
      "$accounts_dir" \
      "${env_files[0]}" \
      "$(account_name_from_env_file "${env_files[0]}")" >&2
    printf '%s\n' "${env_files[0]}"
    return 0
  fi

  printf 'Choose the account you want to test against the installed live config.\n' >&2
  printf 'This sends a real email using the live msmtp config path, not a temporary render.\n' >&2
  label="$(choose_from_menu "Choose an account file for the live-config test:" "${labels[@]}")"
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

choose_target_path() {
  local choice custom_target

  choice="$(choose_from_menu "Choose which live msmtp config path to test:" \
    "User config ~/.msmtprc (Recommended for desktop or single-user setups)" \
    "System config /etc/msmtprc (Recommended for root-managed server installs)" \
    "Custom path")"

  case "$choice" in
    "User config ~/.msmtprc (Recommended for desktop or single-user setups)")
      target_path="${HOME}/.msmtprc"
      ;;
    "System config /etc/msmtprc (Recommended for root-managed server installs)")
      target_path="/etc/msmtprc"
      ;;
    *)
      custom_target="$(prompt_required "Live config path to test")"
      target_path="$custom_target"
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
    --target)
      [ $# -ge 2 ] || die "--target requires a value"
      target_path="$2"
      shift 2
      ;;
    --recipient)
      [ $# -ge 2 ] || die "--recipient requires a value"
      recipient="$2"
      shift 2
      ;;
    --subject)
      [ $# -ge 2 ] || die "--subject requires a value"
      subject="$2"
      shift 2
      ;;
    --body)
      [ $# -ge 2 ] || die "--body requires a value"
      body="$2"
      shift 2
      ;;
    --yes)
      auto_confirm="true"
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
  "Cancelled. No live-config test email was sent." \
  "Cancelled. The live-config test email may have been partially sent. Check the recipient mailbox and SMTP logs."

command -v msmtp >/dev/null 2>&1 || die "The msmtp command was not found. Install msmtp first."

if [ -z "$env_file" ]; then
  if [ -t 0 ]; then
    env_file="$(choose_env_file)"
  else
    env_file="$(default_env_file_if_unambiguous)" || die "This command requires --env-file or a single account file in ${accounts_dir} when run non-interactively"
  fi
fi

if [ -z "$target_path" ]; then
  if [ -t 0 ]; then
    choose_target_path
  else
    target_path="${HOME}/.msmtprc"
  fi
fi

target_path="$(normalize_managed_path "$target_path")"
path_exists "$target_path" || die "Live config target not found: $target_path"

require_file "$env_file"
load_env_file "$env_file"
require_var MSMTP_ACCOUNT_NAME
require_var MSMTP_FROM

account_name="$MSMTP_ACCOUNT_NAME"
from_address="$MSMTP_FROM"
validate_msmtp_account_name "$account_name" "$env_file"

printf 'Selected account file %s (msmtp account name: %s).\n' "$env_file" "$account_name" >&2
printf 'This sends a real email using the live config path %s.\n' "$target_path" >&2
printf 'It will fail if that config is stale or does not contain account %s.\n' "$account_name" >&2

if [ -t 0 ]; then
  recipient="$(prompt_required "Recipient email address" "${recipient:-$from_address}")"
  subject="$(prompt_required "Email subject" "${subject:-msmtp live-config test from ${account_name}}")"
  body="$(prompt_required "Email body" "${body:-msmtp live config is working.}")"
else
  recipient="${recipient:-$from_address}"
  subject="${subject:-msmtp live-config test from ${account_name}}"
  body="${body:-msmtp live config is working.}"
fi

[ -n "$recipient" ] || die "A recipient email address is required"
[ -n "$subject" ] || die "An email subject is required"
[ -n "$body" ] || die "An email body is required"

printf 'Live-config test email summary:\n' >&2
printf '  Config:     %s\n' "$target_path" >&2
printf '  Account:    %s\n' "$account_name" >&2
printf '  From:       %s\n' "$from_address" >&2
printf '  Recipient:  %s\n' "$recipient" >&2
printf '  Subject:    %s\n' "$subject" >&2

if [ "$auto_confirm" != "true" ] && [ -t 0 ]; then
  [ "$(prompt_yes_no "Send the live-config test email now" "yes")" = "yes" ] || {
    printf 'Cancelled. No live-config test email was sent.\n' >&2
    exit 0
  }
fi

message="$(printf 'From: %s\nTo: %s\nSubject: %s\n\n%s\n' \
  "$from_address" \
  "$recipient" \
  "$subject" \
  "$body")"

mark_interrupt_dirty
printf '%s' "$message" | run_with_interrupt_passthrough msmtp -C "$target_path" -a "$account_name" "$recipient"

printf 'Live-config test email sent.\n' >&2
printf 'Next steps:\n' >&2
printf '  1. Confirm the message arrived in %s.\n' "$recipient" >&2
printf '  2. If this fails while make test-email succeeds, rerun make install to refresh %s.\n' "$target_path" >&2
