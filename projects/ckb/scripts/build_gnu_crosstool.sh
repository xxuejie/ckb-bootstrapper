#!/usr/bin/env bash
set -ex

BUILD_BASE="${BUILD_BASE:-/tmp/ckb-build}"

export CROSSTOOL_SHA256=0506ab98fa0ad6d263a555feeb2c7fff9bc24a434635d4b0cdff9137fe5b4477
export CROSSTOOL_VERSION=1.27.0

cd $BUILD_BASE

curl -LO http://crosstool-ng.org/download/crosstool-ng/crosstool-ng-${CROSSTOOL_VERSION}.tar.xz
echo "${CROSSTOOL_SHA256} crosstool-ng-${CROSSTOOL_VERSION}.tar.xz" | sha256sum -c -
tar xJf crosstool-ng-${CROSSTOOL_VERSION}.tar.xz
cd crosstool-ng-${CROSSTOOL_VERSION} && ./configure --prefix=${BUILD_BASE}/ctng && make && make install && cd .. && rm -rf crosstool-ng-*

mkdir ct-ng-build
cp ${BUILD_BASE}/crosstool-ng.config ./ct-ng-build/.config
cd ct-ng-build && CT_PREFIX=${BUILD_BASE}/distroot ${BUILD_BASE}/ctng/bin/ct-ng build && cd .. && rm -rf ct-ng-build
bash -c 'find ${BUILD_BASE}/distroot/bin -name "x86_64-unknown-linux-gnu-*" | while read f; do ln -s "$(basename $f)" "${f/x86_64-unknown-linux-gnu-/}"; done'
rm -rf ${BUILD_BASE}/ctng
