#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=./lib/common.sh
. "${script_dir}/lib/common.sh"

usage() {
  cat <<'EOF'
Usage: scripts/render-config.sh [--env-file PATH] [--output PATH | --stdout]

Render templates/msmtprc.template using values from an env file.
EOF
}

env_file="${repo_root}/.env"
output_file=""
stdout_mode="false"

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
    --stdout)
      stdout_mode="true"
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

if [ "$stdout_mode" = "true" ] && [ -n "$output_file" ]; then
  die "Use either --output or --stdout, not both"
fi

if [ "$stdout_mode" = "false" ] && [ -z "$output_file" ]; then
  output_file="${repo_root}/.msmtprc.generated"
fi

load_env_file "$env_file"

if [ "$stdout_mode" = "true" ]; then
  render_msmtprc_template "${repo_root}/templates/msmtprc.template"
  exit 0
fi

mkdir -p "$(dirname "$output_file")"
umask 077
render_msmtprc_template "${repo_root}/templates/msmtprc.template" > "$output_file"
chmod 600 "$output_file"

printf 'Rendered %s from %s\n' "$output_file" "$env_file"
