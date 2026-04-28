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

handle_interrupt_signal() {
  local message=""

  printf '\n' >&2
  if [ "${INTERRUPT_STATE:-clean}" = "dirty" ]; then
    message="${INTERRUPT_MESSAGE_DIRTY:-Cancelled. Check the affected files for partial changes.}"
  else
    message="${INTERRUPT_MESSAGE_CLEAN:-Cancelled. No changes were written.}"
  fi

  [ -n "$message" ] && printf '%s\n' "$message" >&2
  exit 130
}

install_interrupt_handler() {
  INTERRUPT_MESSAGE_CLEAN="${1:-Cancelled. No changes were written.}"
  INTERRUPT_MESSAGE_DIRTY="${2:-$INTERRUPT_MESSAGE_CLEAN}"
  INTERRUPT_STATE="clean"
  trap 'handle_interrupt_signal' INT TERM
}

mark_interrupt_dirty() {
  INTERRUPT_STATE="dirty"
}

clear_interrupt_handler() {
  trap - INT TERM
}

run_with_interrupt_passthrough() {
  local clean_message="${INTERRUPT_MESSAGE_CLEAN:-}"
  local dirty_message="${INTERRUPT_MESSAGE_DIRTY:-}"
  local interrupt_state="${INTERRUPT_STATE:-clean}"
  local status

  clear_interrupt_handler
  set +e
  "$@"
  status=$?
  set -e

  if [ -n "$clean_message" ] || [ -n "$dirty_message" ]; then
    install_interrupt_handler "$clean_message" "$dirty_message"
    INTERRUPT_STATE="$interrupt_state"
  fi

  return "$status"
}

prompt_value() {
  local prompt_text="$1"
  local default_value="${2:-}"
  local response

  if [ -n "$default_value" ]; then
    printf '%s [%s] (press Enter to accept): ' "$prompt_text" "$default_value" >&2
  else
    printf '%s: ' "$prompt_text" >&2
  fi

  IFS= read -r response
  if [ -z "$response" ]; then
    response="$default_value"
  fi

  printf '%s\n' "$response"
}

prompt_required() {
  local prompt_text="$1"
  local default_value="${2:-}"
  local response=""

  while [ -z "$response" ]; do
    response="$(prompt_value "$prompt_text" "$default_value")"
    if [ -z "$response" ]; then
      printf 'A value is required.\n' >&2
    fi
  done

  printf '%s\n' "$response"
}

prompt_optional_value() {
  local prompt_text="$1"
  local existing_value="${2:-}"
  local response

  if [ -n "$existing_value" ]; then
    printf '%s [%s] (press Enter to keep, enter - to clear): ' "$prompt_text" "$existing_value" >&2
  else
    printf '%s (press Enter to skip): ' "$prompt_text" >&2
  fi

  IFS= read -r response || response=""
  case "$response" in
    "")
      response="$existing_value"
      ;;
    "-")
      response=""
      ;;
  esac

  printf '%s\n' "$response"
}

prompt_yes_no() {
  local prompt_text="$1"
  local default_value="$2"
  local suffix response normalized

  case "$default_value" in
    yes)
      suffix="Y/n"
      ;;
    no)
      suffix="y/N"
      ;;
    *)
      die "Unsupported default for yes/no prompt: $default_value"
      ;;
  esac

  while true; do
    printf '%s [%s] (press Enter for %s): ' "$prompt_text" "$suffix" "$default_value" >&2
    IFS= read -r response
    if [ -z "$response" ]; then
      response="$default_value"
    fi

    normalized="$(printf '%s' "$response" | tr '[:upper:]' '[:lower:]')"
    case "$normalized" in
      y | yes)
        printf 'yes\n'
        return 0
        ;;
      n | no)
        printf 'no\n'
        return 0
        ;;
    esac

    printf 'Please answer yes or no.\n' >&2
  done
}

