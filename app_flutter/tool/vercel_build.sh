#!/usr/bin/env bash
# Vercel（や素の CI）で Flutter Web をビルドする。
# Flutter SDK が入っていない環境でも動くよう、無ければ取ってくる。
set -euo pipefail
cd "$(dirname "$0")/.."

FLUTTER_VERSION="${FLUTTER_VERSION:-3.44.8}"

if ! command -v flutter >/dev/null 2>&1; then
  echo "Flutter $FLUTTER_VERSION を取得します…"
  mkdir -p "$HOME/flutter-sdk"
  curl -fsSL -o /tmp/flutter.tar.xz \
    "https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_${FLUTTER_VERSION}-stable.tar.xz"
  tar xf /tmp/flutter.tar.xz -C "$HOME/flutter-sdk" --strip-components=1
  export PATH="$HOME/flutter-sdk/bin:$PATH"
  git config --global --add safe.directory "$HOME/flutter-sdk" || true
fi

flutter --version
flutter pub get

# --no-web-resources-cdn が要（既定だと CanvasKit を www.gstatic.com から
# 取りにいき、そこに届かない環境では画面が真っ白になる）
flutter build web --release --no-web-resources-cdn
