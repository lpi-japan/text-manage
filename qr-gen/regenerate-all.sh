#!/usr/bin/env bash
# 標準4教科書 + server main-en の Chapter00/12 用 QR をレシピ v1 で再生成する。
set -euo pipefail
ROOT=$(cd "$(dirname "$0")/.." && pwd)
IMAGE=lpi-textbook-qr:v1
SCRIPT_DIR=$(dirname "$0")

docker build -t "$IMAGE" "$SCRIPT_DIR"

gen_one() {
  local url=$1 out=$2
  docker run --rm -v "$ROOT:/work" -w /work "$IMAGE" "$url" "$out"
}

# url -> 相対パス（ROOT 基準）を空白区切りで列挙
declare -A DESTS
add() {
  local url=$1
  shift
  for path in "$@"; do
    DESTS[$url]+=" $path"
  done
}

add 'https://lpij.tayori.com/f/textbookinfo/' \
  admin-text/image/Ch00/QR_toiawase.png \
  linux-text/image/Ch00/QR_toiawase.png \
  network-text/image/Ch0/QR_toiawase.png \
  server-text/main/image/Ch0/QR_toiawase.png \
  server-text/ubuntu/image/Ch0/QR_toiawase.png \
  server-text/main-en/image/Ch0/QR_toiawase.png

add 'https://linuc.org/measures/' \
  admin-text/image/Ch00/QR_measures.png \
  linux-text/image/Ch00/QR_measures.png \
  network-text/image/Ch0/QR_measures.png \
  server-text/main/image/Ch0/QR_measures.png \
  server-text/ubuntu/image/Ch0/QR_measures.png

add 'https://linuc.org/measures/textbook/' \
  admin-text/image/Ch00/QR_textbook.png \
  linux-text/image/Ch00/QR_textbook.png \
  network-text/image/Ch0/QR_textbook.png \
  server-text/main/image/Ch0/QR_textbook.png \
  server-text/ubuntu/image/Ch0/QR_textbook.png

add 'https://linuc.org/about/01.html' \
  admin-text/image/Ch00/QRaboutLinuC.png \
  linux-text/image/Ch00/QRaboutLinuC.png \
  network-text/image/Ch0/QRaboutLinuC.png \
  server-text/main/image/Ch0/QRaboutLinuC.png \
  server-text/ubuntu/image/Ch0/QRaboutLinuC.png

add 'https://linuc.org/textbooks/admin/' admin-text/image/Ch00/QRadmin.png
add 'https://linuc.org/textbooks/linux/' linux-text/image/Ch00/QRlinux.png
add 'https://linuc.org/textbooks/network/' network-text/image/Ch0/QRnetwork.png
add 'https://linuc.org/textbooks/server/' \
  server-text/main/image/Ch0/QRserver.png \
  server-text/ubuntu/image/Ch0/QRserver.png

add 'https://linuc.org/study/column/4513/' linux-text/image/Ch12/QRuserdir.png

BUILD=$ROOT/qr-gen/.build
mkdir -p "$BUILD"

for url in "${!DESTS[@]}"; do
  hash=$(printf '%s' "$url" | md5sum | cut -c1-16)
  tmp_rel=qr-gen/.build/$hash.png
  gen_one "$url" "$tmp_rel"
  tmp_png=$ROOT/$tmp_rel
  for rel in ${DESTS[$url]}; do
    mkdir -p "$ROOT/$(dirname "$rel")"
    cp -a "$tmp_png" "$ROOT/$rel"
    echo "wrote $rel ($(file -b "$ROOT/$rel"))"
  done
done

echo "done: recipe v1 (see qr-gen/RECIPE.md)"
