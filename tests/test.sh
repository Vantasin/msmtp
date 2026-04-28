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
  bash -n "${repo_root}/scripts/secrets-help.sh"
  bash -n "${repo_root}/scripts/secret-check.sh"
  bash -n "${repo_root}/scripts/keychain-add.sh"
  bash -n "${repo_root}/scripts/password-file-init.sh"
  bash -n "${repo_root}/scripts/gpg-file-init.sh"
  bash -n "${repo_root}/scripts/render-config.sh"
  bash -n "${repo_root}/scripts/install.sh"
  bash -n "${repo_root}/scripts/install-helper.sh"
  bash -n "${repo_root}/scripts/restore-backup.sh"
  bash -n "${repo_root}/scripts/restore-helper.sh"
  bash -n "${repo_root}/scripts/account-manager.sh"
  bash -n "${repo_root}/scripts/password-helper.sh"
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

"${repo_root}/scripts/quickstart.sh" \
  --example password-file \
  --env-file "${tmp_dir}/bootstrap.env" >/dev/null

assert_contains "${tmp_dir}/bootstrap.env" "MSMTP_SECRET_METHOD=password_file"

"${repo_root}/scripts/secrets-help.sh" > "${tmp_dir}/secrets-help.txt"
assert_contains "${tmp_dir}/secrets-help.txt" "make secret-check"
assert_contains "${tmp_dir}/secrets-help.txt" "docs/secrets.md"

if "${repo_root}/scripts/quickstart.sh" \
  --example default \
  --env-file "${tmp_dir}/bootstrap.env" >/dev/null 2>&1; then
  fail "quickstart.sh should refuse to overwrite an existing env file"
fi

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
  "" \
  "" \
  "" \
  "no" | "${repo_root}/scripts/setup.sh" \
    --env-file "${tmp_dir}/guided.env" \
    --output "${tmp_dir}/guided.msmtprc" \
    --target "${tmp_dir}/home-guided/.msmtprc" >/dev/null 2>&1

"${repo_root}/scripts/render-config.sh" \
  --env-file "${tmp_dir}/guided.env" \
  --output "${tmp_dir}/guided.msmtprc" >/dev/null

assert_contains "${tmp_dir}/guided.env" "MSMTP_SECRET_METHOD='command'"
assert_contains "${tmp_dir}/guided.msmtprc" "account guided"
assert_contains "${tmp_dir}/guided.msmtprc" "passwordeval pass show mail/guided"

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
  "" \
  "" \
  "" \
  "" \
  "no" | "${repo_root}/scripts/setup.sh" \
    --env-file "${tmp_dir}/guided.env" \
    --overwrite \
    --output "${tmp_dir}/guided.msmtprc" \
    --target "${tmp_dir}/home-guided/.msmtprc" >/dev/null 2>&1

assert_contains "${tmp_dir}/guided.env" "MSMTP_HOST='smtp.edited.example'"

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

cat > "${tmp_dir}/secret-check.env" <<'EOF'
MSMTP_ACCOUNT_NAME=check
MSMTP_HOST=smtp.check.example
MSMTP_PORT=587
MSMTP_FROM=check@example.com
MSMTP_USER=check@example.com
MSMTP_AUTH=on
MSMTP_TLS=on
MSMTP_TLS_STARTTLS=on
MSMTP_TLS_CERTCHECK=on
MSMTP_SET_DEFAULT=true
MSMTP_SECRET_METHOD=command
MSMTP_PASSWORDEVAL_COMMAND='printf check-secret'
EOF

mkdir -p "${tmp_dir}/accounts"
mkdir -p "${tmp_dir}/accounts-check"

cat > "${tmp_dir}/accounts/work.env" <<'EOF'
MSMTP_ACCOUNT_NAME=work
MSMTP_HOST=smtp.work.example
MSMTP_PORT=587
MSMTP_FROM=work@example.com
MSMTP_USER=work@example.com
MSMTP_AUTH=on
MSMTP_TLS=on
MSMTP_TLS_STARTTLS=on
MSMTP_TLS_CERTCHECK=on
MSMTP_SET_DEFAULT=false
MSMTP_SECRET_METHOD=keychain
MSMTP_KEYCHAIN_SERVICE=smtp.work.example
MSMTP_KEYCHAIN_ACCOUNT=work@example.com
EOF

