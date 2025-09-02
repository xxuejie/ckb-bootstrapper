FROM ubuntu:noble AS base-builder

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

ENV CROSSTOOL_SHA256=0506ab98fa0ad6d263a555feeb2c7fff9bc24a434635d4b0cdff9137fe5b4477
ENV CROSSTOOL_VERSION=1.27.0

RUN curl -LO http://crosstool-ng.org/download/crosstool-ng/crosstool-ng-${CROSSTOOL_VERSION}.tar.xz
RUN echo "${CROSSTOOL_SHA256} crosstool-ng-${CROSSTOOL_VERSION}.tar.xz" | sha256sum -c -
RUN tar xJf crosstool-ng-${CROSSTOOL_VERSION}.tar.xz
RUN cd crosstool-ng-${CROSSTOOL_VERSION} && ./configure && make && make install && cd .. && rm -rf crosstool-ng-*

RUN mkdir /build
COPY .config /build/.config
RUN cd /build && CT_PREFIX=/distroot ct-ng build && cd / && rm -rf /build
RUN bash -c 'find /distroot/bin -name "x86_64-unknown-linux-gnu-*" | while read f; do ln -s "$(basename $f)" "${f/x86_64-unknown-linux-gnu-/}"; done'

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

ENV ZLIB_SHA256=9a93b2b7dfdac77ceba5a558a580e74667dd6fede4585b91eefb60f03b72df23
ENV ZLIB_VERSION=1.3.1

RUN curl -LO https://github.com/madler/zlib/releases/download/v${ZLIB_VERSION}/zlib-${ZLIB_VERSION}.tar.gz
RUN echo "${ZLIB_SHA256} zlib-${ZLIB_VERSION}.tar.gz" | sha256sum -c -
RUN tar xzf zlib-${ZLIB_VERSION}.tar.gz
RUN cd zlib-${ZLIB_VERSION} && \
  prefix=`/distroot/bin/cc -print-sysroot` CC=/distroot/bin/cc AR=/distroot/bin/ar \
    ./configure && make && make install && \
  cd .. && rm -rf zlib-*

ENV LLVM_SHA256=6898f963c8e938981e6c4a302e83ec5beb4630147c7311183cf61069af16333d
ENV LLVM_VERSION=20.1.8

RUN curl -LO https://github.com/llvm/llvm-project/releases/download/llvmorg-${LLVM_VERSION}/llvm-project-${LLVM_VERSION}.src.tar.xz
RUN echo "${LLVM_SHA256} llvm-project-${LLVM_VERSION}.src.tar.xz" | sha256sum -c -
RUN tar xJf llvm-project-${LLVM_VERSION}.src.tar.xz
RUN cd llvm-project-${LLVM_VERSION}.src && mkdir build && cd build && \
  CMAKE_PREFIX_PATH=`/distroot/bin/cc -print-sysroot`:$CMAKE_PREFIX_PATH cmake ../llvm \
    -DCMAKE_C_COMPILER=/distroot/bin/cc \
    -DCMAKE_CXX_COMPILER=/distroot/bin/c++ \
    -DDEFAULT_SYSROOT=`/distroot/bin/cc -print-sysroot` \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX=/distroot \
    -DCOMPILER_RT_BUILD_SANITIZERS=OFF \
    -DCOMPILER_RT_BUILD_XRAY=OFF \
    -DCOMPILER_RT_BUILD_MEMPROF=OFF \
    -DCOMPILER_RT_BUILD_CTX_PROFILE=OFF \
    -DLLVM_ENABLE_ZLIB=FORCE_ON \
    -DLLVM_TARGETS_TO_BUILD=X86 \
    -DLLVM_INCLUDE_BENCHMARKS=OFF \
    -DLLVM_INCLUDE_TESTS=OFF \
    -DLLVM_INCLUDE_EXAMPLES=OFF \
    -DLLVM_ENABLE_PROJECTS="clang;lld;compiler-rt" && \
  make -j$(nproc) && make install && \
  cd ../.. && rm -rf llvm-project-*

ENV ZSTD_SHA256=eb33e51f49a15e023950cd7825ca74a4a2b43db8354825ac24fc1b7ee09e6fa3
ENV ZSTD_VERSION=1.5.7

RUN curl -LO https://github.com/facebook/zstd/releases/download/v${ZSTD_VERSION}/zstd-${ZSTD_VERSION}.tar.gz
RUN echo "${ZSTD_SHA256} zstd-${ZSTD_VERSION}.tar.gz" | sha256sum -c -
RUN tar xzf zstd-${ZSTD_VERSION}.tar.gz
RUN cd zstd-${ZSTD_VERSION} && \
  CC=/distroot/bin/clang CXX=/distroot/bin/clang++ AR=/distroot/bin/llvm-ar CFLAGS=-fPIC \
    make PREFIX=`/distroot/bin/cc -print-sysroot` install && \
  cd .. && rm -rf zstd-*

ENV OPENSSL_SHA256=dfdd77e4ea1b57ff3a6dbde6b0bdc3f31db5ac99e7fdd4eaf9e1fbb6ec2db8ce
ENV OPENSSL_VERSION=3.0.17

RUN curl -LO https://github.com/openssl/openssl/releases/download/openssl-${OPENSSL_VERSION}/openssl-${OPENSSL_VERSION}.tar.gz
RUN echo "${OPENSSL_SHA256} openssl-${OPENSSL_VERSION}.tar.gz" | sha256sum -c -
RUN tar xzf openssl-${OPENSSL_VERSION}.tar.gz
RUN cd openssl-${OPENSSL_VERSION} && \
  SOURCE_DATE_EPOCH=0 \
  CC=/distroot/bin/clang CXX=/distroot/bin/clang++ AR=/distroot/bin/llvm-ar \
    ./Configure --prefix=`/distroot/bin/cc -print-sysroot` && make && make install && \
  cd .. && rm -rf openssl-*

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

ENV PATH=/distroot/bin:$PATH
ENV CC=/distroot/bin/clang
ENV CXX=/distroot/bin/clang++
ENV AR=/distroot/bin/llvm-ar
ENV CARGO_TARGET_X86_64_UNKNOWN_LINUX_GNU_LINKER=/distroot/bin/clang

ENV RUST_SHA256=d542c397217b5ba5bac7eb274f5ca62d031f61842c3ba4cc5328c709c38ea1e7
ENV RUST_VERSION=1.85.0

RUN curl -LO https://static.rust-lang.org/dist/rustc-${RUST_VERSION}-src.tar.xz
RUN echo "${RUST_SHA256} rustc-${RUST_VERSION}-src.tar.xz" | sha256sum -c -
RUN tar xJf rustc-${RUST_VERSION}-src.tar.xz
COPY config.toml /rustc-${RUST_VERSION}-src/config.toml
RUN cd rustc-${RUST_VERSION}-src && \
  CMAKE_PREFIX_PATH=`/distroot/bin/cc -print-sysroot`:$CMAKE_PREFIX_PATH \
    OPENSSL_DIR=`/distroot/bin/cc -print-sysroot` \
    ./x.py build --stage 2 library cargo && \
  mkdir /rustroot && cp -r build/host/stage2/* /rustroot/ && cp build/host/stage2-tools-bin/cargo /rustroot/bin/ && \
  cd .. && rm -rf rustc-*

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
