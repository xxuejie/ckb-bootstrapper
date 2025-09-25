{ pkgs ? import (fetchTarball {
  url = "https://github.com/NixOS/nixpkgs/archive/refs/tags/25.05.tar.gz";
}) {} }:

pkgs.mkShellNoCC {
  buildInputs = [
    # Runtime dependencies required to build CKB
    pkgs.gmp
    pkgs.libmpc
    pkgs.mpfr
    pkgs.perl
    pkgs.gnumake42
    pkgs.git
    # Dependencies below are actually required to build gcc, llvm and rust.
    pkgs.gcc
    pkgs.wget
    pkgs.which
    pkgs.python3
    pkgs.bison
    pkgs.flex 
    pkgs.texinfo
    pkgs.curl
    pkgs.cmake
    pkgs.cacert
  ];

  env = {
    SSL_CERT_FILE = "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt";
    BUILD_BASE = "/tmp/ckb-build";
    # Insert proxy environment variables here if you need any
  };

  shellHook = ''
  GNU_TYPE=manual ../scripts/build_all.sh
  rm -rf ''${BUILD_BASE}/cargo

  # Those must be defined after build_all.sh script completes
  export PATH=''${BUILD_BASE}/rustroot/bin:''${BUILD_BASE}/distroot/bin:''$PATH
  export CC=''${BUILD_BASE}/distroot/bin/clang
  export CXX=''${BUILD_BASE}/distroot/bin/clang++
  export AR=''${BUILD_BASE}/distroot/bin/llvm-ar
  export CARGO_HOME=''${BUILD_BASE}/cargo
  export SOURCE_DATE_EPOCH=0
  '';
}
