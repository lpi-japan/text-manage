#!/usr/bin/env bash
# テキストリポジトリの Docker ビルドと PDF/EPUB 生成を確認する（build/*.sh 新系統）。
#
# 使用方法:
#   ./build-check.sh <リポジトリ名> [--build-only|--pdf-only|--epub-only]
#   ./build-check.sh --all [--build-only|--pdf-only|--epub-only]
#
# 出力先: ./tmp/results/<リポジトリ名>/

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_NAME="${1:-}"
MODE="${2:-full}"
RESULTS_DIR="$SCRIPT_DIR/tmp/results"

usage() {
  echo "Usage: $0 <repository> [--build-only|--pdf-only|--epub-only]"
  echo "       $0 --all [--build-only|--pdf-only|--epub-only]"
  echo ""
  echo "Repositories:"
  echo "  admin-text, linux-text, network-text, ossdb-text"
  echo "  server-text, server-text-ubuntu, server-text-en"
  echo "  ossdb-text-en"
  echo ""
  echo "Output: $RESULTS_DIR/<repository>/ (tmp/*text_* 成果物をコピー)"
  exit 1
}

is_valid_repo() {
  case "$1" in
    admin-text|linux-text|network-text|ossdb-text|ossdb-text-en|server-text|server-text-ubuntu|server-text-en)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

actual_repo_dir_for() {
  case "$1" in
    server-text|server-text-ubuntu|server-text-en) echo "server-text" ;;
    ossdb-text-en) echo "ossdb-text" ;;
    *) echo "$1" ;;
  esac
}

image_tag_for() {
  echo "$(actual_repo_dir_for "$1")-test"
}

docker_build() {
  local repo="$1"
  local repo_actual
  repo_actual="$(actual_repo_dir_for "$repo")"
  local repo_dir="$SCRIPT_DIR/$repo_actual"
  local tag
  tag="$(image_tag_for "$repo")"

  echo "========================================="
  echo "Building Docker image: $tag (context build/)"
  echo "========================================="

  docker build -t "$tag" -f "$repo_dir/build/Dockerfile" "$repo_dir/build"
  echo "✓ Docker build successful: $tag"
}

run_pdf_epub() {
  local repo="$1"
  local do_pdf="$2"
  local do_epub="$3"
  local repo_actual
  repo_actual="$(actual_repo_dir_for "$repo")"
  local repo_dir="$SCRIPT_DIR/$repo_actual"
  local tag
  tag="$(image_tag_for "$repo")"
  local output_dir="$RESULTS_DIR/$repo"

  mkdir -p "$output_dir"
  export TEXT_IMAGE="$tag"

  cd "$repo_dir"
  chmod +x build/build-pdf.sh build/build-epub.sh build/with-build-image.sh 2>/dev/null || true

  case "$repo" in
    admin-text|linux-text|network-text|ossdb-text)
      if [[ "$do_pdf" == "1" ]]; then
        ./build/build-pdf.sh all
      fi
      if [[ "$do_epub" == "1" ]]; then
        ./build/build-epub.sh
      fi
      ;;
    ossdb-text-en)
      if [[ "$do_pdf" == "1" ]]; then
        ./build/build-pdf.sh all en
      fi
      if [[ "$do_epub" == "1" ]]; then
        ./build/build-epub.sh en
      fi
      ;;
    server-text)
      if [[ "$do_pdf" == "1" ]]; then
        ./build/build-pdf.sh all main
      fi
      if [[ "$do_epub" == "1" ]]; then
        ./build/build-epub.sh main
      fi
      ;;
    server-text-ubuntu)
      if [[ "$do_pdf" == "1" ]]; then
        ./build/build-pdf.sh all ubuntu
      fi
      if [[ "$do_epub" == "1" ]]; then
        ./build/build-epub.sh ubuntu
      fi
      ;;
    server-text-en)
      if [[ "$do_pdf" == "1" ]]; then
        ./build/build-pdf.sh all main-en
      fi
      if [[ "$do_epub" == "1" ]]; then
        ./build/build-epub.sh main-en
      fi
      ;;
  esac

  shopt -s nullglob
  for f in tmp/*; do
    case "$f" in
      tmp/.*) continue ;;
      tmp/*text_*|tmp/*text_*.*)
        cp -a "$f" "$output_dir/"
        ;;
    esac
  done
  shopt -u nullglob

  echo "✓ Artifacts copied to $output_dir/"
  ls -lh "$output_dir" 2>/dev/null || true
}

process_repo() {
  local repo="$1"
  local mode="$2"

  case "$mode" in
    --build-only) docker_build "$repo" ;;
    --pdf-only)   docker_build "$repo"; run_pdf_epub "$repo" 1 0 ;;
    --epub-only)  docker_build "$repo"; run_pdf_epub "$repo" 0 1 ;;
    *)
      docker_build "$repo"
      run_pdf_epub "$repo" 1 1
      ;;
  esac
}

if [[ -z "$REPO_NAME" ]]; then
  usage
fi

if [[ "$REPO_NAME" == "--all" ]]; then
  for repo in admin-text linux-text network-text ossdb-text ossdb-text-en server-text server-text-ubuntu server-text-en; do
    process_repo "$repo" "$MODE"
  done
  exit 0
fi

if ! is_valid_repo "$REPO_NAME"; then
  echo "Error: Unknown repository '$REPO_NAME'" >&2
  usage
fi

process_repo "$REPO_NAME" "$MODE"

echo ""
echo "========================================="
echo "All checks passed for $REPO_NAME"
echo "========================================="
