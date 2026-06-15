#!/usr/bin/env bash
# Build c-toxcore as a multi-architecture xcframework for iOS.
# Targets: arm64 device, arm64 simulator, x86_64 simulator.
#
# Requires: Xcode (for xcrun, xcodebuild, lipo) and cmake + autoconf via brew.
# Output:   ios/Frameworks/CToxcore.xcframework
#
# Run:  bash ios/scripts/build-toxcore-xcframework.sh
#       (or from ios/:  ./scripts/build-toxcore-xcframework.sh)

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
WORK="$ROOT/_xcframework-build"
OUT="$ROOT/Frameworks"
TOXCORE_REPO="https://github.com/TokTok/c-toxcore.git"
TOXCORE_REF="${TOXCORE_REF:-master}"

c_reset='\033[0m'; c_bold='\033[1m'; c_blue='\033[34m'; c_green='\033[32m'; c_red='\033[31m'
say()  { printf "${c_bold}${c_blue}==>${c_reset} %s\n" "$*"; }
ok()   { printf "${c_bold}${c_green}✓${c_reset}  %s\n" "$*"; }
die()  { printf "${c_bold}${c_red}✗${c_reset}  %s\n" "$*" >&2; exit 1; }

command -v xcrun     >/dev/null || die "Xcode not installed (xcrun missing). Install Xcode from the App Store."
command -v xcodebuild >/dev/null || die "xcodebuild missing."
command -v cmake     >/dev/null || die "cmake missing — brew install cmake."

rm -rf "$WORK" && mkdir -p "$WORK" "$OUT"

say "Cloning c-toxcore@${TOXCORE_REF}"
git clone --depth=1 --recurse-submodules --branch "$TOXCORE_REF" "$TOXCORE_REPO" "$WORK/src"

# c-toxcore deps that are pure C: libsodium, opus, libvpx. We build each
# from source against the iOS SDKs. For the scaffold we only need toxcore
# itself; audio/video (toxav) is a follow-up.

build_arch() {
  local sdk=$1 arch=$2 platform=$3 outdir=$4
  say "Building toxcore for $platform ($sdk / $arch)"
  local sdk_path
  sdk_path=$(xcrun --sdk "$sdk" --show-sdk-path)
  cmake -S "$WORK/src" -B "$WORK/build-$platform-$arch" \
    -DCMAKE_SYSTEM_NAME=iOS \
    -DCMAKE_OSX_SYSROOT="$sdk_path" \
    -DCMAKE_OSX_ARCHITECTURES="$arch" \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_SHARED_LIBS=OFF \
    -DBOOTSTRAP_DAEMON=OFF \
    -DAUTOTEST=OFF \
    -DCMAKE_C_COMPILER=$(xcrun --sdk "$sdk" --find clang) \
    -DCMAKE_INSTALL_PREFIX="$outdir"
  cmake --build "$WORK/build-$platform-$arch" --parallel
  cmake --install "$WORK/build-$platform-$arch"
}

build_arch iphoneos        arm64  device-arm64    "$WORK/install/device-arm64"
build_arch iphonesimulator arm64  sim-arm64       "$WORK/install/sim-arm64"
build_arch iphonesimulator x86_64 sim-x86_64      "$WORK/install/sim-x86_64"

# Lipo the two simulator slices into one fat archive.
say "Combining simulator slices"
mkdir -p "$WORK/install/sim-fat/lib"
lipo -create \
  "$WORK/install/sim-arm64/lib/libtoxcore.a" \
  "$WORK/install/sim-x86_64/lib/libtoxcore.a" \
  -output "$WORK/install/sim-fat/lib/libtoxcore.a"
cp -R "$WORK/install/sim-arm64/include" "$WORK/install/sim-fat/include"

say "Assembling CToxcore.xcframework"
rm -rf "$OUT/CToxcore.xcframework"
xcodebuild -create-xcframework \
  -library "$WORK/install/device-arm64/lib/libtoxcore.a" \
    -headers "$WORK/install/device-arm64/include" \
  -library "$WORK/install/sim-fat/lib/libtoxcore.a" \
    -headers "$WORK/install/sim-fat/include" \
  -output "$OUT/CToxcore.xcframework"

ok "Wrote $OUT/CToxcore.xcframework"
say "Next: edit ios/project.yml to uncomment the FRAMEWORK_SEARCH_PATHS / dependency lines, run xcodegen, and rebuild."
