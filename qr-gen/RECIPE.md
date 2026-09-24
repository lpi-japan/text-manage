# 標準教科書 QR PNG 生成レシピ

本ディレクトリの Docker + `qrencode` 固定パラメータで PNG を生成する。  
**URL と出力パスは原稿の Markdown 画像行**（`![https://…](image/…/QR….png)`）から取る。スクリプト側に台帳は持たない。

## レシピ v1

| 項目 | 値 |
|------|-----|
| ツール | [qrencode](https://fukuchi.org/works/qrencode/) 4.1.1（Debian bookworm パッケージ） |
| モジュールサイズ | `-s 10` |
| quiet zone | `-m 4`（モジュール単位） |
| 誤り訂正 | `-l M` |
| 形式 | `-t PNG` |
| 出力ピクセル | URL 長・QR 版に依存（`s × (モジュール数 + 2×m)`） |

Markdown 側は `{width=25%}`。PDF 上の見かけサイズは LaTeX レイアウトが決める。

## 手順

```bash
cd text-manage/qr-gen
docker build -t lpi-textbook-qr:v1 .
docker run --rm -v "$(cd .. && pwd):/work" -w /work lpi-textbook-qr:v1 \
  'https://linuc.org/measures/' admin-text/image/Ch00/QR_measures.png
```

第 1 引数: 画像の alt テキスト（行先 URL）。第 2 引数: `text-manage/` 直下からの相対パス。

複数リポジトリで同じ URL の PNG を揃えるときは、同じコマンドで 1 回生成し、ファイルをコピーする。

リポジトリ間の同期方針は [SYNC_GUIDE.md](../SYNC_GUIDE.md) を参照。
