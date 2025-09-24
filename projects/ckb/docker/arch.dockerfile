FROM archlinux:base AS base-builder

# All dependencies will be built and installed to BUILD_BASE folder,
# this way the same scripts can be reused in non-docker environments.
ENV BUILD_BASE /tmp/ckb-build
RUN rm -rf ${BUILD_BASE} && mkdir -p ${BUILD_BASE}

# Base builder here allows customization of builder images, such as inserting
# lines for proxy configuration.

FROM base-builder AS gnu-builder
RUN pacman --noconfirm -Syu \
           autoconf \
           bison \
           curl \
           diffutils \
           file \
           flex \
           gawk \
           gcc \
           help2man \
           ncurses \
           libtool \
           make \
           patch \
           texinfo \
           which \
           unzip

COPY scripts/build_make42.sh ${BUILD_BASE}/build_make42.sh
RUN ${BUILD_BASE}/build_make42.sh
ENV PATH=${BUILD_BASE}/make42/bin:$PATH
RUN pacman -R make

COPY scripts/build_gnu_manual.sh ${BUILD_BASE}/build_gnu_manual.sh
RUN ${BUILD_BASE}/build_gnu_manual.sh

FROM base-builder AS dist-builder
COPY --from=gnu-builder ${BUILD_BASE}/distroot ${BUILD_BASE}/distroot

RUN pacman --noconfirm -Syu \
           cmake \
           curl \
           flex \
           make \
           perl \
           python

# For pod2man
ENV PATH="/usr/bin/core_perl:${PATH}"

COPY scripts/build_llvm.sh ${BUILD_BASE}/build_llvm.sh
RUN ${BUILD_BASE}/build_llvm.sh

FROM base-builder AS rust-bootstrap-builder
COPY --from=dist-builder ${BUILD_BASE}/distroot ${BUILD_BASE}/distroot

RUN pacman --noconfirm -Syu \
           cmake \
           curl \
           make \
           python

COPY scripts/build_rust.sh ${BUILD_BASE}/build_rust.sh
COPY scripts/rust-config-bootstrap.toml ${BUILD_BASE}/config.toml
RUN STAGE=2 ${BUILD_BASE}/build_rust.sh

FROM base-builder AS rust-builder
COPY --from=dist-builder ${BUILD_BASE}/distroot ${BUILD_BASE}/distroot
COPY --from=rust-bootstrap-builder ${BUILD_BASE}/rustroot ${BUILD_BASE}/rustbuilder

RUN pacman --noconfirm -Syu \
           cmake \
           curl \
           make \
           python

COPY scripts/build_rust.sh ${BUILD_BASE}/build_rust.sh
COPY scripts/rust-config.toml ${BUILD_BASE}/config.toml
RUN STAGE=3 ${BUILD_BASE}/build_rust.sh

FROM base-builder
COPY --from=rust-builder ${BUILD_BASE}/distroot ${BUILD_BASE}/distroot
COPY --from=rust-builder ${BUILD_BASE}/rustroot ${BUILD_BASE}/rustroot

RUN pacman --noconfirm -Syu flex git perl make
RUN git config --global --add safe.directory ${BUILD_BASE}/ckb

ENV PATH=${BUILD_BASE}/rustroot/bin:${BUILD_BASE}/distroot/bin:$PATH
ENV CC=${BUILD_BASE}/distroot/bin/clang
ENV CXX=${BUILD_BASE}/distroot/bin/clang++
ENV AR=${BUILD_BASE}/distroot/bin/llvm-ar
ENV CARGO_HOME=${BUILD_BASE}/cargo
ENV SOURCE_DATE_EPOCH=0
