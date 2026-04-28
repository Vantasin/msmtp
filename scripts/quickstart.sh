#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=./lib/common.sh
. "${script_dir}/lib/common.sh"

usage() {
  cat <<'EOF'
Usage: scripts/quickstart.sh [--example NAME] [--env-file PATH]

Available examples:
  default
  macos-keychain
  linux-gpg
  password-file

Copies the chosen example account file into place without overwriting an
existing target file.
EOF
}

example_name="default"
env_file="${repo_root}/accounts/default.env"

resolve_example_path() {
  case "$1" in
    default)
      printf '%s/templates/examples/default.env.example' "$repo_root"
      ;;
    macos-keychain)
      printf '%s/templates/examples/macos-keychain.env.example' "$repo_root"
      ;;
    linux-gpg)
      printf '%s/templates/examples/linux-gpg.env.example' "$repo_root"
      ;;
    password-file)
      printf '%s/templates/examples/password-file.env.example' "$repo_root"
      ;;
    *)
      die "Unknown example: $1"
      ;;
  esac
}

while [ $# -gt 0 ]; do
  case "$1" in
    --example)
      [ $# -ge 2 ] || die "--example requires a value"
      example_name="$2"
      shift 2
      ;;
    --env-file)
      [ $# -ge 2 ] || die "--env-file requires a value"
      env_file="$2"
      shift 2
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

source_file="$(resolve_example_path "$example_name")"
require_file "$source_file"

if [ -e "$env_file" ]; then
  die "Refusing to overwrite existing file: $env_file"
fi

mkdir -p "$(dirname "$env_file")"
cp "$source_file" "$env_file"
chmod 600 "$env_file"

printf 'Created %s from %s\n' "$env_file" "$source_file"
printf 'Next steps:\n'
printf '  1. Edit %s and replace placeholders.\n' "$env_file"
printf '  2. Run make check.\n'
printf '  3. Run make install.\n'
