#!/usr/bin/env bash

common_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "${common_dir}/../.." && pwd)"

die() {
  printf 'error: %s\n' "$*" >&2
  exit 1
}

require_file() {
  [ -f "$1" ] || die "Required file not found: $1"
}

require_var() {
  local name="$1"
  local value="${!name:-}"
  [ -n "$value" ] || die "Missing required setting: $name"
}

load_env_file() {
  local env_file="$1"

  require_file "$env_file"

  set -a
  # shellcheck disable=SC1090
  . "$env_file"
  set +a
}

normalize_on_off() {
  case "${1:-}" in
    "" | 1 | on | ON | true | TRUE | yes | YES)
      printf 'on'
      ;;
    0 | off | OFF | false | FALSE | no | NO)
      printf 'off'
      ;;
    *)
      die "Invalid boolean value: $1"
      ;;
  esac
}

is_truthy() {
  case "${1:-}" in
    "" | 1 | on | ON | true | TRUE | yes | YES)
      return 0
      ;;
    0 | off | OFF | false | FALSE | no | NO)
      return 1
      ;;
    *)
      die "Invalid boolean value: $1"
      ;;
  esac
}

shell_quote() {
  printf "'%s'" "$(printf '%s' "$1" | sed "s/'/'\\\\''/g")"
}

write_env_assignment() {
  local key="$1"
  local value="${2:-}"

  printf '%s=%s\n' "$key" "$(shell_quote "$value")"
}

absolute_path() {
  local path="$1"
  local dir_path base_name

  dir_path="$(dirname "$path")"
  base_name="$(basename "$path")"
  dir_path="$(cd "$dir_path" && pwd -P)"

  printf '%s/%s\n' "$dir_path" "$base_name"
}

require_tty() {
  [ -t 0 ] || die "This command requires an interactive terminal"
}

passwordeval_command_from_env_file() {
  local env_file="$1"

  (
    load_env_file "$env_file"
    passwordeval_command
  )
}

passwordeval_command() {
  local method="${MSMTP_SECRET_METHOD:-command}"

  case "$method" in
    keychain)
      require_var MSMTP_KEYCHAIN_SERVICE
      require_var MSMTP_KEYCHAIN_ACCOUNT
      printf "security find-generic-password -w -s %s -a %s" \
        "$(shell_quote "$MSMTP_KEYCHAIN_SERVICE")" \
        "$(shell_quote "$MSMTP_KEYCHAIN_ACCOUNT")"
      ;;
    gpg)
      require_var MSMTP_GPG_FILE
      printf "gpg --quiet --batch --decrypt %s" \
        "$(shell_quote "$MSMTP_GPG_FILE")"
      ;;
    password_file)
      require_var MSMTP_PASSWORD_FILE
      printf "cat %s" "$(shell_quote "$MSMTP_PASSWORD_FILE")"
      ;;
    command)
      require_var MSMTP_PASSWORDEVAL_COMMAND
      printf '%s' "$MSMTP_PASSWORDEVAL_COMMAND"
      ;;
    *)
      die "Unsupported MSMTP_SECRET_METHOD: $method"
      ;;
  esac
}

optional_line() {
  local key="$1"
  local value="$2"

  if [ -n "$value" ]; then
    printf '%s %s\n' "$key" "$value"
  fi
}

default_account_name_from_current_env() {
  if is_truthy "${MSMTP_SET_DEFAULT:-true}"; then
    printf '%s\n' "$MSMTP_ACCOUNT_NAME"
  fi
}

default_account_name_from_env_file() {
  local env_file="$1"

  (
    load_env_file "$env_file"
    if is_truthy "${MSMTP_SET_DEFAULT:-false}"; then
      printf '%s\n' "$MSMTP_ACCOUNT_NAME"
    fi
  )
}

account_name_from_env_file() {
  local env_file="$1"

  (
    load_env_file "$env_file"
    require_var MSMTP_ACCOUNT_NAME
    printf '%s\n' "$MSMTP_ACCOUNT_NAME"
  )
}

