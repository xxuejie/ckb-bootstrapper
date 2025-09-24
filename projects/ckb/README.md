# CKB

This folder keeps reproducible bootstrap designs for [Nervos CKB](https://github.com/nervosnetwork/ckb).

A full reproducible bootstrap workflow for Nervos CKB works as follows:

1. Given pre-built compilers & toolchains provided by the host OS in binary form(we will get to this part later), a GNU toolchain with gcc 8.5.0, glibc 2.27, binutils 2.44 is first built. This GNU toolchain serves several purposes:
    a) It can be used to bootstrap clang, which is the real C/C++ compiler used bo the reproducible build;
    b) For now, CKB binaries are built against glibc 2.27, building a toolchain here provides a sysroot where CKB binaries can be linked against;
2. LLVM 20.1.8 is then built using gcc 8.5.0 built in step 1;
3. Rust 1.85.0 is then built as the first (bootstrap) Rust compiler. Note that in order to build Rust, a prebuilt Rust compiler in binary form must first be available. We will get to this part later.
4. Rust 1.85.0 is built againt as the final Rust compiler to use. This time, we are using Rust 1.85.0 built in step 3 as the prebuilt Rust compiler.
5. Finall, CKB is built using the following components:
    a) Rust 1.85.0 built in step 4;
    b) LLVM built in step 2 as C / C++ compiler;
    c) sysroot using glibc 2.27 built in step 1;

