# text-manage

LPI-Japan テキストリポジトリの統合管理ワークスペースです。

## 目的

標準教科書リポジトリ（admin-text, linux-text, network-text, ossdb-text, server-text）を同一ディレクトリに配置し、AI Agent（GitHub Copilot等）を活用して以下の管理作業をシンプルに行います：

- **リポジトリ間の同期**: ワークフロー、Dockerfile、テンプレートの統一
- **一括確認・修正**: 複数リポジトリへの横断的な変更適用
- **ビルド検証**: ローカルでのPDF/EPUB生成確認

AI Agentがワークスペース全体を参照できるため、「全リポジトリのDockerfileを比較して」「template.texに同じ修正を適用して」といった指示で効率的に作業できます。

## セットアップ

```bash
# このリポジトリをclone
git clone https://github.com/lpi-japan/text-manage.git
cd text-manage

# テキストリポジトリをclone
git clone https://github.com/lpi-japan/admin-text.git
git clone https://github.com/lpi-japan/linux-text.git
git clone https://github.com/lpi-japan/network-text.git
git clone https://github.com/lpi-japan/ossdb-text.git
git clone https://github.com/lpi-japan/server-text.git
```

各教科書は submodule ではなく、配下に clone した独立リポジトリとして置く。text-manage 本体の git には出さない（`.gitignore`）。VS Code / ripgrep は `.gitignore` も読むため、同じパスを `.ignore` で `!` して検索・参照対象に戻す。教科書を足す・外すときは両方を揃える。

## ファイル構成

```
text-manage/
├── README.md           # このファイル
├── SYNC_GUIDE.md       # 同期作業・Pandoc追従ガイド
├── build-check.sh      # ローカルビルド確認スクリプト
├── .gitignore
├── tmp/                # ビルド成果物・ログ（gitignore）
├── admin-text/         # 各テキストリポジトリ（個別git管理）
├── linux-text/
├── network-text/
├── ossdb-text/
└── server-text/
```

## 使い方

### ビルド確認

```bash
./build-check.sh linux-text    # PDF生成確認
./build-check.sh --all         # 全リポジトリ確認
```

出力: `./tmp/results/<リポジトリ名>/`（各教科書の `tmp/*text_*` 成果物をコピー）

### 詳細ガイド

同期作業やPandoc upstream追従については [SYNC_GUIDE.md](SYNC_GUIDE.md) を参照。
