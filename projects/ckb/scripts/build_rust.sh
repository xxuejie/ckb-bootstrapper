#!/usr/bin/env bash
set -ex

BUILD_BASE="${BUILD_BASE:-/tmp/ckb-build}"

export RUST_SHA256="${RUST_SHA256:-d542c397217b5ba5bac7eb274f5ca62d031f61842c3ba4cc5328c709c38ea1e7}"
export RUST_VERSION="${RUST_VERSION:-1.85.0}"
export STAGE="${STAGE:-3}"

export PATH=${BUILD_BASE}/distroot/bin:$PATH
export CC=${BUILD_BASE}/distroot/bin/clang
export CXX=${BUILD_BASE}/distroot/bin/clang++
export AR=${BUILD_BASE}/distroot/bin/llvm-ar
export CARGO_TARGET_X86_64_UNKNOWN_LINUX_GNU_LINKER=${BUILD_BASE}/distroot/bin/clang

cd $BUILD_BASE

curl -LO https://static.rust-lang.org/dist/rustc-${RUST_VERSION}-src.tar.xz
echo "${RUST_SHA256} rustc-${RUST_VERSION}-src.tar.xz" | sha256sum -c -
tar xJf rustc-${RUST_VERSION}-src.tar.xz
cp ${BUILD_BASE}/config.toml ./rustc-${RUST_VERSION}-src/config.toml
cd rustc-${RUST_VERSION}-src && \
  CMAKE_PREFIX_PATH=`${BUILD_BASE}/distroot/bin/cc -print-sysroot`:$CMAKE_PREFIX_PATH \
    OPENSSL_DIR=`${BUILD_BASE}/distroot/bin/cc -print-sysroot` \
    ./x.py build --stage ${STAGE} library cargo && \
  mkdir ${BUILD_BASE}/rustroot && cp -r build/host/stage${STAGE}/* ${BUILD_BASE}/rustroot/ && \
  cp build/host/stage${STAGE}-tools-bin/cargo ${BUILD_BASE}/rustroot/bin/ && \
  cd .. && rm -rf rustc-*
