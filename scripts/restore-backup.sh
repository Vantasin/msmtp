#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=./lib/common.sh
. "${script_dir}/lib/common.sh"

usage() {
  cat <<'EOF'
Usage: scripts/restore-backup.sh --backup PATH
                                 [--target PATH]
                                 [--force]

Restore a previously backed up msmtp target.

Existing target files are backed up before replacement. Interactive runs ask
for confirmation when a target already exists. Non-interactive runs require
--force to replace an existing target.
EOF
}

backup_path=""
target_path="${HOME}/.msmtprc"
force_replace="false"

while [ $# -gt 0 ]; do
  case "$1" in
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

[ -n "$backup_path" ] || die "--backup is required"
[ "$backup_path" != "$target_path" ] || die "--backup and --target must be different paths"
[ -e "$backup_path" ] || [ -L "$backup_path" ] || die "Backup path not found: $backup_path"

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
  local next_backup_path="$2"
  local response normalized

  if [ "$force_replace" = "true" ]; then
    return 0
  fi

  [ -t 0 ] || die "Refusing to replace existing target without confirmation: ${destination_path}. Re-run with --force to back up and replace it."

  printf 'Existing target detected: %s\n' "$destination_path" >&2
  printf 'Backup path: %s\n' "$next_backup_path" >&2

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
        die "Restore cancelled"
        ;;
    esac

    printf 'Please answer yes or no.\n' >&2
  done
}

backup_current_target_if_needed() {
  local destination_path="$1"
  local next_backup_path=""

  if [ -d "$destination_path" ] && [ ! -L "$destination_path" ]; then
    die "Refusing to replace directory: $destination_path"
  fi

  if ! path_exists "$destination_path"; then
    return 0
  fi

  next_backup_path="$(backup_path_for "$destination_path")"
  confirm_target_replacement "$destination_path" "$next_backup_path"
  mv "$destination_path" "$next_backup_path"
  printf 'Backed up existing target to %s\n' "$next_backup_path"
}

restore_backup() {
  local source_path="$1"
  local destination_path="$2"

  mkdir -p "$(dirname "$destination_path")"
  if [ -L "$source_path" ]; then
    cp -P "$source_path" "$destination_path"
    return 0
  fi

  cp "$source_path" "$destination_path"
  chmod 600 "$destination_path"
}

backup_current_target_if_needed "$target_path"
restore_backup "$backup_path" "$target_path"

printf 'Restored %s from backup %s\n' "$target_path" "$backup_path"
