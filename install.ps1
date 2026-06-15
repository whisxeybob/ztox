# ztox installer for Windows (PowerShell).
# Usage:
#   irm https://raw.githubusercontent.com/whisxeybob/ztox/main/install.ps1 | iex
# Env knobs (set with $env:NAME = "value" before piping):
#   ZTOX_REPO       — local path to a checkout
#   ZTOX_REPO_URL   — clone URL (default: this repo)
#   ZTOX_REF        — branch/tag/sha (default: main)
#   ZTOX_PREFIX     — install root (default: $env:LOCALAPPDATA\ztox)

$ErrorActionPreference = 'Stop'
$ProgressPreference    = 'SilentlyContinue'

$repoUrl = if ($env:ZTOX_REPO_URL) { $env:ZTOX_REPO_URL } else { 'https://github.com/whisxeybob/ztox.git' }
$ref     = if ($env:ZTOX_REF)      { $env:ZTOX_REF }      else { 'main' }
$prefix  = if ($env:ZTOX_PREFIX)   { $env:ZTOX_PREFIX }   else { Join-Path $env:LOCALAPPDATA 'ztox' }

function Write-Step($msg) { Write-Host "==> $msg" -ForegroundColor Cyan }
function Write-OK($msg)   { Write-Host "[+] $msg" -ForegroundColor Green }
function Write-Warn($msg) { Write-Host "[!] $msg" -ForegroundColor Yellow }
function Die($msg)        { Write-Host "[x] $msg" -ForegroundColor Red; exit 1 }

function Have-Cmd($name) {
  $null -ne (Get-Command $name -ErrorAction SilentlyContinue)
}

function Pick-PkgMgr {
  if (Have-Cmd 'winget') { return 'winget' }
  if (Have-Cmd 'scoop')  { return 'scoop' }
  if (Have-Cmd 'choco')  { return 'choco' }
  return $null
}

function Install-Deps {
  $pkg = Pick-PkgMgr
  if (-not $pkg) {
    Die "No package manager found (winget/scoop/choco). Install one and re-run, or install CMake+Ninja+Qt6+Git+vcpkg manually."
  }
  Write-Step "Installing build dependencies via $pkg"
  switch ($pkg) {
    'winget' {
      winget install --silent --accept-package-agreements --accept-source-agreements --id Kitware.CMake     | Out-Null
      winget install --silent --accept-package-agreements --accept-source-agreements --id Ninja-build.Ninja | Out-Null
      winget install --silent --accept-package-agreements --accept-source-agreements --id Git.Git           | Out-Null
      Write-Warn "Qt6 via winget is unreliable. Recommend: install Qt 6.7+ from https://www.qt.io/download-open-source"
      Write-Warn "Set environment variable Qt6_DIR to the install path before re-running this script if Qt is not auto-detected."
    }
    'scoop' {
      scoop install cmake ninja git | Out-Null
      scoop bucket add extras 2>$null
      Write-Warn "Qt6 via scoop is best-effort. If build fails, install Qt 6.7+ from https://www.qt.io/download-open-source"
    }
    'choco' {
      choco install -y cmake ninja git    | Out-Null
      choco install -y qt6-base-dev       | Out-Null
    }
  }
  Write-OK "Dependencies installed (Qt may need manual setup)"
}

function Ensure-Vcpkg {
  $vcpkgRoot = Join-Path $prefix 'vcpkg'
  if (-not (Test-Path (Join-Path $vcpkgRoot 'vcpkg.exe'))) {
    Write-Step "Cloning vcpkg into $vcpkgRoot"
    New-Item -ItemType Directory -Force -Path $prefix | Out-Null
    git clone --depth 1 https://github.com/microsoft/vcpkg.git $vcpkgRoot
    & (Join-Path $vcpkgRoot 'bootstrap-vcpkg.bat') -disableMetrics
  }
  Write-Step "Installing c-toxcore via vcpkg (this can take ~10 minutes)"
  & (Join-Path $vcpkgRoot 'vcpkg.exe') install libsodium:x64-windows opus:x64-windows libvpx:x64-windows sqlcipher:x64-windows
  Write-Warn "c-toxcore is not in vcpkg's mainline. Will build from source after deps."
  $script:VCPKG_ROOT = $vcpkgRoot
}

