This folder provides a new reproducible build flow with the help of [crosstool-ng](https://crosstool-ng.github.io/). Basically we are:

1. Build a new GNU toolchain with older glibc version
2. Use the built GNU toolchain to build LLVM / clang
3. Use built GNU toolchain, LLVM / clang to build Rust
4. Finally use Rust to build CKB

Right now we have docker files for `Ubuntu 24.04`, `Debian 13`, `Fedora 42`, and latest `Archlinux`, both environments have been tested to build the exact same ckb binary(note that a clean build of each of the docker image below, requires building gcc 1 time, LLVM 3 times, and Rust 2 times. On a 6-core machine, this is taking ~2.5 hours).

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

One can now verify that `ckb_fedora/target/prod/ckb` and `ckb_nobel/target/prod/ckb` contain the exact same binary. The binary is built against `glibc 2.27`, so it can be executed on `Ubuntu 18.04`, the same as current ckb release configuration.

The sha256sum of this binary shall be `c821fc61d5084885c7a0d40b201b3e5c260daa56166badda10b20ad63fd12585`.
The sha512sum of this binary shall be `ab889665a81e6d96843cda4ca5e0727c9e3dce66a959b9e4c43283f3786831159fd328c334633fad387a7371992dc937e6245c16927b4767487c98dbe760231c`.

## Rust bootstrapping

In addition to initial OS provided binary blobs, there is another piece of binary in bootstrapping: building Rust requires a previous version(or the same as the built version) of Rust compiler. Normally, this is downloaded automatically by the Rust bootstrapping process. In fact all 4 supported OSes now would download the same pre-built Rust compiler from `static.rust-lang.org`, which is slightly concerning: what if `static.rust-lang.org` somehow contains a malicious binary? To solve this problem, we have provided a new docker image which is also based on `Debian 13`, but uses debian's own shipped `rust-all` package to provide pre-built Rust compiler for bootstrapping. It is expected that Debian employed a separate build process from `static.rust-lang.org`, meaning we will have multiple source of binary blobs for the bootstrapping Rust compiler as well. You can try the following steps to build the binary:

```bash
$ cd projects/ckb/_crosstool_ng
$ docker build dockerfiles -f dockerfiles/trixie_os_rust.dockerfile -t cross-ng-test-trixie-os-rust

$ git clone https://github.com/nervosnetwork/ckb ckb_trixie_os_rust
$ cd ckb_trixie_os_rust
$ git checkout v0.202.0
$ docker run --rm -it -v `pwd`:/code cross-ng-test-trixie-os-rust
(docker) # cd /code
(docker) # CARGO_HOME=/tmp/cargo SOURCE_DATE_EPOCH=0 make prod
(docker) # exit
$ cd ..
```

It's roughly the same build process as above steps, but this time, we are using Debian's built Rust compiler for bootstrapping, not the ones on <https://static.rust-lang.org>, we have utilized a different source for certain binary blobs.

If needed, one can even expand this process so we are building rustc completely from source: <https://github.com/dtolnay/bootstrap>. Providing more guarentees on the bootstrapping process.

It's worth mentioning that there is a coincidence that CKB v0.202.0 and Debian 13 both uses Rust 1.85.0. Debian's own `rustc` can simply be used in our building process. Assuming CKB switches to a different Rust version, e.g., CKB v0.205.0 switches to Rust 1.88.0, we will have perform some of the complete bootstrapping process above: starting from Debian's own Rust 1.85.0, we first build Rust 1.86.0, then build Rust 1.87.0 with Rust 1.86.0, and finally build Rust 1.88.0 with Rust 1.87.0.
