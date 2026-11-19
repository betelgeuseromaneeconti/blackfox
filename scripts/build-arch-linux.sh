#!/usr/bin/env bash
# Builds BLACKFOX for Arch Linux (x86_64) into RELEASE/ARCH-LINUX/:
# - RELEASE/ARCH-LINUX/x86_64/Portable/ (portable bundle)
# - RELEASE/ARCH-LINUX/x86_64/BLACKFOX-1.0.3-1-x86_64.pkg.tar.zst (when makepkg is available)
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
VERSION="$(grep -E '^version:' "$ROOT/app/pubspec.yaml" | sed -E 's/^version:\s*([0-9]+\.[0-9]+\.[0-9]+).*/\1/')"

command -v flutter >/dev/null 2>&1 || { echo "Error: flutter is not installed." >&2; exit 1; }
command -v go >/dev/null 2>&1 || { echo "Error: go is not installed." >&2; exit 1; }

OUT_DIR="$ROOT/RELEASE/ARCH-LINUX/x86_64"
PORTABLE_DIR="$OUT_DIR/Portable"
mkdir -p "$PORTABLE_DIR/core"

pushd "$ROOT/app" >/dev/null
flutter pub get --offline || flutter pub get
flutter build linux --release --no-pub --dart-define=APP_VERSION="$VERSION"
cp -r build/linux/x64/release/bundle/* "$PORTABLE_DIR/"
popd >/dev/null

pushd "$ROOT/core" >/dev/null
LDFLAGS="-s -w -X github.com/shakur4min/blackfox/core/internal/version.Current=$VERSION"
go build -trimpath -ldflags "$LDFLAGS" -o "$PORTABLE_DIR/core/blackfox-vpn-core" ./cmd/blackfox-core
go build -trimpath -ldflags "$LDFLAGS" -o "$PORTABLE_DIR/core/blackfox-vpn-tun" ./cmd/blackfox-tun
popd >/dev/null

if command -v makepkg >/dev/null 2>&1; then
  pushd "$ROOT/RELEASE/ARCH-LINUX/PKGBUILD" >/dev/null
  makepkg -sf --noconfirm
  mv -f ./*.pkg.tar.zst "$OUT_DIR/"
  popd >/dev/null
fi

echo "Built Arch Linux artifacts in $OUT_DIR"
