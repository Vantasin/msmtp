#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=./lib/common.sh
. "${script_dir}/lib/common.sh"

usage() {
  cat <<'EOF'
Usage: scripts/render-config.sh [--env-file PATH | --accounts-dir PATH]
                                [--default-account NAME]
                                [--output PATH | --stdout]

Render templates/msmtprc.template from one env file or an accounts directory.
EOF
}

env_file=""
accounts_dir=""
default_account=""
output_file=""
stdout_mode="false"

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

if [ -n "$env_file" ] && [ -n "$accounts_dir" ]; then
  die "Use either --env-file or --accounts-dir, not both"
fi

if [ -z "$env_file" ] && [ -z "$accounts_dir" ]; then
  env_file="${repo_root}/.env"
fi

if [ -n "$accounts_dir" ]; then
  rendered_config="$(render_config_from_accounts_dir "$accounts_dir" "$default_account")"
else
  rendered_config="$(render_config_from_env_file "$env_file")"
fi

if [ "$stdout_mode" = "true" ]; then
  printf '%s\n' "$rendered_config"
  exit 0
fi

mkdir -p "$(dirname "$output_file")"
umask 077
printf '%s\n' "$rendered_config" > "$output_file"
chmod 600 "$output_file"

if [ -n "$accounts_dir" ]; then
  printf 'Rendered %s from %s\n' "$output_file" "$accounts_dir"
else
  printf 'Rendered %s from %s\n' "$output_file" "$env_file"
fi
