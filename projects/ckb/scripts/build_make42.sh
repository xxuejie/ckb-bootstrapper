#!/usr/bin/env bash
set -ex

# Build and install make 4.2 from source, this is required by glibc 2.27

BUILD_BASE="${BUILD_BASE:-/tmp/ckb-build}"

export MAKE42_SHA256=e968ce3c57ad39a593a92339e23eb148af6296b9f40aa453a9a9202c99d34436

cd $BUILD_BASE

curl -LO https://ftp.gnu.org/gnu/make/make-4.2.tar.gz
echo "${MAKE42_SHA256} make-4.2.tar.gz" | sha256sum -c -

tar xzf make-4.2.tar.gz
# Older make requires a patch so it can be compiled using a newer gnu toolchain
sed -i 's/#if !defined __alloca \&\& !defined __GNU_LIBRARY__/#if !defined __alloca \&\& defined __GNU_LIBRARY__/g; s/#ifndef __GNU_LIBRARY__/#ifdef __GNU_LIBRARY__/g' 'make-4.2/glob/glob.c'

cd make-4.2 && ./configure --prefix=${BUILD_BASE}/make42 && \
  make -j$(nproc) && make install && \
  cd .. && rm -rf make-4.2*
