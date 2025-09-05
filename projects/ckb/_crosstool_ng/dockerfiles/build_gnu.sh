#!/usr/bin/env bash
set -ex

export CROSSTOOL_SHA256=0506ab98fa0ad6d263a555feeb2c7fff9bc24a434635d4b0cdff9137fe5b4477
export CROSSTOOL_VERSION=1.27.0

curl -LO http://crosstool-ng.org/download/crosstool-ng/crosstool-ng-${CROSSTOOL_VERSION}.tar.xz
echo "${CROSSTOOL_SHA256} crosstool-ng-${CROSSTOOL_VERSION}.tar.xz" | sha256sum -c -
tar xJf crosstool-ng-${CROSSTOOL_VERSION}.tar.xz
cd crosstool-ng-${CROSSTOOL_VERSION} && ./configure && make && make install && cd .. && rm -rf crosstool-ng-*

mkdir /build
cp /tmp/crosstool-ng.config /build/.config
cd /build && CT_PREFIX=/distroot ct-ng build && cd / && rm -rf /build
bash -c 'find /distroot/bin -name "x86_64-unknown-linux-gnu-*" | while read f; do ln -s "$(basename $f)" "${f/x86_64-unknown-linux-gnu-/}"; done'
