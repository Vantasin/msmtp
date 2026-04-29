# Bootstrap

The repository includes a self-contained
[`scripts/bootstrap.sh`](../scripts/bootstrap.sh) entrypoint for optional
first-run automation.

Supported public bootstrap command:

```bash
curl -fsSL https://raw.githubusercontent.com/Vantasin/msmtp/main/scripts/bootstrap.sh | bash
```

What it does:

- clones the repository into `~/Git/msmtp` by default
- creates `~/Git` first when needed
- installs the basic dependencies with a supported package manager
- changes into the cloned checkout internally
- starts `make configure` when an interactive terminal is available

Supported package managers:

- macOS: Homebrew for `git` and `msmtp`, with `make` expected from Apple's
  Command Line Tools
- Linux: `apt-get`, `dnf`

Current limits:

- a shell script can `cd` internally before it runs `make configure`, but it
  cannot leave your calling shell inside the cloned repository after it exits

Configuration knobs:

- `--repo-url URL` or `MSMTP_BOOTSTRAP_REPO_URL`
- `--dest-parent PATH` or `MSMTP_BOOTSTRAP_DEST_PARENT`
- `--repo-name NAME` or `MSMTP_BOOTSTRAP_REPO_NAME`
- `--skip-configure` or `MSMTP_BOOTSTRAP_SKIP_CONFIGURE=yes`

Example for a local dry run against an existing checkout:

```bash
MSMTP_BOOTSTRAP_REPO_URL="$PWD" \
MSMTP_BOOTSTRAP_DEST_PARENT="$HOME/Git" \
bash ./scripts/bootstrap.sh --skip-configure
```