choose_from_menu() {
  local prompt_text="$1"
  shift
  local options=("$@")
  local default_index="${CHOOSE_DEFAULT_INDEX:-1}"
  local response choice

  [ "${#options[@]}" -gt 0 ] || die "choose_from_menu requires at least one option"

  while true; do
    printf '%s\n' "$prompt_text" >&2
    for choice in "${!options[@]}"; do
      printf '  %d. %s\n' "$((choice + 1))" "${options[$choice]}" >&2
    done

    printf 'Enter a number or press Enter for [%s]: ' "$default_index" >&2
    IFS= read -r response
    if [ -z "$response" ]; then
      response="$default_index"
    fi

    case "$response" in
      '' | *[!0-9]*)
        printf 'Please enter a valid number.\n' >&2
        continue
        ;;
    esac

    if [ "$response" -ge 1 ] && [ "$response" -le "${#options[@]}" ]; then
      printf '%s\n' "${options[$((response - 1))]}"
      return 0
    fi

    printf 'Please enter a number between 1 and %d.\n' "${#options[@]}" >&2
  done
}

path_exists() {
  [ -e "$1" ] || [ -L "$1" ]
}

backup_path_for() {
  local original_path="$1"
  local timestamp candidate_path suffix

  timestamp="$(date -u '+%Y%m%dT%H%M%SZ')"
  candidate_path="${original_path}.bak.${timestamp}"
  suffix=1
  while path_exists "$candidate_path"; do
    candidate_path="${original_path}.bak.${timestamp}.${suffix}"
    suffix=$((suffix + 1))
  done

  printf '%s\n' "$candidate_path"
}

temp_path_for_destination() {
  local destination_path="$1"
  local destination_dir base_name

  destination_dir="$(dirname "$destination_path")"
  base_name="$(basename "$destination_path")"
  mkdir -p "$destination_dir"
  mktemp "${destination_dir}/.${base_name}.tmp.XXXXXX"
}

atomic_write_text_file() {
  local destination_path="$1"
  local file_mode="$2"
  local file_contents="$3"
  local tmp_path=""

  tmp_path="$(temp_path_for_destination "$destination_path")"
  if ! printf '%s\n' "$file_contents" > "$tmp_path"; then
    rm -f "$tmp_path"
    return 1
  fi

  chmod "$file_mode" "$tmp_path"
  mark_interrupt_dirty
  mv -f "$tmp_path" "$destination_path"
}

atomic_write_raw_file() {
  local destination_path="$1"
  local file_mode="$2"
  local file_contents="$3"
  local tmp_path=""

  tmp_path="$(temp_path_for_destination "$destination_path")"
  if ! printf '%s' "$file_contents" > "$tmp_path"; then
    rm -f "$tmp_path"
    return 1
  fi

  chmod "$file_mode" "$tmp_path"
  mark_interrupt_dirty
  mv -f "$tmp_path" "$destination_path"
}

atomic_backup_copy() {
  local source_path="$1"
  local backup_path="$2"
  local tmp_path="" symlink_target=""

  tmp_path="$(temp_path_for_destination "$backup_path")"

  if [ -L "$source_path" ]; then
    symlink_target="$(readlink "$source_path")" || {
      rm -f "$tmp_path"
      return 1
    }
    rm -f "$tmp_path"
    ln -s "$symlink_target" "$tmp_path"
  else
    if ! cp -p "$source_path" "$tmp_path"; then
      rm -f "$tmp_path"
      return 1
    fi
  fi

  mark_interrupt_dirty
  mv -f "$tmp_path" "$backup_path"
}

atomic_replace_from_path() {
  local source_path="$1"
  local destination_path="$2"
  local file_mode="${3:-}"
  local tmp_path="" symlink_target=""

  tmp_path="$(temp_path_for_destination "$destination_path")"

  if [ -L "$source_path" ]; then
    symlink_target="$(readlink "$source_path")" || {
      rm -f "$tmp_path"
      return 1
    }
    rm -f "$tmp_path"
    ln -s "$symlink_target" "$tmp_path"
  else
    if ! cp "$source_path" "$tmp_path"; then
      rm -f "$tmp_path"
      return 1
    fi
    if [ -n "$file_mode" ]; then
      chmod "$file_mode" "$tmp_path"
    fi
  fi

  mark_interrupt_dirty
  mv -f "$tmp_path" "$destination_path"
}

