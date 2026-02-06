# text-manage

LPI-Japan テキストリポジトリの統合管理ワークスペースです。

## 目的

4つのテキストリポジトリ（admin-text, linux-text, ossdb-text, server-text）を同一ディレクトリに配置し、AI Agent（GitHub Copilot等）を活用して以下の管理作業をシンプルに行います：

- **リポジトリ間の同期**: ワークフロー、Dockerfile、テンプレートの統一
- **一括確認・修正**: 複数リポジトリへの横断的な変更適用
- **ビルド検証**: ローカルでのPDF/EPUB生成確認

AI Agentがワークスペース全体を参照できるため、「全リポジトリのDockerfileを比較して」「template.texに同じ修正を適用して」といった指示で効率的に作業できます。

## セットアップ

```bash
# このリポジトリをclone
git clone https://github.com/lpi-japan/text-manage.git
cd text-manage

# 4つのテキストリポジトリをclone
git clone https://github.com/lpi-japan/admin-text.git
git clone https://github.com/lpi-japan/linux-text.git
git clone https://github.com/lpi-japan/ossdb-text.git
git clone https://github.com/lpi-japan/server-text.git
```

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
├── ossdb-text/
└── server-text/
```

## 使い方

### ビルド確認

```bash
./build-check.sh linux-text    # PDF生成確認
./build-check.sh --all         # 全リポジトリ確認
```

出力: `./tmp/results/<リポジトリ名>/guide.pdf`

### 詳細ガイド

同期作業やPandoc upstream追従については [SYNC_GUIDE.md](SYNC_GUIDE.md) を参照。
