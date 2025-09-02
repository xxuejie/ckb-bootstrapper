# TODO: checksum for all tarballs
FROM fedora:42 AS gnu-builder

ENV ALL_PROXY="http://192.168.1.247:31082"
ENV HTTP_PROXY="http://192.168.1.247:31082"
ENV HTTPS_PROXY="http://192.168.1.247:31082"

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

RUN curl -LO http://crosstool-ng.org/download/crosstool-ng/crosstool-ng-1.27.0.tar.xz
RUN tar xJf crosstool-ng-1.27.0.tar.xz
RUN cd crosstool-ng-1.27.0 && ./configure && make && make install && cd .. && rm -rf crosstool-ng-*

RUN mkdir /build
COPY .config /build/.config
RUN cd /build && CT_PREFIX=/distroot ct-ng build && cd / && rm -rf /build
RUN bash -c 'find /distroot/bin -name "x86_64-unknown-linux-gnu-*" | while read f; do ln -s "$(basename $f)" "${f/x86_64-unknown-linux-gnu-/}"; done'

FROM fedora:42 AS dist-builder
COPY --from=gnu-builder /distroot /distroot

ENV ALL_PROXY="http://192.168.1.247:31082"
ENV HTTP_PROXY="http://192.168.1.247:31082"
ENV HTTPS_PROXY="http://192.168.1.247:31082"

RUN dnf install -y \
        cmake \
        curl \
        make \
        python3

RUN curl -LO https://github.com/madler/zlib/releases/download/v1.3.1/zlib-1.3.1.tar.gz
RUN tar xzf zlib-1.3.1.tar.gz
RUN cd zlib-1.3.1 && \
  prefix=`/distroot/bin/cc -print-sysroot` CC=/distroot/bin/cc AR=/distroot/bin/ar \
    ./configure && make && make install && \
  cd .. && rm -rf zlib-*

RUN curl -LO https://github.com/llvm/llvm-project/releases/download/llvmorg-20.1.8/llvm-project-20.1.8.src.tar.xz
RUN tar xJf llvm-project-20.1.8.src.tar.xz
RUN cd llvm-project-20.1.8.src && mkdir build && cd build && \
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

RUN curl -LO https://github.com/facebook/zstd/releases/download/v1.5.7/zstd-1.5.7.tar.gz
RUN tar xzf zstd-1.5.7.tar.gz
RUN cd zstd-1.5.7 && \
  CC=/distroot/bin/clang CXX=/distroot/bin/clang++ AR=/distroot/bin/llvm-ar CFLAGS=-fPIC \
    make PREFIX=`/distroot/bin/cc -print-sysroot` install && \
  cd .. && rm -rf zstd-*

RUN dnf install -y \
        perl

RUN curl -LO https://github.com/openssl/openssl/releases/download/openssl-3.0.17/openssl-3.0.17.tar.gz
RUN tar xzf openssl-3.0.17.tar.gz
RUN cd openssl-3.0.17 && \
  CC=/distroot/bin/clang CXX=/distroot/bin/clang++ AR=/distroot/bin/llvm-ar \
    ./Configure --prefix=`/distroot/bin/cc -print-sysroot` && make && make install && \
  cd .. && rm -rf openssl-*

FROM fedora:42 AS rust-builder
COPY --from=dist-builder /distroot /distroot

ENV ALL_PROXY="http://192.168.1.247:31082"
ENV HTTP_PROXY="http://192.168.1.247:31082"
ENV HTTPS_PROXY="http://192.168.1.247:31082"

RUN dnf install -y \
        cmake \
        curl \
        make \
        python3

ENV PATH=/distroot/bin:$PATH
ENV CC=/distroot/bin/clang
ENV CXX=/distroot/bin/clang++
ENV AR=/distroot/bin/llvm-ar
ENV CARGO_TARGET_X86_64_UNKNOWN_LINUX_GNU_LINKER=/distroot/bin/clang

RUN curl -LO https://static.rust-lang.org/dist/rustc-1.85.0-src.tar.xz
RUN tar xJf rustc-1.85.0-src.tar.xz
COPY config.toml /rustc-1.85.0-src/config.toml
RUN cd rustc-1.85.0-src && \
  CMAKE_PREFIX_PATH=`/distroot/bin/cc -print-sysroot`:$CMAKE_PREFIX_PATH \
    OPENSSL_DIR=`/distroot/bin/cc -print-sysroot` \
    ./x.py build --stage 2 library cargo && \
  mkdir /rustroot && cp -r build/host/stage2/* /rustroot/ && cp build/host/stage2-tools-bin/cargo /rustroot/bin/ && \
  cd .. && rm -rf rustc-*

FROM fedora:42
COPY --from=rust-builder /distroot /distroot
COPY --from=rust-builder /rustroot /rustroot

RUN dnf install -y perl make

ENV ALL_PROXY="http://192.168.1.247:31082"
ENV HTTP_PROXY="http://192.168.1.247:31082"
ENV HTTPS_PROXY="http://192.168.1.247:31082"

ENV PATH=/rustroot/bin:/distroot/bin:$PATH
ENV CC=/distroot/bin/clang
ENV CXX=/distroot/bin/clang++
ENV AR=/distroot/bin/llvm-ar
ENV CARGO_TARGET_X86_64_UNKNOWN_LINUX_GNU_LINKER=/distroot/bin/clang
