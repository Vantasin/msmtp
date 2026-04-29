#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "$0")" && pwd -P)"
if repo_root="$(git -C "${script_dir}/.." rev-parse --show-toplevel 2>/dev/null)"; then
  repo_root="$(cd "$repo_root" && pwd -P)"
else
  repo_root="$(cd "${script_dir}/.." && pwd -P)"
fi

fail() {
  printf 'test failure: %s\n' "$*" >&2
  exit 1
}

assert_contains() {
  local file_path="$1"
  local expected="$2"

  if ! grep -F "$expected" "$file_path" >/dev/null 2>&1; then
    printf 'Expected to find:\n%s\n\nIn file:\n%s\n' "$expected" "$file_path" >&2
    sed -n '1,200p' "$file_path" >&2
    exit 1
  fi
}

assert_line() {
  local file_path="$1"
  local expected="$2"

  if ! grep -Fx "$expected" "$file_path" >/dev/null 2>&1; then
    printf 'Expected line:\n%s\n\nIn file:\n%s\n' "$expected" "$file_path" >&2
    sed -n '1,200p' "$file_path" >&2
    exit 1
  fi
}

assert_matches() {
  local value="$1"
  local pattern="$2"

  if ! printf '%s\n' "$value" | grep -Eq "$pattern"; then
    printf 'Expected value to match pattern:\n%s\n\nValue:\n%s\n' "$pattern" "$value" >&2
    exit 1
  fi
}

file_mode() {
  local path="$1"

  if stat -f '%OLp' "$path" >/dev/null 2>&1; then
    stat -f '%OLp' "$path"
  else
    stat -c '%a' "$path"
  fi
}