cat > "${tmp_dir}/accounts/personal.env" <<'EOF'
MSMTP_ACCOUNT_NAME=personal
MSMTP_HOST=smtp.personal.example
MSMTP_PORT=465
MSMTP_FROM=me@example.net
MSMTP_USER=me@example.net
MSMTP_AUTH=on
MSMTP_TLS=on
MSMTP_TLS_STARTTLS=off
MSMTP_TLS_CERTCHECK=on
MSMTP_SET_DEFAULT=false
MSMTP_SECRET_METHOD=command
MSMTP_PASSWORDEVAL_COMMAND='pass show mail/personal'
EOF

cat > "${tmp_dir}/accounts-check/work.env" <<'EOF'
MSMTP_ACCOUNT_NAME=work
MSMTP_HOST=smtp.work.example
MSMTP_PORT=587
MSMTP_FROM=work@example.com
MSMTP_USER=work@example.com
MSMTP_AUTH=on
MSMTP_TLS=on
MSMTP_TLS_STARTTLS=on
MSMTP_TLS_CERTCHECK=on
MSMTP_SET_DEFAULT=true
MSMTP_SECRET_METHOD=command
MSMTP_PASSWORDEVAL_COMMAND='printf work-secret'
EOF

cat > "${tmp_dir}/accounts-check/personal.env" <<'EOF'
MSMTP_ACCOUNT_NAME=personal
MSMTP_HOST=smtp.personal.example
MSMTP_PORT=465
MSMTP_FROM=me@example.net
MSMTP_USER=me@example.net
MSMTP_AUTH=on
MSMTP_TLS=on
MSMTP_TLS_STARTTLS=off
MSMTP_TLS_CERTCHECK=on
MSMTP_SET_DEFAULT=false
MSMTP_SECRET_METHOD=command
MSMTP_PASSWORDEVAL_COMMAND='printf personal-secret'
EOF

"${repo_root}/scripts/secret-check.sh" \
  --env-file "${tmp_dir}/secret-check.env" > "${tmp_dir}/secret-check-single.txt"

assert_contains "${tmp_dir}/secret-check-single.txt" "ok: check"

"${repo_root}/scripts/secret-check.sh" \
  --accounts-dir "${tmp_dir}/accounts-check" > "${tmp_dir}/secret-check-accounts.txt"

assert_contains "${tmp_dir}/secret-check-accounts.txt" "ok: work"
assert_contains "${tmp_dir}/secret-check-accounts.txt" "ok: personal"

"${repo_root}/scripts/render-config.sh" \
  --accounts-dir "${tmp_dir}/accounts" \
  --default-account personal \
  --output "${tmp_dir}/multi.msmtprc" >/dev/null

assert_contains "${tmp_dir}/multi.msmtprc" "account work"
assert_contains "${tmp_dir}/multi.msmtprc" "account personal"
assert_contains "${tmp_dir}/multi.msmtprc" "passwordeval security find-generic-password -w -s 'smtp.work.example' -a 'work@example.com'"
assert_contains "${tmp_dir}/multi.msmtprc" "passwordeval pass show mail/personal"
assert_contains "${tmp_dir}/multi.msmtprc" "account default : personal"

printf 'mail-secret\nmail-secret\n' | "${repo_root}/scripts/password-file-init.sh" \
  --env-file "${tmp_dir}/password-file.env" \
  --password-file "${tmp_dir}/password-store/secret.txt" >/dev/null 2>&1

password_file_contents="$(cat "${tmp_dir}/password-store/secret.txt")"
[ "$password_file_contents" = "mail-secret" ] || fail "Unexpected password-file contents"

