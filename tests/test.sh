#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "$0")" && pwd)"
repo_root="$(cd "${script_dir}/.." && pwd)"

fail() {
  printf 'test failure: %s\n' "$*" >&2
  exit 1
}

assert_contains() {
  local file_path="$1"
  local expected="$2"

  if ! grep -F "$expected" "$file_path" >/dev/null 2>&1; then
    printf 'Expected to find:\n%s\n\nIn file:\n%s\n' "$expected" "$file_path" >&2
    sed -n '1,160p' "$file_path" >&2
    exit 1
  fi
}

run_syntax_checks() {
  bash -n "${repo_root}/scripts/render-config.sh"
  bash -n "${repo_root}/scripts/install.sh"
  bash -n "${repo_root}/scripts/quickstart.sh"
  bash -n "${repo_root}/scripts/lib/common.sh"
  bash -n "${repo_root}/tests/test.sh"
}

tmp_dir="$(mktemp -d "${TMPDIR:-/tmp}/msmtp-tests.XXXXXX")"

cleanup() {
  rm -rf "$tmp_dir"
}

trap cleanup EXIT

run_syntax_checks

"${repo_root}/scripts/quickstart.sh" \
  --example password-file \
  --env-file "${tmp_dir}/bootstrap.env" >/dev/null

assert_contains "${tmp_dir}/bootstrap.env" "MSMTP_SECRET_METHOD=password_file"

if "${repo_root}/scripts/quickstart.sh" \
  --example default \
  --env-file "${tmp_dir}/bootstrap.env" >/dev/null 2>&1; then
  fail "quickstart.sh should refuse to overwrite an existing env file"
fi

cat > "${tmp_dir}/keychain.env" <<'EOF'
MSMTP_ACCOUNT_NAME=work
MSMTP_HOST=smtp.example.com
MSMTP_PORT=587
MSMTP_FROM=alice@example.com
MSMTP_USER=alice@example.com
MSMTP_AUTH=on
MSMTP_TLS=on
MSMTP_TLS_STARTTLS=on
MSMTP_TLS_CERTCHECK=on
MSMTP_SET_DEFAULT=true
MSMTP_SECRET_METHOD=keychain
MSMTP_KEYCHAIN_SERVICE=smtp.example.com
MSMTP_KEYCHAIN_ACCOUNT=alice@example.com
EOF

"${repo_root}/scripts/render-config.sh" \
  --env-file "${tmp_dir}/keychain.env" \
  --output "${tmp_dir}/keychain.msmtprc" >/dev/null

assert_contains "${tmp_dir}/keychain.msmtprc" "account work"
assert_contains "${tmp_dir}/keychain.msmtprc" "passwordeval security find-generic-password -w -s 'smtp.example.com' -a 'alice@example.com'"
assert_contains "${tmp_dir}/keychain.msmtprc" "account default : work"

cat > "${tmp_dir}/gpg.env" <<'EOF'
MSMTP_ACCOUNT_NAME=linux
MSMTP_HOST=mail.internal.example
MSMTP_PORT=465
MSMTP_FROM=ops@example.com
MSMTP_USER=ops@example.com
MSMTP_AUTH=on
MSMTP_TLS=on
MSMTP_TLS_STARTTLS=off
MSMTP_TLS_CERTCHECK=on
MSMTP_TLS_TRUST_FILE=/etc/ssl/certs/ca-certificates.crt
MSMTP_SET_DEFAULT=false
MSMTP_SECRET_METHOD=gpg
MSMTP_GPG_FILE=/root/.config/msmtp/password.gpg
EOF

"${repo_root}/scripts/render-config.sh" \
  --env-file "${tmp_dir}/gpg.env" \
  --output "${tmp_dir}/gpg.msmtprc" >/dev/null

assert_contains "${tmp_dir}/gpg.msmtprc" "tls_starttls off"
assert_contains "${tmp_dir}/gpg.msmtprc" "tls_trust_file /etc/ssl/certs/ca-certificates.crt"
assert_contains "${tmp_dir}/gpg.msmtprc" "passwordeval gpg --quiet --batch --decrypt '/root/.config/msmtp/password.gpg'"

cat > "${tmp_dir}/password-file.env" <<'EOF'
MSMTP_ACCOUNT_NAME=rootmail
MSMTP_HOST=smtp.example.net
MSMTP_PORT=587
MSMTP_FROM=root@example.net
MSMTP_USER=root@example.net
MSMTP_AUTH=on
MSMTP_TLS=on
MSMTP_TLS_STARTTLS=on
MSMTP_TLS_CERTCHECK=on
MSMTP_SET_DEFAULT=true
MSMTP_SECRET_METHOD=password_file
MSMTP_PASSWORD_FILE=/etc/msmtp/password
EOF

"${repo_root}/scripts/render-config.sh" \
  --env-file "${tmp_dir}/password-file.env" \
  --output "${tmp_dir}/password-file.msmtprc" >/dev/null

assert_contains "${tmp_dir}/password-file.msmtprc" "passwordeval cat '/etc/msmtp/password'"

cat > "${tmp_dir}/command.env" <<'EOF'
MSMTP_ACCOUNT_NAME=cli
MSMTP_HOST=smtp.example.org
MSMTP_PORT=587
MSMTP_FROM=cli@example.org
MSMTP_USER=cli@example.org
MSMTP_AUTH=on
MSMTP_TLS=on
MSMTP_TLS_STARTTLS=on
MSMTP_TLS_CERTCHECK=on
MSMTP_LOGFILE=/tmp/msmtp.log
MSMTP_SET_DEFAULT=true
MSMTP_SECRET_METHOD=command
MSMTP_PASSWORDEVAL_COMMAND='pass show mail/msmtp'
EOF

"${repo_root}/scripts/install.sh" \
  --env-file "${tmp_dir}/command.env" \
  --output "${tmp_dir}/command.msmtprc" \
  --target "${tmp_dir}/home/.msmtprc" >/dev/null

assert_contains "${tmp_dir}/command.msmtprc" "logfile /tmp/msmtp.log"
assert_contains "${tmp_dir}/command.msmtprc" "passwordeval pass show mail/msmtp"
assert_contains "${tmp_dir}/home/.msmtprc" "account cli"

if command -v make >/dev/null 2>&1; then
  make -C "${repo_root}" \
    ENV_FILE="${tmp_dir}/command.env" \
    OUTPUT="${tmp_dir}/make.msmtprc" \
    render >/dev/null
  assert_contains "${tmp_dir}/make.msmtprc" "account cli"
fi

printf 'All tests passed.\n'