run_syntax_checks() {
  bash -n "${repo_root}/scripts/secrets-help.sh"
  bash -n "${repo_root}/scripts/secret-check.sh"
  bash -n "${repo_root}/scripts/keychain-add.sh"
  bash -n "${repo_root}/scripts/password-file-init.sh"
  bash -n "${repo_root}/scripts/gpg-file-init.sh"
  bash -n "${repo_root}/scripts/bootstrap.sh"
  bash -n "${repo_root}/scripts/render-config.sh"
  bash -n "${repo_root}/scripts/install.sh"
  bash -n "${repo_root}/scripts/install-helper.sh"
  bash -n "${repo_root}/scripts/restore-backup.sh"
  bash -n "${repo_root}/scripts/restore-config-helper.sh"
  bash -n "${repo_root}/scripts/restore-account-helper.sh"
  bash -n "${repo_root}/scripts/restore-secret-helper.sh"
  bash -n "${repo_root}/scripts/restore-helper.sh"
  bash -n "${repo_root}/scripts/account-manager.sh"
  bash -n "${repo_root}/scripts/configure.sh"
  bash -n "${repo_root}/scripts/password-helper.sh"
  bash -n "${repo_root}/scripts/rotate-password.sh"
  bash -n "${repo_root}/scripts/test-email.sh"
  bash -n "${repo_root}/scripts/test-live-email.sh"
  bash -n "${repo_root}/scripts/setup.sh"
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

canonical_repo_root="$(git -C "${repo_root}" rev-parse --show-toplevel)"
common_repo_root="$(bash -lc '. "'"${repo_root}/scripts/lib/common.sh"'"; printf "%s\n" "$repo_root"')"
[ "$common_repo_root" = "$canonical_repo_root" ] || fail "Expected common.sh repo_root to match git rev-parse --show-toplevel"
friendly_backup_timestamp="$(TZ=America/Toronto bash -lc '. "'"${repo_root}/scripts/lib/common.sh"'"; human_readable_backup_timestamp_from_path "/tmp/.msmtprc.bak.2026-04-27T15-30-00Z"')"
[ "$friendly_backup_timestamp" = "Apr 27, 2026 11:30 EDT" ] || fail "Expected human-readable backup timestamp formatter to prefer the local timezone"
friendly_backup_timestamp_fallback="$(bash -lc '. "'"${repo_root}/scripts/lib/common.sh"'"; date() { return 1; }; human_readable_backup_timestamp_from_path "/tmp/.msmtprc.bak.2026-04-27T15-30-00Z"')"
[ "$friendly_backup_timestamp_fallback" = "Apr 27, 2026 15:30 UTC" ] || fail "Expected human-readable backup timestamp formatter to fall back to UTC when local conversion is unavailable"

mkdir -p "${tmp_dir}/fake-repo/passwords"
chmod 755 "${tmp_dir}/fake-repo/passwords"
bash -lc '. "'"${repo_root}/scripts/lib/common.sh"'"; repo_root="'"${tmp_dir}/fake-repo"'"; ensure_repo_local_passwords_dir_permissions_for_path "$repo_root/passwords/repo-local-test.password"'
[ "$(file_mode "${tmp_dir}/fake-repo/passwords")" = "700" ] || fail "Expected repo-local passwords directory helper to enforce mode 700"

mkdir -p "${tmp_dir}/bootstrap-accounts"
"${repo_root}/scripts/quickstart.sh" \
  --example password-file \
  --env-file "${tmp_dir}/bootstrap-accounts/default.env" >/dev/null 2>&1
assert_contains "${tmp_dir}/bootstrap-accounts/default.env" "MSMTP_SECRET_METHOD=password_file"
assert_contains "${tmp_dir}/bootstrap-accounts/default.env" "MSMTP_ACCOUNT_NAME=primary"
[ "$(cat "${tmp_dir}/bootstrap-accounts/.default-account")" = "primary" ] || fail "Expected quickstart to initialize the persistent default account"

if "${repo_root}/scripts/quickstart.sh" \
  --example default \
  --env-file "${tmp_dir}/bootstrap-accounts/default.env" >/dev/null 2>&1; then
  fail "quickstart.sh should refuse to overwrite an existing account file"
fi

mkdir -p "${tmp_dir}/bootstrap-bin"
cat > "${tmp_dir}/bootstrap-bin/sudo" <<'EOF'
#!/usr/bin/env bash
"$@"
EOF
chmod +x "${tmp_dir}/bootstrap-bin/sudo"

cat > "${tmp_dir}/bootstrap-bin/apt-get" <<EOF
#!/usr/bin/env bash
printf '%s\n' "\$*" >> "${tmp_dir}/bootstrap-install.log"
if [ "\$1" = "install" ]; then
  cat > "${tmp_dir}/bootstrap-bin/msmtp" <<'INNER'
#!/usr/bin/env bash
exit 0
INNER
  chmod +x "${tmp_dir}/bootstrap-bin/msmtp"
fi
EOF
chmod +x "${tmp_dir}/bootstrap-bin/apt-get"

PATH="${tmp_dir}/bootstrap-bin:/usr/bin:/bin" \
MSMTP_BOOTSTRAP_OS=Linux \
MSMTP_BOOTSTRAP_REPO_URL="${repo_root}" \
MSMTP_BOOTSTRAP_DEST_PARENT="${tmp_dir}/bootstrap-home/Git" \
MSMTP_BOOTSTRAP_REPO_NAME="bootstrap-clone" \
"${repo_root}/scripts/bootstrap.sh" --skip-configure >/dev/null 2>&1

[ -d "${tmp_dir}/bootstrap-home/Git/bootstrap-clone/.git" ] || fail "Expected bootstrap.sh to clone the repository into the requested destination"
assert_contains "${tmp_dir}/bootstrap-install.log" "update"
assert_contains "${tmp_dir}/bootstrap-install.log" "install -y git make msmtp"

if PATH="/usr/bin:/bin" \
  MSMTP_BOOTSTRAP_OS=Darwin \
  "${repo_root}/scripts/bootstrap.sh" --skip-configure >/dev/null 2>"${tmp_dir}/bootstrap-macos-error.log"; then
  fail "bootstrap.sh should require Homebrew on macOS"
fi
assert_contains "${tmp_dir}/bootstrap-macos-error.log" "Homebrew is required on macOS"

"${repo_root}/scripts/secrets-help.sh" > "${tmp_dir}/secrets-help.txt"
assert_contains "${tmp_dir}/secrets-help.txt" "make password"
assert_contains "${tmp_dir}/secrets-help.txt" "ACCOUNT_NAME=work"

mkdir -p "${tmp_dir}/guided-accounts"
printf '%s\n' \
  "guided" \
  "smtp.guided.example" \
  "587" \
  "guided@example.com" \
  "" \
  "command" \
  "pass show mail/guided" \
  "" \
  "" \
  "" \
  "" \
  "~/.msmtp.log" \
  "" \
  "" | "${repo_root}/scripts/setup.sh" \
    --env-file "${tmp_dir}/guided-accounts/guided.env" >/dev/null 2>&1

assert_contains "${tmp_dir}/guided-accounts/guided.env" "MSMTP_SECRET_METHOD='command'"
assert_contains "${tmp_dir}/guided-accounts/guided.env" "MSMTP_LOGFILE='~/.msmtp.log'"
[ "$(cat "${tmp_dir}/guided-accounts/.default-account")" = "guided" ] || fail "Expected setup.sh to initialize the persistent default account"
[ ! -e "${tmp_dir}/guided-home/.msmtprc" ] || fail "setup.sh should not install a live config"

printf '%s\n' \
  "repofile" \
  "smtp.repo.example" \
  "587" \
  "repo@example.com" \
  "" \
  "password_file" \
  "2" \
  "" \
  "" \
  "" \
  "" \
  "" \
  "" \
  "" | "${repo_root}/scripts/setup.sh" \
    --env-file "${tmp_dir}/guided-accounts/repofile.env" >/dev/null 2>&1

assert_contains "${tmp_dir}/guided-accounts/repofile.env" "MSMTP_SECRET_METHOD='password_file'"
assert_contains "${tmp_dir}/guided-accounts/repofile.env" "MSMTP_PASSWORD_FILE='${repo_root}/passwords/repofile.password'"

printf '%s\n' \
  "gpgback" \
  "smtp.gpgback.example" \
  "587" \
  "gpgback@example.com" \
  "" \
  "gpg" \
  "4" \
  "command" \
  "pass show mail/gpgback" \
  "" \
  "" \
  "" \
  "" \
  "" \
  "" \
  "" | "${repo_root}/scripts/setup.sh" \
    --env-file "${tmp_dir}/guided-accounts/gpgback.env" >/dev/null 2>&1

assert_contains "${tmp_dir}/guided-accounts/gpgback.env" "MSMTP_SECRET_METHOD='command'"
assert_contains "${tmp_dir}/guided-accounts/gpgback.env" "MSMTP_GPG_FILE=''"
assert_contains "${tmp_dir}/guided-accounts/gpgback.env" "MSMTP_PASSWORDEVAL_COMMAND='pass show mail/gpgback'"

printf '%s\n' \
  "" \
  "smtp.edited.example" \
  "" \
  "" \
  "" \
  "" \
  "" \
  "" \
  "" \
  "" \
  "" \
  "-" \
  "" \
  "" | "${repo_root}/scripts/setup.sh" \
    --env-file "${tmp_dir}/guided-accounts/guided.env" \
    --overwrite >/dev/null 2>&1

assert_contains "${tmp_dir}/guided-accounts/guided.env" "MSMTP_HOST='smtp.edited.example'"
assert_contains "${tmp_dir}/guided-accounts/guided.env" "MSMTP_LOGFILE=''"
[ "$(cat "${tmp_dir}/guided-accounts/.default-account")" = "guided" ] || fail "Expected setup.sh edit to preserve the persistent default account"

mkdir -p "${tmp_dir}/single-account"
cat > "${tmp_dir}/single-account/default.env" <<'EOF'
MSMTP_ACCOUNT_NAME=work
MSMTP_HOST=smtp.example.com
MSMTP_PORT=587
MSMTP_FROM=alice@example.com
MSMTP_USER=alice@example.com
MSMTP_AUTH=on
MSMTP_TLS=on
MSMTP_TLS_STARTTLS=on
MSMTP_TLS_CERTCHECK=on
MSMTP_SECRET_METHOD=keychain
MSMTP_KEYCHAIN_SERVICE=smtp.example.com
MSMTP_KEYCHAIN_ACCOUNT=alice@example.com
EOF

printf 'work\n' > "${tmp_dir}/single-account/.default-account"

"${repo_root}/scripts/render-config.sh" \
  --accounts-dir "${tmp_dir}/single-account" \
  --output "${tmp_dir}/single.msmtprc" >/dev/null

assert_contains "${tmp_dir}/single.msmtprc" "account work"
assert_contains "${tmp_dir}/single.msmtprc" "passwordeval security find-generic-password -w -s 'smtp.example.com' -a 'alice@example.com'"
assert_contains "${tmp_dir}/single.msmtprc" "account default : work"

mkdir -p "${tmp_dir}/multi-accounts"
cat > "${tmp_dir}/multi-accounts/work.env" <<'EOF'
MSMTP_ACCOUNT_NAME=work
MSMTP_HOST=smtp.work.example
MSMTP_PORT=587
MSMTP_FROM=work@example.com
MSMTP_USER=work@example.com
MSMTP_AUTH=on
MSMTP_TLS=on
MSMTP_TLS_STARTTLS=on
MSMTP_TLS_CERTCHECK=on
MSMTP_SECRET_METHOD=keychain
MSMTP_KEYCHAIN_SERVICE=smtp.work.example
MSMTP_KEYCHAIN_ACCOUNT=work@example.com
EOF

cat > "${tmp_dir}/multi-accounts/personal.env" <<'EOF'
MSMTP_ACCOUNT_NAME=personal
MSMTP_HOST=smtp.personal.example
MSMTP_PORT=465
MSMTP_FROM=me@example.net
MSMTP_USER=me@example.net
MSMTP_AUTH=on
MSMTP_TLS=on
MSMTP_TLS_STARTTLS=off
MSMTP_TLS_CERTCHECK=on
MSMTP_LOGFILE=/tmp/msmtp-personal.log
MSMTP_TLS_TRUST_FILE=/etc/ssl/certs/ca-certificates.crt
MSMTP_TLS_FINGERPRINT=AA:BB:CC:DD
MSMTP_SECRET_METHOD=command
MSMTP_PASSWORDEVAL_COMMAND='pass show mail/personal'
EOF

"${repo_root}/scripts/render-config.sh" \
  --accounts-dir "${tmp_dir}/multi-accounts" \
  --default-account personal \
  --output "${tmp_dir}/multi.msmtprc" >/dev/null

assert_contains "${tmp_dir}/multi.msmtprc" "account work"
assert_contains "${tmp_dir}/multi.msmtprc" "account personal"
assert_contains "${tmp_dir}/multi.msmtprc" "tls_starttls off"
assert_contains "${tmp_dir}/multi.msmtprc" "account default : personal"
assert_line "${tmp_dir}/multi.msmtprc" "logfile /tmp/msmtp-personal.log"
assert_line "${tmp_dir}/multi.msmtprc" "tls_trust_file /etc/ssl/certs/ca-certificates.crt"
assert_line "${tmp_dir}/multi.msmtprc" "tls_fingerprint AA:BB:CC:DD"
assert_line "${tmp_dir}/multi.msmtprc" "host smtp.personal.example"

mkdir -p "${tmp_dir}/persistent-defaults"
cat > "${tmp_dir}/persistent-defaults/default.env" <<'EOF'
MSMTP_ACCOUNT_NAME=server
MSMTP_HOST=smtp.server.example
MSMTP_PORT=587
MSMTP_FROM=server@example.com
MSMTP_USER=server@example.com
MSMTP_AUTH=on
MSMTP_TLS=on
MSMTP_TLS_STARTTLS=on
MSMTP_TLS_CERTCHECK=on
MSMTP_SECRET_METHOD=command
MSMTP_PASSWORDEVAL_COMMAND='printf server-secret'
EOF

cat > "${tmp_dir}/persistent-defaults/test.env" <<'EOF'
MSMTP_ACCOUNT_NAME=test
MSMTP_HOST=smtp.test.example
MSMTP_PORT=587
MSMTP_FROM=test@example.com
MSMTP_USER=test@example.com
MSMTP_AUTH=on
MSMTP_TLS=on
MSMTP_TLS_STARTTLS=on
MSMTP_TLS_CERTCHECK=on
MSMTP_SECRET_METHOD=command
MSMTP_PASSWORDEVAL_COMMAND='printf test-secret'
EOF

printf 'test\n' > "${tmp_dir}/persistent-defaults/.default-account"

"${repo_root}/scripts/render-config.sh" \
  --accounts-dir "${tmp_dir}/persistent-defaults" \
  --output "${tmp_dir}/persistent-defaults.msmtprc" >/dev/null

assert_line "${tmp_dir}/persistent-defaults.msmtprc" "account default : test"

if "${repo_root}/scripts/render-config.sh" \
  --accounts-dir "${tmp_dir}/persistent-defaults" \
  --default-account missing \
  --output "${tmp_dir}/persistent-defaults-fail.msmtprc" \
  >"${tmp_dir}/persistent-defaults.stdout" 2>"${tmp_dir}/persistent-defaults.stderr"; then
  fail "render-config.sh should refuse an explicit default account that is missing"
fi

assert_contains "${tmp_dir}/persistent-defaults.stderr" "Default account 'missing' was not found"

printf 'missing\n' > "${tmp_dir}/persistent-defaults/.default-account"
if "${repo_root}/scripts/render-config.sh" \
  --accounts-dir "${tmp_dir}/persistent-defaults" \
  --output "${tmp_dir}/persistent-defaults-stale.msmtprc" \
  >"${tmp_dir}/persistent-defaults-stale.stdout" 2>"${tmp_dir}/persistent-defaults-stale.stderr"; then
  fail "render-config.sh should refuse a stale persistent default account file"
fi

assert_contains "${tmp_dir}/persistent-defaults-stale.stderr" ".default-account"
assert_contains "${tmp_dir}/persistent-defaults-stale.stderr" "was not found"

mkdir -p "${tmp_dir}/duplicate-account-names"
cat > "${tmp_dir}/duplicate-account-names/work.env" <<'EOF'
MSMTP_ACCOUNT_NAME=shared
MSMTP_HOST=smtp.work.example
MSMTP_PORT=587
MSMTP_FROM=work@example.com
MSMTP_USER=work@example.com
MSMTP_AUTH=on
MSMTP_TLS=on
MSMTP_TLS_STARTTLS=on
MSMTP_TLS_CERTCHECK=on
MSMTP_SECRET_METHOD=command
MSMTP_PASSWORDEVAL_COMMAND='printf work-secret'
EOF

cat > "${tmp_dir}/duplicate-account-names/personal.env" <<'EOF'
MSMTP_ACCOUNT_NAME=shared
MSMTP_HOST=smtp.personal.example
MSMTP_PORT=587
MSMTP_FROM=personal@example.com
MSMTP_USER=personal@example.com
MSMTP_AUTH=on
MSMTP_TLS=on
MSMTP_TLS_STARTTLS=on
MSMTP_TLS_CERTCHECK=on
MSMTP_SECRET_METHOD=command
MSMTP_PASSWORDEVAL_COMMAND='printf personal-secret'
EOF

if "${repo_root}/scripts/render-config.sh" \
  --accounts-dir "${tmp_dir}/duplicate-account-names" \
  --output "${tmp_dir}/duplicate-account-names.msmtprc" \
  >"${tmp_dir}/duplicate-account-names.stdout" 2>"${tmp_dir}/duplicate-account-names.stderr"; then
  fail "render-config.sh should refuse duplicate MSMTP_ACCOUNT_NAME values"
fi

assert_contains "${tmp_dir}/duplicate-account-names.stderr" "Duplicate MSMTP_ACCOUNT_NAME 'shared'"

mkdir -p "${tmp_dir}/reserved-account-name"
cat > "${tmp_dir}/reserved-account-name/default.env" <<'EOF'
MSMTP_ACCOUNT_NAME=default
MSMTP_HOST=smtp.example.com
MSMTP_PORT=587
MSMTP_FROM=reserved@example.com
MSMTP_USER=reserved@example.com
MSMTP_AUTH=on
MSMTP_TLS=on
MSMTP_TLS_STARTTLS=on
MSMTP_TLS_CERTCHECK=on
MSMTP_SECRET_METHOD=command
MSMTP_PASSWORDEVAL_COMMAND='printf reserved-secret'
EOF

if "${repo_root}/scripts/render-config.sh" \
  --accounts-dir "${tmp_dir}/reserved-account-name" \
  --output "${tmp_dir}/reserved-account-name.msmtprc" \
  >"${tmp_dir}/reserved-account-name.stdout" 2>"${tmp_dir}/reserved-account-name.stderr"; then
  fail "render-config.sh should refuse the reserved MSMTP_ACCOUNT_NAME=default"
fi

assert_contains "${tmp_dir}/reserved-account-name.stderr" "MSMTP_ACCOUNT_NAME 'default' is reserved by msmtp"

cat > "${tmp_dir}/multi-accounts/password.env" <<EOF
MSMTP_ACCOUNT_NAME=passwordfile
MSMTP_HOST=smtp.example.net
MSMTP_PORT=587
MSMTP_FROM=root@example.net
MSMTP_USER=root@example.net
MSMTP_AUTH=on
MSMTP_TLS=on
MSMTP_TLS_STARTTLS=on
MSMTP_TLS_CERTCHECK=on
MSMTP_SECRET_METHOD=password_file
MSMTP_PASSWORD_FILE=${tmp_dir}/password-store/secret.txt
EOF

printf 'mail-secret\nmail-secret\n' | "${repo_root}/scripts/password-file-init.sh" \
  --env-file "${tmp_dir}/multi-accounts/password.env" >/dev/null 2>&1

password_file_contents="$(cat "${tmp_dir}/password-store/secret.txt")"
[ "$password_file_contents" = "mail-secret" ] || fail "Unexpected password-file contents"

mkdir -p "${tmp_dir}/tilde-home"
cat > "${tmp_dir}/multi-accounts/password-tilde.env" <<'EOF'
MSMTP_ACCOUNT_NAME=passwordtilde
MSMTP_HOST=smtp.example.net
MSMTP_PORT=587
MSMTP_FROM=root@example.net
MSMTP_USER=root@example.net
MSMTP_AUTH=on
MSMTP_TLS=on
MSMTP_TLS_STARTTLS=on
MSMTP_TLS_CERTCHECK=on
MSMTP_SECRET_METHOD=password_file
MSMTP_PASSWORD_FILE='~/.local/state/msmtp/tilde-secret.txt'
EOF

printf 'tilde-secret\ntilde-secret\n' | HOME="${tmp_dir}/tilde-home" "${repo_root}/scripts/password-file-init.sh" \
  --env-file "${tmp_dir}/multi-accounts/password-tilde.env" >/dev/null 2>&1

[ -f "${tmp_dir}/tilde-home/.local/state/msmtp/tilde-secret.txt" ] || fail "Expected ~ in password file path to expand into HOME"
[ ! -e "${repo_root}/~/.local/state/msmtp/tilde-secret.txt" ] || fail "Expected password-file init to avoid literal ~ paths under the repo"

HOME="${tmp_dir}/tilde-home" "${repo_root}/scripts/render-config.sh" \
  --accounts-dir "${tmp_dir}/multi-accounts" \
  --default-account passwordtilde \
  --output "${tmp_dir}/password-tilde.msmtprc" >/dev/null

assert_contains "${tmp_dir}/password-tilde.msmtprc" "passwordeval cat '${tmp_dir}/tilde-home/.local/state/msmtp/tilde-secret.txt'"

mkdir -p "${tmp_dir}/secret-check-accounts"
cat > "${tmp_dir}/secret-check-accounts/work.env" <<'EOF'
MSMTP_ACCOUNT_NAME=work
MSMTP_HOST=smtp.work.example
MSMTP_PORT=587
MSMTP_FROM=work@example.com
MSMTP_USER=work@example.com
MSMTP_AUTH=on
MSMTP_TLS=on
MSMTP_TLS_STARTTLS=on
MSMTP_TLS_CERTCHECK=on
MSMTP_SECRET_METHOD=command
MSMTP_PASSWORDEVAL_COMMAND='printf work-secret'
EOF

cat > "${tmp_dir}/secret-check-accounts/personal.env" <<'EOF'
MSMTP_ACCOUNT_NAME=personal
MSMTP_HOST=smtp.personal.example
MSMTP_PORT=465
MSMTP_FROM=me@example.net
MSMTP_USER=me@example.net
MSMTP_AUTH=on
MSMTP_TLS=on
MSMTP_TLS_STARTTLS=off
MSMTP_TLS_CERTCHECK=on
MSMTP_SECRET_METHOD=command
MSMTP_PASSWORDEVAL_COMMAND='printf personal-secret'
EOF

"${repo_root}/scripts/secret-check.sh" \
  --env-file "${tmp_dir}/secret-check-accounts/work.env" > "${tmp_dir}/secret-check-single.txt"
assert_contains "${tmp_dir}/secret-check-single.txt" "ok: work"

"${repo_root}/scripts/secret-check.sh" \
  --accounts-dir "${tmp_dir}/secret-check-accounts" > "${tmp_dir}/secret-check-accounts.txt"
assert_contains "${tmp_dir}/secret-check-accounts.txt" "ok: work"
assert_contains "${tmp_dir}/secret-check-accounts.txt" "ok: personal"

mkdir -p "${tmp_dir}/password-helper-accounts"
cat > "${tmp_dir}/password-helper-accounts/helper.env" <<EOF
MSMTP_ACCOUNT_NAME=helper
MSMTP_HOST=smtp.helper.example
MSMTP_PORT=587
MSMTP_FROM=helper@example.com
MSMTP_USER=helper@example.com
MSMTP_AUTH=on
MSMTP_TLS=on
MSMTP_TLS_STARTTLS=on
MSMTP_TLS_CERTCHECK=on
MSMTP_SECRET_METHOD=password_file
MSMTP_PASSWORD_FILE=${tmp_dir}/password-helper-secret
EOF

printf 'helper-secret\nhelper-secret\n' | "${repo_root}/scripts/password-helper.sh" \
  --accounts-dir "${tmp_dir}/password-helper-accounts" >/dev/null 2>&1

password_helper_contents="$(cat "${tmp_dir}/password-helper-secret")"
[ "$password_helper_contents" = "helper-secret" ] || fail "Unexpected password-helper output"
rm -f "${tmp_dir}/password-helper-secret"

mkdir -p "${tmp_dir}/rotate-password-accounts"
cat > "${tmp_dir}/rotate-password-accounts/default.env" <<EOF
MSMTP_ACCOUNT_NAME=rotator
MSMTP_HOST=smtp.rotate.example
MSMTP_PORT=587
MSMTP_FROM=rotator@example.com
MSMTP_USER=rotator@example.com
MSMTP_AUTH=on
MSMTP_TLS=on
MSMTP_TLS_STARTTLS=on
MSMTP_TLS_CERTCHECK=on
MSMTP_SECRET_METHOD=password_file
MSMTP_PASSWORD_FILE=${tmp_dir}/rotate-password-secret
EOF

printf 'old-rotate-secret' > "${tmp_dir}/rotate-password-secret"
printf 'new-rotate-secret\nnew-rotate-secret\n' | "${repo_root}/scripts/rotate-password.sh" \
  --accounts-dir "${tmp_dir}/rotate-password-accounts" \
  --force > "${tmp_dir}/rotate-password-output.txt" 2>&1

rotated_password_contents="$(cat "${tmp_dir}/rotate-password-secret")"
[ "$rotated_password_contents" = "new-rotate-secret" ] || fail "Unexpected rotated password contents"
rotate_backup_path="$(sed -n 's/^Backed up existing secret to //p' "${tmp_dir}/rotate-password-output.txt" | head -n 1)"
[ -n "$rotate_backup_path" ] || fail "Expected backup path in rotate-password output"
[ -f "$rotate_backup_path" ] || fail "Expected rotate-password backup file"
assert_matches "$rotate_backup_path" '\.bak\.[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}-[0-9]{2}-[0-9]{2}Z(\.[0-9]+)?$'
assert_contains "$rotate_backup_path" "old-rotate-secret"
assert_contains "${tmp_dir}/rotate-password-output.txt" "ok: rotator"

"${repo_root}/scripts/install.sh" \
  --accounts-dir "${tmp_dir}/multi-accounts" \
  --default-account personal \
  --output "${tmp_dir}/installed.msmtprc" \
  --target "${tmp_dir}/home/.msmtprc" >/dev/null

assert_contains "${tmp_dir}/installed.msmtprc" "account personal"
assert_contains "${tmp_dir}/home/.msmtprc" "account work"

"${repo_root}/scripts/install-helper.sh" \
  --accounts-dir "${tmp_dir}/multi-accounts" \
  --default-account personal \
  --output "${tmp_dir}/helper-install.msmtprc" \
  --target "${tmp_dir}/helper-home/.msmtprc" \
  --mode copy \
  --result-file "${tmp_dir}/helper-install-result.env" >/dev/null

assert_contains "${tmp_dir}/helper-home/.msmtprc" "account personal"
assert_contains "${tmp_dir}/helper-install-result.env" "INSTALL_TARGET_PATH='${tmp_dir}/helper-home/.msmtprc'"
assert_contains "${tmp_dir}/helper-install-result.env" "INSTALL_MODE='copy'"
assert_contains "${tmp_dir}/helper-install-result.env" "INSTALL_DEFAULT_ACCOUNT='personal'"

mkdir -p "${tmp_dir}/existing-home"
printf 'old-config\n' > "${tmp_dir}/existing-home/.msmtprc"
if "${repo_root}/scripts/install.sh" \
  --accounts-dir "${tmp_dir}/multi-accounts" \
  --default-account personal \
  --output "${tmp_dir}/existing-command.msmtprc" \
  --target "${tmp_dir}/existing-home/.msmtprc" >/dev/null 2>&1; then
  fail "install.sh should refuse to replace an existing target without confirmation or --force"
fi

"${repo_root}/scripts/install.sh" \
  --accounts-dir "${tmp_dir}/multi-accounts" \
  --default-account personal \
  --output "${tmp_dir}/existing-command.msmtprc" \
  --target "${tmp_dir}/existing-home/.msmtprc" \
  --force > "${tmp_dir}/forced-install.txt"

backup_path="$(sed -n 's/^Backed up existing target to //p' "${tmp_dir}/forced-install.txt" | head -n 1)"
[ -n "$backup_path" ] || fail "Expected backup path in forced install output"
[ -f "$backup_path" ] || fail "Expected forced install backup file"
assert_matches "$backup_path" '\.bak\.[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}-[0-9]{2}-[0-9]{2}Z(\.[0-9]+)?$'
assert_contains "$backup_path" "old-config"
assert_contains "${tmp_dir}/existing-home/.msmtprc" "account personal"

"${repo_root}/scripts/install.sh" \
  --accounts-dir "${tmp_dir}/multi-accounts" \
  --default-account personal \
  --output "${tmp_dir}/central/generated.msmtprc" \
  --target "${tmp_dir}/home-link/.msmtprc" \
  --mode symlink >/dev/null

[ -L "${tmp_dir}/home-link/.msmtprc" ] || fail "Expected symlink install target"
link_target="$(readlink "${tmp_dir}/home-link/.msmtprc")"
expected_link_target="$(cd "${tmp_dir}/central" && pwd -P)/generated.msmtprc"
[ "$link_target" = "$expected_link_target" ] || fail "Unexpected symlink target: $link_target"
assert_contains "${tmp_dir}/central/generated.msmtprc" "account work"

mkdir -p "${tmp_dir}/restore-home"
printf 'current-config\n' > "${tmp_dir}/restore-home/.msmtprc"
printf 'restored-config\n' > "${tmp_dir}/restore-home/.msmtprc.bak.saved"
if "${repo_root}/scripts/restore-backup.sh" \
  --backup "${tmp_dir}/restore-home/.msmtprc.bak.saved" \
  --target "${tmp_dir}/restore-home/.msmtprc" >/dev/null 2>&1; then
  fail "restore-backup.sh should refuse to replace an existing target without confirmation or --force"
fi

"${repo_root}/scripts/restore-backup.sh" \
  --backup "${tmp_dir}/restore-home/.msmtprc.bak.saved" \
  --target "${tmp_dir}/restore-home/.msmtprc" \
  --force > "${tmp_dir}/restore-output.txt"

restore_backup_path="$(sed -n 's/^Backed up existing target to //p' "${tmp_dir}/restore-output.txt" | head -n 1)"
[ -n "$restore_backup_path" ] || fail "Expected backup path in restore output"
[ -f "$restore_backup_path" ] || fail "Expected restore backup file"
assert_contains "$restore_backup_path" "current-config"
assert_contains "${tmp_dir}/restore-home/.msmtprc" "restored-config"
[ -f "${tmp_dir}/restore-home/.msmtprc.bak.saved" ] || fail "Expected chosen restore backup to remain in place"

printf 'restore-helper-config\n' > "${tmp_dir}/restore-helper.bak"
"${repo_root}/scripts/restore-config-helper.sh" \
  --backup "${tmp_dir}/restore-helper.bak" \
  --target "${tmp_dir}/restore-helper-home/.msmtprc" >/dev/null
assert_contains "${tmp_dir}/restore-helper-home/.msmtprc" "restore-helper-config"

printf 'restore-umbrella-config\n' > "${tmp_dir}/restore-umbrella.bak"
"${repo_root}/scripts/restore-helper.sh" \
  --type config \
  --backup "${tmp_dir}/restore-umbrella.bak" \
  --target "${tmp_dir}/restore-umbrella-home/.msmtprc" >/dev/null
assert_contains "${tmp_dir}/restore-umbrella-home/.msmtprc" "restore-umbrella-config"

mkdir -p "${tmp_dir}/restore-links"
printf 'linked-config\n' > "${tmp_dir}/restore-links/generated.msmtprc"
ln -s "${tmp_dir}/restore-links/generated.msmtprc" "${tmp_dir}/restore-links/symlink-backup"
"${repo_root}/scripts/restore-backup.sh" \
  --backup "${tmp_dir}/restore-links/symlink-backup" \
  --target "${tmp_dir}/restore-links/.msmtprc" >/dev/null
[ -L "${tmp_dir}/restore-links/.msmtprc" ] || fail "Expected symlink restore target"

mkdir -p "${tmp_dir}/managed-accounts"
cp "${tmp_dir}/multi-accounts/work.env" "${tmp_dir}/managed-accounts/work.env"
cp "${tmp_dir}/multi-accounts/personal.env" "${tmp_dir}/managed-accounts/personal.env"

"${repo_root}/scripts/account-manager.sh" \
  --accounts-dir "${tmp_dir}/managed-accounts" \
  --action set-default \
  --account personal >/dev/null 2>&1

[ "$(cat "${tmp_dir}/managed-accounts/.default-account")" = "personal" ] || fail "Expected account-manager set-default to write the persistent default account file"

"${repo_root}/scripts/account-manager.sh" \
  --accounts-dir "${tmp_dir}/managed-accounts" \
  --action list > "${tmp_dir}/managed-accounts-list.txt" 2>&1

assert_contains "${tmp_dir}/managed-accounts-list.txt" "personal.env (msmtp account: personal, persistent default)"

"${repo_root}/scripts/account-manager.sh" \
  --accounts-dir "${tmp_dir}/managed-accounts" \
  --action delete \
  --account work \
  --force > "${tmp_dir}/managed-accounts-delete.txt" 2>&1

[ ! -f "${tmp_dir}/managed-accounts/work.env" ] || fail "Expected work.env to be moved away"
deleted_account_backup="$(find "${tmp_dir}/managed-accounts" -maxdepth 1 -type f -name 'work.env.bak.*' -print -quit)"
[ -n "$deleted_account_backup" ] || fail "Expected deleted account backup"

"${repo_root}/scripts/restore-account-helper.sh" \
  --accounts-dir "${tmp_dir}/managed-accounts" \
  --backup "$deleted_account_backup" >/dev/null 2>&1

[ -f "${tmp_dir}/managed-accounts/work.env" ] || fail "Expected restore-account-helper to restore work.env"
assert_contains "${tmp_dir}/managed-accounts/work.env" "MSMTP_ACCOUNT_NAME=work"

"${repo_root}/scripts/restore-secret-helper.sh" \
  --env-file "${tmp_dir}/rotate-password-accounts/default.env" \
  --backup "$rotate_backup_path" \
  --force > "${tmp_dir}/restore-secret-output.txt" 2>&1

assert_contains "${tmp_dir}/rotate-password-secret" "old-rotate-secret"
assert_contains "${tmp_dir}/restore-secret-output.txt" "ok: rotator"

mkdir -p "${tmp_dir}/test-email-accounts"
cat > "${tmp_dir}/test-email-accounts/default.env" <<EOF
MSMTP_ACCOUNT_NAME=mailtest
MSMTP_HOST=smtp.test-email.example
MSMTP_PORT=587
MSMTP_FROM=mailtest@example.com
MSMTP_USER=mailtest@example.com
MSMTP_AUTH=on
MSMTP_TLS=on
MSMTP_TLS_STARTTLS=on
MSMTP_TLS_CERTCHECK=on
MSMTP_SECRET_METHOD=command
MSMTP_PASSWORDEVAL_COMMAND='printf fake-test-password'
EOF

mkdir -p "${tmp_dir}/fake-bin"
cat > "${tmp_dir}/fake-bin/msmtp" <<EOF
#!/usr/bin/env bash
set -euo pipefail
printf 'ARGS:%s\n' "\$*" > "${tmp_dir}/fake-msmtp-log.txt"
cat >> "${tmp_dir}/fake-msmtp-log.txt"
EOF
chmod +x "${tmp_dir}/fake-bin/msmtp"

PATH="${tmp_dir}/fake-bin:${PATH}" "${repo_root}/scripts/test-email.sh" \
  --env-file "${tmp_dir}/test-email-accounts/default.env" \
  --recipient recipient@example.com \
  --subject "repo test subject" \
  --body "repo test body" \
  --yes > "${tmp_dir}/test-email-output.txt" 2>&1

assert_contains "${tmp_dir}/fake-msmtp-log.txt" "ARGS:-C "
assert_contains "${tmp_dir}/fake-msmtp-log.txt" " -a mailtest recipient@example.com"
assert_contains "${tmp_dir}/fake-msmtp-log.txt" "From: mailtest@example.com"
assert_contains "${tmp_dir}/fake-msmtp-log.txt" "To: recipient@example.com"
assert_contains "${tmp_dir}/fake-msmtp-log.txt" "Subject: repo test subject"
assert_contains "${tmp_dir}/fake-msmtp-log.txt" "repo test body"
assert_contains "${tmp_dir}/test-email-output.txt" "Test email sent."

printf 'live-config\n' > "${tmp_dir}/live-test.msmtprc"
PATH="${tmp_dir}/fake-bin:${PATH}" "${repo_root}/scripts/test-live-email.sh" \
  --env-file "${tmp_dir}/test-email-accounts/default.env" \
  --target "${tmp_dir}/live-test.msmtprc" \
  --recipient live@example.com \
  --subject "live subject" \
  --body "live body" \
  --yes > "${tmp_dir}/test-live-email-output.txt" 2>&1

assert_contains "${tmp_dir}/fake-msmtp-log.txt" "ARGS:-C ${tmp_dir}/live-test.msmtprc -a mailtest live@example.com"
assert_contains "${tmp_dir}/fake-msmtp-log.txt" "Subject: live subject"
assert_contains "${tmp_dir}/fake-msmtp-log.txt" "live body"
assert_contains "${tmp_dir}/test-live-email-output.txt" "Live-config test email sent."

if command -v make >/dev/null 2>&1; then
  make -C "${repo_root}" \
    ACCOUNTS_DIR="${tmp_dir}/multi-accounts" \
    DEFAULT_ACCOUNT=personal \
    OUTPUT="${tmp_dir}/make.msmtprc" \
    generate >/dev/null
  assert_contains "${tmp_dir}/make.msmtprc" "account default : personal"

  make -C "${repo_root}" \
    ACCOUNTS_DIR="${tmp_dir}/secret-check-accounts" \
    ACCOUNT_NAME=work \
    secret-check > "${tmp_dir}/make-secret-check-single.txt"
  assert_contains "${tmp_dir}/make-secret-check-single.txt" "ok: work"

  make -C "${repo_root}" \
    ACCOUNTS_DIR="${tmp_dir}/multi-accounts" \
    DEFAULT_ACCOUNT=personal \
    SYSTEM_INSTALL_PATH="${tmp_dir}/etc/msmtprc" \
    INSTALL_FORCE=yes \
    install-system >/dev/null
  assert_contains "${tmp_dir}/etc/msmtprc" "account personal"

  printf 'make-restored\n' > "${tmp_dir}/make-restore-user.bak"
  make -C "${repo_root}" \
    USER_INSTALL_PATH="${tmp_dir}/make-restore-home/.msmtprc" \
    BACKUP="${tmp_dir}/make-restore-user.bak" \
    restore-user-config >/dev/null
  assert_contains "${tmp_dir}/make-restore-home/.msmtprc" "make-restored"

  mkdir -p "${tmp_dir}/make-password-accounts"
  cat > "${tmp_dir}/make-password-accounts/default.env" <<EOF
MSMTP_ACCOUNT_NAME=makehelper
MSMTP_HOST=smtp.helper.example
MSMTP_PORT=587
MSMTP_FROM=makehelper@example.com
MSMTP_USER=makehelper@example.com
MSMTP_AUTH=on
MSMTP_TLS=on
MSMTP_TLS_STARTTLS=on
MSMTP_TLS_CERTCHECK=on
MSMTP_SECRET_METHOD=password_file
MSMTP_PASSWORD_FILE=${tmp_dir}/make-password-secret
EOF

  printf 'make-password\nmake-password\n' | make -C "${repo_root}" \
    ACCOUNTS_DIR="${tmp_dir}/make-password-accounts" \
    password >/dev/null 2>&1
  assert_contains "${tmp_dir}/make-password-secret" "make-password"
  rm -f "${tmp_dir}/make-password-secret"

  mkdir -p "${tmp_dir}/make-rotate-accounts"
  cat > "${tmp_dir}/make-rotate-accounts/default.env" <<EOF
MSMTP_ACCOUNT_NAME=makerotate
MSMTP_HOST=smtp.rotate.example
MSMTP_PORT=587
MSMTP_FROM=makerotate@example.com
MSMTP_USER=makerotate@example.com
MSMTP_AUTH=on
MSMTP_TLS=on
MSMTP_TLS_STARTTLS=on
MSMTP_TLS_CERTCHECK=on
MSMTP_SECRET_METHOD=password_file
MSMTP_PASSWORD_FILE=${tmp_dir}/make-rotate-secret
EOF

  printf 'old-make-rotate' > "${tmp_dir}/make-rotate-secret"
  printf 'make-rotated\nmake-rotated\n' | make -C "${repo_root}" \
    ACCOUNTS_DIR="${tmp_dir}/make-rotate-accounts" \
    ROTATE_FORCE=yes \
    rotate-password > "${tmp_dir}/make-rotate-output.txt" 2>&1
  assert_contains "${tmp_dir}/make-rotate-secret" "make-rotated"
  make_rotate_backup_path="$(sed -n 's/^Backed up existing secret to //p' "${tmp_dir}/make-rotate-output.txt" | head -n 1)"
  [ -n "$make_rotate_backup_path" ] || fail "Expected backup path in make rotate-password output"
  assert_contains "$make_rotate_backup_path" "old-make-rotate"

  make -C "${repo_root}" \
    ACCOUNT_FILE="${tmp_dir}/make-rotate-accounts/default.env" \
    BACKUP="${make_rotate_backup_path}" \
    INSTALL_FORCE=yes \
    restore-secret > "${tmp_dir}/make-restore-secret-output.txt" 2>&1
  assert_contains "${tmp_dir}/make-rotate-secret" "old-make-rotate"
  assert_contains "${tmp_dir}/make-restore-secret-output.txt" "ok: makerotate"

  mkdir -p "${tmp_dir}/make-test-email-accounts"
  cat > "${tmp_dir}/make-test-email-accounts/default.env" <<EOF
MSMTP_ACCOUNT_NAME=maketest
MSMTP_HOST=smtp.make-test.example
MSMTP_PORT=587
MSMTP_FROM=maketest@example.com
MSMTP_USER=maketest@example.com
MSMTP_AUTH=on
MSMTP_TLS=on
MSMTP_TLS_STARTTLS=on
MSMTP_TLS_CERTCHECK=on
MSMTP_SECRET_METHOD=command
MSMTP_PASSWORDEVAL_COMMAND='printf make-test-password'
EOF

  mkdir -p "${tmp_dir}/make-fake-bin"
  cat > "${tmp_dir}/make-fake-bin/msmtp" <<EOF
#!/usr/bin/env bash
set -euo pipefail
printf 'ARGS:%s\n' "\$*" > "${tmp_dir}/make-fake-msmtp-log.txt"
cat >> "${tmp_dir}/make-fake-msmtp-log.txt"
EOF
  chmod +x "${tmp_dir}/make-fake-bin/msmtp"

  PATH="${tmp_dir}/make-fake-bin:${PATH}" make -C "${repo_root}" \
    ACCOUNTS_DIR="${tmp_dir}/make-test-email-accounts" \
    TEST_RECIPIENT=verify@example.com \
    TEST_SUBJECT="make subject" \
    TEST_BODY="make body" \
    test-email > "${tmp_dir}/make-test-email-output.txt" 2>&1
  assert_contains "${tmp_dir}/make-fake-msmtp-log.txt" " -a maketest verify@example.com"
  assert_contains "${tmp_dir}/make-fake-msmtp-log.txt" "Subject: make subject"
  assert_contains "${tmp_dir}/make-test-email-output.txt" "Test email sent."

  printf 'live make config\n' > "${tmp_dir}/make-live-test.msmtprc"
  PATH="${tmp_dir}/make-fake-bin:${PATH}" make -C "${repo_root}" \
    ACCOUNTS_DIR="${tmp_dir}/make-test-email-accounts" \
    LIVE_CONFIG_PATH="${tmp_dir}/make-live-test.msmtprc" \
    TEST_RECIPIENT=deploy@example.com \
    TEST_SUBJECT="make live subject" \
    TEST_BODY="make live body" \
    test-live-email > "${tmp_dir}/make-test-live-email-output.txt" 2>&1
  assert_contains "${tmp_dir}/make-fake-msmtp-log.txt" "ARGS:-C ${tmp_dir}/make-live-test.msmtprc -a maketest deploy@example.com"
  assert_contains "${tmp_dir}/make-fake-msmtp-log.txt" "Subject: make live subject"
  assert_contains "${tmp_dir}/make-test-live-email-output.txt" "Live-config test email sent."
fi

printf 'All tests passed.\n'
