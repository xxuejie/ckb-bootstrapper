(use-modules (guix gexp)
             (guix packages)
             (guix build-system trivial)
             (gnu packages base)
             (gnu packages cross-base)
             (gnu packages commencement)
             (gnu packages gcc)
             (gnu packages linux)
             (srfi srfi-1))

(define (make-cross-toolchain target
                              base-gcc-for-libc
                              base-kernel-headers
                              base-libc
                              base-gcc)
  "Create a cross-compilation toolchain package for TARGET"
  (let* ((xbinutils (cross-binutils target))
         ;; 1. Build a cross-compiling gcc without targeting any libc, derived
         ;; from BASE-GCC-FOR-LIBC
         (xgcc-sans-libc (cross-gcc target
                                    #:xgcc base-gcc-for-libc
                                    #:xbinutils xbinutils))
         ;; 2. Build cross-compiled kernel headers with XGCC-SANS-LIBC, derived
         ;; from BASE-KERNEL-HEADERS
         (xkernel (cross-kernel-headers target
                                        #:linux-headers base-kernel-headers
                                        #:xgcc xgcc-sans-libc
                                        #:xbinutils xbinutils))
         ;; 3. Build a cross-compiled libc with XGCC-SANS-LIBC and XKERNEL,
         ;; derived from BASE-LIBC
         (xlibc (cross-libc target
                            #:libc base-libc
                            #:xgcc xgcc-sans-libc
                            #:xbinutils xbinutils
                            #:xheaders xkernel))
         ;; 4. Build a cross-compiling gcc targeting XLIBC, derived from
         ;; BASE-GCC
         (xgcc (cross-gcc target
                          #:xgcc base-gcc
                          #:xbinutils xbinutils
                          #:libc xlibc)))
    ;; Define a meta-package that propagates the resulting XBINUTILS, XLIBC, and
    ;; XGCC
    (package
      (name (string-append target "-toolchain"))
      (version (package-version xgcc))
      (source #f)
      (build-system trivial-build-system)
      (arguments '(#:builder (begin (mkdir %output) #t)))
      (propagated-inputs
        (list xbinutils
              xlibc
              xgcc
              `(,xlibc "static")
              `(,xgcc "lib")))
      (synopsis (string-append "Complete GCC tool chain for " target))
      (description (string-append "This package provides a complete GCC tool
chain for " target " development."))
      (home-page (package-home-page xgcc))
      (license (package-license xgcc)))))

(define* (make-bitcoin-cross-toolchain target
                                       #:key
                                       (base-gcc-for-libc gcc-13)
                                       (base-kernel-headers linux-libre-headers-6.1)
                                       (base-libc glibc)
                                       (base-gcc gcc-13))
  "Convenience wrapper around MAKE-CROSS-TOOLCHAIN with default values
desirable for building Bitcoin Core release binaries."
  (make-cross-toolchain target
                        base-gcc-for-libc
                        base-kernel-headers
                        base-libc
                        base-gcc))

(concatenate-manifests
  (list
    (packages->manifest
     (list (make-bitcoin-cross-toolchain "x86_64-linux-gnu")))
    (specifications->manifest
     '("coreutils"
       "diffutils"
       "findutils"
       "bash"
       "tar"
       "gzip"
       "xz"
       "sed"
       "grep"
       "gawk"
       "gmp"
       "mpc"
       "mpfr"
       "make@4.2.1"
       "git"
       "perl"
       "wget"
       "which"
       "python"
       "bison"
       "flex"
       "texinfo"
       "curl"
       "nss-certs"
       "cmake"))))