cat > "${tmp_dir}/password-helper.env" <<EOF
MSMTP_ACCOUNT_NAME=helper
MSMTP_HOST=smtp.helper.example
MSMTP_PORT=587
MSMTP_FROM=helper@example.com
MSMTP_USER=helper@example.com
MSMTP_AUTH=on
MSMTP_TLS=on
MSMTP_TLS_STARTTLS=on
MSMTP_TLS_CERTCHECK=on
MSMTP_SET_DEFAULT=true
MSMTP_SECRET_METHOD=password_file
MSMTP_PASSWORD_FILE=${tmp_dir}/password-helper-secret
EOF

printf 'helper-secret\nhelper-secret\n' | "${repo_root}/scripts/password-helper.sh" \
  --env-file "${tmp_dir}/password-helper.env" >/dev/null 2>&1

password_helper_contents="$(cat "${tmp_dir}/password-helper-secret")"
[ "$password_helper_contents" = "helper-secret" ] || fail "Unexpected password-helper output"
rm -f "${tmp_dir}/password-helper-secret"

"${repo_root}/scripts/install.sh" \
  --env-file "${tmp_dir}/command.env" \
  --output "${tmp_dir}/command.msmtprc" \
  --target "${tmp_dir}/home/.msmtprc" >/dev/null

assert_contains "${tmp_dir}/command.msmtprc" "logfile /tmp/msmtp.log"
assert_contains "${tmp_dir}/command.msmtprc" "passwordeval pass show mail/msmtp"
assert_contains "${tmp_dir}/home/.msmtprc" "account cli"

"${repo_root}/scripts/install-helper.sh" \
  --env-file "${tmp_dir}/command.env" \
  --output "${tmp_dir}/helper-install.msmtprc" \
  --target "${tmp_dir}/helper-home/.msmtprc" \
  --mode copy >/dev/null

assert_contains "${tmp_dir}/helper-home/.msmtprc" "account cli"

mkdir -p "${tmp_dir}/existing-home"
printf 'old-config\n' > "${tmp_dir}/existing-home/.msmtprc"
if "${repo_root}/scripts/install.sh" \
  --env-file "${tmp_dir}/command.env" \
  --output "${tmp_dir}/existing-command.msmtprc" \
  --target "${tmp_dir}/existing-home/.msmtprc" >/dev/null 2>&1; then
  fail "install.sh should refuse to replace an existing target without confirmation or --force"
fi

"${repo_root}/scripts/install.sh" \
  --env-file "${tmp_dir}/command.env" \
  --output "${tmp_dir}/existing-command.msmtprc" \
  --target "${tmp_dir}/existing-home/.msmtprc" \
  --force > "${tmp_dir}/forced-install.txt"

backup_path="$(sed -n 's/^Backed up existing target to //p' "${tmp_dir}/forced-install.txt" | head -n 1)"
[ -n "$backup_path" ] || fail "Expected backup path in forced install output"
[ -f "$backup_path" ] || fail "Expected forced install backup file"
assert_contains "$backup_path" "old-config"
assert_contains "${tmp_dir}/existing-home/.msmtprc" "account cli"

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
"${repo_root}/scripts/restore-helper.sh" \
  --backup "${tmp_dir}/restore-helper.bak" \
  --target "${tmp_dir}/restore-helper-home/.msmtprc" >/dev/null
assert_contains "${tmp_dir}/restore-helper-home/.msmtprc" "restore-helper-config"

mkdir -p "${tmp_dir}/restore-links"
printf 'linked-config\n' > "${tmp_dir}/restore-links/generated.msmtprc"
ln -s "${tmp_dir}/restore-links/generated.msmtprc" "${tmp_dir}/restore-links/symlink-backup"
"${repo_root}/scripts/restore-backup.sh" \
  --backup "${tmp_dir}/restore-links/symlink-backup" \
  --target "${tmp_dir}/restore-links/.msmtprc" >/dev/null
[ -L "${tmp_dir}/restore-links/.msmtprc" ] || fail "Expected symlink restore target"

"${repo_root}/scripts/install.sh" \
  --env-file "${tmp_dir}/command.env" \
  --output "${tmp_dir}/central/generated.msmtprc" \
  --target "${tmp_dir}/home-link/.msmtprc" \
  --mode symlink >/dev/null

