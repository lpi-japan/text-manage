# 標準教科書 QR PNG 生成用（レシピ v1）。執筆 PC の OS には依存しない。
FROM debian:bookworm-slim

RUN apt-get update \
    && apt-get install -y --no-install-recommends qrencode=4.1.1-1 \
    && rm -rf /var/lib/apt/lists/* \
    && qrencode -V

COPY gen-qr.sh /usr/local/bin/gen-qr
RUN chmod +x /usr/local/bin/gen-qr

WORKDIR /work
ENTRYPOINT ["/usr/local/bin/gen-qr"]
