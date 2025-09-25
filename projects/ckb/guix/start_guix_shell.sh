#!/usr/bin/env bash
set -ex

export BUILD_BASE="${BUILD_BASE:-/tmp/ckb-build}"
rm -rf ${BUILD_BASE} && mkdir -p ${BUILD_BASE}

guix time-machine \
  --url=https://codeberg.org/guix/guix.git \
  --commit=53396a22afc04536ddf75d8f82ad2eafa5082725 -- shell \
      -m manifest.scm \
      --container \
      --network \
      --pure \
      --expose=`pwd`/../scripts=/scripts \
      --share=${BUILD_BASE}=/tmp/ckb-build
