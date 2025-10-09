FROM ubuntu:22.04

ARG DEBIAN_FRONTEND=noninteractive
ARG CODEQL_VERSION=2.23.0
ARG THREADS=4
ARG V8_OUT=out.gn/x64.release
ARG CODEQL_DB_DIR=/app/v8/v8-src-db

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential python3 python3-pip pkg-config \
    ninja-build git curl unzip zstd ca-certificates \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY . /app/v8

WORKDIR /app/v8
RUN ./tools/dev/v8gen.py x64.release

WORKDIR /tools
RUN curl -L -o codeql-linux64.zip https://github.com/github/codeql-cli-binaries/releases/download/v${CODEQL_VERSION}/codeql-linux64.zip \
 && unzip codeql-linux64.zip \
 && rm codeql-linux64.zip
ENV PATH="/tools/codeql:${PATH}"

WORKDIR /app/v8
RUN codeql database create ${CODEQL_DB_DIR} \
      --language=cpp \
      --source-root=/app/v8 \
      --command="ninja -C ${V8_OUT} -j ${THREADS}"

WORKDIR /out
RUN tar --use-compress-program=zstd -cvf v8-src-db.tar.zst -C /app/v8 v8-src-db