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

RUN git clone https://chromium.googlesource.com/chromium/tools/depot_tools.git /opt/depot_tools
ENV PATH="/opt/depot_tools:${PATH}"

WORKDIR /app/v8
RUN gclient config --unmanaged . \
 && gclient sync -D --no-history --force --jobs=8

RUN ./tools/dev/v8gen.py x64.release
RUN ninja -C ${V8_OUT} -j ${THREADS} d8

WORKDIR /tools
RUN curl -L -o codeql-linux64.zip https://github.com/github/codeql-cli-binaries/releases/download/v${CODEQL_VERSION}/codeql-linux64.zip \
 && unzip codeql-linux64.zip \
 && rm codeql-linux64.zip
ENV PATH="/tools/codeql:${PATH}"

WORKDIR /app/v8
RUN codeql database create ${CODEQL_DB_DIR} \
      --language=cpp \
      --source-root=/app/v8 \
      --command="ninja -C ${V8_OUT} -j ${THREADS} d8" \
      --threads=${THREADS} --ram=8192 \
  && codeql database check ${CODEQL_DB_DIR}

WORKDIR /out
RUN tar --use-compress-program=zstd -cvf v8-src-db.tar.zst -C /app/v8 v8-src-db
