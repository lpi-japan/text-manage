# テキストリポジトリ管理ガイド

標準教科書リポジトリ（admin-text, linux-text, network-text, ossdb-text, server-text）の管理ガイドです。

管理作業は以下の2つに大別されます：

1. **リポジトリ間同期** - リポジトリ間で共通設定を揃える
2. **Pandoc upstream追従** - Pandoc本体の更新にカスタムテンプレートを追随させる

---

# Part 1: リポジトリ間同期

## 同期対象ファイル

以下のファイルはリポジトリ間で**ロジックを統一**し、リポジトリ固有の値のみ異なるようにします。

### `.github/workflows/build-container.yaml`
- **目的**: PandocコンテナイメージのビルドとGitHub Container Registryへのpush
- **統一**: ワークフローの構造、使用するactions
- **固有**: なし（リポジトリ名は自動取得）

### `.github/workflows/pandoc.yaml`
- **目的**: PDF/EPUB生成ワークフロー
- **統一**: ビルドコマンドの形式、出力オプション
- **固有**: コンテナイメージ名、表紙画像パス、テンプレートパス

### `Dockerfile`
- **目的**: Pandoc実行環境のコンテナイメージ定義
- **統一**: ベースイメージ、共通パッケージ、フォント設定
- **固有**: リポジトリ特有の追加パッケージ（例: ossdb-textのinkscape）
- **配置**: admin-text / network-text は `build/Dockerfile`。他はリポジトリ直下

### `template.tex`
- **目的**: PDF生成用LaTeXテンプレート
- **統一**: LaTeXマクロ定義、パッケージ設定、共通メタ情報（Copyright等）
- **固有**: 表紙画像、書籍タイトル
- **配置**: admin-text / network-text は `build/template.tex`。他はリポジトリ直下（server-text は共有ファイルとして直下）

### `Chapter00.md`
- **目的**: 前書き・目次前ページ
- **統一**: フォーマット規約、共通の案内文（問い合わせ先等）
- **固有**: 章構成説明、執筆者情報、認定試験紹介

## 同期対象外

- `config-pdf.yaml`, `config-epub.yaml`, `crossref.yaml` - リポジトリ固有設定
- `Chapter01.md` 以降 - 本文

---

## server-text のデュアルバリアント構造

server-textは他のリポジトリと異なり、`main/`（AlmaLinux版）と`ubuntu/`（Ubuntu版）の2つのバリアントを持つ。

### ディレクトリ構成

```
server-text/
├── main/           # AlmaLinux版
│   ├── Chapter*.md
│   ├── config-pdf.yaml
│   ├── config-epub.yaml
│   └── image/
├── ubuntu/         # Ubuntu版
│   ├── Chapter*.md
│   ├── config-pdf.yaml
│   ├── config-epub.yaml
│   └── image/
├── template.tex    # 共通
├── crossref.yaml   # 共通
└── epub.css        # 共通
```

### バリアント間の同期

両バリアントで**共通に更新すべき箇所**:
- `Chapter00.md` の連絡先セクション（問い合わせURL、QRコード）
- `image/Ch0/QR_toiawase.png` などの共通画像

---

## 前書き QR コード PNG（正規ルール）

**2026-09 以降、QR 画像は [qr-gen/](qr-gen/) の Docker レシピ v1 で生成したものだけを正とする。**  
旧手順（手作業・370px 固定・`npx qrcode` 等）で作った PNG は置き換え済みとみなす。

- レシピ・パラメータ: [qr-gen/RECIPE.md](qr-gen/RECIPE.md)
- 一括再生成: `cd qr-gen && ./regenerate-all.sh`
- 出力ピクセル数は URL 長に依存（固定 px 規定なし）。Markdown は `{width=25%}` のまま。
- 同一 URL のファイルは **バイト同一**になるよう `regenerate-all.sh` で配布する（例: `QR_toiawase.png` を全リポジトリで同期）。
- 配布中 PDF/EPUB は版リリースまで変わらない。PNG 更新は原稿更新と一緒に main へ入れ、次回ビルドで反映する。

**共通 QR（URL が同じもの）**

| ファイル名 | URL（Chapter00 の alt テキスト） |
|------------|----------------------------------|
| `QR_toiawase.png` | `https://lpij.tayori.com/f/textbookinfo/` |
| `QR_measures.png` | `https://linuc.org/measures/` |
| `QR_textbook.png` | `https://linuc.org/measures/textbook/` |
| `QRaboutLinuC.png` | `https://linuc.org/about/01.html` |

**教科書別**（`QRadmin.png` / `QRlinux.png` / `QRnetwork.png` / `QRserver.png`）は各リポジトリの `linuc.org/textbooks/...` URL に対応。  
`linux-text` の `image/Ch12/QRuserdir.png` のみ本文 QR（`regenerate-all.sh` に含む）。

