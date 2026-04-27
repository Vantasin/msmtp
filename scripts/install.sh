#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=./lib/common.sh
. "${script_dir}/lib/common.sh"

usage() {
  cat <<'EOF'
Usage: scripts/install.sh [--env-file PATH] [--output PATH] [--target PATH]

Render a config and install it to the desired msmtp target path.
EOF
}

env_file="${repo_root}/.env"
output_file="${repo_root}/.msmtprc.generated"
target_path="${HOME}/.msmtprc"

while [ $# -gt 0 ]; do
  case "$1" in
    --env-file)
      [ $# -ge 2 ] || die "--env-file requires a value"
      env_file="$2"
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
    -h | --help)
      usage
      exit 0
      ;;
    *)
      die "Unknown argument: $1"
      ;;
  esac
done

tmp_output="$(mktemp "${TMPDIR:-/tmp}/msmtprc-install.XXXXXX")"

cleanup() {
  rm -f "$tmp_output"
}

install_file() {
  local source_path="$1"
  local destination_path="$2"

  mkdir -p "$(dirname "$destination_path")"
  cp "$source_path" "$destination_path"
  chmod 600 "$destination_path"
}

trap cleanup EXIT

"${repo_root}/scripts/render-config.sh" --env-file "$env_file" --output "$tmp_output" >/dev/null

if [ "$output_file" != "$target_path" ]; then
  install_file "$tmp_output" "$output_file"
fi

install_file "$tmp_output" "$target_path"

printf 'Installed %s from %s\n' "$target_path" "$env_file"
if [ "$output_file" != "$target_path" ]; then
  printf 'Saved rendered copy to %s\n' "$output_file"
fi