atomic_replace_symlink() {
  local symlink_target="$1"
  local destination_path="$2"
  local tmp_path=""

  tmp_path="$(temp_path_for_destination "$destination_path")"
  rm -f "$tmp_path"
  ln -s "$symlink_target" "$tmp_path"
  mark_interrupt_dirty
  mv -f "$tmp_path" "$destination_path"
}

list_account_env_files() {
  local accounts_dir="$1"

  [ -d "$accounts_dir" ] || return 0
  find "$accounts_dir" -maxdepth 1 -type f -name '*.env' | sort
}

secret_method_from_env_file() {
  local env_file="$1"

  (
    load_env_file "$env_file"
    printf '%s\n' "${MSMTP_SECRET_METHOD:-command}"
  )
}

write_msmtp_env_file() {
  local destination="$1"
  local rendered_env=""

  rendered_env="$({
    printf '# Generated by repository automation.\n'
    printf '# Review and edit as needed before rerendering.\n'
    write_env_assignment MSMTP_ACCOUNT_NAME "${MSMTP_ACCOUNT_NAME:-}"
    write_env_assignment MSMTP_HOST "${MSMTP_HOST:-}"
    write_env_assignment MSMTP_PORT "${MSMTP_PORT:-}"
    write_env_assignment MSMTP_FROM "${MSMTP_FROM:-}"
    write_env_assignment MSMTP_USER "${MSMTP_USER:-}"
    write_env_assignment MSMTP_AUTH "${MSMTP_AUTH:-}"
    write_env_assignment MSMTP_TLS "${MSMTP_TLS:-}"
    write_env_assignment MSMTP_TLS_STARTTLS "${MSMTP_TLS_STARTTLS:-}"
    write_env_assignment MSMTP_TLS_CERTCHECK "${MSMTP_TLS_CERTCHECK:-}"
    write_env_assignment MSMTP_SET_DEFAULT "${MSMTP_SET_DEFAULT:-}"
    write_env_assignment MSMTP_LOGFILE "${MSMTP_LOGFILE:-}"
    write_env_assignment MSMTP_TLS_TRUST_FILE "${MSMTP_TLS_TRUST_FILE:-}"
    write_env_assignment MSMTP_TLS_FINGERPRINT "${MSMTP_TLS_FINGERPRINT:-}"
    write_env_assignment MSMTP_SECRET_METHOD "${MSMTP_SECRET_METHOD:-}"
    write_env_assignment MSMTP_KEYCHAIN_SERVICE "${MSMTP_KEYCHAIN_SERVICE:-}"
    write_env_assignment MSMTP_KEYCHAIN_ACCOUNT "${MSMTP_KEYCHAIN_ACCOUNT:-}"
    write_env_assignment MSMTP_GPG_FILE "${MSMTP_GPG_FILE:-}"
    write_env_assignment MSMTP_PASSWORD_FILE "${MSMTP_PASSWORD_FILE:-}"
    write_env_assignment MSMTP_PASSWORDEVAL_COMMAND "${MSMTP_PASSWORDEVAL_COMMAND:-}"
  })"

  umask 077
  atomic_write_text_file "$destination" 600 "$rendered_env"
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
  local auth tls starttls certcheck passwordeval

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

  printf 'account %s\n' "$MSMTP_ACCOUNT_NAME"
  printf 'auth %s\n' "$auth"
  printf 'tls %s\n' "$tls"
  printf 'tls_starttls %s\n' "$starttls"
  printf 'tls_certcheck %s\n' "$certcheck"
  optional_line "logfile" "${MSMTP_LOGFILE:-}"
  optional_line "tls_trust_file" "${MSMTP_TLS_TRUST_FILE:-}"
  optional_line "tls_fingerprint" "${MSMTP_TLS_FINGERPRINT:-}"
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
