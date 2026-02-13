#!/bin/bash
# テキストリポジトリのDockerビルドとPDF/EPUB生成を確認するスクリプト
#
# 使用方法:
#   ./build-check.sh <リポジトリ名> [--build-only|--pdf-only|--epub-only]
#
# 例:
#   ./build-check.sh linux-text               # フルチェック（Docker build + PDF）
#   ./build-check.sh admin-text --build-only  # Dockerビルドのみ
#   ./build-check.sh server-text --pdf-only   # PDF生成のみ（既存イメージ使用）
#
# 出力先: ./tmp/results/<リポジトリ名>/
# クリーンアップ: rm -rf ./tmp/results

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_NAME="${1:-}"
MODE="${2:-full}"
RESULTS_DIR="$SCRIPT_DIR/tmp/results"

# リポジトリ設定 (working_dir, template, repo_dir)
# coverはpandoc.yamlから動的に取得
# bash 3.2互換のため連想配列を使わずcase文で対応

usage() {
    echo "Usage: $0 <repository> [--build-only|--pdf-only|--epub-only]"
    echo ""
    echo "Repositories: admin-text, linux-text, ossdb-text, server-text, server-text-ubuntu"
    echo ""
    echo "Options:"
    echo "  --build-only  Docker build only"
    echo "  --pdf-only    PDF generation only (uses existing image)"
    echo "  --epub-only   EPUB generation only"
    echo "  --all         Run for all repositories"
    echo ""
    echo "Output: $RESULTS_DIR/<repository>/guide.pdf"
    echo "Clean:  rm -rf $RESULTS_DIR"
    exit 1
}

is_valid_repo() {
    local repo="$1"
    case "$repo" in
        admin-text|linux-text|ossdb-text|server-text|server-text-ubuntu)
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

get_config() {
    local repo="$1"
    local key="$2"
    
    case "$repo" in
        admin-text|linux-text|ossdb-text)
            case "$key" in
                working_dir) echo "." ;;
                template) echo "template.tex" ;;
                repo_dir) echo "$repo" ;;
            esac
            ;;
        server-text)
            case "$key" in
                working_dir) echo "main" ;;
                template) echo "../template.tex" ;;
                repo_dir) echo "server-text" ;;
            esac
            ;;
        server-text-ubuntu)
            case "$key" in
                working_dir) echo "ubuntu" ;;
                template) echo "../template.tex" ;;
                repo_dir) echo "server-text" ;;
            esac
            ;;
    esac
}

# pandoc.yamlから--epub-cover-image=の値を抽出
get_cover_from_workflow() {
    local repo_dir="$1"
    grep -oP '(?<=--epub-cover-image=)[^ ]+' "$repo_dir/.github/workflows/pandoc.yaml" | head -1
}

docker_build() {
    local repo="$1"
    local repo_actual=$(get_config "$repo" "repo_dir")
    repo_actual="${repo_actual:-$repo}"
    local repo_dir="$SCRIPT_DIR/$repo_actual"

    echo "========================================="
    echo "Building Docker image for $repo_actual"
    echo "========================================="

    cd "$repo_dir"
    docker build -t "${repo_actual}-test" .

    echo "✓ Docker build successful: ${repo_actual}-test"
}

generate_pdf() {
    local repo="$1"
    local repo_actual=$(get_config "$repo" "repo_dir")
    repo_actual="${repo_actual:-$repo}"
    local repo_dir="$SCRIPT_DIR/$repo_actual"
    local working_dir=$(get_config "$repo" "working_dir")
    local template=$(get_config "$repo" "template")

    working_dir="${working_dir:-.}"
    template="${template:-template.tex}"

    echo "========================================="
    echo "Generating PDF for $repo"
    echo "========================================="

    cd "$repo_dir"

    local output_dir="$RESULTS_DIR/$repo"
    mkdir -p "$output_dir"

    docker run --rm \
        -v "$(pwd):/data" \
        -w "/data/$working_dir" \
        --entrypoint /bin/sh \
        "${repo_actual}-test" \
        -c "
            chapters=\$(ls -1 Chapter*.md | grep -v 'Chapter00.md' | sort -V | tr '\n' ' ' | sed 's/ \$//')
            pandoc Chapter00.md -o preface.tex
            pandoc -d config.yaml --template $template -B preface.tex \${chapters} -o guide.pdf --verbose 2>&1 | grep -v '^  '
        "

    # 生成されたファイルを出力ディレクトリにコピー
    cp "$repo_dir/$working_dir/guide.pdf" "$output_dir/"

    # リポジトリ内の一時ファイルを削除
    rm -f "$repo_dir/$working_dir/preface.tex" "$repo_dir/$working_dir/guide.pdf"

    echo "✓ PDF generated: $output_dir/guide.pdf"
}

