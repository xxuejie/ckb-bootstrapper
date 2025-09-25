#!/usr/bin/env bash
set -ex

BUILD_BASE="${BUILD_BASE:-/tmp/ckb-build}"

export BINUTILS_SHA256=0cdd76777a0dfd3dd3a63f215f030208ddb91c2361d2bcc02acec0f1c16b6a2e
export BINUTILS_VERSION=2.44
export GCC_SHA256=6e6e0628573d2185727a2dd83211d04a2b2748e4a262099099b9c8064634c9ee
export GCC_VERSION=8.5.0
export KERNEL_SHA256=3f89cd717e0d497ba4818e145a33002f4c15032e355c1ad6d3d7f31f122caf41
export KERNEL_VERSION=4.15.18
export GLIBC_SHA256=5172de54318ec0b7f2735e5a91d908afe1c9ca291fec16b5374d9faadfc1fc72
export GLIBC_VERSION=2.27

export target=x86_64-unknown-linux-gnu
export KERNEL_ARCH=x86

cd $BUILD_BASE

export BUILD_SYSROOT=${BUILD_BASE}/distroot/${target}/sysroot

curl -LO http://ftpmirror.gnu.org/binutils/binutils-${BINUTILS_VERSION}.tar.gz
echo "${BINUTILS_SHA256} binutils-${BINUTILS_VERSION}.tar.gz" | sha256sum -c -
tar xzf binutils-${BINUTILS_VERSION}.tar.gz
mkdir build-binutils
cd build-binutils
../binutils-${BINUTILS_VERSION}/configure \
  --prefix=${BUILD_BASE}/distroot \
  --with-sysroot=${BUILD_SYSROOT} \
  --enable-ld=yes \
  --enable-deterministic-archives \
  --disable-multilib \
  --disable-sim \
  --disable-gdb \
  --disable-nls \
  --without-zstd \
  --target=${target}
make -j$(nproc)
make install
cd ..
rm -rf build-binutils binutils-*

curl -LO https://www.kernel.org/pub/linux/kernel/v4.x/linux-${KERNEL_VERSION}.tar.xz
echo "${KERNEL_SHA256} linux-${KERNEL_VERSION}.tar.xz" | sha256sum -c -
tar xJf linux-${KERNEL_VERSION}.tar.xz
cd linux-${KERNEL_VERSION}
make ARCH=${KERNEL_ARCH} INSTALL_HDR_PATH=${BUILD_SYSROOT}/usr headers_install
cd ..
rm -rf linux-*

curl -LO http://ftpmirror.gnu.org/gcc/gcc-${GCC_VERSION}/gcc-${GCC_VERSION}.tar.gz
echo "${GCC_SHA256} gcc-${GCC_VERSION}.tar.gz" | sha256sum -c -
tar xzf gcc-${GCC_VERSION}.tar.gz
mkdir build-gcc
cd build-gcc
../gcc-${GCC_VERSION}/configure \
  --target=${target} \
  --prefix=${BUILD_BASE}/distroot \
  --with-sysroot=${BUILD_SYSROOT} \
  --enable-languages=c,c++ \
  --disable-threads \
  --disable-multilib \
  --disable-libssp \
  --disable-nls \
  --disable-shared \
  ${GCC_STAGE1_BUILD_ARGS}
make -j$(nproc) all-gcc
make install-gcc
cd ..

curl -LO http://ftpmirror.gnu.org/glibc/glibc-${GLIBC_VERSION}.tar.xz
echo "${GLIBC_SHA256} glibc-${GLIBC_VERSION}.tar.xz" | sha256sum -c -
tar xJf glibc-${GLIBC_VERSION}.tar.xz
mkdir build-glibc
cd build-glibc
echo "libc_cv_forced_unwind=yes" > config.cache
echo "libc_cv_c_cleanup=yes" >> config.cache
../glibc-${GLIBC_VERSION}/configure \
  --host=${target} \
  --prefix=/usr \
  --with-headers=${BUILD_SYSROOT}/usr/include \
  --config-cache \
  --enable-add-ons=nptl \
  --enable-kernel=${KERNEL_VERSION}
make install_root=${BUILD_SYSROOT} install-headers
cd ..
rm -rf build-glibc

mkdir -p ${BUILD_BASE}/distroot/${target}/include/gnu
touch ${BUILD_BASE}/distroot/${target}/include/gnu/stubs.h
cd build-gcc
make -j$(nproc) all-target-libgcc
make install-target-libgcc
cd ..
rm -rf build-gcc

export PATH=${BUILD_BASE}/distroot/bin:$PATH
mkdir build-glibc
cd build-glibc
echo "libc_cv_forced_unwind=yes" > config.cache
echo "libc_cv_c_cleanup=yes" >> config.cache
export CC="${target}-gcc"
export AR="${target}-ar"
export RANLIB="${target}-ranlib"
export OBJCOPY="${target}-objcopy"
../glibc-${GLIBC_VERSION}/configure \
  --host=${target} \
  --prefix=/usr \
  --libexecdir=/usr/lib/glibc \
  --with-binutils=${BUILD_BASE}/distroot/bin \
  --with-headers=${BUILD_SYSROOT}/usr/include \
  --disable-werror \
  --config-cache \
  --enable-add-ons=nptl \
  --enable-kernel=${KERNEL_VERSION}
make -j$(nproc)
make install_root=${BUILD_SYSROOT} install
cd ..
rm -rf build-glibc glibc-*

mkdir build-gcc
cd build-gcc
export CC="gcc"
export AR="ar"
export RANLIB="ranlib"
export OBJCOPY="objcopy"
../gcc-${GCC_VERSION}/configure \
  --with-gnu-ld \
  --with-gnu-as \
  --disable-nls \
  --disable-libssp \
  --disable-plugin \
  --disable-multilib \
  --disable-tm-clone-registry \
  --disable-libmudflap \
  --disable-libgomp \
  --disable-libssp \
  --disable-libquadmath \
  --disable-libquadmath-support \
  --disable-libsanitizer \
  --enable-lto \
  --enable-threads=posix \
  --enable-languages=c,c++ \
  --enable-__cxa_atexit \
  --enable-long-long \
  --without-zstd \
  --target=${target} \
  --prefix=${BUILD_BASE}/distroot \
  --with-sysroot=${BUILD_SYSROOT}
make -j$(nproc)
make install
cd ..
rm -rf build-gcc gcc-*

bash -c "find ${BUILD_BASE}/distroot/bin -name \"x86_64-unknown-linux-gnu-*\" | while read f; do ln -s \"\$(basename \$f)\" \"\${f/x86_64-unknown-linux-gnu-/}\"; done"
ln -s gcc ${BUILD_BASE}/distroot/bin/cc
