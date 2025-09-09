# This is similar to trixie except for the handling of Rust bootstrap:
# When building Rust, a pre-built Rust compiler is required to kickoff
# the bootstrapping process. By default, a pre-built beta compiler from
# static.rust-lang.org is downloaded and used.
# However, all previous OS configurations would all aim to download beta
# compilers from one location, we are relying on one binary blob to behave
# correctly.
# This dockerfile changes the workflow, so we are using Debian's own rust-all
# package built by servers from the debian team as the pre-built compiler.
# With this new flow, even if something bad happened to static.rust-lang.org,
# we still have rust-all package from the debian team as a safe guard, boosting
# the security of our reproducible build process.
# There is a coincidence that CKB v0.202.0 and Debian 13(trixie) both use Rust
# 1.85.0. However, assuming CKB v0.205.0 upgrades to Rust 1.88.0, we will need
# a more complicated process:
#
# * Use pre-built Rust 1.85.0 provided by Debian 13 to build Rust 1.86.0
# * Use Rust 1.86.0 built in the previous step to build Rust 1.87.0
# * Use Rust 1.87.0 built in the previous step to build Rust 1.88.0
# * Now we can use Rust 1.88.0 built by us to build CKB v0.205.0
FROM debian:trixie AS base-builder

# Base builder here allows customization of builder images, such as inserting
# lines for proxy configuration.

FROM base-builder AS gnu-builder

RUN apt-get update; \
    apt-get install -y --no-install-recommends \
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
        xz-utils

COPY build_gnu.sh /tmp/build_gnu.sh
COPY crosstool-ng.config /tmp/crosstool-ng.config
RUN /tmp/build_gnu.sh

FROM base-builder AS dist-builder
COPY --from=gnu-builder /distroot /distroot

RUN apt-get update; \
    apt-get install -y --no-install-recommends \
        autoconf \
        ca-certificates \
        cmake \
        curl \
        make \
        python3 \
        xz-utils

COPY build_llvm.sh /tmp/build_llvm.sh
RUN /tmp/build_llvm.sh

FROM base-builder AS rust-bootstrap-builder
COPY --from=dist-builder /distroot /distroot

RUN apt-get update; \
    apt-get install -y --no-install-recommends \
        ca-certificates \
        cmake \
        curl \
        make \
        libssl-dev \
        pkg-config \
        python3 \
        xz-utils \
        rust-all

COPY build_rust.sh /tmp/build_rust.sh
COPY rust-config-trixie-os-rustc.toml /tmp/config.toml
RUN STAGE=2 /tmp/build_rust.sh

FROM base-builder AS rust-builder
COPY --from=dist-builder /distroot /distroot
COPY --from=rust-bootstrap-builder /rustroot /rustbuilder

RUN apt-get update; \
    apt-get install -y --no-install-recommends \
        ca-certificates \
        cmake \
        curl \
        make \
        libssl-dev \
        pkg-config \
        python3 \
        xz-utils

COPY build_rust.sh /tmp/build_rust.sh
COPY rust-config.toml /tmp/config.toml
RUN STAGE=3 /tmp/build_rust.sh

FROM base-builder
COPY --from=rust-builder /distroot /distroot
COPY --from=rust-builder /rustroot /rustroot

RUN apt-get update; \
    apt-get install -y --no-install-recommends \
        ca-certificates \
        make \
        libfindbin-libs-perl

ENV PATH=/rustroot/bin:/distroot/bin:$PATH
ENV CC=/distroot/bin/clang
ENV CXX=/distroot/bin/clang++
ENV AR=/distroot/bin/llvm-ar
ENV CARGO_TARGET_X86_64_UNKNOWN_LINUX_GNU_LINKER=/distroot/bin/clang
