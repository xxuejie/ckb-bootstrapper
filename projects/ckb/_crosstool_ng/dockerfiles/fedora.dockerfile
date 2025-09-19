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
        unzip

COPY build_gnu.sh ${BUILD_BASE}/build_gnu.sh
COPY crosstool-ng.config ${BUILD_BASE}/crosstool-ng.config
RUN ${BUILD_BASE}/build_gnu.sh

FROM base-builder AS dist-builder
COPY --from=gnu-builder ${BUILD_BASE}/distroot ${BUILD_BASE}/distroot

RUN dnf install -y \
        cmake \
        curl \
        make \
        perl \
        python3

COPY build_llvm.sh ${BUILD_BASE}/build_llvm.sh
RUN ${BUILD_BASE}/build_llvm.sh

FROM base-builder AS rust-bootstrap-builder
COPY --from=dist-builder ${BUILD_BASE}/distroot ${BUILD_BASE}/distroot

RUN dnf install -y \
        cmake \
        curl \
        make \
        python3

COPY build_rust.sh ${BUILD_BASE}/build_rust.sh
COPY rust-config-bootstrap.toml ${BUILD_BASE}/config.toml
RUN STAGE=2 ${BUILD_BASE}/build_rust.sh

FROM base-builder AS rust-builder
COPY --from=dist-builder ${BUILD_BASE}/distroot ${BUILD_BASE}/distroot
COPY --from=rust-bootstrap-builder ${BUILD_BASE}/rustroot ${BUILD_BASE}/rustbuilder

RUN dnf install -y \
        cmake \
        curl \
        make \
        python3

COPY build_rust.sh ${BUILD_BASE}/build_rust.sh
COPY rust-config.toml ${BUILD_BASE}/config.toml
RUN STAGE=3 ${BUILD_BASE}/build_rust.sh

FROM base-builder
COPY --from=rust-builder ${BUILD_BASE}/distroot ${BUILD_BASE}/distroot
COPY --from=rust-builder ${BUILD_BASE}/rustroot ${BUILD_BASE}/rustroot

RUN dnf install -y perl make

ENV PATH=${BUILD_BASE}/rustroot/bin:${BUILD_BASE}/distroot/bin:$PATH
ENV CC=${BUILD_BASE}/distroot/bin/clang
ENV CXX=${BUILD_BASE}/distroot/bin/clang++
ENV AR=${BUILD_BASE}/distroot/bin/llvm-ar
ENV CARGO_TARGET_X86_64_UNKNOWN_LINUX_GNU_LINKER=${BUILD_BASE}/distroot/bin/clang
