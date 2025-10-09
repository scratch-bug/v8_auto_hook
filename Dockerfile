FROM ubuntu:22.04

ARG DEBIAN_FRONTEND=noninteractive
ARG CODEQL_VERSION=2.23.0
ARG THREADS=4
ARG V8_OUT=out.gn/x64.release
ARG CODEQL_DB_DIR=/app/v8/v8-src-db

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential python3 python3-pip pkg-config \
    ninja-build git curl unzip zstd ca-certificates \
    lsb-release python-is-python3 file \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY . /app/v8

WORKDIR /tools
RUN git clone https://chromium.googlesource.com/chromium/tools/depot_tools.git
ENV PATH="${PATH}:/tools/depot_tools"

WORKDIR /setup
RUN mkdir -p chromium/src/build

WORKDIR /setup/chromium/src
RUN curl -s https://chromium.googlesource.com/chromium/src/+/main/build/install-build-deps.sh?format=TEXT | base64 -d > build/install-build-deps.sh
RUN chmod u+x build/install-build-deps.sh
RUN curl -s https://chromium.googlesource.com/chromium/src/+/main/build/install-build-deps.py?format=TEXT | base64 -d > build/install-build-deps.py
RUN chmod u+x build/install-build-deps.py

RUN ./build/install-build-deps.sh \
    --no-prompt \
    --no-chromeos-fonts \
    --no-arm \
    --no-syms \
    --no-nacl \
    --no-backwards-compatible

WORKDIR /app/v8
RUN gclient sync

RUN ./tools/dev/v8gen.py x64.release

WORKDIR /tools
RUN curl -L -o codeql-linux64.zip https://github.com/github/codeql-cli-binaries/releases/download/v${CODEQL_VERSION}/codeql-linux64.zip \
 && unzip codeql-linux64.zip \
 && rm codeql-linux64.zip
ENV PATH="/tools/codeql:${PATH}"

WORKDIR /app/v8
RUN codeql database create v8-src-db \
      --language=cpp \
      --source-root=/app/v8 \
      --command="ninja -C ./out.gn/x64.release"

WORKDIR /out
RUN tar --use-compress-program=zstd -cvf v8-src-db.tar.zst -C /app/v8 v8-src-db
