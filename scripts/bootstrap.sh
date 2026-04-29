#!/usr/bin/env bash
set -euo pipefail

default_repo_url='ssh://git@gitea.vantasin.duckdns.org:2222/Vantasin/msmtp.git'
dest_parent="${MSMTP_BOOTSTRAP_DEST_PARENT:-${HOME}/Git}"
repo_name="${MSMTP_BOOTSTRAP_REPO_NAME:-msmtp}"
repo_url="${MSMTP_BOOTSTRAP_REPO_URL:-$default_repo_url}"
skip_configure="${MSMTP_BOOTSTRAP_SKIP_CONFIGURE:-no}"

usage() {
  cat <<'EOF'
Usage: scripts/bootstrap.sh [--repo-url URL] [--dest-parent PATH]
                            [--repo-name NAME] [--skip-configure]

Bootstrap a fresh msmtp checkout into ~/Git by default, install the basic
dependencies with a supported package manager, and then start make configure.

Supported package managers:
  - macOS: Homebrew for git and msmtp, with make expected from Command Line Tools
  - Linux: apt-get, dnf

Environment overrides:
  MSMTP_BOOTSTRAP_REPO_URL
  MSMTP_BOOTSTRAP_DEST_PARENT
  MSMTP_BOOTSTRAP_REPO_NAME
  MSMTP_BOOTSTRAP_SKIP_CONFIGURE=yes
  MSMTP_BOOTSTRAP_OS=Darwin|Linux   # test or override only
EOF
}

say() {
  printf '%s\n' "$*" >&2
}

die() {
  printf 'error: %s\n' "$*" >&2
  exit 1
}

have_cmd() {
  command -v "$1" >/dev/null 2>&1
}

expand_tilde_path() {
  local raw_path="${1:-}"

  case "$raw_path" in
    "~")
      printf '%s\n' "$HOME"
      ;;
    "~/"*)
      printf '%s/%s\n' "$HOME" "${raw_path#"~/"}"
      ;;
    *)
      printf '%s\n' "$raw_path"
      ;;
  esac
}

strip_trailing_slashes() {
  local path_value="$1"

  while [ "$path_value" != "/" ] && [ "${path_value%/}" != "$path_value" ]; do
    path_value="${path_value%/}"
  done

  printf '%s\n' "$path_value"
}

