#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=./lib/common.sh
. "${script_dir}/lib/common.sh"

usage() {
  cat <<'EOF'
Usage: scripts/test-email.sh [--env-file PATH]
                             [--accounts-dir PATH]
                             [--recipient ADDRESS]
                             [--subject TEXT]
                             [--body TEXT]
                             [--yes]

Send a real test email for one account using a temporary one-account render.
This verifies the selected SMTP account without depending on the installed
live config path.
EOF
}

env_file=""
accounts_dir="${repo_root}/accounts"
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

  printf 'Choose the account you want to test.\n' >&2
  printf 'This sends a real email using the selected SMTP account.\n' >&2
  label="$(choose_from_menu "Choose an account file for the test email:" "${labels[@]}")"
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

send_test_email() {
  local temp_accounts_dir="$1"
  local env_file_path="$2"
  local selected_account_name="$3"
  local selected_from="$4"
  local selected_recipient="$5"
  local selected_subject="$6"
  local selected_body="$7"
  local temp_config_path="" temp_env_path="" message=""

  temp_env_path="${temp_accounts_dir}/$(basename "$env_file_path")"
  cp "$env_file_path" "$temp_env_path"
  printf '%s\n' "$selected_account_name" > "${temp_accounts_dir}/.default-account"

  temp_config_path="$(mktemp "${TMPDIR:-/tmp}/msmtp-test-email.XXXXXX")"
  chmod 600 "$temp_config_path"
  TEMP_TEST_EMAIL_CONFIG="$temp_config_path"

  run_with_interrupt_passthrough \
    "${repo_root}/scripts/render-config.sh" \
    --accounts-dir "$temp_accounts_dir" \
    --output "$temp_config_path" >/dev/null

  message="$(printf 'From: %s\nTo: %s\nSubject: %s\n\n%s\n' \
    "$selected_from" \
    "$selected_recipient" \
    "$selected_subject" \
    "$selected_body")"

  mark_interrupt_dirty
  printf '%s' "$message" | run_with_interrupt_passthrough msmtp -C "$temp_config_path" -a "$selected_account_name" "$selected_recipient"
}

cleanup_test_email_files() {
  [ -n "${TEMP_TEST_EMAIL_DIR:-}" ] && rm -rf "${TEMP_TEST_EMAIL_DIR}"
  [ -n "${TEMP_TEST_EMAIL_CONFIG:-}" ] && rm -f "${TEMP_TEST_EMAIL_CONFIG}"
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
  "Cancelled. No test email was sent." \
  "Cancelled. The test email may have been partially sent. Check the recipient mailbox and SMTP logs."
trap cleanup_test_email_files EXIT

command -v msmtp >/dev/null 2>&1 || die "The msmtp command was not found. Install msmtp first."

if [ -z "$env_file" ]; then
  if [ -t 0 ]; then
    env_file="$(choose_env_file)"
  else
    env_file="$(default_env_file_if_unambiguous)" || die "This command requires --env-file or a single account file in ${accounts_dir} when run non-interactively"
  fi
fi

require_file "$env_file"
load_env_file "$env_file"
require_var MSMTP_ACCOUNT_NAME
require_var MSMTP_FROM

account_name="$MSMTP_ACCOUNT_NAME"
from_address="$MSMTP_FROM"

printf 'Selected account file %s (msmtp account name: %s).\n' "$env_file" "$account_name" >&2
printf 'This sends a real email using a temporary one-account render from the selected account file.\n' >&2

if [ -t 0 ]; then
  recipient="$(prompt_required "Recipient email address" "${recipient:-$from_address}")"
  subject="$(prompt_required "Email subject" "${subject:-msmtp test from ${account_name}}")"
  body="$(prompt_required "Email body" "${body:-msmtp is working.}")"
else
  recipient="${recipient:-$from_address}"
  subject="${subject:-msmtp test from ${account_name}}"
  body="${body:-msmtp is working.}"
fi

[ -n "$recipient" ] || die "A recipient email address is required"
[ -n "$subject" ] || die "An email subject is required"
[ -n "$body" ] || die "An email body is required"

printf 'Test email summary:\n' >&2
printf '  Account:   %s\n' "$account_name" >&2
printf '  From:      %s\n' "$from_address" >&2
printf '  Recipient: %s\n' "$recipient" >&2
printf '  Subject:   %s\n' "$subject" >&2

if [ "$auto_confirm" != "true" ] && [ -t 0 ]; then
  [ "$(prompt_yes_no "Send the test email now" "yes")" = "yes" ] || {
    printf 'Cancelled. No test email was sent.\n' >&2
    exit 0
  }
fi

TEMP_TEST_EMAIL_DIR="$(mktemp -d "${TMPDIR:-/tmp}/msmtp-test-account.XXXXXX")"
send_test_email "$TEMP_TEST_EMAIL_DIR" "$env_file" "$account_name" "$from_address" "$recipient" "$subject" "$body"

printf 'Test email sent.\n' >&2
printf 'Next steps:\n' >&2
printf '  1. Confirm the message arrived in %s.\n' "$recipient" >&2
printf '  2. Run make rotate-password ACCOUNT_NAME=%s when the SMTP secret changes.\n' "$(basename "$env_file" .env)" >&2
