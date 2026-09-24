#!/bin/sh
# 用法: gen-qr <url> <output.png>
# レシピの正本は RECIPE.md（v1）。
set -eu
if [ "$#" -ne 2 ]; then
  echo "usage: gen-qr <url> <output.png>" >&2
  exit 1
fi
url=$1
out=$2
mkdir -p "$(dirname "$out")"
qrencode -o "$out" -s 10 -m 4 -l M -t PNG "$url"
