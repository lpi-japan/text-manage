# 標準教科書 QR PNG 生成レシピ

**正規ルール（2026-09 以降）**は本ディレクトリの Docker + `qrencode` 固定パラメータである。  
旧来の手作業 PNG・370px 固定・RGBA 指定・`npx qrcode` 手順は廃止した。

配布中 PDF/EPUB はリリース時点のまま。QR 画像の更新は原稿・版更新と一緒にコミットする（ランニングチェンジ）。

## レシピ v1

| 項目 | 値 |
|------|-----|
| ツール | [qrencode](https://fukuchi.org/works/qrencode/) 4.1.1（Debian bookworm パッケージ） |
| モジュールサイズ | `-s 10` |
| quiet zone | `-m 4`（モジュール単位） |
| 誤り訂正 | `-l M` |
| 形式 | `-t PNG` |
| 出力ピクセル | **URL 長に依存**（固定 px 規定なし） |

Markdown 側は従来どおり `{width=25%}`。PDF 上の見かけサイズは LaTeX レイアウトが決める。

## 再生成

```bash
cd text-manage/qr-gen
./regenerate-all.sh
```

個別:

```bash
docker build -t lpi-textbook-qr:v1 .
docker run --rm -v "$(cd .. && pwd):/work" lpi-textbook-qr:v1 \
  'https://linuc.org/measures/' admin-text/image/Ch00/QR_measures.png
```

## 同期

同一 URL の PNG は **バイト同一**になるよう `regenerate-all.sh` で一括生成する。  
共通 QR（問い合わせ・measures・textbook 等）の更新手順は [SYNC_GUIDE.md](../SYNC_GUIDE.md) を参照。