**バリアント固有の箇所**（同期不要）:
- ディストリビューション名の記載
- インストール手順・コマンド例
- 執筆者（contributors）情報

### ビルド確認

```bash
./build-check.sh server-text         # main（AlmaLinux）版
./build-check.sh server-text-ubuntu  # ubuntu版
```

---

## network-text の現状

原稿と `config-*.yaml` はリポジトリ直下（linux-text / admin-text と同じ単一バリアント）。ビルド一式は admin-text と同じく `build/`。`main/` `ubuntu/` `main-en/` は持たない。バリアントを足すときは `pandoc.yaml` の `working-directory` を切り替える。

---

## カバー画像管理

### ファイル構成

各リポジトリの `image/Cover/` ディレクトリに以下のファイルを配置：

| ファイル | 用途 | 命名規則 |
|----------|------|----------|
| **電子版PNG** | PDF/EPUB表紙 | `電子版表紙_300dpi_2480x3508.png` |
| **印刷用AI** | 入稿データ | `印刷用：<書籍名><バージョン>_<日付>.ai` |

### 電子版PNG仕様

| 項目 | 値 |
|------|-----|
| サイズ | 2480 x 3508 px（A4相当） |
| 形式 | PNG (8-bit RGB) |
| ファイル名 | **固定**: `電子版表紙_300dpi_2480x3508.png` |

ファイル名に解像度とサイズを含めることで、仕様が一目で分かるようにする。
DPIメタデータはPNG内に埋め込まなくてもよい（印刷時はAIファイルから出力するため）。

### 参照箇所

カバー画像は以下の2箇所で参照される：

1. **template.tex** (PDF用)
   ```latex
   \ThisCenterWallPaper{1}{image/Cover/電子版表紙_300dpi_2480x3508.png}
   ```
   （admin-text / network-text ではこの定義は `build/template.tex`）

2. **pandoc.yaml** (EPUB用)
   ```yaml
   --epub-cover-image=image/Cover/電子版表紙_300dpi_2480x3508.png
   ```

---

## 同期作業手順

### 1. 差分確認

```bash
# 例: Dockerfile比較
diff admin-text/build/Dockerfile linux-text/Dockerfile
diff admin-text/build/Dockerfile network-text/build/Dockerfile
diff admin-text/build/Dockerfile ossdb-text/Dockerfile
diff admin-text/build/Dockerfile server-text/Dockerfile
```

### 2. コミット履歴確認

```bash
for repo in admin-text linux-text network-text ossdb-text server-text; do
  echo "=== $repo ===" && git -C $repo log --oneline -10 -- .github/workflows/
done
```

### 3. 修正適用

修正は**内容ごとにコミット**し、各リポジトリに同じコミットメッセージで適用。

### 4. ビルド確認

```bash
./build-check.sh linux-text > ./tmp/build.log 2>&1
tail -30 ./tmp/build.log
```

出力先: `./tmp/results/<リポジトリ名>/guide.pdf`
クリーンアップ: `rm -rf ./tmp/results`

---

# Part 2: Pandoc upstream追従

カスタムテンプレート（`template.tex`）は、Pandoc本体の更新に追随が必要です。

## 確認対象

- **GitHub**: <https://github.com/jgm/pandoc/commits/main/data/templates/default.latex>
- **確認頻度**: Pandocイメージ更新時（必須）、四半期ごと（推奨）、エラー発生時（即座）

## 確認方法

### GitHub Web UIで確認

上記URLにアクセスし、最終更新日と前回確認日を比較。

### gitコマンドで確認

```bash
# クローン（初回のみ）
git clone https://github.com/jgm/pandoc.git ./tmp/pandoc-upstream

# 更新取得と履歴確認
cd ./tmp/pandoc-upstream && git pull
git log --oneline -30 -- data/templates/default.latex
```

### GitHub APIで監視

```bash
curl -s "https://api.github.com/repos/jgm/pandoc/commits?path=data/templates/default.latex&per_page=5" \
  | jq -r '.[] | "\(.commit.author.date) \(.sha[0:7]) \(.commit.message | split("\n")[0])"'
```

## 反映判断

| 反映 | 種類 |
|------|------|
| **必須** | 新しいLaTeXマクロ追加、パッケージ依存変更、構文エラー修正 |
| **検討** | 新しいテンプレート変数、フォーマット改善 |
| **不要** | コメントのみ、カスタマイズ済み部分の変更 |

## 差分適用

```bash
# 最新テンプレートを取得して比較
docker run --rm pandoc/extra:edge-ubuntu pandoc -D latex > ./tmp/default-latest.tex
diff -u ./tmp/default-latest.tex admin-text/build/template.tex | less

# 必要部分を手動でコピー（自動適用は危険）
```

## 過去の対応例

- **2024-06-24**: `\pandocbounded`マクロ追加 (PR #9666) - 全template.texに定義追加
- **2024年以前**: `\tightlist`マクロ - 既に反映済み


