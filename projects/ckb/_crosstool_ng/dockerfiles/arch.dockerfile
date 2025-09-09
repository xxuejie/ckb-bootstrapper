FROM archlinux:base AS base-builder

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

COPY build_gnu.sh /tmp/build_gnu.sh
COPY crosstool-ng.config /tmp/crosstool-ng.config
RUN /tmp/build_gnu.sh

FROM base-builder AS dist-builder
COPY --from=gnu-builder /distroot /distroot

RUN pacman --noconfirm -Syu \
           cmake \
           curl \
           flex \
           make \
           perl \
           python

# For pod2man
ENV PATH="/usr/bin/core_perl:${PATH}"

COPY build_llvm.sh /tmp/build_llvm.sh
RUN /tmp/build_llvm.sh

FROM base-builder AS rust-bootstrap-builder
COPY --from=dist-builder /distroot /distroot

RUN pacman --noconfirm -Syu \
           cmake \
           curl \
           make \
           python

COPY build_rust.sh /tmp/build_rust.sh
COPY rust-config-bootstrap.toml /tmp/config.toml
RUN STAGE=2 /tmp/build_rust.sh

FROM base-builder AS rust-builder
COPY --from=dist-builder /distroot /distroot
COPY --from=rust-bootstrap-builder /rustroot /rustbuilder

RUN pacman --noconfirm -Syu \
           cmake \
           curl \
           make \
           python

COPY build_rust.sh /tmp/build_rust.sh
COPY rust-config.toml /tmp/config.toml
RUN STAGE=3 /tmp/build_rust.sh

FROM base-builder
COPY --from=rust-builder /distroot /distroot
COPY --from=rust-builder /rustroot /rustroot

RUN pacman --noconfirm -Syu flex perl make

ENV PATH=/rustroot/bin:/distroot/bin:$PATH
ENV CC=/distroot/bin/clang
ENV CXX=/distroot/bin/clang++
ENV AR=/distroot/bin/llvm-ar
ENV CARGO_TARGET_X86_64_UNKNOWN_LINUX_GNU_LINKER=/distroot/bin/clang
