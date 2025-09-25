FROM fedora:42 AS base-builder

# All dependencies will be built and installed to BUILD_BASE folder,
# this way the same scripts can be reused in non-docker environments.
ENV BUILD_BASE /tmp/ckb-build
RUN rm -rf ${BUILD_BASE} && mkdir -p ${BUILD_BASE}

# Base builder here allows customization of builder images, such as inserting
# lines for proxy configuration.

FROM base-builder AS gnu-builder

RUN dnf install -y \
        autoconf \
        bison \
        curl \
        diffutils \
        file \
        flex \
        gawk \
        gcc \
        glibc-static \
        g++ \
        help2man \
        ncurses-devel \
        libstdc++-static \
        libtool \
        patch \
        texinfo \
        which \
        unzip \
        gmp-devel \
        mpfr-devel \
        libmpc-devel

COPY scripts/build_make42.sh ${BUILD_BASE}/build_make42.sh
RUN ${BUILD_BASE}/build_make42.sh
ENV PATH=${BUILD_BASE}/make42/bin:$PATH

COPY scripts/build_gnu_manual.sh ${BUILD_BASE}/build_gnu_manual.sh
RUN ${BUILD_BASE}/build_gnu_manual.sh

FROM base-builder AS dist-builder
COPY --from=gnu-builder ${BUILD_BASE}/distroot ${BUILD_BASE}/distroot

RUN dnf install -y \
        cmake \
        curl \
        make \
        perl \
        python3 \
        gmp \
        mpfr \
        libmpc

COPY scripts/build_llvm.sh ${BUILD_BASE}/build_llvm.sh
RUN ${BUILD_BASE}/build_llvm.sh

FROM base-builder AS rust-bootstrap-builder
COPY --from=dist-builder ${BUILD_BASE}/distroot ${BUILD_BASE}/distroot

RUN dnf install -y \
        cmake \
        curl \
        make \
        python3

COPY scripts/build_rust.sh ${BUILD_BASE}/build_rust.sh
COPY scripts/rust-config-bootstrap.toml ${BUILD_BASE}/config.toml
RUN STAGE=2 ${BUILD_BASE}/build_rust.sh

FROM base-builder AS rust-builder
COPY --from=dist-builder ${BUILD_BASE}/distroot ${BUILD_BASE}/distroot
COPY --from=rust-bootstrap-builder ${BUILD_BASE}/rustroot ${BUILD_BASE}/rustbuilder

RUN dnf install -y \
        cmake \
        curl \
        make \
        python3

COPY scripts/build_rust.sh ${BUILD_BASE}/build_rust.sh
COPY scripts/rust-config.toml ${BUILD_BASE}/config.toml
RUN STAGE=3 ${BUILD_BASE}/build_rust.sh

FROM base-builder
COPY --from=rust-builder ${BUILD_BASE}/distroot ${BUILD_BASE}/distroot
COPY --from=rust-builder ${BUILD_BASE}/rustroot ${BUILD_BASE}/rustroot

RUN dnf install -y perl make git
RUN git config --global --add safe.directory ${BUILD_BASE}/ckb

ENV PATH=${BUILD_BASE}/rustroot/bin:${BUILD_BASE}/distroot/bin:$PATH
ENV CC=${BUILD_BASE}/distroot/bin/clang
ENV CXX=${BUILD_BASE}/distroot/bin/clang++
ENV AR=${BUILD_BASE}/distroot/bin/llvm-ar
ENV CARGO_HOME=${BUILD_BASE}/cargo
ENV SOURCE_DATE_EPOCH=0
