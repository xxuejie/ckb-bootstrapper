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

FROM base-builder AS rust-builder
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
        xz-utils

COPY build_rust.sh /tmp/build_rust.sh
COPY rust-config.toml /tmp/config.toml
RUN /tmp/build_rust.sh

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
