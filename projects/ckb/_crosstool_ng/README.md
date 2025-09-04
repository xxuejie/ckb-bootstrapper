This folder provides a new reproducible build flow with the help of [crosstool-ng](https://crosstool-ng.github.io/). Basically we are:

1. Build a new GNU toolchain with older glibc version
2. Use the built GNU toolchain to build LLVM / clang
3. Use built GNU toolchain, LLVM / clang to build Rust
4. Finally use Rust to build CKB

Right now we have docker files for `Ubuntu 24.04`, `Debian 13`, `Fedora 42`, and latest `Archlinux`, both environments have been tested to build the exact same ckb binary.

```bash
$ cd projects/ckb/_crosstool_ng
$ docker build dockerfiles -f dockerfiles/fedora.dockerfile -t cross-ng-test-fedora
$ docker build dockerfiles -f dockerfiles/noble.dockerfile -t cross-ng-test-noble
$ docker build dockerfiles -f dockerfiles/trixie.dockerfile -t cross-ng-test-trixie
$ docker build dockerfiles -f dockerfiles/arch.dockerfile -t cross-ng-test-arch

$ git clone https://github.com/nervosnetwork/ckb ckb_fedora
$ cd ckb_fedora
$ git checkout v0.202.0
$ docker run --rm -it -v `pwd`:/code cross-ng-test-fedora
(docker) # cd /code
(docker) # CARGO_HOME=/tmp/cargo SOURCE_DATE_EPOCH=0 make prod
(docker) # exit
$ cd ..

$ git clone https://github.com/nervosnetwork/ckb ckb_noble
$ cd ckb_noble
$ git checkout v0.202.0
$ docker run --rm -it -v `pwd`:/code cross-ng-test-noble
(docker) # cd /code
(docker) # CARGO_HOME=/tmp/cargo SOURCE_DATE_EPOCH=0 make prod
(docker) # exit
$ cd ..

$ git clone https://github.com/nervosnetwork/ckb ckb_trixie
$ cd ckb_trixie
$ git checkout v0.202.0
$ docker run --rm -it -v `pwd`:/code cross-ng-test-trixie
(docker) # cd /code
(docker) # CARGO_HOME=/tmp/cargo SOURCE_DATE_EPOCH=0 make prod
(docker) # exit
$ cd ..

$ git clone https://github.com/nervosnetwork/ckb ckb_arch
$ cd ckb_arch
$ git checkout v0.202.0
$ docker run --rm -it -v `pwd`:/code cross-ng-test-arch
(docker) # cd /code
(docker) # CARGO_HOME=/tmp/cargo SOURCE_DATE_EPOCH=0 make prod
(docker) # exit
$ cd ..
```

One can now verify that `ckb_fedora/target/prod/ckb` and `ckb_nobel/target/prod/ckb` contain the exact same binary. The binary can also be executed on `Ubuntu 20.04`.

The sha256sum of this binary shall be `eeeb5983416185b73478bbf67cfaaa6789ceaf7097b7c41b87739f9e67d74c30`.
The sha512sum of this binary shall be `13c21dae029c9bb4beef013dc6c3e081d2d1f86b5fb2a867ac32623e92f84d0ba83a703897236fd562d0407b2ff8e022b04a061a9a941507cf6e4cc0bfc949bb`.