We spent a lot of time studying [Bitcoin's reproducible build setup](https://github.com/bitcoin/bitcoin/tree/689a32197638e92995dd8eb071425715f5fdc3a4/contrib/guix) using [Guix](https://guix.gnu.org/). Guix really spent [a lot of efforts](https://guix.gnu.org/en/blog/2023/the-full-source-bootstrap-building-from-source-all-the-way-down/) chasing the full-source bootstrap goal, meaning the final output shall be built from source code alone, minimizing the prebuilt binaries used. However, even with Guix's tremendous efforts towards a full-source bootstrap setup, there is still a small driver(mostly GNU guile) that must come in binary form. One can only trust this small binary to be valid.

While designing reproducible bootstrap workflow for CKB, we spent quite some time tweaking Guix for our purposes. While we do hugely respect the Bitcoin team and the Guix team, it shall be pointed out, that CKB is quite different from Bitcoin:

* CKB is a hybrid codebase that uses Rust, C / C++ and slight assembly code, while Bitcoin is mostly written in C++, using only a C++ compiler;
* In the end Guix still relies on a binary component, we do want to see if we can work to remove this final restriction.

Given those thoughts, we started approaching the problem from a different angle: it is really hard to eliminate prebuilt binaries in a bootstrap process. So what if we instead embrace binaries? Binaries themselves are not the problem, the real problem is if the source of the binaries can be trusted. So what if we can have multiple sources providing binaries? If multiple independent sources can all provide prebuilt binaries used in the bootstrapping process, in a way, I don't think it will be a problem that our bootstrapping process requires prebuilt binaries.

In the above reproducible bootstrap workflow, prebuilt binaries are required in 2 scenarios:

* Building all of componenets would require a series of binaries, such as gcc, make, cmake, python, perl, etc.
* Building the first (bootstrap) Rust compiler in step 3 would require a prebuilt Rust compiler.

We solve the prebuilt binary problem by:

* Our reproducible bootstrap workflow can work on different OSes, including Debian 13, Ubuntu 24.04, Archlinux, Fedora 42 and Nix-based environment. In each different OS / environment, the prebuilt binaries from the distribution will be downloaded and used. All those different OSes and environments can complete the reproducible bootstrap workflow with the exact same CKB binary. An attacker to the bootstrap workflow, must simoutenously attack all of the infrastructures maintained by different teams, so as to perform a real attack on our reprodicible bootstrap workflow.
* 2 sources are provided as the prebuilt Rust compiler: rustc / cargo built by the Rust team on `static.rust-lang.org`(which is also what `rustup` uses); and the prebuilt rustc shipped by Debian team in Debian 13. An attacker will need to attack both infrastructures to succeed in attacking our workflow. We do acknowledge that this is slightly less secure than the previous case, since for now we only have 2 sources instead of 5. But as we progress, more sources might be added so different prebuilt Rust compilers can be used.

As of now, we can say that all prebuilt binaries used in our reproducible bootstrap workflow have multiple sources, which significantly complicates the task required to do a supply chain attack. In a way, I think we achieve the same level of security as Bitcoin's reproducible setup from a different perspective.

## Usage

There are several different paths you can run the reproducible bootstrap workflow for CKB:

### Docker

While not strictly required, we have prepared dockerfiles for `Debian 13`, `Ubuntu 24.04`, `Fedora 42` and latest `Archilinux`, where you can easily try the different reproducible bootstrap workflow(here we use `Debian 13` as an example):

```
$ git clone https://github.com/xxuejie/ckb-bootstrapper
$ cd ckb-bootstrapper/project/ckb
$ docker build . -f docker/trixie.dockerfile -t ckb-build-trixie
$ git clone --depth 1 --branch v0.202.0 https://github.com/nervosnetwork/ckb builds/ckb_trixie
$ docker run --rm -v `pwd`/builds/ckb_trixie:/tmp/ckb-build/ckb ckb-build-trixie \
  bash -c "cd /tmp/ckb-build/ckb && make prod"
```

Since we have to compile gcc, LLVM, and Rust 2 times, it might take some time to build the docker image. On a 6-core machine, this is taking roughly 3 hours. But the good news is that you can cache the docker image after the initial build.

When the docker container finishes, you can locate the built CKB binary at `builds/ckb_trixie/target/prod/ckb`. For CKB v0.202.0, the sha256 hash of this binary will be `159125ef9c59069802b97c705947caff2627dda23710423d26a6a9ff40ac87f1`. You can also replicate that other OSes generate the exact same binary.

For `Ubuntu 24.04`:

```
$ docker build . -f docker/noble.dockerfile -t ckb-build-noble
$ git clone --depth 1 --branch v0.202.0 https://github.com/nervosnetwork/ckb builds/ckb_noble
$ docker run --rm -v `pwd`/builds/ckb_noble:/tmp/ckb-build/ckb ckb-build-noble \
  bash -c "cd /tmp/ckb-build/ckb && make prod"
```

For `Fedora 42`:

```
$ docker build . -f docker/fedora.dockerfile -t ckb-build-fedora
$ git clone --depth 1 --branch v0.202.0 https://github.com/nervosnetwork/ckb builds/ckb_fedora
$ docker run --rm -v `pwd`/builds/ckb_fedora:/tmp/ckb-build/ckb ckb-build-fedora \
  bash -c "cd /tmp/ckb-build/ckb && make prod"
```

For `Archlinux`:

```
$ docker build . -f docker/arch.dockerfile -t ckb-build-arch
$ git clone --depth 1 --branch v0.202.0 https://github.com/nervosnetwork/ckb builds/ckb_arch
$ docker run --rm -v `pwd`/builds/ckb_arch:/tmp/ckb-build/ckb ckb-build-arch \
  bash -c "cd /tmp/ckb-build/ckb && make prod"
```

Lastly, we are still using `Debian 13`, but let's use Debian's prebuilt rustc package:

```
$ docker build . -f docker/trixie_os_rust.dockerfile -t ckb-build-trixie-os-rust
$ git clone --depth 1 --branch v0.202.0 https://github.com/nervosnetwork/ckb builds/ckb_trixie_os_rust
$ docker run --rm -v `pwd`/builds/ckb_trixie_os_rust:/tmp/ckb-build/ckb ckb-build-trixie-os-rust \
  bash -c "cd /tmp/ckb-build/ckb && make prod"
```

You can just verify that all docker containers using different OSes, result in the same CKB binary:

```
$ sha256sum builds/ckb_*/target/prod/ckb
```

### Scratch

Docker is being used in our reproducible bootstrap workflow as a simplication, but not a requirement. It's always possible to replicate the exact same steps in the docker container on a plain OS. For example, the following steps builds the same CKB binary above on a freshly installed Ubuntu machine:

```
$ sudo apt-get update
$ sudo apt-get install -y --no-install-recommends \
        autoconf \
        bison \
        build-essential \
        ca-certificates \
        curl \
        file \
        flex \
        gawk \
        help2man \
        libtool-bin \
        ncurses-dev \
        texinfo \
        unzip \
        xz-utils \
        libgmp-dev \
        libmpfr-dev \
        libmpc-dev \
        cmake \
        python3 \
        libssl-dev \
        pkg-config \
        git \
        libfindbin-libs-perl
$ git clone https://github.com/xxuejie/ckb-bootstrapper
$ cd ckb-bootstrapper/project/ckb
$ export BUILD_BASE=/tmp/ckb-build
$ mkdir -p $BUILD_BASE
$ ./scripts/build_make42.sh
$ export PATH=${BUILD_BASE}/make42/bin:$PATH
$ ./scripts/build_all.sh
$ git clone --depth 1 --branch v0.202.0 \
  https://github.com/nervosnetwork/ckb /tmp/ckb-build/ckb
$ cd /tmp/ckb-build/ckb
$ export PATH=${BUILD_BASE}/rustroot/bin:${BUILD_BASE}/distroot/bin:$PATH
$ export CC=${BUILD_BASE}/distroot/bin/clang
$ export CXX=${BUILD_BASE}/distroot/bin/clang++
$ export AR=${BUILD_BASE}/distroot/bin/llvm-ar
$ export CARGO_HOME=${BUILD_BASE}/cargo
$ export SOURCE_DATE_EPOCH=0
$ make prod
```

Now you can verify the same CKB binary is built:

```
$ sha256sum /tmp/ckb-build/ckb/target/prod/ckb
```

If you want to try other OSes, you might want to consult dockerfiles for dependencies to install, and then run `build_all.sh`. Note the docker separates different stages, and only install dependencies required for each particular stage, but this is not a general requirement. When you are testing on a plain OS, you can simply install all dependencies at once. The reproducible bootstrap workflow will merely focus on `/tmp/ckb-build`.

### NixOS

It's also possible to try the same workflow in a [Nix](https://nixos.org/) based environment:

```
$ git clone https://github.com/xxuejie/ckb-bootstrapper
$ cd ckb-bootstrapper/project/ckb/nix
$ nix-shell --pure
[nix-shell]$ git clone --depth 1 --branch v0.202.0 \
  https://github.com/nervosnetwork/ckb /tmp/ckb-build/ckb
[nix-shell]$ cd /tmp/ckb-build/ckb
[nix-shell]$ make prod
```

After this command completes, you can verify that the Nix environment also generates the exact same CKB binary:

```
$ sha256sum /tmp/ckb-build/ckb/target/prod/ckb
```

To make sure the exact same binary is generated, and that no environment runs into permission issues. We have to compile everything in `/tmp/ckb-build`. For docker images it is fine since docker would cache the image, but for Nix environments, you might want to cache `/tmp/ckb-build` somewhere, otherwise you might need to rebuild everything again after rebooting.
