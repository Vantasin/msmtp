#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=./lib/common.sh
. "${script_dir}/lib/common.sh"

usage() {
  cat <<'EOF'
Usage: scripts/install.sh [--env-file PATH | --accounts-dir PATH]
                          [--default-account NAME]
                          [--output PATH]
                          [--target PATH]
                          [--mode copy|symlink]
                          [--force]

Render a config and install it to the desired msmtp target path.

Modes:
  copy    Render a config and copy it to the target path.
  symlink Render a config to --output and symlink the target path to it.

Existing target files are backed up before replacement. Interactive runs ask
for confirmation when a target already exists. Non-interactive runs require
--force to replace an existing target.
EOF
}

env_file=""
accounts_dir=""
default_account=""
output_file="${repo_root}/.msmtprc.generated"
target_path="${HOME}/.msmtprc"
install_mode="copy"
force_replace="false"

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

case "$install_mode" in
  copy | symlink)
    ;;
  *)
    die "Unsupported install mode: $install_mode"
    ;;
esac

if [ -n "$env_file" ] && [ -n "$accounts_dir" ]; then
  die "Use either --env-file or --accounts-dir, not both"
fi

if [ -z "$env_file" ] && [ -z "$accounts_dir" ]; then
  env_file="${repo_root}/.env"
fi

if [ -n "$accounts_dir" ]; then
  install_source="$accounts_dir"
else
  install_source="$env_file"
fi

render_args=()
if [ -n "$accounts_dir" ]; then
  render_args+=(--accounts-dir "$accounts_dir")
else
  render_args+=(--env-file "$env_file")
fi

if [ -n "$default_account" ]; then
  render_args+=(--default-account "$default_account")
fi

tmp_output="$(mktemp "${TMPDIR:-/tmp}/msmtprc-install.XXXXXX")"

cleanup() {
  rm -f "$tmp_output"
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

confirm_target_replacement() {
  local destination_path="$1"
  local backup_path="$2"
  local response normalized

  if [ "$force_replace" = "true" ]; then
    return 0
  fi

  [ -t 0 ] || die "Refusing to replace existing target without confirmation: ${destination_path}. Re-run with --force to back up and replace it."

  printf 'Existing target detected: %s\n' "$destination_path" >&2
  printf 'Backup path: %s\n' "$backup_path" >&2

  while true; do
    printf 'Back up and replace it? [y/N]: ' >&2
    if ! IFS= read -r response < /dev/tty; then
      die "Unable to read confirmation from terminal"
    fi

    normalized="$(printf '%s' "$response" | tr '[:upper:]' '[:lower:]')"
    case "$normalized" in
      y | yes)
        return 0
        ;;
      "" | n | no)
        die "Installation cancelled"
        ;;
    esac

    printf 'Please answer yes or no.\n' >&2
  done
}

prepare_target_path() {
  local destination_path="$1"
  local backup_path=""

  if [ -d "$destination_path" ] && [ ! -L "$destination_path" ]; then
    die "Refusing to replace directory: $destination_path"
  fi

  if ! path_exists "$destination_path"; then
    return 0
  fi

  backup_path="$(backup_path_for "$destination_path")"
  confirm_target_replacement "$destination_path" "$backup_path"
  mv "$destination_path" "$backup_path"
  printf 'Backed up existing target to %s\n' "$backup_path"
}

write_generated_copy() {
  local source_path="$1"
  local destination_path="$2"

  if [ -d "$destination_path" ] && [ ! -L "$destination_path" ]; then
    die "Refusing to replace directory with file: $destination_path"
  fi

  mkdir -p "$(dirname "$destination_path")"
  if path_exists "$destination_path"; then
    rm -f "$destination_path"
  fi

  cp "$source_path" "$destination_path"
  chmod 600 "$destination_path"
}

install_file() {
  local source_path="$1"
  local destination_path="$2"

  prepare_target_path "$destination_path"
  mkdir -p "$(dirname "$destination_path")"
  cp "$source_path" "$destination_path"
  chmod 600 "$destination_path"
}

install_symlink() {
  local source_path="$1"
  local destination_path="$2"

  prepare_target_path "$destination_path"
  mkdir -p "$(dirname "$destination_path")"
  ln -s "$source_path" "$destination_path"
}

trap cleanup EXIT

if [ "$install_mode" = "copy" ]; then
  "${repo_root}/scripts/render-config.sh" "${render_args[@]}" --output "$tmp_output" >/dev/null

  if [ "$output_file" != "$target_path" ]; then
    write_generated_copy "$tmp_output" "$output_file"
  fi

  install_file "$tmp_output" "$target_path"

  printf 'Installed %s from %s using copy mode\n' "$target_path" "$install_source"
  if [ "$output_file" != "$target_path" ]; then
    printf 'Saved rendered copy to %s\n' "$output_file"
  fi
  exit 0
fi

[ "$output_file" != "$target_path" ] || die "In symlink mode, --output and --target must be different paths"

mkdir -p "$(dirname "$output_file")"
"${repo_root}/scripts/render-config.sh" "${render_args[@]}" --output "$output_file" >/dev/null
install_symlink "$(absolute_path "$output_file")" "$target_path"

printf 'Installed %s from %s using symlink mode\n' "$target_path" "$install_source"
printf 'Symlink target: %s\n' "$(absolute_path "$output_file")"
