#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=./lib/common.sh
. "${script_dir}/lib/common.sh"

usage() {
  cat <<'EOF'
Usage: scripts/install.sh [--env-file PATH] [--output PATH] [--target PATH] [--mode copy|symlink]

Render a config and install it to the desired msmtp target path.

Modes:
  copy    Render a config and copy it to the target path.
  symlink Render a config to --output and symlink the target path to it.
EOF
}

env_file="${repo_root}/.env"
output_file="${repo_root}/.msmtprc.generated"
target_path="${HOME}/.msmtprc"
install_mode="copy"

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
    --mode)
      [ $# -ge 2 ] || die "--mode requires a value"
      install_mode="$2"
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

case "$install_mode" in
  copy | symlink)
    ;;
  *)
    die "Unsupported install mode: $install_mode"
    ;;
esac

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

install_symlink() {
  local source_path="$1"
  local destination_path="$2"

  mkdir -p "$(dirname "$destination_path")"

  if [ -d "$destination_path" ] && [ ! -L "$destination_path" ]; then
    die "Refusing to replace directory with symlink: $destination_path"
  fi

  rm -f "$destination_path"
  ln -s "$source_path" "$destination_path"
}

trap cleanup EXIT

if [ "$install_mode" = "copy" ]; then
  "${repo_root}/scripts/render-config.sh" --env-file "$env_file" --output "$tmp_output" >/dev/null

  if [ "$output_file" != "$target_path" ]; then
    install_file "$tmp_output" "$output_file"
  fi

  install_file "$tmp_output" "$target_path"

  printf 'Installed %s from %s using copy mode\n' "$target_path" "$env_file"
  if [ "$output_file" != "$target_path" ]; then
    printf 'Saved rendered copy to %s\n' "$output_file"
  fi
  exit 0
fi

[ "$output_file" != "$target_path" ] || die "In symlink mode, --output and --target must be different paths"

mkdir -p "$(dirname "$output_file")"
"${repo_root}/scripts/render-config.sh" --env-file "$env_file" --output "$output_file" >/dev/null
install_symlink "$(absolute_path "$output_file")" "$target_path"

printf 'Installed %s from %s using symlink mode\n' "$target_path" "$env_file"
printf 'Symlink target: %s\n' "$(absolute_path "$output_file")"
