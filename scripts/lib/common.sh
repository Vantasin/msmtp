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
    printf '%s %s' "$key" "$value"
  fi
}

render_msmtprc_template() {
  local template_path="$1"
  local auth tls starttls certcheck default_line logfile_line trust_file_line
  local fingerprint_line passwordeval

  require_file "$template_path"

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

  if is_truthy "${MSMTP_SET_DEFAULT:-true}"; then
    default_line="account default : ${MSMTP_ACCOUNT_NAME}"
  else
    default_line=""
  fi

  logfile_line="$(optional_line "logfile" "${MSMTP_LOGFILE:-}")"
  trust_file_line="$(optional_line "tls_trust_file" "${MSMTP_TLS_TRUST_FILE:-}")"
  fingerprint_line="$(optional_line "tls_fingerprint" "${MSMTP_TLS_FINGERPRINT:-}")"

  awk \
    -v account_name="$MSMTP_ACCOUNT_NAME" \
    -v host="$MSMTP_HOST" \
    -v port="$MSMTP_PORT" \
    -v from="$MSMTP_FROM" \
    -v user="$MSMTP_USER" \
    -v auth="$auth" \
    -v tls="$tls" \
    -v starttls="$starttls" \
    -v certcheck="$certcheck" \
    -v passwordeval="$passwordeval" \
    -v default_line="$default_line" \
    -v logfile_line="$logfile_line" \
    -v trust_file_line="$trust_file_line" \
    -v fingerprint_line="$fingerprint_line" '
      function escape_replacement(value) {
        gsub(/\\/,"\\\\",value)
        gsub(/&/,"\\&",value)
        return value
      }

      BEGIN {
        account_name = escape_replacement(account_name)
        host = escape_replacement(host)
        port = escape_replacement(port)
        from = escape_replacement(from)
        user = escape_replacement(user)
        auth = escape_replacement(auth)
        tls = escape_replacement(tls)
        starttls = escape_replacement(starttls)
        certcheck = escape_replacement(certcheck)
        passwordeval = escape_replacement(passwordeval)
        default_line = escape_replacement(default_line)
        logfile_line = escape_replacement(logfile_line)
        trust_file_line = escape_replacement(trust_file_line)
        fingerprint_line = escape_replacement(fingerprint_line)
      }

      {
        gsub(/\{\{ACCOUNT_NAME\}\}/, account_name)
        gsub(/\{\{HOST\}\}/, host)
        gsub(/\{\{PORT\}\}/, port)
        gsub(/\{\{FROM\}\}/, from)
        gsub(/\{\{USER\}\}/, user)
        gsub(/\{\{AUTH\}\}/, auth)
        gsub(/\{\{TLS\}\}/, tls)
        gsub(/\{\{TLS_STARTTLS\}\}/, starttls)
        gsub(/\{\{TLS_CERTCHECK\}\}/, certcheck)
        gsub(/\{\{PASSWORDEVAL_COMMAND\}\}/, passwordeval)
        gsub(/\{\{DEFAULT_ACCOUNT_LINE\}\}/, default_line)
        gsub(/\{\{LOGFILE_LINE\}\}/, logfile_line)
        gsub(/\{\{TLS_TRUST_FILE_LINE\}\}/, trust_file_line)
        gsub(/\{\{TLS_FINGERPRINT_LINE\}\}/, fingerprint_line)
        print
      }
    ' "$template_path"
}