normalize_path() {
  local raw_path="$1"
  local expanded_path

  expanded_path="$(expand_tilde_path "$raw_path")"
  case "$expanded_path" in
    /*)
      strip_trailing_slashes "$expanded_path"
      ;;
    ./*)
      strip_trailing_slashes "$(pwd -P)/${expanded_path#./}"
      ;;
    *)
      strip_trailing_slashes "$(pwd -P)/$expanded_path"
      ;;
  esac
}

normalize_bool() {
  case "${1:-}" in
    1 | on | ON | true | TRUE | yes | YES)
      printf 'yes\n'
      ;;
    "" | 0 | off | OFF | false | FALSE | no | NO)
      printf 'no\n'
      ;;
    *)
      die "Invalid boolean value: $1"
      ;;
  esac
}

detect_os() {
  if [ -n "${MSMTP_BOOTSTRAP_OS:-}" ]; then
    printf '%s\n' "$MSMTP_BOOTSTRAP_OS"
  else
    uname -s
  fi
}

run_as_root_if_needed() {
  if [ "$(id -u)" -eq 0 ]; then
    "$@"
  elif have_cmd sudo; then
    sudo "$@"
  else
    die "This step requires elevated privileges. Install sudo or rerun the bootstrap as root."
  fi
}

install_dependencies() {
  local detected_os="$1"
  local missing=()

  case "$detected_os" in
    Darwin)
      if ! have_cmd brew; then
        die "Homebrew is required on macOS for the bootstrap path. Install Homebrew first, or use the manual quick start."
      fi

      have_cmd git || missing+=("git")
      have_cmd msmtp || missing+=("msmtp")

      if [ "${#missing[@]}" -gt 0 ]; then
        say "Installing dependencies with Homebrew: ${missing[*]}"
        brew install "${missing[@]}"
      else
        say "Dependencies already available: git and msmtp"
      fi

      have_cmd make || die "make is still unavailable on this macOS host. Install Apple's Command Line Tools, then rerun the bootstrap."
      ;;
    Linux)
      have_cmd git || missing+=("git")
      have_cmd make || missing+=("make")
      have_cmd msmtp || missing+=("msmtp")

      if [ "${#missing[@]}" -eq 0 ]; then
        say "Dependencies already available: git, make, and msmtp"
        return 0
      fi

      if have_cmd apt-get; then
        say "Installing dependencies with apt-get: git make msmtp"
        run_as_root_if_needed apt-get update
        run_as_root_if_needed apt-get install -y git make msmtp
      elif have_cmd dnf; then
        say "Installing dependencies with dnf: git make msmtp"
        run_as_root_if_needed dnf install -y git make msmtp
      else
        die "Unsupported Linux package manager for bootstrap. Install git, make, and msmtp manually, or use the manual quick start."
      fi
      ;;
    *)
      die "Unsupported operating system for bootstrap: $detected_os"
      ;;
  esac

  have_cmd git || die "git is still unavailable after dependency installation."
  have_cmd make || die "make is still unavailable after dependency installation."
  have_cmd msmtp || die "msmtp is still unavailable after dependency installation."
}

clone_or_reuse_repo() {
  local destination_path="$1"

  mkdir -p "$dest_parent"

  if [ -d "${destination_path}/.git" ]; then
    say "Using existing checkout at ${destination_path}"
    return 0
  fi

  if [ -e "$destination_path" ] && [ -n "$(ls -A "$destination_path" 2>/dev/null || true)" ]; then
    die "Destination already exists and is not an msmtp git checkout: $destination_path"
  fi

  say "Cloning ${repo_url} into ${destination_path}"
  git clone "$repo_url" "$destination_path"
}

reattach_stdin_to_tty_if_available() {
  if [ ! -t 0 ] && [ -r /dev/tty ]; then
    exec </dev/tty
  fi
}

run_configure() {
  local destination_path="$1"

  if [ "$(normalize_bool "$skip_configure")" = "yes" ]; then
    say "Skipping make configure because bootstrap was asked to stop after clone and dependency install."
    return 0
  fi

  if [ ! -t 0 ] && [ ! -r /dev/tty ]; then
    say "No interactive terminal is available, so bootstrap cannot start make configure automatically."
    say "Next step: cd ${destination_path} && make configure"
    return 0
  fi

  reattach_stdin_to_tty_if_available
  say "Starting guided setup with make configure in ${destination_path}"
  (
    cd "$destination_path"
    make configure
  )
}

while [ $# -gt 0 ]; do
  case "$1" in
    --repo-url)
      [ $# -ge 2 ] || die "--repo-url requires a value"
      repo_url="$2"
      shift 2
      ;;
    --dest-parent)
      [ $# -ge 2 ] || die "--dest-parent requires a value"
      dest_parent="$2"
      shift 2
      ;;
    --repo-name)
      [ $# -ge 2 ] || die "--repo-name requires a value"
      repo_name="$2"
      shift 2
      ;;
    --skip-configure)
      skip_configure="yes"
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

dest_parent="$(normalize_path "$dest_parent")"
repo_path="${dest_parent}/${repo_name}"
detected_os="$(detect_os)"

say "Preparing msmtp bootstrap for ${repo_path}"
install_dependencies "$detected_os"
clone_or_reuse_repo "$repo_path"
run_configure "$repo_path"
say "Bootstrap completed in ${repo_path}"
say "Note: this script cannot leave your current shell inside ${repo_path} after it exits."
