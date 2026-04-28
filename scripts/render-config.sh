#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=./lib/common.sh
. "${script_dir}/lib/common.sh"

usage() {
  cat <<'EOF'
Usage: scripts/render-config.sh [--accounts-dir PATH]
                                [--default-account NAME]
                                [--output PATH | --stdout]

Render templates/msmtprc.template from an accounts directory.
EOF
}

accounts_dir="${repo_root}/accounts"
default_account=""
output_file=""
stdout_mode="false"

while [ $# -gt 0 ]; do
  case "$1" in
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

rendered_config="$(render_config_from_accounts_dir "$accounts_dir" "$default_account")"

if [ "$stdout_mode" = "true" ]; then
  printf '%s\n' "$rendered_config"
  exit 0
fi

umask 077
atomic_write_text_file "$output_file" 600 "$rendered_config"

printf 'Rendered %s from %s\n' "$output_file" "$accounts_dir"