render_account_block() {
  local auth tls starttls certcheck default_line logfile_line trust_file_line
  local fingerprint_line passwordeval

  require_var MSMTP_ACCOUNT_NAME
  require_var MSMTP_HOST
  require_var MSMTP_PORT
  require_var MSMTP_FROM
  require_var MSMTP_USER

  auth="$(normalize_on_off "${MSMTP_AUTH:-on}")"
  tls="$(normalize_on_off "${MSMTP_TLS:-on}")"
  starttls="$(normalize_on_off "${MSMTP_TLS_STARTTLS:-on}")"
  certcheck="$(normalize_on_off "${MSMTP_TLS_CERTCHECK:-on}")"
  passwordeval="$(passwordeval_command)"
  logfile_line="$(optional_line "logfile" "${MSMTP_LOGFILE:-}")"
  trust_file_line="$(optional_line "tls_trust_file" "${MSMTP_TLS_TRUST_FILE:-}")"
  fingerprint_line="$(optional_line "tls_fingerprint" "${MSMTP_TLS_FINGERPRINT:-}")"

  printf 'account %s\n' "$MSMTP_ACCOUNT_NAME"
  printf 'auth %s\n' "$auth"
  printf 'tls %s\n' "$tls"
  printf 'tls_starttls %s\n' "$starttls"
  printf 'tls_certcheck %s\n' "$certcheck"
  if [ -n "$logfile_line" ]; then
    printf '%s' "$logfile_line"
  fi
  if [ -n "$trust_file_line" ]; then
    printf '%s' "$trust_file_line"
  fi
  if [ -n "$fingerprint_line" ]; then
    printf '%s' "$fingerprint_line"
  fi
  printf 'host %s\n' "$MSMTP_HOST"
  printf 'port %s\n' "$MSMTP_PORT"
  printf 'from %s\n' "$MSMTP_FROM"
  printf 'user %s\n' "$MSMTP_USER"
  printf 'passwordeval %s\n' "$passwordeval"
}

render_account_block_from_env_file() {
  local env_file="$1"

  (
    load_env_file "$env_file"
    render_account_block
  )
}

render_msmtprc_template() {
  local template_path="$1"
  local account_blocks="$2"
  local default_line="$3"
  local line

  require_file "$template_path"

  while IFS= read -r line || [ -n "$line" ]; do
    case "$line" in
      "{{ACCOUNT_BLOCKS}}")
        printf '%s\n' "$account_blocks"
        ;;
      "{{DEFAULT_ACCOUNT_LINE}}")
        if [ -n "$default_line" ]; then
          printf '%s\n' "$default_line"
        fi
        ;;
      *)
        printf '%s\n' "$line"
        ;;
    esac
  done < "$template_path"
}

render_config_from_env_file() {
  local env_file="$1"
  local account_block default_account_name default_line

  load_env_file "$env_file"
  account_block="$(render_account_block)"
  default_account_name="$(default_account_name_from_current_env)"

  if [ -n "$default_account_name" ]; then
    default_line="account default : ${default_account_name}"
  else
    default_line=""
  fi

  render_msmtprc_template "${repo_root}/templates/msmtprc.template" \
    "$account_block" \
    "$default_line"
}

render_config_from_accounts_dir() {
  local accounts_dir="$1"
  local explicit_default_account="$2"
  local env_files env_file account_blocks account_block default_candidate
  local implicit_default_account default_account_name default_line account_name
  local found_explicit_default="false"

  [ -d "$accounts_dir" ] || die "Accounts directory not found: $accounts_dir"

  env_files="$(find "$accounts_dir" -maxdepth 1 -type f -name '*.env' | sort)"
  [ -n "$env_files" ] || die "No account env files found in: $accounts_dir"

  account_blocks=""
  implicit_default_account=""

  while IFS= read -r env_file; do
    [ -n "$env_file" ] || continue

    account_block="$(render_account_block_from_env_file "$env_file")"
    account_name="$(account_name_from_env_file "$env_file")"
    default_candidate="$(default_account_name_from_env_file "$env_file")"

    if [ -n "$account_blocks" ]; then
      account_blocks="${account_blocks}

${account_block}"
    else
      account_blocks="$account_block"
    fi

    if [ -n "$explicit_default_account" ] && [ "$account_name" = "$explicit_default_account" ]; then
      found_explicit_default="true"
    fi

    if [ -n "$default_candidate" ]; then
      if [ -n "$implicit_default_account" ] && [ "$implicit_default_account" != "$default_candidate" ]; then
        die "Multiple account files are marked as default in $accounts_dir. Set only one MSMTP_SET_DEFAULT=true or pass --default-account."
      fi
      implicit_default_account="$default_candidate"
    fi
  done <<EOF
$env_files
EOF

  default_account_name="$explicit_default_account"
  if [ -z "$default_account_name" ]; then
    default_account_name="$implicit_default_account"
  elif [ "$found_explicit_default" != "true" ]; then
    die "Default account '$explicit_default_account' was not found in $accounts_dir"
  fi

  if [ -n "$default_account_name" ]; then
    default_line="account default : ${default_account_name}"
  else
    default_line=""
  fi

  render_msmtprc_template "${repo_root}/templates/msmtprc.template" \
    "$account_blocks" \
    "$default_line"
}
