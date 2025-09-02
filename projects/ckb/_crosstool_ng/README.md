This folder provides a new reproducible build flow with the help of [crosstool-ng](https://crosstool-ng.github.io/). Basically we are:

1. Build a new GNU toolchain with older glibc version
2. Use the built GNU toolchain to build LLVM / clang
3. Use built GNU toolchain, LLVM / clang to build Rust
4. Finally use Rust to build CKB

Right now we have docker files for `Ubuntu 24.04` and `Fedora 42`, both environments have been tested to build the exact same ckb binary.

```bash
$ cd projects/ckb/_crosstool_ng
$ docker build dockerfiles -f dockerfiles/fedora.dockerfile -t cross-ng-test-fedora
$ docker build dockerfiles -f dockerfiles/noble.dockerfile -t cross-ng-test-noble

$ git clone https://github.com/nervosnetwork/ckb ckb_fedora
$ cd ckb_fedora
$ git checkout v0.202.0
$ docker run --rm -it -v `pwd`:/code cross-ng-test-fedora
(docker) # cd /code
(docker) # SOURCE_DATE_EPOCH=0 make prod
(docker) # exit
$ cd ..

$ git clone https://github.com/nervosnetwork/ckb ckb_noble
$ cd ckb_noble
$ git checkout v0.202.0
$ docker run --rm -it -v `pwd`:/code cross-ng-test-noble
(docker) # cd /code
(docker) # SOURCE_DATE_EPOCH=0 make prod
(docker) # exit
$ cd ..
```

One can now verify that `ckb_fedora/target/prod/ckb` and `ckb_nobel/target/prod/ckb` contain the exact same binary. The binary can also be executed on `Ubuntu 20.04`.

The sha256sum of this binary shall be `6e2c92995438cc6a2ee5d0d495b608b44b9af73b531e2640130bd25919ae597e`.
The sha512sum of this binary shall be `eb70ac7d813ae830b5040fe22733d2a3423b2d28914368fc24216832c9d694ed41068e81b7bac7eb456412af9aa7d6393eeb2d0a91a51fc86ca74c5ee4f61efa`.
