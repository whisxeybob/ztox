#!/usr/bin/env bash
# ztox installer for macOS and Linux.
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/whisxeybob/ztox/main/install.sh | bash
# Env knobs:
#   ZTOX_REPO       — local path to a checkout (skip the git clone)
#   ZTOX_REPO_URL   — override clone URL (default: this repo)
#   ZTOX_REF        — branch/tag/sha to check out (default: main)
#   ZTOX_PREFIX     — install prefix (default: $HOME/.local)
#   ZTOX_NO_DEPS    — skip dependency installation (you handle it yourself)
#   ZTOX_NO_TOXCORE — assume c-toxcore is already on the system
#   ZTOX_BUILD_DIR  — out-of-tree build dir (default: $(mktemp -d))

set -euo pipefail

ZTOX_REPO_URL="${ZTOX_REPO_URL:-https://github.com/whisxeybob/ztox.git}"
ZTOX_REF="${ZTOX_REF:-main}"
ZTOX_PREFIX="${ZTOX_PREFIX:-$HOME/.local}"
ZTOX_NO_DEPS="${ZTOX_NO_DEPS:-0}"
ZTOX_NO_TOXCORE="${ZTOX_NO_TOXCORE:-0}"

c_reset='\033[0m'
c_bold='\033[1m'
c_blue='\033[34m'
c_green='\033[32m'
c_yellow='\033[33m'
c_red='\033[31m'

say()  { printf "${c_bold}${c_blue}==>${c_reset} %s\n" "$*"; }
ok()   { printf "${c_bold}${c_green}✓${c_reset}  %s\n" "$*"; }
warn() { printf "${c_bold}${c_yellow}!${c_reset}  %s\n" "$*" >&2; }
die()  { printf "${c_bold}${c_red}✗${c_reset}  %s\n" "$*" >&2; exit 1; }

need() { command -v "$1" >/dev/null 2>&1 || die "missing required tool: $1"; }

detect_platform() {
  local uname_s
  uname_s="$(uname -s)"
  case "$uname_s" in
    Darwin)
      PLATFORM=macos
      PKG_MGR=brew
      return
      ;;
    Linux)
      PLATFORM=linux
      ;;
    *)
      die "unsupported OS: $uname_s (this script handles macOS and Linux only — see install.ps1 for Windows)"
      ;;
  esac
  if [ -r /etc/os-release ]; then
    # shellcheck disable=SC1091
    . /etc/os-release
    case "${ID:-}${ID_LIKE:-}" in
      *debian*|*ubuntu*) PKG_MGR=apt ;;
      *fedora*|*rhel*|*centos*) PKG_MGR=dnf ;;
      *arch*|*manjaro*) PKG_MGR=pacman ;;
      *suse*) PKG_MGR=zypper ;;
      *alpine*) PKG_MGR=apk ;;
      *) PKG_MGR=unknown ;;
    esac
  else
    PKG_MGR=unknown
  fi
}

install_deps_macos() {
  if ! command -v brew >/dev/null 2>&1; then
    die "Homebrew is required on macOS. Install it from https://brew.sh and re-run."
  fi
  say "Installing build dependencies via Homebrew"
  brew install cmake ninja pkg-config qt@6 libsodium libvpx opus ffmpeg \
               sqlcipher openal-soft qrencode libexif >/dev/null
  if [ "$ZTOX_NO_TOXCORE" != "1" ]; then
    brew install toxcore >/dev/null
  fi
  ok "macOS dependencies installed"
}

install_deps_apt() {
  say "Installing build dependencies via apt (will use sudo)"
  sudo apt-get update -qq
  sudo apt-get install -y --no-install-recommends \
    build-essential cmake ninja-build pkg-config git ca-certificates \
    qt6-base-dev qt6-tools-dev qt6-tools-dev-tools qt6-l10n-tools \
    libqt6svg6-dev libqt6opengl6-dev \
    libsodium-dev libopus-dev libvpx-dev libavcodec-dev libavformat-dev \
    libavutil-dev libswscale-dev libavdevice-dev \
    libsqlcipher-dev libopenal-dev libqrencode-dev libexif-dev \
    libxss-dev libgtk-3-dev wget file
  ok "apt dependencies installed"
}

install_deps_dnf() {
  say "Installing build dependencies via dnf (will use sudo)"
  sudo dnf install -y \
    @development-tools cmake ninja-build pkgconf-pkg-config git \
    qt6-qtbase-devel qt6-qtsvg-devel qt6-qttools-devel \
    libsodium-devel opus-devel libvpx-devel ffmpeg-devel \
    sqlcipher-devel openal-soft-devel qrencode-devel libexif-devel
  ok "dnf dependencies installed"
}

install_deps_pacman() {
  say "Installing build dependencies via pacman (will use sudo)"
  sudo pacman -S --noconfirm --needed \
    base-devel cmake ninja git pkgconf \
    qt6-base qt6-svg qt6-tools \
    libsodium opus libvpx ffmpeg sqlcipher openal qrencode libexif
  ok "pacman dependencies installed"
}

install_deps_zypper() {
  say "Installing build dependencies via zypper (will use sudo)"
  sudo zypper install -y -t pattern devel_basis
  sudo zypper install -y \
    cmake ninja pkgconf git \
    qt6-base-devel qt6-svg-devel qt6-tools-devel \
    libsodium-devel libopus-devel libvpx-devel \
    ffmpeg-devel sqlcipher-devel openal-soft-devel libqrencode-devel libexif-devel
  ok "zypper dependencies installed"
}