function Build-Toxcore {
  $src = Join-Path $env:TEMP "c-toxcore-$(Get-Random)"
  Write-Step "Building c-toxcore from source"
  git clone --depth 1 https://github.com/TokTok/c-toxcore.git $src
  $b = Join-Path $src '_build'
  cmake -S $src -B $b -G Ninja `
    -DCMAKE_BUILD_TYPE=Release `
    -DCMAKE_TOOLCHAIN_FILE="$VCPKG_ROOT\scripts\buildsystems\vcpkg.cmake" `
    -DVCPKG_TARGET_TRIPLET=x64-windows `
    -DCMAKE_INSTALL_PREFIX="$prefix" `
    -DBOOTSTRAP_DAEMON=OFF -DAUTOTEST=OFF
  cmake --build $b --parallel
  cmake --install $b
  Write-OK "c-toxcore installed to $prefix"
}

function Clone-Or-Use-Source {
  if ($env:ZTOX_REPO) {
    $script:SRC_DIR = $env:ZTOX_REPO
    Write-Step "Using local checkout at $SRC_DIR"
    if (-not (Test-Path (Join-Path $SRC_DIR 'desktop'))) {
      Die "$SRC_DIR does not look like a ztox checkout (no desktop/ subdir)"
    }
    return
  }
  $script:SRC_DIR = Join-Path $env:TEMP "ztox-$(Get-Random)"
  Write-Step "Cloning $repoUrl @ $ref"
  git clone --depth 1 --branch $ref $repoUrl $SRC_DIR
}

function Build-Ztox {
  $b = Join-Path $env:TEMP "ztox-build-$(Get-Random)"
  Write-Step "Building ztox in $b"
  $cmakeArgs = @(
    "-S", "$SRC_DIR\desktop",
    "-B", $b,
    "-G", "Ninja",
    "-DCMAKE_BUILD_TYPE=Release",
    "-DCMAKE_TOOLCHAIN_FILE=$VCPKG_ROOT\scripts\buildsystems\vcpkg.cmake",
    "-DVCPKG_TARGET_TRIPLET=x64-windows",
    "-DCMAKE_PREFIX_PATH=$prefix"
  )
  cmake @cmakeArgs
  cmake --build $b --parallel --config Release
  $script:BUILD_DIR = $b
}

function Install-Ztox {
  $exe = Get-ChildItem -Path $BUILD_DIR -Filter 'ztox.exe' -Recurse | Select-Object -First 1
  if (-not $exe) { Die "build did not produce ztox.exe — check log above" }
  $dest = Join-Path $prefix 'bin'
  New-Item -ItemType Directory -Force -Path $dest | Out-Null
  Copy-Item $exe.FullName $dest -Force
  Write-OK "ztox installed to $dest\ztox.exe"
  Write-Step "Add $dest to PATH or pin it to Start Menu for convenience"
}

# --- main --------------------------------------------------------------------

Write-Host "ztox installer (Windows) — prefix=$prefix ref=$ref" -ForegroundColor White
Write-Warn "This builds ztox from source. Expect 30-60 minutes on first run."
Write-Warn "Anonymity-by-default profile assumes Tor is running on 127.0.0.1:9050."
Write-Warn "Without Tor, fresh ztox profiles will not connect — disable in Settings → Advanced → Proxy."
Write-Host ""

if (-not (Have-Cmd 'git')) { Install-Deps } else { Install-Deps }
if (-not (Have-Cmd 'cmake')) { Die "cmake not on PATH after install — open a fresh PowerShell window and re-run." }

Ensure-Vcpkg
Build-Toxcore
Clone-Or-Use-Source
Build-Ztox
Install-Ztox

Write-OK "Done."
