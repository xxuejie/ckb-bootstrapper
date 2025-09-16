# This is adapted from
# https://twosixtech.com/blog/repeatable-cross-gcc-toolchain-builds-with-nix/
{ pkgs ? import (fetchTarball {
  url = "https://github.com/NixOS/nixpkgs/archive/refs/tags/25.05.tar.gz";
}) {} }:

let
  binutilsVersion       = "2.44";
  gccVersion            = "8.5.0";
  linuxKernelVersion    = "4.15.18";
  glibcVersion          = "2.27";

  target = "x86_64-unknown-linux-gnu";
in
pkgs.stdenvNoCC.mkDerivation {
  name = "gcc-toolchain-for-ckb";
  version = "1.0";

  srcs = [
    ( pkgs.fetchurl {
      url = "http://ftpmirror.gnu.org/binutils/binutils-${binutilsVersion}.tar.gz";
      sha256 = "sha256-DN12d3oN/T3Tpj8hXwMCCN25HCNh0rzAKs7A8cFrai4=";
    })
    ( pkgs.fetchurl {
      url = "http://ftpmirror.gnu.org/gcc/gcc-${gccVersion}/gcc-${gccVersion}.tar.gz";
      sha256 = "sha256-bm4GKFc9IYVyei3YMhHQSisnSOSiYgmQmbnIBkY0ye4=";
    })
    ( pkgs.fetchurl {
      url = "https://www.kernel.org/pub/linux/kernel/v4.x/linux-${linuxKernelVersion}.tar.xz";
      sha256 = "sha256-P4nNcX4NSXukgY4UWjMAL0wVAy41XBrW09fzHxIsr0E=";
    })
    ( pkgs.fetchurl {
      url = "http://ftpmirror.gnu.org/glibc/glibc-${glibcVersion}.tar.xz";
      sha256 = "sha256-UXLeVDGOwLfyc15akdkIr+HJyikf7Ba1N02fqt/B/HI=";
    })
  ];

  buildInputs = [
    pkgs.gmp
    pkgs.libmpc
    pkgs.mpfr
  ];

  nativeBuildInputs = [
    pkgs.gcc
    pkgs.wget
    pkgs.which
    pkgs.rsync
    pkgs.python3
    pkgs.bison
    pkgs.flex 
    pkgs.gnumake42
    pkgs.texinfo
  ];

  # I believe the following prevents gcc from treating "-Werror=format-security"
  # warnings as errors
  hardeningDisable = [ "format" ];

  sourceRoot = ".";

  buildPhase = ''
    echo $PWD
    ls -lah .
    make --version

    # binutils
    mkdir build-binutils
    cd build-binutils
    ../binutils-${binutilsVersion}/configure \
      --prefix=$out \
      --with-sysroot=$out/sysroot \
      --target=${target}

    make -j$(nproc)
    make install

    cd ../linux-${linuxKernelVersion}
    make ARCH=x86 INSTALL_HDR_PATH=$out/sysroot/usr headers_install
    cd ..

    # gcc stage 1
    mkdir build-gcc
    cd build-gcc
    ../gcc-${gccVersion}/configure \
      --target=${target} \
      --prefix=$out \
      --with-sysroot=$out/sysroot \
      --enable-languages=c,c++ \
      --disable-threads \
      --disable-multilib \
      --disable-libssp \
      --disable-nls \
      --disable-shared \
      --with-gmp=${pkgs.gmp} \
      --with-mpfr=${pkgs.mpfr} \
      --with-mpc=${pkgs.libmpc}
    make -j$(nproc) all-gcc
    make install-gcc
    cd ../

    # build glibc headers
    echo line 113
    mkdir build-glibc
    cd build-glibc
    rm -rf *
    echo "libc_cv_forced_unwind=yes" > config.cache
    echo "libc_cv_c_cleanup=yes" >> config.cache
    ../glibc-${glibcVersion}/configure \
      --host=${target} \
      --prefix=/usr \
      --with-headers=$out/sysroot/usr/include \
      --config-cache \
      --enable-add-ons=nptl \
      --enable-kernel=${linuxKernelVersion}
    make install_root=$out/sysroot install-headers
    cd ..

    # gcc stage 1.5
    mkdir -p $out/${target}/include/gnu
    touch $out/${target}/include/gnu/stubs.h
    cd build-gcc
    make -j$(nproc) all-target-libgcc
    make install-target-libgcc
    cd ..

    # build glibc
    export PATH=$out/bin:$PATH
    echo line 138
    cd build-glibc
    rm -rf *
    echo "libc_cv_forced_unwind=yes" > config.cache
    echo "libc_cv_c_cleanup=yes" >> config.cache
    export CC="${target}-gcc"
    export AR="${target}-ar"
    export RANLIB="${target}-ranlib"
    export OBJCOPY="${target}-objcopy"
    ../glibc-${glibcVersion}/configure \
      --host=${target} \
      --prefix=/usr \
      --libexecdir=/usr/lib/glibc \
      --with-binutils=$out/bin \
      --with-headers=$out/sysroot/usr/include \
      --disable-werror \
      --config-cache \
      --enable-add-ons=nptl \
      --enable-kernel=${linuxKernelVersion}
    make -j$(nproc)
    make install_root=$out/sysroot install
    cd ..

    # build glibc-final
    cd build-gcc
    rm -rf *
    export CC="gcc"
    export AR="ar"
    export RANLIB="ranlib"
    export OBJCOPY="objcopy"
    ../gcc-${gccVersion}/configure \
      --with-gnu-ld \
      --with-gnu-as \
      --disable-nls \
      --disable-libssp \
      --disable-multilib \
      --enable-languages=c,c++ \
      --target=${target} \
      --prefix=$out \
      --with-sysroot=$out/sysroot
    make -j$(nproc)
    make install
    cd ..

    mkdir -p $out/${target}/lib
    mkdir -p $out/sysroot/lib
    rsync -a $out/${target}/lib/ $out/sysroot/lib
  '';

  meta = {
    description = "Cross-compilation toolchain for OpenRISC architecture";
    homepage = "https://openrisc.io";
    license = pkgs.lib.licenses.gpl2;
    maintainers = with pkgs.stdenv.lib.maintainers; [ ];
  };
}
