#!/usr/bin/env bash
set -ex

GNU_TYPE="${GNU_TYPE:-manual}"

export BUILD_BASE="${BUILD_BASE:-/tmp/ckb-build}"
rm -rf ${BUILD_BASE} && mkdir -p ${BUILD_BASE}

TOP="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

if [[ "x$GNU_TYPE" == "xctng" ]]; then
  cp ${TOP}/crosstool-ng.config ${BUILD_BASE}/crosstool-ng.config
  bash ${TOP}/build_gnu_crosstool.sh
elif [[ "x$GNU_TYPE" == "xmanual" ]]; then
  bash ${TOP}/build_gnu_manual.sh
else
  echo "You can only build GNU via ctng, or manual"
  exit 1
fi


bash ${TOP}/build_llvm.sh

cp ${TOP}/rust-config-bootstrap.toml ${BUILD_BASE}/config.toml
STAGE=2 bash ${TOP}/build_rust.sh
mv ${BUILD_BASE}/rustroot ${BUILD_BASE}/rustbuilder

cp ${TOP}/rust-config.toml ${BUILD_BASE}/config.toml
STAGE=3 bash ${TOP}/build_rust.sh

rm -rf ${BUILD_BASE}/config.toml ${BUILD_BASE}/rustbuilder
