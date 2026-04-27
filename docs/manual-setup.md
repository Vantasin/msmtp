# Manual Setup

Use this guide if you want to configure `msmtp` directly without the repo's
automation layer.

The automated path in this repository is still the preferred workflow because
it keeps inputs reproducible and testable, but a manual fallback is useful for
debugging, one-off hosts, and environments where you do not want generation
scripts.

## 1. Create the Config File

Create `~/.msmtprc` and lock down its permissions:

```bash
touch ~/.msmtprc
chmod 600 ~/.msmtprc
```

Do not commit personalized `msmtprc` files to Git. They often contain private
addresses, usernames, hostnames, and secret lookup paths even when they do not
contain raw passwords.

## 2. Add a Base Config

Start with a minimal structure like this:

```text
defaults
auth on
tls on
tls_starttls on
tls_certcheck on

account work
host smtp.example.com
port 587
from user@example.com
user user@example.com
passwordeval <choose one of the commands below>

account default : work
```

## 3. Choose a Secret Lookup Method

Use one `passwordeval` strategy:

### macOS Keychain

```text
passwordeval security find-generic-password -w -s 'smtp.example.com' -a 'user@example.com'
```

### Linux GPG File

```text
passwordeval gpg --quiet --batch --decrypt '/root/.config/msmtp/password.gpg'
```

### Root-Owned Password File

```text
passwordeval cat '/etc/msmtp/password'
```

### Custom Command

```text
passwordeval pass show mail/msmtp
```

## 4. Validate the File

Check the generated content carefully:

- host, port, `from`, and `user` should match the account you expect
- the `passwordeval` command should resolve to the right secret source
- file permissions should remain `600`

## 5. Optional Repo-Centralized Workflow

If you still want a repo-centralized local config without hand-copying files,
the automated path can install a symlink for you:

```bash
make install INSTALL_MODE=symlink
```

That keeps the canonical generated file in the repo while `msmtp` continues to
read `~/.msmtprc`.
