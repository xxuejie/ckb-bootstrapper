#!/usr/bin/env bash
set -ex

export ZLIB_SHA256=9a93b2b7dfdac77ceba5a558a580e74667dd6fede4585b91eefb60f03b72df23
export ZLIB_VERSION=1.3.1

export LLVM_SHA256=6898f963c8e938981e6c4a302e83ec5beb4630147c7311183cf61069af16333d
export LLVM_VERSION=20.1.8

export ZSTD_SHA256=eb33e51f49a15e023950cd7825ca74a4a2b43db8354825ac24fc1b7ee09e6fa3
export ZSTD_VERSION=1.5.7

export OPENSSL_SHA256=dfdd77e4ea1b57ff3a6dbde6b0bdc3f31db5ac99e7fdd4eaf9e1fbb6ec2db8ce
export OPENSSL_VERSION=3.0.17

curl -LO https://github.com/madler/zlib/releases/download/v${ZLIB_VERSION}/zlib-${ZLIB_VERSION}.tar.gz
echo "${ZLIB_SHA256} zlib-${ZLIB_VERSION}.tar.gz" | sha256sum -c -
tar xzf zlib-${ZLIB_VERSION}.tar.gz
cd zlib-${ZLIB_VERSION} && \
  prefix=`/distroot/bin/cc -print-sysroot` CC=/distroot/bin/cc AR=/distroot/bin/ar \
    ./configure && make && make install && \
  cd .. && rm -rf zlib-*

curl -LO https://github.com/llvm/llvm-project/releases/download/llvmorg-${LLVM_VERSION}/llvm-project-${LLVM_VERSION}.src.tar.xz
echo "${LLVM_SHA256} llvm-project-${LLVM_VERSION}.src.tar.xz" | sha256sum -c -
tar xJf llvm-project-${LLVM_VERSION}.src.tar.xz
cd llvm-project-${LLVM_VERSION}.src && mkdir build && cd build && \
  CMAKE_PREFIX_PATH=`/distroot/bin/cc -print-sysroot`:$CMAKE_PREFIX_PATH cmake ../llvm \
    -DCMAKE_C_COMPILER=/distroot/bin/cc \
    -DCMAKE_CXX_COMPILER=/distroot/bin/c++ \
    -DDEFAULT_SYSROOT=`/distroot/bin/cc -print-sysroot` \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX=/distroot \
    -DCOMPILER_RT_BUILD_SANITIZERS=OFF \
    -DCOMPILER_RT_BUILD_XRAY=OFF \
    -DCOMPILER_RT_BUILD_MEMPROF=OFF \
    -DCOMPILER_RT_BUILD_CTX_PROFILE=OFF \
    -DLLVM_ENABLE_ZLIB=FORCE_ON \
    -DLLVM_ENABLE_ZSTD=OFF \
    -DLLVM_TARGETS_TO_BUILD=X86 \
    -DLLVM_INCLUDE_BENCHMARKS=OFF \
    -DLLVM_INCLUDE_TESTS=OFF \
    -DLLVM_INCLUDE_EXAMPLES=OFF \
    -DLLVM_ENABLE_PROJECTS="clang;lld;compiler-rt" && \
  make -j$(nproc) && make install && \
  cd ../.. && rm -rf llvm-project-*

curl -LO https://github.com/facebook/zstd/releases/download/v${ZSTD_VERSION}/zstd-${ZSTD_VERSION}.tar.gz
echo "${ZSTD_SHA256} zstd-${ZSTD_VERSION}.tar.gz" | sha256sum -c -
tar xzf zstd-${ZSTD_VERSION}.tar.gz
cd zstd-${ZSTD_VERSION} && \
  CC=/distroot/bin/clang CXX=/distroot/bin/clang++ AR=/distroot/bin/llvm-ar CFLAGS=-fPIC \
    make PREFIX=`/distroot/bin/cc -print-sysroot` install && \
  cd .. && rm -rf zstd-*

curl -LO https://github.com/openssl/openssl/releases/download/openssl-${OPENSSL_VERSION}/openssl-${OPENSSL_VERSION}.tar.gz
echo "${OPENSSL_SHA256} openssl-${OPENSSL_VERSION}.tar.gz" | sha256sum -c -
tar xzf openssl-${OPENSSL_VERSION}.tar.gz
cd openssl-${OPENSSL_VERSION} && \
  SOURCE_DATE_EPOCH=0 \
  CC=/distroot/bin/clang CXX=/distroot/bin/clang++ AR=/distroot/bin/llvm-ar \
    ./Configure --prefix=`/distroot/bin/cc -print-sysroot` && make && make install && \
  cd .. && rm -rf openssl-*
