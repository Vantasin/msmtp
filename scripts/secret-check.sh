#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=./lib/common.sh
. "${script_dir}/lib/common.sh"

usage() {
  cat <<'EOF'
Usage: scripts/secret-check.sh [--env-file PATH | --accounts-dir PATH]

Validate that the configured passwordeval command runs successfully for one env
file or every account env file in an accounts directory. The command executes
the configured passwordeval helper but never prints the secret value.
EOF
}

env_file=""
accounts_dir=""

check_secret_for_env_file() {
  local env_path="$1"
  local command_output passwordeval account_name

  account_name="$(account_name_from_env_file "$env_path")"
  passwordeval="$(passwordeval_command_from_env_file "$env_path")"

  if ! command_output="$(bash -lc "$passwordeval")"; then
    die "Secret check failed for account '$account_name' in $env_path"
  fi

  [ -n "$command_output" ] || die "Secret check returned empty output for account '$account_name' in $env_path"

  printf 'ok: %s\n' "$account_name"
}

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
    -h | --help)
      usage
      exit 0
      ;;
    *)
      die "Unknown argument: $1"
      ;;
  esac
done

if [ -n "$env_file" ] && [ -n "$accounts_dir" ]; then
  die "Use either --env-file or --accounts-dir, not both"
fi

if [ -z "$env_file" ] && [ -z "$accounts_dir" ]; then
  env_file="${repo_root}/.env"
fi

if [ -n "$accounts_dir" ]; then
  [ -d "$accounts_dir" ] || die "Accounts directory not found: $accounts_dir"
  found_env_files="false"

  while IFS= read -r account_env; do
    [ -n "$account_env" ] || continue
    found_env_files="true"
    check_secret_for_env_file "$account_env"
  done <<EOF
$(find "$accounts_dir" -maxdepth 1 -type f -name '*.env' | sort)
EOF

  [ "$found_env_files" = "true" ] || die "No account env files found in: $accounts_dir"
  exit 0
fi

check_secret_for_env_file "$env_file"