[ -L "${tmp_dir}/home-link/.msmtprc" ] || fail "Expected symlink install target"
link_target="$(readlink "${tmp_dir}/home-link/.msmtprc")"
expected_link_target="$(cd "${tmp_dir}/central" && pwd -P)/generated.msmtprc"
[ "$link_target" = "$expected_link_target" ] || fail "Unexpected symlink target: $link_target"
assert_contains "${tmp_dir}/central/generated.msmtprc" "account cli"

"${repo_root}/scripts/install.sh" \
  --accounts-dir "${tmp_dir}/accounts" \
  --default-account personal \
  --output "${tmp_dir}/multi-install.msmtprc" \
  --target "${tmp_dir}/multi-home/.msmtprc" >/dev/null

assert_contains "${tmp_dir}/multi-install.msmtprc" "account work"
assert_contains "${tmp_dir}/multi-home/.msmtprc" "account personal"

mkdir -p "${tmp_dir}/managed-accounts"
cp "${tmp_dir}/accounts/work.env" "${tmp_dir}/managed-accounts/work.env"
cp "${tmp_dir}/accounts/personal.env" "${tmp_dir}/managed-accounts/personal.env"

"${repo_root}/scripts/account-manager.sh" \
  --accounts-dir "${tmp_dir}/managed-accounts" \
  --mode multi \
  --action set-default \
  --account personal >/dev/null

assert_contains "${tmp_dir}/managed-accounts/personal.env" "MSMTP_SET_DEFAULT='true'"
assert_contains "${tmp_dir}/managed-accounts/work.env" "MSMTP_SET_DEFAULT='false'"

"${repo_root}/scripts/account-manager.sh" \
  --accounts-dir "${tmp_dir}/managed-accounts" \
  --mode multi \
  --action list > "${tmp_dir}/managed-accounts-list.txt"

assert_contains "${tmp_dir}/managed-accounts-list.txt" "personal.env (personal, default)"

"${repo_root}/scripts/account-manager.sh" \
  --accounts-dir "${tmp_dir}/managed-accounts" \
  --mode multi \
  --action delete \
  --account work \
  --force > "${tmp_dir}/managed-accounts-delete.txt"

[ ! -f "${tmp_dir}/managed-accounts/work.env" ] || fail "Expected work.env to be moved away"
[ -n "$(find "${tmp_dir}/managed-accounts" -maxdepth 1 -type f -name 'work.env.bak.*' -print -quit)" ] || fail "Expected deleted account backup"

if command -v make >/dev/null 2>&1; then
  make -C "${repo_root}" \
    ENV_FILE="${tmp_dir}/command.env" \
    OUTPUT="${tmp_dir}/make.msmtprc" \
    generate >/dev/null
  assert_contains "${tmp_dir}/make.msmtprc" "account cli"

  make -C "${repo_root}" \
    ACCOUNTS_DIR="${tmp_dir}/accounts" \
    DEFAULT_ACCOUNT=personal \
    OUTPUT="${tmp_dir}/make-multi.msmtprc" \
    generate >/dev/null
  assert_contains "${tmp_dir}/make-multi.msmtprc" "account default : personal"

  make -C "${repo_root}" \
    ENV_FILE="${tmp_dir}/command.env" \
    SYSTEM_INSTALL_PATH="${tmp_dir}/etc/msmtprc" \
    INSTALL_FORCE=yes \
    install-system >/dev/null
  assert_contains "${tmp_dir}/etc/msmtprc" "account cli"

  printf 'make-restored\n' > "${tmp_dir}/make-restore-user.bak"
  make -C "${repo_root}" \
    USER_INSTALL_PATH="${tmp_dir}/make-restore-home/.msmtprc" \
    BACKUP="${tmp_dir}/make-restore-user.bak" \
    restore-user >/dev/null
  assert_contains "${tmp_dir}/make-restore-home/.msmtprc" "make-restored"

  printf 'make-password\nmake-password\n' | make -C "${repo_root}" \
    SECRET_ENV_FILE="${tmp_dir}/password-helper.env" \
    password >/dev/null
  assert_contains "${tmp_dir}/password-helper-secret" "make-password"
  rm -f "${tmp_dir}/password-helper-secret"
fi

printf 'All tests passed.\n'