install_deps() {
  if [ "$ZTOX_NO_DEPS" = "1" ]; then
    warn "ZTOX_NO_DEPS=1 set — skipping dependency installation"
    return
  fi
  case "$PKG_MGR" in
    brew) install_deps_macos ;;
    apt) install_deps_apt ;;
    dnf) install_deps_dnf ;;
    pacman) install_deps_pacman ;;
    zypper) install_deps_zypper ;;
    apk|unknown)
      warn "Auto-install of build deps for $PKG_MGR is not implemented."
      warn "Install manually: cmake ninja qt6-base qt6-svg qt6-tools libsodium opus libvpx ffmpeg sqlcipher openal qrencode libexif."
      warn "Then re-run with ZTOX_NO_DEPS=1."
      die "stopping until dependencies are present"
      ;;
  esac
}

build_toxcore_from_source() {
  say "Building c-toxcore from source (no system package available)"
  local src
  src="$(mktemp -d)/c-toxcore"
  git clone --depth=1 --recurse-submodules https://github.com/TokTok/c-toxcore.git "$src"
  cmake -S "$src" -B "$src/_build" -G Ninja \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_INSTALL_PREFIX="$ZTOX_PREFIX" \
        -DBOOTSTRAP_DAEMON=OFF \
        -DAUTOTEST=OFF
  cmake --build "$src/_build" --parallel
  if [ -w "$ZTOX_PREFIX" ]; then
    cmake --install "$src/_build"
  else
    sudo cmake --install "$src/_build"
  fi
  ok "c-toxcore installed to $ZTOX_PREFIX"
}

ensure_toxcore() {
  if [ "$ZTOX_NO_TOXCORE" = "1" ]; then return; fi
  if pkg-config --exists toxcore 2>/dev/null; then
    ok "toxcore already present ($(pkg-config --modversion toxcore))"
    return
  fi
  # macOS brew install was already done in install_deps_macos
  if [ "$PLATFORM" = "macos" ]; then return; fi
  build_toxcore_from_source
}

clone_or_use_source() {
  if [ -n "${ZTOX_REPO:-}" ]; then
    SRC_DIR="$ZTOX_REPO"
    say "Using local checkout at $SRC_DIR"
    [ -d "$SRC_DIR/desktop" ] || die "$SRC_DIR does not look like a ztox checkout (no desktop/ subdir)"
    return
  fi
  SRC_DIR="$(mktemp -d)/ztox"
  say "Cloning $ZTOX_REPO_URL @ $ZTOX_REF"
  git clone --depth=1 --branch "$ZTOX_REF" "$ZTOX_REPO_URL" "$SRC_DIR"
}

build_ztox() {
  local build_dir
  build_dir="${ZTOX_BUILD_DIR:-$(mktemp -d)/ztox-build}"
  say "Building ztox in $build_dir"
  local cmake_prefix=""
  if [ "$PLATFORM" = "macos" ]; then
    cmake_prefix="-DCMAKE_PREFIX_PATH=$(brew --prefix qt@6)"
  fi
  cmake -S "$SRC_DIR/desktop" -B "$build_dir" -G Ninja \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_INSTALL_PREFIX="$ZTOX_PREFIX" \
        $cmake_prefix
  cmake --build "$build_dir" --parallel
  BUILD_DIR="$build_dir"
}

install_macos() {
  local app="$BUILD_DIR/ztox.app"
  [ -d "$app" ] || die "build did not produce ztox.app at $app"
  local dest="$ZTOX_PREFIX/Applications/ztox.app"
  mkdir -p "$(dirname "$dest")"
  rm -rf "$dest"
  cp -R "$app" "$dest"
  mkdir -p "$ZTOX_PREFIX/bin"
  ln -sf "$dest/Contents/MacOS/ztox" "$ZTOX_PREFIX/bin/ztox"
  ok "ztox installed to $dest"
  ok "Launcher symlink: $ZTOX_PREFIX/bin/ztox"
  say "Open the app: open $dest"
}

install_linux() {
  say "Installing ztox to $ZTOX_PREFIX"
  if [ -w "$ZTOX_PREFIX" ]; then
    cmake --install "$BUILD_DIR"
  else
    sudo cmake --install "$BUILD_DIR"
  fi
  ok "ztox installed. Launch with: $ZTOX_PREFIX/bin/ztox"
}

main() {
  need uname
  need git
  need cmake
  detect_platform

  printf "${c_bold}ztox installer${c_reset} — platform=%s pkg=%s prefix=%s ref=%s\n" \
    "$PLATFORM" "$PKG_MGR" "$ZTOX_PREFIX" "$ZTOX_REF"
  warn "This builds ztox from source. Expect 15-40 minutes on first run."
  warn "ztox does NOT hide your IP from peers by default. If you want that,"
  warn "set a SOCKS5 proxy (e.g. Tor on 127.0.0.1:9050) in Settings → Advanced."
  echo

  install_deps
  ensure_toxcore
  clone_or_use_source
  build_ztox

  case "$PLATFORM" in
    macos) install_macos ;;
    linux) install_linux ;;
  esac

  ok "Done."
}

main "$@"
