FROM ubuntu:noble AS base-builder

# All dependencies will be built and installed to BUILD_BASE folder,
# this way the same scripts can be reused in non-docker environments.
ENV BUILD_BASE /tmp/ckb-build
RUN rm -rf ${BUILD_BASE} && mkdir -p ${BUILD_BASE}

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
        xz-utils \
        libgmp-dev \
        libmpfr-dev \
        libmpc-dev

COPY scripts/build_make42.sh ${BUILD_BASE}/build_make42.sh
RUN ${BUILD_BASE}/build_make42.sh
ENV PATH=${BUILD_BASE}/make42/bin:$PATH
RUN apt remove -y make

COPY scripts/build_gnu_manual.sh ${BUILD_BASE}/build_gnu_manual.sh
RUN ${BUILD_BASE}/build_gnu_manual.sh

FROM base-builder AS dist-builder
COPY --from=gnu-builder ${BUILD_BASE}/distroot ${BUILD_BASE}/distroot

RUN apt-get update; \
    apt-get install -y --no-install-recommends \
        autoconf \
        ca-certificates \
        cmake \
        curl \
        make \
        python3 \
        xz-utils \
        libgmp10 \
        libmpfr6 \
        libmpc3

COPY scripts/build_llvm.sh ${BUILD_BASE}/build_llvm.sh
RUN ${BUILD_BASE}/build_llvm.sh

FROM base-builder AS rust-bootstrap-builder
COPY --from=dist-builder ${BUILD_BASE}/distroot ${BUILD_BASE}/distroot

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

COPY scripts/build_rust.sh ${BUILD_BASE}/build_rust.sh
COPY scripts/rust-config-bootstrap.toml ${BUILD_BASE}/config.toml
RUN STAGE=2 ${BUILD_BASE}/build_rust.sh

FROM base-builder AS rust-builder
COPY --from=dist-builder ${BUILD_BASE}/distroot ${BUILD_BASE}/distroot
COPY --from=rust-bootstrap-builder ${BUILD_BASE}/rustroot ${BUILD_BASE}/rustbuilder

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

COPY build_rust.sh ${BUILD_BASE}/build_rust.sh
COPY scripts/rust-config.toml ${BUILD_BASE}/config.toml
RUN STAGE=3 ${BUILD_BASE}/build_rust.sh

FROM base-builder
COPY --from=rust-builder ${BUILD_BASE}/distroot ${BUILD_BASE}/distroot
COPY --from=rust-builder ${BUILD_BASE}/rustroot ${BUILD_BASE}/rustroot

RUN apt-get update; \
    apt-get install -y --no-install-recommends \
        ca-certificates \
        git \
        make \
        libfindbin-libs-perl
RUN git config --global --add safe.directory ${BUILD_BASE}/ckb

ENV PATH=${BUILD_BASE}/rustroot/bin:${BUILD_BASE}/distroot/bin:$PATH
ENV CC=${BUILD_BASE}/distroot/bin/clang
ENV CXX=${BUILD_BASE}/distroot/bin/clang++
ENV AR=${BUILD_BASE}/distroot/bin/llvm-ar
ENV CARGO_HOME=${BUILD_BASE}/cargo
ENV SOURCE_DATE_EPOCH=0