generate_epub() {
    local repo="$1"
    local repo_actual=$(get_config "$repo" "repo_dir")
    repo_actual="${repo_actual:-$repo}"
    local repo_dir="$SCRIPT_DIR/$repo_actual"
    local working_dir=$(get_config "$repo" "working_dir")
    local cover=$(get_cover_from_workflow "$repo_dir")

    working_dir="${working_dir:-.}"

    if [[ -z "$cover" ]]; then
        echo "Error: Could not find cover image in $repo_dir/.github/workflows/pandoc.yaml"
        exit 1
    fi

    # working_dirがサブディレクトリの場合、共通ファイルへのパスを調整
    local path_prefix=""
    if [[ "$working_dir" != "." ]]; then
        path_prefix="../"
    fi

    echo "========================================="
    echo "Generating EPUB for $repo"
    echo "========================================="

    cd "$repo_dir"

    local output_dir="$RESULTS_DIR/$repo"
    mkdir -p "$output_dir"

    docker run --rm \
        -v "$(pwd):/data" \
        -w "/data/$working_dir" \
        --entrypoint /bin/sh \
        pandoc/core:3.1.1.0 \
        -c "
            cat \$(ls -1 Chapter*.md | sort -V | tr '\n' ' ' | sed 's/ \$//') | sed 's/^####.*/#& {-}/' > guide.md
            /usr/bin/awk 'BEGIN{go=0;}{ if (go==1){print;} else {if(\$0 ~ /^#/) { go=1;print;}}}' guide.md | \
                pandoc -t epub3 -F pandoc-crossref -o guide.epub -N \
                -M crossrefYaml=${path_prefix}crossref.yaml \
                --metadata-file=${path_prefix}metadata.yaml \
                --epub-cover-image=$cover \
                --css=${path_prefix}epub.css
        "

    cp "$repo_dir/$working_dir/guide.epub" "$output_dir/" 2>/dev/null || true
    rm -f "$repo_dir/$working_dir/guide.md" "$repo_dir/$working_dir/guide.epub"

    echo "✓ EPUB generated: $output_dir/guide.epub"
}

run_all() {
    local mode="$1"
    for repo in admin-text linux-text ossdb-text server-text server-text-ubuntu; do
        case "$mode" in
            --build-only) docker_build "$repo" ;;
            --pdf-only)   generate_pdf "$repo" ;;
            --epub-only)  generate_epub "$repo" ;;
            *)
                docker_build "$repo"
                generate_pdf "$repo"
                generate_epub "$repo"
                ;;
        esac
    done
}

# メイン処理
if [[ -z "$REPO_NAME" ]]; then
    usage
fi

if [[ "$REPO_NAME" == "--all" ]]; then
    run_all "$MODE"
    exit 0
fi

if ! is_valid_repo "$REPO_NAME"; then
    echo "Error: Unknown repository '$REPO_NAME'"
    usage
fi

case "$MODE" in
    --build-only) docker_build "$REPO_NAME" ;;
    --pdf-only)   generate_pdf "$REPO_NAME" ;;
    --epub-only)  generate_epub "$REPO_NAME" ;;
    *)
        docker_build "$REPO_NAME"
        generate_pdf "$REPO_NAME"
        generate_epub "$REPO_NAME"
        ;;
esac

echo ""
echo "========================================="
echo "All checks passed for $REPO_NAME"
echo "========================================="
