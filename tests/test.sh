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
    sed -n '1,200p' "$file_path" >&2
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
  bash -n "${repo_root}/scripts/rotate-password.sh"
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

mkdir -p "${tmp_dir}/bootstrap-accounts"
"${repo_root}/scripts/quickstart.sh" \
  --example password-file \
  --env-file "${tmp_dir}/bootstrap-accounts/default.env" >/dev/null
assert_contains "${tmp_dir}/bootstrap-accounts/default.env" "MSMTP_SECRET_METHOD=password_file"

if "${repo_root}/scripts/quickstart.sh" \
  --example default \
  --env-file "${tmp_dir}/bootstrap-accounts/default.env" >/dev/null 2>&1; then
  fail "quickstart.sh should refuse to overwrite an existing account file"
fi

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
  "" \
  "" \
  "" \
  "no" | "${repo_root}/scripts/setup.sh" \
    --env-file "${tmp_dir}/guided-accounts/guided.env" \
    --output "${tmp_dir}/guided.msmtprc" \
    --target "${tmp_dir}/guided-home/.msmtprc" >/dev/null 2>&1

assert_contains "${tmp_dir}/guided-accounts/guided.env" "MSMTP_SECRET_METHOD='command'"

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
  "no" | "${repo_root}/scripts/setup.sh" \
    --env-file "${tmp_dir}/guided-accounts/guided.env" \
    --overwrite \
    --output "${tmp_dir}/guided.msmtprc" \
    --target "${tmp_dir}/guided-home/.msmtprc" >/dev/null 2>&1

assert_contains "${tmp_dir}/guided-accounts/guided.env" "MSMTP_HOST='smtp.edited.example'"

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
MSMTP_SET_DEFAULT=true
MSMTP_SECRET_METHOD=keychain
MSMTP_KEYCHAIN_SERVICE=smtp.example.com
MSMTP_KEYCHAIN_ACCOUNT=alice@example.com
EOF

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
MSMTP_SET_DEFAULT=false
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
MSMTP_SET_DEFAULT=false
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
MSMTP_SET_DEFAULT=false
MSMTP_SECRET_METHOD=password_file
MSMTP_PASSWORD_FILE=${tmp_dir}/password-store/secret.txt
EOF

printf 'mail-secret\nmail-secret\n' | "${repo_root}/scripts/password-file-init.sh" \
  --env-file "${tmp_dir}/multi-accounts/password.env" >/dev/null 2>&1

password_file_contents="$(cat "${tmp_dir}/password-store/secret.txt")"
[ "$password_file_contents" = "mail-secret" ] || fail "Unexpected password-file contents"

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
MSMTP_SET_DEFAULT=true
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
MSMTP_SET_DEFAULT=false
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
MSMTP_SET_DEFAULT=true
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
MSMTP_SET_DEFAULT=true
MSMTP_SECRET_METHOD=password_file
MSMTP_PASSWORD_FILE=${tmp_dir}/rotate-password-secret
EOF

printf 'old-rotate-secret' > "${tmp_dir}/rotate-password-secret"
printf 'new-rotate-secret\nnew-rotate-secret\n' | "${repo_root}/scripts/rotate-password.sh" \
  --accounts-dir "${tmp_dir}/rotate-password-accounts" \
  --force > "${tmp_dir}/rotate-password-output.txt"

rotated_password_contents="$(cat "${tmp_dir}/rotate-password-secret")"
[ "$rotated_password_contents" = "new-rotate-secret" ] || fail "Unexpected rotated password contents"
rotate_backup_path="$(sed -n 's/^Backed up existing secret to //p' "${tmp_dir}/rotate-password-output.txt" | head -n 1)"
[ -n "$rotate_backup_path" ] || fail "Expected backup path in rotate-password output"
[ -f "$rotate_backup_path" ] || fail "Expected rotate-password backup file"
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
  --mode copy >/dev/null

assert_contains "${tmp_dir}/helper-home/.msmtprc" "account personal"

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

mkdir -p "${tmp_dir}/managed-accounts"
cp "${tmp_dir}/multi-accounts/work.env" "${tmp_dir}/managed-accounts/work.env"
cp "${tmp_dir}/multi-accounts/personal.env" "${tmp_dir}/managed-accounts/personal.env"

"${repo_root}/scripts/account-manager.sh" \
  --accounts-dir "${tmp_dir}/managed-accounts" \
  --action set-default \
  --account personal >/dev/null

assert_contains "${tmp_dir}/managed-accounts/personal.env" "MSMTP_SET_DEFAULT='true'"
assert_contains "${tmp_dir}/managed-accounts/work.env" "MSMTP_SET_DEFAULT='false'"

"${repo_root}/scripts/account-manager.sh" \
  --accounts-dir "${tmp_dir}/managed-accounts" \
  --action list > "${tmp_dir}/managed-accounts-list.txt"

assert_contains "${tmp_dir}/managed-accounts-list.txt" "personal.env (personal, default)"

"${repo_root}/scripts/account-manager.sh" \
  --accounts-dir "${tmp_dir}/managed-accounts" \
  --action delete \
  --account work \
  --force > "${tmp_dir}/managed-accounts-delete.txt"

[ ! -f "${tmp_dir}/managed-accounts/work.env" ] || fail "Expected work.env to be moved away"
[ -n "$(find "${tmp_dir}/managed-accounts" -maxdepth 1 -type f -name 'work.env.bak.*' -print -quit)" ] || fail "Expected deleted account backup"

if command -v make >/dev/null 2>&1; then
  make -C "${repo_root}" \
    ACCOUNTS_DIR="${tmp_dir}/multi-accounts" \
    DEFAULT_ACCOUNT=personal \
    OUTPUT="${tmp_dir}/make.msmtprc" \
    generate >/dev/null
  assert_contains "${tmp_dir}/make.msmtprc" "account default : personal"

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
    restore-user >/dev/null
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
MSMTP_SET_DEFAULT=true
MSMTP_SECRET_METHOD=password_file
MSMTP_PASSWORD_FILE=${tmp_dir}/make-password-secret
EOF

  printf 'make-password\nmake-password\n' | make -C "${repo_root}" \
    ACCOUNTS_DIR="${tmp_dir}/make-password-accounts" \
    password >/dev/null
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
MSMTP_SET_DEFAULT=true
MSMTP_SECRET_METHOD=password_file
MSMTP_PASSWORD_FILE=${tmp_dir}/make-rotate-secret
EOF

  printf 'old-make-rotate' > "${tmp_dir}/make-rotate-secret"
  printf 'make-rotated\nmake-rotated\n' | make -C "${repo_root}" \
    ACCOUNTS_DIR="${tmp_dir}/make-rotate-accounts" \
    ROTATE_FORCE=yes \
    rotate-password > "${tmp_dir}/make-rotate-output.txt"
  assert_contains "${tmp_dir}/make-rotate-secret" "make-rotated"
  make_rotate_backup_path="$(sed -n 's/^Backed up existing secret to //p' "${tmp_dir}/make-rotate-output.txt" | head -n 1)"
  [ -n "$make_rotate_backup_path" ] || fail "Expected backup path in make rotate-password output"
  assert_contains "$make_rotate_backup_path" "old-make-rotate"
fi

printf 'All tests passed.\n'
